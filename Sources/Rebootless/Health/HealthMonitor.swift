import Foundation
import Combine

public actor HealthMonitor {
    public static let shared = HealthMonitor()
    
    private var healthChecks: [String: any HealthCheck] = [:]
    private var subsystemStates: [String: SubsystemHealthStatus] = [:]
    public let issueTracker = IssueTracker()
    
    public var isMonitoringEnabled: Bool = true
    public var retryDelayNanoseconds: UInt64 = 5_000_000_000 // 5 seconds
    
    private var monitoringTask: Task<Void, Never>?
    
    // Callbacks for events
    private var onProblemConfirmed: (@Sendable (ActiveIssue) -> Void)?
    private var onSubsystemRecovered: (@Sendable (String) -> Void)?
    
    public init() {
        // Register Quick Look health check as reference implementation
        let ql = QuickLookHealthCheck()
        healthChecks[ql.subsystemId] = ql
    }
    
    public func registerHealthCheck(_ check: any HealthCheck) {
        healthChecks[check.subsystemId] = check
    }
    
    public func setCallbacks(
        onProblemConfirmed: (@Sendable (ActiveIssue) -> Void)? = nil,
        onSubsystemRecovered: (@Sendable (String) -> Void)? = nil
    ) {
        self.onProblemConfirmed = onProblemConfirmed
        self.onSubsystemRecovered = onSubsystemRecovered
    }
    
    public func getSubsystemStatus(_ subsystemId: String) -> SubsystemHealthStatus {
        subsystemStates[subsystemId] ?? .unknown
    }
    
    public func getAllSubsystemStatuses() -> [String: SubsystemHealthStatus] {
        subsystemStates
    }
    
    /// Conservative evaluation: initial check -> retry if failed -> secondary confirmation -> confirm or discard
    public func evaluateSubsystem(
        id: String,
        skipRetryDelayForTesting: Bool = false
    ) async -> SubsystemHealthStatus {
        guard let check = healthChecks[id] else {
            return .unsupported
        }
        
        let initialResult = await check.checkHealth()
        
        if initialResult.status.isHealthy {
            // Check if it was previously an active problem
            if let _ = await issueTracker.recordRecovery(subsystemId: id) {
                subsystemStates[id] = .healthy
                onSubsystemRecovered?(id)
            } else {
                subsystemStates[id] = .healthy
            }
            return .healthy
        }
        
        // Initial check failed. Conservative rule: Do NOT immediately alert!
        // Wait and retry
        if !skipRetryDelayForTesting {
            try? await Task.sleep(nanoseconds: retryDelayNanoseconds)
        }
        
        let retryResult = await check.checkHealth()
        if retryResult.status.isHealthy {
            // Transient failure resolved on retry
            subsystemStates[id] = .healthy
            return .healthy
        }
        
        // Retry also failed. Run secondary independent verification if available
        if let secondaryResult = await check.secondaryConfirmation() {
            if secondaryResult.status.isHealthy {
                // Secondary check indicates system is still operational
                subsystemStates[id] = .degraded
                return .degraded
            }
        }
        
        // Confirmed problem!
        subsystemStates[id] = .problemDetected
        
        let symptoms: [String]
        let title: String
        let recipeId: String
        
        if id == "quicklook" {
            title = "Quick Look appears to have stopped responding."
            symptoms = [
                "Spacebar file previews no longer open",
                "Force Click previews stop working",
                "File thumbnails fail to generate"
            ]
            recipeId = "recipe_quicklook"
        } else {
            title = "\(check.name) issue detected."
            symptoms = ["Subsystem is unresponsive"]
            recipeId = id
        }
        
        let (activeIssue, shouldNotify) = await issueTracker.recordProblem(
            subsystemId: id,
            subsystemName: check.name,
            recipeId: recipeId,
            userVisibleTitle: title,
            symptoms: symptoms
        )
        
        if shouldNotify {
            onProblemConfirmed?(activeIssue)
        }
        
        return .problemDetected
    }
    
    public func evaluateAllSubsystems(skipRetryDelayForTesting: Bool = false) async {
        for id in healthChecks.keys {
            _ = await evaluateSubsystem(id: id, skipRetryDelayForTesting: skipRetryDelayForTesting)
        }
    }
    
    public func startBackgroundMonitoring(intervalSeconds: Double = 60.0) {
        stopBackgroundMonitoring()
        guard isMonitoringEnabled else { return }
        
        monitoringTask = Task {
            while !Task.isCancelled {
                await evaluateAllSubsystems()
                let intervalNanos = UInt64(intervalSeconds * 1_000_000_000)
                try? await Task.sleep(nanoseconds: intervalNanos)
            }
        }
    }
    
    public func stopBackgroundMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
    }
}
