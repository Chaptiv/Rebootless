import Foundation

public struct HealthResult: Sendable, Equatable {
    public let subsystemId: String
    public let status: SubsystemHealthStatus
    public let details: String
    public let timestamp: Date
    
    public init(
        subsystemId: String,
        status: SubsystemHealthStatus,
        details: String,
        timestamp: Date = Date()
    ) {
        self.subsystemId = subsystemId
        self.status = status
        self.details = details
        self.timestamp = timestamp
    }
}

public protocol HealthCheck: Sendable {
    var subsystemId: String { get }
    var name: String { get }
    func checkHealth() async -> HealthResult
    func secondaryConfirmation() async -> HealthResult?
}

extension HealthCheck {
    public func secondaryConfirmation() async -> HealthResult? {
        nil
    }
}

public struct MockHealthCheck: HealthCheck {
    public let subsystemId: String
    public let name: String
    private let primaryGenerator: @Sendable () -> HealthResult
    private let secondaryGenerator: (@Sendable () -> HealthResult?)?
    
    public init(
        subsystemId: String = "mock_subsystem",
        name: String = "Mock Health Check",
        primaryResult: HealthResult,
        secondaryResult: HealthResult? = nil
    ) {
        self.subsystemId = subsystemId
        self.name = name
        self.primaryGenerator = { primaryResult }
        if let sec = secondaryResult {
            self.secondaryGenerator = { sec }
        } else {
            self.secondaryGenerator = nil
        }
    }
    
    public init(
        subsystemId: String = "mock_subsystem",
        name: String = "Mock Health Check",
        primaryGenerator: @escaping @Sendable () -> HealthResult,
        secondaryGenerator: (@Sendable () -> HealthResult?)? = nil
    ) {
        self.subsystemId = subsystemId
        self.name = name
        self.primaryGenerator = primaryGenerator
        self.secondaryGenerator = secondaryGenerator
    }
    
    public func checkHealth() async -> HealthResult {
        primaryGenerator()
    }
    
    public func secondaryConfirmation() async -> HealthResult? {
        secondaryGenerator?()
    }
}
