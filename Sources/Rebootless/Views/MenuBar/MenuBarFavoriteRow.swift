import SwiftUI

public struct MenuBarFavoriteRow: View {
    @EnvironmentObject var serviceManager: ServiceManager
    let service: ServiceItem
    
    @State private var showingDangerousAlert = false
    
    private var isRestarting: Bool {
        serviceManager.restartingServiceIds.contains(service.id)
    }
    
    private var lastResult: RestartResult? {
        serviceManager.recentResults[service.id]
    }
    
    public var body: some View {
        HStack(spacing: 10) {
            // Service Icon
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(service.category.accentColor.opacity(0.18))
                    .frame(width: 28, height: 28)
                
                Image(systemName: service.iconName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(service.category.accentColor)
            }
            
            // Name and Subtitle
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(service.name)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                    
                    if service.requiresAdmin {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .help("Requires administrator privileges")
                    }
                }
                
                Text(service.subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Restart Button with dynamic state
            Button {
                triggerRestart()
            } label: {
                HStack(spacing: 4) {
                    if isRestarting {
                        ProgressView()
                            .controlSize(.small)
                            .scaleEffect(0.7)
                    } else if let result = lastResult, Date().timeIntervalSince(result.timestamp) < 4 {
                        if result.isSuccess {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.green)
                            Text("Done")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.orange)
                            Text("Failed")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.orange)
                        }
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Restart")
                            .font(.system(size: 11, weight: .medium))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(isRestarting)
            .help(isRestarting ? "Restarting..." : "Restart \(service.name)")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.03))
        )
        .alert("Restart \(service.name)?", isPresented: $showingDangerousAlert) {
            Button("Restart", role: .destructive) {
                Task {
                    _ = await serviceManager.restartService(service)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(service.warningMessage ?? "This action may interrupt your work.")
        }
    }
    
    private func triggerRestart() {
        if service.isDangerous && serviceManager.confirmDangerousActions {
            showingDangerousAlert = true
        } else {
            Task {
                _ = await serviceManager.restartService(service)
            }
        }
    }
}
