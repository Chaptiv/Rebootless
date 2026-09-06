import Foundation

public enum RepairStatus: String, Codable, Sendable {
    case idle
    case diagnosing
    case issueDetected
    case repairing
    case verifying
    case fixed
    case repairExecutedButUnverified
    case stillBroken
    case failed
    case unsupported
    
    public var isTerminal: Bool {
        switch self {
        case .fixed, .repairExecutedButUnverified, .stillBroken, .failed, .unsupported:
            return true
        default:
            return false
        }
    }
    
    public var isSuccess: Bool {
        self == .fixed || self == .repairExecutedButUnverified
    }
}
