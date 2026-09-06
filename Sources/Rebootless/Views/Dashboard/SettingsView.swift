import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject var serviceManager: ServiceManager
    @StateObject private var launchAtLogin = LaunchAtLoginManager.shared
    
    public var body: some View {
        Form {
            Section("Subsystem Health Monitoring") {
                Toggle("Enable background health monitoring", isOn: $serviceManager.isMonitoringEnabled)
                    .help("Periodically runs lightweight, conservative functional checks to detect hung or unresponsive subsystems.")
                
                Text("Monitored Subsystems")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Quick Look Previews")
                        .font(.system(size: 13))
                    Spacer()
                    Text("Active (Reference)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "circle")
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("Core Audio (Sound & Mic)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Planned")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "circle")
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("DNS Cache & Resolution")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Planned")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "circle")
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("Finder Subsystem")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Planned")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "circle")
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("Spotlight Indexer")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Planned")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            Section("General & Startup") {
                Toggle("Launch Rebootless at Login", isOn: Binding(
                    get: { launchAtLogin.isEnabled },
                    set: { launchAtLogin.setEnabled($0) }
                ))
                .help("Automatically start Rebootless in your Menu Bar when your Mac starts.")
            }
            
            Section("Notifications & Feedback") {
                Toggle("Show notifications when problems are detected or repaired", isOn: $serviceManager.notificationsEnabled)
                    .help("Displays native system banner notifications when a subsystem issue is confirmed or successfully repaired.")
                
                Toggle("Play sound feedback on repair completion", isOn: $serviceManager.soundEnabled)
                    .help("Plays an audible confirmation chime when a repair finishes.")
            }
            
            Section("Safety & Confirmations") {
                Toggle("Confirm high-impact actions (e.g. Finder restart, WindowServer)", isOn: $serviceManager.confirmDangerousActions)
                    .help("Requires your confirmation before escalating repairs to actions that affect active app windows.")
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
                            Text("Detect & repair broken macOS subsystems before you reboot.")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text("Rebootless monitors your Mac for failing subsystems, explains symptoms in clear English, applies the least disruptive repair, and verifies that the issue actually recovered.")
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
