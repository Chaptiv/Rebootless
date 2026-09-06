import Foundation
import UserNotifications
import AppKit

public final class NotificationManager: @unchecked Sendable {
    public static let shared = NotificationManager()
    
    private init() {
        requestAuthorization()
    }
    
    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    public func sendNotification(for result: RestartResult, soundEnabled: Bool = true) {
        let content = UNMutableNotificationContent()
        content.title = result.isSuccess ? "Service Restarted" : "Restart Failed"
        content.subtitle = result.serviceName
        
        if result.isSuccess {
            content.body = "Successfully restarted \(result.serviceName) in \(String(format: "%.1f", result.duration))s."
        } else {
            content.body = result.errorMessage ?? "An error occurred while restarting the service."
        }
        
        if soundEnabled {
            content.sound = UNNotificationSound.default
        }
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Deliver immediately
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
