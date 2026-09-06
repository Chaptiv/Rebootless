import Foundation

public struct RestartResult: Identifiable, Codable, Sendable {
    public let id: UUID
    public let serviceId: String
    public let serviceName: String
    public let command: String
    public let timestamp: Date
    public let duration: TimeInterval
    public let isSuccess: Bool
    public let output: String
    public let errorMessage: String?
    
    public init(
        id: UUID = UUID(),
        serviceId: String,
        serviceName: String,
        command: String,
        timestamp: Date = Date(),
        duration: TimeInterval,
        isSuccess: Bool,
        output: String = "",
        errorMessage: String? = nil
    ) {
        self.id = id
        self.serviceId = serviceId
        self.serviceName = serviceName
        self.command = command
        self.timestamp = timestamp
        self.duration = duration
        self.isSuccess = isSuccess
        self.output = output
        self.errorMessage = errorMessage
    }
}
