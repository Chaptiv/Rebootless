import SwiftUI

public struct HistoryView: View {
    @EnvironmentObject var serviceManager: ServiceManager
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Restart History")
                        .font(.system(size: 16, weight: .bold))
                    Text("Recent service restart events and command exit logs")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !serviceManager.history.isEmpty {
                    Button("Clear History") {
                        serviceManager.clearHistory()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            if serviceManager.history.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("No restart events yet")
                        .font(.system(size: 16, weight: .semibold))
                    Text("When you restart services from the Menu Bar or Dashboard, their status and diagnostics will appear here.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 320)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(serviceManager.history) { item in
                        HistoryRow(item: item)
                    }
                }
                .listStyle(.inset)
            }
        }
    }
}

private struct HistoryRow: View {
    let item: RestartResult
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: item.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(item.isSuccess ? .green : .red)
                    .font(.system(size: 14))
                
                Text(item.serviceName)
                    .font(.system(size: 13, weight: .semibold))
                
                Spacer()
                
                Text("\(String(format: "%.2f", item.duration))s")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                
                Text(formatDate(item.timestamp))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text(item.command)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                if !item.output.isEmpty || item.errorMessage != nil {
                    Button(isExpanded ? "Hide Details" : "Details") {
                        isExpanded.toggle()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 10))
                    .foregroundColor(.blue)
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    if !item.output.isEmpty {
                        Text("Output:")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                        Text(item.output)
                            .font(.system(size: 10, design: .monospaced))
                            .padding(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.primary.opacity(0.04))
                            .cornerRadius(4)
                    }
                    if let err = item.errorMessage {
                        Text("Error:")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.red)
                        Text(err)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.red)
                            .padding(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.08))
                            .cornerRadius(4)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}
