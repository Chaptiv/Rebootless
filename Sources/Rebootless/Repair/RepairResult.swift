import Foundation

public struct RepairExecutionResult: Identifiable, Codable, Sendable {
    public let id: UUID
    public let recipeId: String
    public let recipeName: String
    public let subsystemName: String
    public let startedAt: Date
    public let completedAt: Date
    public let duration: TimeInterval
    public let status: RepairStatus
    public let executedStages: [String]
    public let verificationDetails: String?
    public let summaryMessage: String
    public let isAutomatic: Bool
    
    public init(
        id: UUID = UUID(),
        recipeId: String,
        recipeName: String,
        subsystemName: String,
        startedAt: Date,
        completedAt: Date = Date(),
        duration: TimeInterval,
        status: RepairStatus,
        executedStages: [String],
        verificationDetails: String?,
        summaryMessage: String,
        isAutomatic: Bool = false
    ) {
        self.id = id
        self.recipeId = recipeId
        self.recipeName = recipeName
        self.subsystemName = subsystemName
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.duration = duration
        self.status = status
        self.executedStages = executedStages
        self.verificationDetails = verificationDetails
        self.summaryMessage = summaryMessage
        self.isAutomatic = isAutomatic
    }
}
