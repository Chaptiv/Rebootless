import SwiftUI
import AppKit

@main
struct RebootlessApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var serviceManager = ServiceManager.shared
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarView(
                onOpenDashboard: {
                    AppDelegate.shared.showDashboardWindow()
                },
                onQuit: {
                    NSApp.terminate(nil)
                }
            )
            .environmentObject(serviceManager)
        } label: {
            Image(systemName: serviceManager.isAnyRestarting ? "arrow.trianglehead.2.clockwise.rotate.90" : "arrow.clockwise.circle.fill")
        }
        .menuBarExtraStyle(.window)
        
        Settings {
            SettingsView()
                .environmentObject(serviceManager)
        }
    }
}
