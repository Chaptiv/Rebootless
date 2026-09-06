import Foundation

public enum VerificationResult: Sendable, Equatable {
    case verifiedHealthy(details: String)
    case stillFailing(reason: String)
    case unverifiable(reason: String)
    
    public var isHealthy: Bool {
        if case .verifiedHealthy = self { return true }
        return false
    }
    
    public var isUnverifiable: Bool {
        if case .unverifiable = self { return true }
        return false
    }
    
    public var details: String {
        switch self {
        case .verifiedHealthy(let details):
            return details
        case .stillFailing(let reason):
            return reason
        case .unverifiable(let reason):
            return reason
        }
    }
}

public protocol VerificationCheck: Sendable {
    var name: String { get }
    func verify() async -> VerificationResult
}

public struct MockVerificationCheck: VerificationCheck {
    public let name: String
    private let resultGenerator: @Sendable () -> VerificationResult
    
    public init(name: String = "Mock Verification", result: VerificationResult) {
        self.name = name
        self.resultGenerator = { result }
    }
    
    public init(name: String = "Mock Verification", resultGenerator: @escaping @Sendable () -> VerificationResult) {
        self.name = name
        self.resultGenerator = resultGenerator
    }
    
    public func verify() async -> VerificationResult {
        resultGenerator()
    }
}
