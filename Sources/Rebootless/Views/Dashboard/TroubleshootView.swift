import SwiftUI

public struct TroubleshootView: View {
    @EnvironmentObject var serviceManager: ServiceManager
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Header Banner
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 20))
                            .foregroundColor(.purple)
                        Text("Problem Solver")
                            .font(.system(size: 20, weight: .bold))
                    }
                    
                    Text("Select what is broken on your Mac. Rebootless will restart the exact underlying macOS system service for you—no terminal commands required.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.purple.opacity(0.08))
                )
                
                // Issues Grid
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                    ForEach(TroubleshootItem.commonIssues) { issue in
                        TroubleshootCard(issue: issue)
                    }
                }
            }
            .padding(18)
        }
    }
}

private struct TroubleshootCard: View {
    @EnvironmentObject var serviceManager: ServiceManager
    let issue: TroubleshootItem
    
    private var service: ServiceItem? {
        serviceManager.getService(byId: issue.serviceId)
    }
    
    private var isRestarting: Bool {
        serviceManager.restartingServiceIds.contains(issue.serviceId)
    }
    
    private var lastResult: RestartResult? {
        serviceManager.recentResults[issue.serviceId]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.purple.opacity(0.12))
                        .frame(width: 34, height: 34)
                    
                    Image(systemName: issue.iconName)
                        .font(.system(size: 16))
                        .foregroundColor(.purple)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(issue.title)
                        .font(.system(size: 14, weight: .semibold))
                    if let s = service {
                        Text("Service: \(s.name)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            Text(issue.symptom)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(3)
                .frame(minHeight: 36, alignment: .topLeading)
            
            Divider()
            
            Button {
                if let s = service {
                    Task {
                        _ = await serviceManager.restartService(s)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    if isRestarting {
                        ProgressView()
                            .controlSize(.small)
                            .scaleEffect(0.7)
                        Text("Fixing...")
                            .font(.system(size: 12, weight: .medium))
                    } else if let result = lastResult, Date().timeIntervalSince(result.timestamp) < 5 {
                        if result.isSuccess {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Fixed!")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text("Retry Fix")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.red)
                        }
                    } else {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 11))
                        Text(issue.recommendedActionTitle)
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isRestarting ? Color.primary.opacity(0.06) : Color.purple)
                )
                .foregroundColor(isRestarting ? .primary : .white)
            }
            .buttonStyle(.plain)
            .disabled(isRestarting || service == nil)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}
