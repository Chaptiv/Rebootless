import Foundation

public enum HistoryType: String, Codable, Sendable {
    case repairEvent
    case directCommand
    case automaticProblemDetected
    case automaticRecovery
}

public struct HistoryRecord: Identifiable, Codable, Sendable {
    public let id: UUID
    public let type: HistoryType
    public let title: String
    public let subtitle: String
    public let timestamp: Date
    public let duration: TimeInterval?
    public let statusText: String
    public let isSuccess: Bool
    public let details: [String]
    
    public init(
        id: UUID = UUID(),
        type: HistoryType,
        title: String,
        subtitle: String,
        timestamp: Date = Date(),
        duration: TimeInterval? = nil,
        statusText: String,
        isSuccess: Bool,
        details: [String] = []
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.timestamp = timestamp
        self.duration = duration
        self.statusText = statusText
        self.isSuccess = isSuccess
        self.details = details
    }
    
    public static func fromRepairResult(_ result: RepairExecutionResult) -> HistoryRecord {
        var details: [String] = []
        if result.isAutomatic {
            details.append("Detected automatically by background health monitor")
        } else {
            details.append("Triggered manually via Troubleshooter")
        }
        
        for (idx, stage) in result.executedStages.enumerated() {
            details.append("Stage \(idx + 1): \(stage)")
        }
        
        if let verif = result.verificationDetails {
            details.append("Verification: \(verif)")
        }
        
        return HistoryRecord(
            type: .repairEvent,
            title: "\(result.recipeName) Repair",
            subtitle: result.subsystemName,
            timestamp: result.completedAt,
            duration: result.duration,
            statusText: result.status.rawValue.capitalized,
            isSuccess: result.status.isSuccess,
            details: details
        )
    }
    
    public static func fromRestartResult(_ result: RestartResult) -> HistoryRecord {
        HistoryRecord(
            type: .directCommand,
            title: "\(result.serviceName) Command",
            subtitle: result.command,
            timestamp: result.timestamp,
            duration: result.duration,
            statusText: result.isSuccess ? "Command Succeeded" : "Command Failed",
            isSuccess: result.isSuccess,
            details: [result.output.isEmpty ? (result.errorMessage ?? "") : result.output]
        )
    }
    
    public static func fromProblemDetected(_ issue: ActiveIssue) -> HistoryRecord {
        HistoryRecord(
            type: .automaticProblemDetected,
            title: "\(issue.subsystemName) Issue Detected",
            subtitle: "Background health monitor detected abnormal behavior",
            timestamp: issue.detectedAt,
            duration: nil,
            statusText: "Problem Confirmed",
            isSuccess: false,
            details: issue.userVisibleSymptoms.map { "Symptom: \($0)" }
        )
    }
    
    public static func fromRecovery(subsystemName: String) -> HistoryRecord {
        HistoryRecord(
            type: .automaticRecovery,
            title: "\(subsystemName) Recovered",
            subtitle: "Subsystem returned to healthy state without repair",
            timestamp: Date(),
            duration: nil,
            statusText: "Recovered",
            isSuccess: true,
            details: ["All health verification probes passed."]
        )
    }
}
