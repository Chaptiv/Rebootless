import Foundation
import UserNotifications
import AppKit

public final class NotificationManager: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    public static let shared = NotificationManager()
    
    public var onRepairActionTriggered: ((String) -> Void)?
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        requestAuthorization()
        setupNotificationCategories()
    }
    
    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    
    private func setupNotificationCategories() {
        let repairAction = UNNotificationAction(
            identifier: "REPAIR_ACTION",
            title: "Repair",
            options: [.foreground]
        )
        
        let category = UNNotificationCategory(
            identifier: "SUBSYSTEM_ISSUE",
            actions: [repairAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let recipeId = userInfo["recipeId"] as? String {
            DispatchQueue.main.async {
                self.onRepairActionTriggered?(recipeId)
            }
        }
        completionHandler()
    }
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
    
    public func sendIssueNotification(issue: ActiveIssue) {
        let content = UNMutableNotificationContent()
        content.title = "Rebootless"
        content.subtitle = issue.userVisibleTitle
        
        var bodyText = "You may notice:\n"
        for symptom in issue.userVisibleSymptoms {
            bodyText += "• \(symptom)\n"
        }
        bodyText += "Click to repair before rebooting."
        
        content.body = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "SUBSYSTEM_ISSUE"
        content.userInfo = ["recipeId": issue.recipeId, "subsystemId": issue.id]
        
        let request = UNNotificationRequest(
            identifier: "issue_\(issue.id)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { _ in }
    }
    
    public func sendRepairResultNotification(result: RepairExecutionResult) {
        let content = UNMutableNotificationContent()
        content.title = result.status == .fixed ? "Subsystem Repaired" : "Repair Completed"
        content.subtitle = result.recipeName
        content.body = result.summaryMessage
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { _ in }
    }
    
    public func sendNotification(for result: RestartResult, soundEnabled: Bool = true) {
        let content = UNMutableNotificationContent()
        content.title = result.isSuccess ? "Service Restarted" : "Restart Failed"
        content.subtitle = result.serviceName
        
        if result.isSuccess {
            content.body = "Command completed: \(result.serviceName) in \(String(format: "%.1f", result.duration))s."
        } else {
            content.body = result.errorMessage ?? "An error occurred while running the restart command."
        }
        
        if soundEnabled {
            content.sound = UNNotificationSound.default
        }
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { _ in }
    }
    
    public func playSuccessFeedback() {
        NSSound(named: "Glass")?.play()
    }
    
    public func playErrorFeedback() {
        NSSound(named: "Basso")?.play()
    }
}
