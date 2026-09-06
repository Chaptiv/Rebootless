import Foundation
import AppKit
import SwiftUI

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    public static let shared = AppDelegate()
    
    private var dashboardWindow: NSWindow?
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Request notification permissions
        NotificationManager.shared.requestAuthorization()
        
        // Ensure app can show windows even as accessory
        NSApp.setActivationPolicy(.accessory)
    }
    
    public func showDashboardWindow() {
        if let existing = dashboardWindow, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let contentView = DashboardView()
            .environmentObject(ServiceManager.shared)
        
        let hostingController = NSHostingController(rootView: contentView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 880, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.center()
        window.setFrameAutosaveName("RebootlessDashboardWindow")
        window.contentViewController = hostingController
        window.title = "Rebootless"
        window.titlebarAppearsTransparent = false
        window.toolbarStyle = .unified
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 760, height: 500)
        
        self.dashboardWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
