import Foundation

public enum StageImpact: String, Codable, Sendable {
    case minimal = "Minimal"
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    
    public var userFriendlyDescription: String {
        switch self {
        case .minimal:
            return "No noticeable effect on running apps."
        case .low:
            return "Subsystem will quickly reset; open preview/subsystem windows may close."
        case .moderate:
            return "Visible app or subsystem restart (e.g. Finder will briefly refresh)."
        case .high:
            return "High impact action (e.g. system session reset)."
        }
    }
}

public struct RepairStage: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let impact: StageImpact
    public let warningMessage: String?
    public let requiresConfirmation: Bool
    public let executeAction: @Sendable () async -> (success: Bool, output: String)
    
    public init(
        id: String,
        name: String,
        description: String,
        impact: StageImpact = .low,
        warningMessage: String? = nil,
        requiresConfirmation: Bool = false,
        executeAction: @escaping @Sendable () async -> (success: Bool, output: String)
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.impact = impact
        self.warningMessage = warningMessage
        self.requiresConfirmation = requiresConfirmation
        self.executeAction = executeAction
    }
}
