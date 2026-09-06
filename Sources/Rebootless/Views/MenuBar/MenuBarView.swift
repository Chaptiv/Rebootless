import SwiftUI

public struct MenuBarView: View {
    @EnvironmentObject var serviceManager: ServiceManager
    var onOpenDashboard: () -> Void
    var onQuit: () -> Void
    
    @State private var quickSearch: String = ""
    
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
                    Text("One-Click macOS Fixer")
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
            
            // Favorites Section Header
            HStack {
                Text("FAVORITES")
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
                .padding(.vertical, 16)
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
                .frame(maxHeight: 220)
            }
            
            Divider()
                .padding(.top, 4)
            
            // Quick Troubleshoot Helpers
            VStack(alignment: .leading, spacing: 5) {
                Text("QUICK FIXES")
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
                    .foregroundColor(color)
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
