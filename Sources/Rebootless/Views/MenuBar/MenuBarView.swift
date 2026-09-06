import SwiftUI

public struct MenuBarView: View {
    @EnvironmentObject var serviceManager: ServiceManager
    var onOpenDashboard: () -> Void
    var onQuit: () -> Void
    
    public init(onOpenDashboard: @escaping () -> Void = {}, onQuit: @escaping () -> Void = { NSApp.terminate(nil) }) {
        self.onOpenDashboard = onOpenDashboard
        self.onQuit = onQuit
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("Rebootless")
                        .font(.system(size: 13, weight: .bold))
                    Text("Proactive macOS Repair")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    onOpenDashboard()
                } label: {
                    Image(systemName: "macwindow.badge.plus")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(5)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Open Full Dashboard")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            
            Divider()
            
            // Subsystem Health & Repair Status Section
            VStack(alignment: .leading, spacing: 6) {
                if !serviceManager.activeIssues.isEmpty {
                    // Active Problem Banner
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 12))
                            Text("\(serviceManager.activeIssues.count) Issue Detected")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.orange)
                            Spacer()
                        }
                        
                        ForEach(serviceManager.activeIssues) { issue in
                            HStack {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(issue.subsystemName)
                                        .font(.system(size: 12, weight: .semibold))
                                    Text("Preview subsystem not responding")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if let recipe = serviceManager.repairRecipes.first(where: { $0.id == issue.recipeId }) {
                                    Button {
                                        Task {
                                            _ = await serviceManager.executeRepair(for: recipe, isAutomatic: false)
                                        }
                                    } label: {
                                        HStack(spacing: 3) {
                                            Image(systemName: "bolt.fill")
                                                .font(.system(size: 9))
                                            Text("Repair")
                                                .font(.system(size: 11, weight: .semibold))
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3.5)
                                        .background(Color.purple)
                                        .foregroundColor(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(8)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                    .padding(10)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                } else {
                    // All Healthy Banner
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 12))
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("System Repair Status")
                                .font(.system(size: 11, weight: .semibold))
                            Text("✓ Quick Look monitored • No issues detected")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                }
            }
            
            Divider()
            
            // Favorites Section Header
            HStack {
                Text("FAVORITE SERVICES")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !serviceManager.favoriteServices.isEmpty {
                    Button {
                        Task {
                            await serviceManager.restartAllFavorites()
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                                .font(.system(size: 9))
                            Text("Restart All")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .disabled(serviceManager.isAnyRestarting)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 4)
            
            // Favorites List
            if serviceManager.favoriteServices.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "star")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                    Text("No favorited services")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("Open Dashboard to star your frequent services")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 10)
            } else {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(serviceManager.favoriteServices) { service in
                            MenuBarFavoriteRow(service: service)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 180)
            }
            
            Divider()
                .padding(.top, 4)
            
            // Quick Direct Controls
            VStack(alignment: .leading, spacing: 5) {
                Text("DIRECT SERVICE RESTARTS")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.top, 6)
                
                HStack(spacing: 6) {
                    QuickFixButton(title: "Sound", icon: "speaker.wave.3.fill", color: .purple) {
                        if let s = serviceManager.getService(byId: "coreaudio") {
                            Task { _ = await serviceManager.restartService(s) }
                        }
                    }
                    QuickFixButton(title: "Finder", icon: "macwindow", color: .blue) {
                        if let s = serviceManager.getService(byId: "finder") {
                            Task { _ = await serviceManager.restartService(s) }
                        }
                    }
                    QuickFixButton(title: "DNS", icon: "network", color: .cyan) {
                        if let s = serviceManager.getService(byId: "dnscache") {
                            Task { _ = await serviceManager.restartService(s) }
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 6)
            }
            
            Divider()
            
            // Bottom Action Bar
            HStack {
                Button {
                    onOpenDashboard()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "app.badge")
                            .font(.system(size: 11))
                        Text("Open Dashboard...")
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button {
                    onQuit()
                } label: {
                    Text("Quit")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.02))
        }
        .frame(width: 320)
    }
}

private struct QuickFixButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(color.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }
}
