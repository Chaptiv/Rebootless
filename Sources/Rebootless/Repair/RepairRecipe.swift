import Foundation

public struct RepairRecipe: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let subsystemName: String
    public let description: String
    public let symptoms: [String]
    public let keywords: [String]
    public let diagnosticChecks: [any DiagnosticCheck]
    public let repairStages: [RepairStage]
    public let verificationChecks: [any VerificationCheck]
    public let supportedOSVersions: String
    
    public init(
        id: String,
        name: String,
        subsystemName: String,
        description: String,
        symptoms: [String],
        keywords: [String],
        diagnosticChecks: [any DiagnosticCheck],
        repairStages: [RepairStage],
        verificationChecks: [any VerificationCheck],
        supportedOSVersions: String = "macOS 14.0+"
    ) {
        self.id = id
        self.name = name
        self.subsystemName = subsystemName
        self.description = description
        self.symptoms = symptoms
        self.keywords = keywords
        self.diagnosticChecks = diagnosticChecks
        self.repairStages = repairStages
        self.verificationChecks = verificationChecks
        self.supportedOSVersions = supportedOSVersions
    }
}

extension RepairRecipe {
    /// Reference implementation: Quick Look Repair Recipe
    public static func makeQuickLookRecipe(
        customStages: [RepairStage]? = nil,
        customVerifications: [any VerificationCheck]? = nil
    ) -> RepairRecipe {
        let stages = customStages ?? [
            RepairStage(
                id: "ql_stage1_soft_reset",
                name: "Stage 1 – Soft Reset",
                description: "Reloads Quick Look generator list and flushes thumbnail cache without terminating UI services.",
                impact: .minimal,
                warningMessage: nil,
                requiresConfirmation: false,
                executeAction: {
                    let result = await ServiceRunner.shared.executeCommand("qlmanage -r && qlmanage -r cache")
                    return (result.isSuccess, result.output)
                }
            ),
            RepairStage(
                id: "ql_stage2_service_restart",
                name: "Stage 2 – Service Restart",
                description: "Restarts QuickLookUIService, QuickLookSatellite, and ThumbnailsAgent background daemons.",
                impact: .low,
                warningMessage: "Any open Quick Look preview window will close.",
                requiresConfirmation: false,
                executeAction: {
                    let cmd = "killall QuickLookUIService 2>/dev/null || true; killall QuickLookSatellite 2>/dev/null || true; killall com.apple.quicklook.ThumbnailsAgent 2>/dev/null || true; qlmanage -r 2>/dev/null || true"
                    let result = await ServiceRunner.shared.executeCommand(cmd)
                    // Allow half second for launchd to prepare fresh services
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    return (result.isSuccess, result.output)
                }
            ),
            RepairStage(
                id: "ql_stage3_finder_restart",
                name: "Stage 3 – Finder Integration Reset",
                description: "Restarts Finder to clear hung Quick Look selection hooks and preview handlers.",
                impact: .moderate,
                warningMessage: "Open Finder windows will briefly close and reopen.",
                requiresConfirmation: true,
                executeAction: {
                    let result = await ServiceRunner.shared.executeCommand("killall Finder")
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    return (result.isSuccess, result.output)
                }
            )
        ]
        
        let verifications = customVerifications ?? [
            QuickLookFunctionalVerificationCheck()
        ]
        
        return RepairRecipe(
            id: "recipe_quicklook",
            name: "Quick Look Previews",
            subsystemName: "Quick Look",
            description: "Spacebar, Force Click, and thumbnail preview generator subsystem.",
            symptoms: [
                "Spacebar file previews do not open or show a blank box",
                "Force Click previews stop responding",
                "File thumbnails fail to generate in Finder or file dialogs"
            ],
            keywords: [
                "force touch preview stopped working",
                "force touch preview doesn't work",
                "spacebar preview doesn't work",
                "spacebar preview broken",
                "can't preview files",
                "quick look stopped working",
                "quick look",
                "quicklook",
                "preview",
                "file preview",
                "spacebar",
                "space bar",
                "force touch",
                "force click",
                "thumbnail"
            ],
            diagnosticChecks: [
                QuickLookDiagnosticCheck()
            ],
            repairStages: stages,
            verificationChecks: verifications,
            supportedOSVersions: "macOS 14.0+"
        )
    }
}

/// Multi-Layer Functional Verification for Quick Look
public struct QuickLookFunctionalVerificationCheck: VerificationCheck {
    public let name: String = "Quick Look Multi-Layer Verification"
    
    public init() {}
    
    public func verify() async -> VerificationResult {
        // Run probes across all 4 distinct layers
        let report = await QuickLookLayerProber.shared.runCompleteDiagnostics()
        
        // 1. Check for hard failures in any layer
        for probe in report.probes {
            if probe.status == .problemDetected {
                return .stillFailing(reason: "Failure in \(probe.layer.rawValue): \(probe.details)")
            }
        }
        
        // 2. Generation, daemon, and Finder event loop passed
        var verifiedDetails = "Generation, Daemon, and Finder event loop responding normally."
        if let uiProbe = report.probes.first(where: { $0.layer == .uiPresentation }) {
            if uiProbe.status == .unknown {
                verifiedDetails += " Note: Active window presentation is marked unknown (macOS provides no non-invasive headless window test)."
            }
        }
        
        return .verifiedHealthy(details: verifiedDetails)
    }
}

/// Multi-Layer Diagnostic Check for Quick Look
public struct QuickLookDiagnosticCheck: DiagnosticCheck {
    public let name: String = "Quick Look Multi-Layer Diagnostic"
    
    public init() {}
    
    public func diagnose() async -> DiagnosticResult {
        let report = await QuickLookLayerProber.shared.runCompleteDiagnostics()
        
        var summaryLines: [String] = []
        for probe in report.probes {
            summaryLines.append("[\(probe.layer.rawValue)]: \(probe.status.rawValue) (\(String(format: "%.0f", probe.latencyMs))ms) – \(probe.details)")
        }
        
        return DiagnosticResult(
            isIssueDetected: report.overallStatus == .problemDetected,
            summary: report.explanation,
            technicalDetails: summaryLines.joined(separator: "\n")
        )
    }
}
