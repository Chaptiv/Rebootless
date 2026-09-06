import Foundation

public struct ActiveIssue: Identifiable, Codable, Sendable, Equatable {
    public let id: String
    public let subsystemName: String
    public let recipeId: String
    public let userVisibleTitle: String
    public let userVisibleSymptoms: [String]
    public let detectedAt: Date
    public var hasNotifiedUser: Bool
    public var consecutiveFailures: Int
    
    public init(
        id: String,
        subsystemName: String,
        recipeId: String,
        userVisibleTitle: String,
        userVisibleSymptoms: [String],
        detectedAt: Date = Date(),
        hasNotifiedUser: Bool = false,
        consecutiveFailures: Int = 1
    ) {
        self.id = id
        self.subsystemName = subsystemName
        self.recipeId = recipeId
        self.userVisibleTitle = userVisibleTitle
        self.userVisibleSymptoms = userVisibleSymptoms
        self.detectedAt = detectedAt
        self.hasNotifiedUser = hasNotifiedUser
        self.consecutiveFailures = consecutiveFailures
    }
}

public actor IssueTracker {
    private var activeIssues: [String: ActiveIssue] = [:]
    
    public init() {}
    
    public func getActiveIssues() -> [ActiveIssue] {
        Array(activeIssues.values)
    }
    
    public func getIssue(for subsystemId: String) -> ActiveIssue? {
        activeIssues[subsystemId]
    }
    
    public func recordProblem(
        subsystemId: String,
        subsystemName: String,
        recipeId: String,
        userVisibleTitle: String,
        symptoms: [String]
    ) -> (issue: ActiveIssue, isNewNotificationDue: Bool) {
        if var existing = activeIssues[subsystemId] {
            existing.consecutiveFailures += 1
            let shouldNotify = !existing.hasNotifiedUser
            if shouldNotify {
                existing.hasNotifiedUser = true
            }
            activeIssues[subsystemId] = existing
            return (existing, shouldNotify)
        } else {
            let newIssue = ActiveIssue(
                id: subsystemId,
                subsystemName: subsystemName,
                recipeId: recipeId,
                userVisibleTitle: userVisibleTitle,
                userVisibleSymptoms: symptoms,
                detectedAt: Date(),
                hasNotifiedUser: true,
                consecutiveFailures: 1
            )
            activeIssues[subsystemId] = newIssue
            return (newIssue, true)
        }
    }
    
    public func recordRecovery(subsystemId: String) -> ActiveIssue? {
        if let resolved = activeIssues.removeValue(forKey: subsystemId) {
            return resolved
        }
        return nil
    }
    
    public func clearAll() {
        activeIssues.removeAll()
    }
}
