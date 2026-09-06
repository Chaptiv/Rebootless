import XCTest
import Foundation
@testable import Rebootless

final class RebootlessTests: XCTestCase {
    
    // MARK: - Baseline Model Tests
    
    func testUniqueServiceIds() {
        let services = ServiceItem.builtInServices
        let ids = services.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "All built-in service IDs should be unique")
    }
    
    func testServiceProperties() {
        for service in ServiceItem.builtInServices {
            XCTAssertFalse(service.id.isEmpty)
            XCTAssertFalse(service.name.isEmpty)
            XCTAssertFalse(service.subtitle.isEmpty)
            XCTAssertFalse(service.command.isEmpty)
            XCTAssertFalse(service.fixesDescription.isEmpty)
            XCTAssertFalse(service.iconName.isEmpty)
        }
    }
    
    func testTroubleshootMappings() {
        let validServiceIds = Set(ServiceItem.builtInServices.map { $0.id })
        for issue in TroubleshootItem.commonIssues {
            XCTAssertTrue(validServiceIds.contains(issue.serviceId), "Issue \(issue.id) maps to missing service \(issue.serviceId)")
            XCTAssertFalse(issue.title.isEmpty)
            XCTAssertFalse(issue.symptom.isEmpty)
            XCTAssertFalse(issue.recommendedActionTitle.isEmpty)
        }
    }
    
    func testServiceRunnerExecution() async {
        let testService = ServiceItem(
            id: "test_echo",
            name: "Echo Test",
            subtitle: "Unit test service",
            category: .system,
            iconName: "terminal",
            fixesDescription: "Tests execution",
            command: "echo 'Rebootless Test Output'",
            requiresAdmin: false,
            isBuiltIn: false
        )
        
        let result = await ServiceRunner.shared.execute(service: testService)
        XCTAssertTrue(result.isSuccess)
        XCTAssertTrue(result.output.contains("Rebootless Test Output"))
        XCTAssertGreaterThanOrEqual(result.duration, 0)
        XCTAssertEqual(result.serviceId, "test_echo")
    }
    
    func testRestartResultSerialization() throws {
        let result = RestartResult(
            serviceId: "finder",
            serviceName: "Finder",
            command: "killall Finder",
            duration: 0.12,
            isSuccess: true,
            output: "done",
            errorMessage: nil
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(result)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RestartResult.self, from: data)
        
        XCTAssertEqual(decoded.serviceId, result.serviceId)
        XCTAssertEqual(decoded.serviceName, result.serviceName)
        XCTAssertEqual(decoded.isSuccess, result.isSuccess)
        XCTAssertEqual(decoded.command, result.command)
    }
    
    // MARK: - Health Confirmation Tests (Mocks)
    
    func testHealthConfirmationTransientFailureIgnored() async {
        let monitor = HealthMonitor()
        
        final class Counter: @unchecked Sendable {
            var count = 0
        }
        let counter = Counter()
        
        // Fails first call, succeeds on retry
        let mockCheck = MockHealthCheck(
            subsystemId: "test_transient",
            name: "Transient Subsystem",
            primaryGenerator: {
                counter.count += 1
                if counter.count == 1 {
                    return HealthResult(subsystemId: "test_transient", status: .problemDetected, details: "Glitch")
                } else {
                    return HealthResult(subsystemId: "test_transient", status: .healthy, details: "Recovered")
                }
            }
        )
        
        await monitor.registerHealthCheck(mockCheck)
        let status = await monitor.evaluateSubsystem(id: "test_transient", skipRetryDelayForTesting: true)
        
        XCTAssertEqual(status, .healthy, "Transient failure resolved on retry should evaluate to healthy")
        let activeIssues = await monitor.issueTracker.getActiveIssues()
        XCTAssertTrue(activeIssues.isEmpty, "No active issue should be recorded for transient failure")
    }
    
    func testHealthConfirmationPersistentFailure() async {
        let monitor = HealthMonitor()
        
        let mockCheck = MockHealthCheck(
            subsystemId: "test_persistent",
            name: "Broken Subsystem",
            primaryGenerator: {
                HealthResult(subsystemId: "test_persistent", status: .problemDetected, details: "Timeout")
            },
            secondaryGenerator: {
                HealthResult(subsystemId: "test_persistent", status: .problemDetected, details: "Secondary failed")
            }
        )
        
        await monitor.registerHealthCheck(mockCheck)
        let status = await monitor.evaluateSubsystem(id: "test_persistent", skipRetryDelayForTesting: true)
        
        XCTAssertEqual(status, .problemDetected, "Persistent failure across retry and secondary check must confirm problemDetected")
        let active = await monitor.issueTracker.getIssue(for: "test_persistent")
        XCTAssertNotNil(active)
        XCTAssertEqual(active?.subsystemName, "Broken Subsystem")
    }
    
    // MARK: - Notification Deduplication Tests
    
    func testNotificationDeduplication() async {
        let tracker = IssueTracker()
        
        let (_, shouldNotify1) = await tracker.recordProblem(
            subsystemId: "quicklook",
            subsystemName: "Quick Look",
            recipeId: "recipe_quicklook",
            userVisibleTitle: "Quick Look Issue",
            symptoms: ["Preview hung"]
        )
        XCTAssertTrue(shouldNotify1, "First confirmation must request notification")
        
        let (_, shouldNotify2) = await tracker.recordProblem(
            subsystemId: "quicklook",
            subsystemName: "Quick Look",
            recipeId: "recipe_quicklook",
            userVisibleTitle: "Quick Look Issue",
            symptoms: ["Preview hung"]
        )
        XCTAssertFalse(shouldNotify2, "Second confirmation on active unresolved issue must NOT request duplicate notification")
    }
    
    // MARK: - Recovery Detection Tests
    
    func testRecoveryDetection() async {
        let monitor = HealthMonitor()
        
        final class StatusHolder: @unchecked Sendable {
            var currentStatus: SubsystemHealthStatus = .problemDetected
        }
        let holder = StatusHolder()
        
        let mockCheck = MockHealthCheck(
            subsystemId: "test_subsystem",
            name: "Recoverable Subsystem",
            primaryGenerator: {
                HealthResult(subsystemId: "test_subsystem", status: holder.currentStatus, details: "Status check")
            }
        )
        
        await monitor.registerHealthCheck(mockCheck)
        
        // 1. Trigger confirmed problem
        _ = await monitor.evaluateSubsystem(id: "test_subsystem", skipRetryDelayForTesting: true)
        let issueBefore = await monitor.issueTracker.getIssue(for: "test_subsystem")
        XCTAssertNotNil(issueBefore)
        
        // 2. Subsystem recovers
        holder.currentStatus = .healthy
        final class RecoveredFlag: @unchecked Sendable {
            var wasNotified = false
        }
        let flag = RecoveredFlag()
        await monitor.setCallbacks(onSubsystemRecovered: { id in
            if id == "test_subsystem" {
                flag.wasNotified = true
            }
        })
        
        let statusAfter = await monitor.evaluateSubsystem(id: "test_subsystem", skipRetryDelayForTesting: true)
        XCTAssertEqual(statusAfter, .healthy)
        
        let issueAfter = await monitor.issueTracker.getIssue(for: "test_subsystem")
        XCTAssertNil(issueAfter, "Active issue state must be cleared after recovery")
        XCTAssertTrue(flag.wasNotified, "Recovery callback must be notified")
    }
    
    // MARK: - Repair Escalation & Immediate Success Tests
    
    func testRepairEscalation() async {
        let engine = RepairEngine()
        
        final class StageExecutionTracker: @unchecked Sendable {
            var executedStages: [String] = []
        }
        let tracker = StageExecutionTracker()
        
        // Stage 1 fails verification, Stage 2 succeeds
        final class VerificationState: @unchecked Sendable {
            var checkCount = 0
        }
        let vState = VerificationState()
        
        let mockVerification = MockVerificationCheck(
            name: "Escalation Verification",
            resultGenerator: {
                vState.checkCount += 1
                if vState.checkCount == 1 {
                    return .stillFailing(reason: "Still unresponsive after stage 1")
                } else {
                    return .verifiedHealthy(details: "Healthy after stage 2")
                }
            }
        )
        
        let stage1 = RepairStage(
            id: "stage_1",
            name: "Stage 1 – Soft Reset",
            description: "Soft reset",
            executeAction: {
                tracker.executedStages.append("Stage 1")
                return (true, "Soft reset done")
            }
        )
        
        let stage2 = RepairStage(
            id: "stage_2",
            name: "Stage 2 – Service Restart",
            description: "Service restart",
            executeAction: {
                tracker.executedStages.append("Stage 2")
                return (true, "Services restarted")
            }
        )
        
        let stage3 = RepairStage(
            id: "stage_3",
            name: "Stage 3 – Finder Restart",
            description: "Finder restart",
            executeAction: {
                tracker.executedStages.append("Stage 3")
                return (true, "Finder restarted")
            }
        )
        
        let recipe = RepairRecipe(
            id: "test_escalation_recipe",
            name: "Escalation Test Recipe",
            subsystemName: "Test Subsystem",
            description: "Test recipe",
            symptoms: ["Broken"],
            keywords: ["test"],
            diagnosticChecks: [],
            repairStages: [stage1, stage2, stage3],
            verificationChecks: [mockVerification]
        )
        
        let result = await engine.execute(recipe: recipe)
        
        XCTAssertEqual(result.status, .fixed, "Repair should report fixed after stage 2")
        XCTAssertEqual(tracker.executedStages, ["Stage 1", "Stage 2"], "Stage 1 and 2 must execute, Stage 3 must NOT execute")
        XCTAssertEqual(result.executedStages.count, 2)
    }
    
    func testImmediateRepairSuccessDoesNotEscalate() async {
        let engine = RepairEngine()
        
        final class Tracker: @unchecked Sendable {
            var stagesRun: [String] = []
        }
        let tracker = Tracker()
        
        let mockVerification = MockVerificationCheck(
            name: "Immediate Verification",
            result: .verifiedHealthy(details: "Healthy immediately")
        )
        
        let stage1 = RepairStage(
            id: "stage_1",
            name: "Stage 1",
            description: "First step",
            executeAction: {
                tracker.stagesRun.append("Stage 1")
                return (true, "OK")
            }
        )
        
        let stage2 = RepairStage(
            id: "stage_2",
            name: "Stage 2",
            description: "Second step",
            executeAction: {
                tracker.stagesRun.append("Stage 2")
                return (true, "OK")
            }
        )
        
        let recipe = RepairRecipe(
            id: "test_immediate_recipe",
            name: "Immediate Recipe",
            subsystemName: "Test Subsystem",
            description: "Test",
            symptoms: ["Glitch"],
            keywords: ["test"],
            diagnosticChecks: [],
            repairStages: [stage1, stage2],
            verificationChecks: [mockVerification]
        )
        
        let result = await engine.execute(recipe: recipe)
        
        XCTAssertEqual(result.status, .fixed)
        XCTAssertEqual(tracker.stagesRun, ["Stage 1"], "Stage 2 must NOT execute when Stage 1 passes verification")
    }
    
    func testCommandFailureDoesNotReportFixed() async {
        let engine = RepairEngine()
        
        let mockVerification = MockVerificationCheck(
            name: "Failing Verification",
            result: .stillFailing(reason: "Still broken")
        )
        
        let stage1 = RepairStage(
            id: "failing_stage",
            name: "Failing Stage",
            description: "Fails",
            executeAction: {
                return (false, "Command exited with status 1")
            }
        )
        
        let recipe = RepairRecipe(
            id: "test_command_failure_recipe",
            name: "Failing Recipe",
            subsystemName: "Test",
            description: "Test",
            symptoms: [],
            keywords: [],
            diagnosticChecks: [],
            repairStages: [stage1],
            verificationChecks: [mockVerification]
        )
        
        let result = await engine.execute(recipe: recipe)
        XCTAssertNotEqual(result.status, .fixed, "Failed command and verification must not report fixed")
        XCTAssertEqual(result.status, .stillBroken)
    }
    
    func testUnverifiableRepairReturnsExpectedStatus() async {
        let engine = RepairEngine()
        
        let stage1 = RepairStage(
            id: "unverified_stage",
            name: "Unverified Stage",
            description: "No verification available",
            executeAction: {
                return (true, "Executed without verification")
            }
        )
        
        let recipe = RepairRecipe(
            id: "test_unverifiable_recipe",
            name: "Unverifiable Recipe",
            subsystemName: "Test",
            description: "Test",
            symptoms: [],
            keywords: [],
            diagnosticChecks: [],
            repairStages: [stage1],
            verificationChecks: [] // No verification checks provided
        )
        
        let result = await engine.execute(recipe: recipe)
        XCTAssertEqual(result.status, .repairExecutedButUnverified, "Must report repairExecutedButUnverified when no verification check exists")
    }
    
    // MARK: - Local Symptom Matching Tests
    
    func testSymptomMatching() {
        let qlRecipe = RepairRecipe.makeQuickLookRecipe()
        let matcher = SymptomMatcher(recipes: [qlRecipe])
        
        let testQueries = [
            "force touch preview stopped working",
            "force touch preview doesn't work",
            "spacebar preview doesn't work",
            "spacebar preview broken",
            "can't preview files",
            "quick look stopped working"
        ]
        
        for query in testQueries {
            let matches = matcher.match(query: query)
            XCTAssertFalse(matches.isEmpty, "Query '\(query)' should match Quick Look recipe")
            XCTAssertEqual(matches.first?.recipe.id, "recipe_quicklook", "Query '\(query)' must resolve to recipe_quicklook")
            XCTAssertGreaterThanOrEqual(matches.first?.confidenceScore ?? 0, 0.45)
        }
    }
    
    // MARK: - Multi-Layer Quick Look Diagnostic Tests
    
    func testLayerProberGenerationLayer() async {
        let probe = await QuickLookLayerProber.shared.probeGenerationLayer()
        XCTAssertEqual(probe.layer, .generation)
        XCTAssertTrue(probe.isVerifiableNonInvasively)
        XCTAssertTrue(probe.status == .healthy || probe.status == .problemDetected)
    }
    
    func testLayerProberDaemonLayer() async {
        let probe = await QuickLookLayerProber.shared.probeDaemonLayer()
        XCTAssertEqual(probe.layer, .daemon)
        XCTAssertTrue(probe.isVerifiableNonInvasively)
        XCTAssertTrue(probe.status == .healthy || probe.status == .problemDetected)
    }
    
    func testLayerProberUIPresentationLayerUnknownConstraint() async {
        let probe = await QuickLookLayerProber.shared.probeUIPresentationLayer()
        XCTAssertEqual(probe.layer, .uiPresentation)
        
        // Critical requirement: If not actively in a crash/zombie state, on-screen presentation
        // cannot be tested non-invasively, so it must be marked unknown rather than healthy!
        if probe.status != .problemDetected {
            XCTAssertEqual(probe.status, .unknown, "On-screen window presentation must be marked unknown rather than falsely healthy")
            XCTAssertFalse(probe.isVerifiableNonInvasively)
            XCTAssertNotNil(probe.limitationNote)
        }
    }
    
    func testLayerProberFinderIntegrationLayer() async {
        let probe = await QuickLookLayerProber.shared.probeFinderIntegrationLayer()
        XCTAssertEqual(probe.layer, .finderIntegration)
        XCTAssertTrue(probe.isVerifiableNonInvasively)
        XCTAssertTrue(probe.status == .healthy || probe.status == .problemDetected)
    }
    
    func testCompleteDiagnosticsReportCoversAllFourLayers() async {
        let report = await QuickLookLayerProber.shared.runCompleteDiagnostics()
        let reportedLayers = Set(report.probes.map { $0.layer })
        
        XCTAssertEqual(reportedLayers.count, 4, "Report must cover all 4 distinct subsystem layers")
        XCTAssertTrue(reportedLayers.contains(.generation), "Must include Generation layer")
        XCTAssertTrue(reportedLayers.contains(.daemon), "Must include Daemon layer")
        XCTAssertTrue(reportedLayers.contains(.uiPresentation), "Must include UI/Presentation layer")
        XCTAssertTrue(reportedLayers.contains(.finderIntegration), "Must include Finder Integration layer")
    }
    
    func testLayerDiagnosticsDistinguishesDaemonFromUI() {
        // Verify that a report can have a healthy daemon while UI presentation is unknown or failing
        let daemonProbe = QuickLookProbeResult(
            layer: .daemon,
            probeName: "quicklookd probe",
            status: .healthy,
            latencyMs: 15.0,
            details: "quicklookd responsive",
            isVerifiableNonInvasively: true
        )
        let uiProbe = QuickLookProbeResult(
            layer: .uiPresentation,
            probeName: "QuickLookUIService probe",
            status: .problemDetected,
            latencyMs: 12.0,
            details: "Zombie QuickLookUIService detected",
            isVerifiableNonInvasively: true
        )
        
        let report = QuickLookDiagnosticsReport(
            overallStatus: .problemDetected,
            probes: [daemonProbe, uiProbe],
            explanation: "UI layer failed while daemon is healthy"
        )
        
        XCTAssertEqual(report.overallStatus, .problemDetected)
        XCTAssertEqual(report.probes.first(where: { $0.layer == .daemon })?.status, .healthy)
        XCTAssertEqual(report.probes.first(where: { $0.layer == .uiPresentation })?.status, .problemDetected)
    }
}
