import Foundation

public enum SubsystemHealthStatus: String, Codable, Sendable {
    case healthy = "Healthy"
    case degraded = "Degraded"
    case problemDetected = "Problem Detected"
    case unknown = "Unknown"
    case unsupported = "Unsupported"
    
    public var isHealthy: Bool {
        self == .healthy
    }
    
    public var isProblem: Bool {
        self == .problemDetected || self == .degraded
    }
}
