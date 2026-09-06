import Foundation

public struct QuickLookHealthCheck: HealthCheck {
    public let subsystemId: String = "quicklook"
    public let name: String = "Quick Look Subsystem Health"
    
    public init() {}
    
    public func checkHealth() async -> HealthResult {
        let report = await QuickLookLayerProber.shared.runCompleteDiagnostics()
        
        let failingProbes = report.probes.filter { $0.status == .problemDetected }
        if !failingProbes.isEmpty {
            let layerNames = failingProbes.map { "\($0.layer.rawValue): \($0.details)" }.joined(separator: " | ")
            return HealthResult(
                subsystemId: subsystemId,
                status: .problemDetected,
                details: "Layer failure detected: \(layerNames)"
            )
        }
        
        return HealthResult(
            subsystemId: subsystemId,
            status: .healthy,
            details: report.explanation
        )
    }
    
    public func secondaryConfirmation() async -> HealthResult? {
        // Independent secondary check: generator plugin registry inspection
        let pluginProbe = await QuickLookLayerProber.shared.probeGenerationLayer()
        if pluginProbe.status == .healthy {
            return HealthResult(
                subsystemId: subsystemId,
                status: .healthy,
                details: pluginProbe.details
            )
        } else {
            return HealthResult(
                subsystemId: subsystemId,
                status: .problemDetected,
                details: pluginProbe.details
            )
        }
    }
}
