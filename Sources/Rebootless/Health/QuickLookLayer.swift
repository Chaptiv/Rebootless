import Foundation

public enum QuickLookLayer: String, CaseIterable, Codable, Sendable {
    case generation = "Generation (Plugins)"
    case daemon = "Daemon (quicklookd)"
    case uiPresentation = "UI / Presentation (QuickLookUIService)"
    case finderIntegration = "Finder Integration (Event Loop)"
    
    public var layerDescription: String {
        switch self {
        case .generation:
            return "File format generators & plugins responsible for parsing and rendering content types."
        case .daemon:
            return "quicklookd daemon managing thumbnail synthesis, caching, and satellite workers."
        case .uiPresentation:
            return "QuickLookUIService XPC handling remote window presentation and UI events."
        case .finderIntegration:
            return "Finder main thread event loop receiving Spacebar and Force Click gestures."
        }
    }
}

public struct QuickLookProbeResult: Identifiable, Codable, Sendable, Equatable {
    public let id: String
    public let layer: QuickLookLayer
    public let probeName: String
    public let status: SubsystemHealthStatus
    public let latencyMs: Double
    public let details: String
    public let isVerifiableNonInvasively: Bool
    public let limitationNote: String?
    
    public init(
        id: String = UUID().uuidString,
        layer: QuickLookLayer,
        probeName: String,
        status: SubsystemHealthStatus,
        latencyMs: Double,
        details: String,
        isVerifiableNonInvasively: Bool,
        limitationNote: String? = nil
    ) {
        self.id = id
        self.layer = layer
        self.probeName = probeName
        self.status = status
        self.latencyMs = latencyMs
        self.details = details
        self.isVerifiableNonInvasively = isVerifiableNonInvasively
        self.limitationNote = limitationNote
    }
}

public struct QuickLookDiagnosticsReport: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let timestamp: Date
    public let overallStatus: SubsystemHealthStatus
    public let probes: [QuickLookProbeResult]
    public let explanation: String
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        overallStatus: SubsystemHealthStatus,
        probes: [QuickLookProbeResult],
        explanation: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.overallStatus = overallStatus
        self.probes = probes
        self.explanation = explanation
    }
}
