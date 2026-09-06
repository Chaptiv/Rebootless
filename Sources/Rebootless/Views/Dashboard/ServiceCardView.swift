import SwiftUI
import AppKit

public struct ServiceCardView: View {
    @EnvironmentObject var serviceManager: ServiceManager
    let service: ServiceItem
    
    @State private var showingDetails = false
    @State private var showingDangerousAlert = false
    @State private var copiedCommand = false
    
    private var isRestarting: Bool {
        serviceManager.restartingServiceIds.contains(service.id)
    }
    
    private var lastResult: RestartResult? {
        serviceManager.recentResults[service.id]
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header Row: Icon, Titles, Star, Restart Button
            HStack(alignment: .top, spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(service.category.accentColor.opacity(0.15))
                        .frame(width: 38, height: 38)
                    
                    Image(systemName: service.iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(service.category.accentColor)
                }
                
                // Titles and badges
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(service.name)
                            .font(.system(size: 15, weight: .semibold))
                        
                        if service.requiresAdmin {
                            HStack(spacing: 2) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 8))
                                Text("Admin")
                                    .font(.system(size: 9, weight: .semibold))
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.18))
                            .foregroundColor(.orange)
                            .clipShape(Capsule())
                            .help("Requires administrator privileges / Touch ID")
                        }
                        
                        if service.isDangerous {
                            HStack(spacing: 2) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 8))
                                Text("Session Reset")
                                    .font(.system(size: 9, weight: .semibold))
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.18))
                            .foregroundColor(.red)
                            .clipShape(Capsule())
                        }
                        
                        if !service.isBuiltIn {
                            Text("Custom")
                                .font(.system(size: 9, weight: .semibold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.18))
                                .foregroundColor(.green)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(service.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Favorite Star Button
                Button {
                    serviceManager.toggleFavorite(for: service.id)
                } label: {
                    Image(systemName: service.isFavorited ? "star.fill" : "star")
                        .font(.system(size: 14))
                        .foregroundColor(service.isFavorited ? .yellow : .secondary.opacity(0.6))
                        .padding(6)
                        .background(Color.primary.opacity(0.04))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(service.isFavorited ? "Remove from Menu Bar favorites" : "Add to Menu Bar favorites")
                
                // Restart Button
                Button {
                    triggerRestart()
                } label: {
                    HStack(spacing: 5) {
                        if isRestarting {
                            ProgressView()
                                .controlSize(.small)
                                .scaleEffect(0.8)
                            Text("Restarting...")
                                .font(.system(size: 12, weight: .medium))
                        } else if let result = lastResult, Date().timeIntervalSince(result.timestamp) < 5 {
                            if result.isSuccess {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.green)
                                Text("Restarted")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.red)
                                Text("Failed")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.red)
                            }
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Restart")
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(isRestarting ? Color.primary.opacity(0.08) : Color.accentColor)
                    )
                    .foregroundColor(isRestarting ? .primary : .white)
                }
                .buttonStyle(.plain)
                .disabled(isRestarting)
            }
            
            // Problem Description
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.top, 1)
                
                Text(service.fixesDescription)
                    .font(.system(size: 12))
                    .foregroundColor(.primary.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.primary.opacity(0.03))
            )
            
            // Technical disclosure toggle
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingDetails.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showingDetails ? "chevron.down" : "chevron.right")
                            .font(.system(size: 9, weight: .semibold))
                        Text(showingDetails ? "Hide Command" : "View Technical Command")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                if let result = lastResult {
                    Text("Last run: \(formatTimestamp(result.timestamp)) (\(String(format: "%.1f", result.duration))s)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            
            // Technical details view
            if showingDetails {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("SHELL COMMAND:")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(service.command, forType: .string)
                            copiedCommand = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                copiedCommand = false
                            }
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: copiedCommand ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 9))
                                Text(copiedCommand ? "Copied" : "Copy")
                                    .font(.system(size: 9))
                            }
                            .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text(service.command)
                        .font(.system(size: 11, design: .monospaced))
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(6)
                    
                    if let result = lastResult, !result.output.isEmpty {
                        Text("OUTPUT:")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                        Text(result.output)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.primary.opacity(0.04))
                            .cornerRadius(6)
                    }
                    
                    if let result = lastResult, let error = result.errorMessage {
                        Text("ERROR:")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.red)
                        Text(error)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.red)
                            .padding(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.08))
                            .cornerRadius(6)
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.primary.opacity(0.025))
                )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
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
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}
