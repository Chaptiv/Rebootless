import SwiftUI

public struct HistoryView: View {
    @EnvironmentObject var serviceManager: ServiceManager
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Repair & Diagnostic History")
                        .font(.system(size: 16, weight: .bold))
                    Text("Timeline of subsystem health detections, repair recipe executions, and commands")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !serviceManager.historyRecords.isEmpty {
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
            
            if serviceManager.historyRecords.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("No diagnostic or repair events yet")
                        .font(.system(size: 16, weight: .semibold))
                    Text("When Rebootless monitors subsystems, detects abnormal behavior, or applies repairs, detailed records will appear here.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 340)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(serviceManager.historyRecords) { record in
                        HistoryRecordRow(record: record)
                    }
                }
                .listStyle(.inset)
            }
        }
    }
}

private struct HistoryRecordRow: View {
    let record: HistoryRecord
    @State private var isExpanded = false
    
    private var badgeColor: Color {
        switch record.type {
        case .repairEvent:
            return .purple
        case .directCommand:
            return .blue
        case .automaticProblemDetected:
            return .orange
        case .automaticRecovery:
            return .green
        }
    }
    
    private var badgeText: String {
        switch record.type {
        case .repairEvent:
            return "Repair"
        case .directCommand:
            return "Command"
        case .automaticProblemDetected:
            return "Detected"
        case .automaticRecovery:
            return "Recovered"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: record.isSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundColor(record.isSuccess ? .green : (record.type == .automaticProblemDetected ? .orange : .red))
                    .font(.system(size: 14))
                
                Text(record.title)
                    .font(.system(size: 13, weight: .semibold))
                
                Text(badgeText)
                    .font(.system(size: 9, weight: .semibold))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(badgeColor.opacity(0.15))
                    .foregroundColor(badgeColor)
                    .clipShape(Capsule())
                
                Spacer()
                
                if let dur = record.duration {
                    Text("\(String(format: "%.2f", dur))s")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                Text(formatDate(record.timestamp))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text(record.subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                if !record.details.isEmpty {
                    Button(isExpanded ? "Hide Details" : "View Details") {
                        isExpanded.toggle()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundColor(.blue)
                }
            }
            
            if isExpanded && !record.details.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(record.details, id: \.self) { line in
                        Text(line)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.primary.opacity(0.85))
                            .padding(.vertical, 1)
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.primary.opacity(0.03))
                .cornerRadius(6)
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
