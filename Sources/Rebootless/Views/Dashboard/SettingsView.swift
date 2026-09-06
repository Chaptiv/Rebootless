import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject var serviceManager: ServiceManager
    @StateObject private var launchAtLogin = LaunchAtLoginManager.shared
    
    public var body: some View {
        Form {
            Section("General") {
                Toggle("Launch Rebootless at Login", isOn: Binding(
                    get: { launchAtLogin.isEnabled },
                    set: { launchAtLogin.setEnabled($0) }
                ))
                .help("Automatically start Rebootless in your Menu Bar when your Mac starts.")
            }
            
            Section("Notifications & Feedback") {
                Toggle("Show macOS notification upon service restart", isOn: $serviceManager.notificationsEnabled)
                    .help("Displays a system banner notification indicating whether the restart was successful.")
                
                Toggle("Play sound feedback on restart completion", isOn: $serviceManager.soundEnabled)
                    .help("Plays a subtle confirmation chime when a service finishes restarting.")
            }
            
            Section("Safety & Confirmations") {
                Toggle("Confirm high-impact actions (e.g. WindowServer)", isOn: $serviceManager.confirmDangerousActions)
                    .help("Shows a warning confirmation dialog before executing services that log out your session.")
            }
            
            Section("About Rebootless") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 44, height: 44)
                            Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Rebootless")
                                .font(.system(size: 16, weight: .bold))
                            Text("Version 1.0.0 • Native macOS Utility")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text("Rebootless helps you fix common macOS issues instantly by restarting individual system daemons and services with a single click—no Terminal, commands, or full system reboots required.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding(.vertical, 4)
            }
        }
        .formStyle(.grouped)
        .padding(10)
    }
}
