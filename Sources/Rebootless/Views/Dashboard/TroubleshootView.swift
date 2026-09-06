import SwiftUI

public struct TroubleshootView: View {
    @EnvironmentObject var serviceManager: ServiceManager
    
    @State private var symptomQuery: String = ""
    @State private var matchedResults: [SymptomMatchResult] = []
    @State private var showingFinderConfirmation = false
    @State private var pendingStageContinuation: CheckedContinuation<Bool, Never>?
    @State private var activeRecipeForConfirmation: RepairRecipe?
    
    // Quick Look Layer Diagnostics State
    @State private var diagnosticsReport: QuickLookDiagnosticsReport?
    @State private var isRunningDiagnostics = false
    @State private var showingDiagnosticsSheet = false
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Banner
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 22))
                            .foregroundColor(.purple)
                        Text("Subsystem Health & Repair")
                            .font(.system(size: 20, weight: .bold))
                    }
                    
                    Text("Describe what is broken on your Mac. Rebootless identifies the failing subsystem, applies the least disruptive repair, and verifies that it actually recovered—before you reboot.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    // Symptom input search bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.purple)
                        
                        TextField("What's broken? (e.g. 'spacebar preview doesn't work', 'force click stuck')...", text: $symptomQuery)
                            .textFieldStyle(.plain)
                            .onChange(of: symptomQuery) { _, newValue in
                                matchedResults = SymptomMatcher.shared.match(query: newValue)
                            }
                        
                        if !symptomQuery.isEmpty {
                            Button {
                                symptomQuery = ""
                                matchedResults = []
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.top, 4)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.purple.opacity(0.07))
                )
                
                // Diagnostic Probes Inspection Card (Direct Subsystem Visibility)
                QuickLookLayerDiagnosticCard(
                    report: diagnosticsReport,
                    isRunning: isRunningDiagnostics,
                    onRunDiagnostics: {
                        Task {
                            isRunningDiagnostics = true
                            diagnosticsReport = await QuickLookLayerProber.shared.runCompleteDiagnostics()
                            isRunningDiagnostics = false
                        }
                    }
                )
                
                // Active Detected Issues Banner (if any detected automatically)
                if !serviceManager.activeIssues.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Confirmed Subsystem Issues")
                                .font(.system(size: 14, weight: .bold))
                        }
                        
                        ForEach(serviceManager.activeIssues) { issue in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(issue.userVisibleTitle)
                                        .font(.system(size: 13, weight: .semibold))
                                    Text(issue.userVisibleSymptoms.joined(separator: " • "))
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if let recipe = serviceManager.repairRecipes.first(where: { $0.id == issue.recipeId }) {
                                    RepairRecipeActionButton(recipe: recipe, onRequireFinderConfirmation: { stage, recipe, continuation in
                                        self.pendingStageContinuation = continuation
                                        self.activeRecipeForConfirmation = recipe
                                        self.showingFinderConfirmation = true
                                    })
                                }
                            }
                            .padding(10)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.orange.opacity(0.25), lineWidth: 1)
                    )
                }
                
                // Symptom Query Matches
                if !symptomQuery.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("MATCHED REPAIR RECIPES")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        if matchedResults.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "questionmark.circle")
                                    .foregroundColor(.secondary)
                                Text("No direct subsystem match found. Browse common issues below or try other keywords like 'preview', 'spacebar', or 'quicklook'.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .padding(12)
                            .background(Color.primary.opacity(0.03))
                            .cornerRadius(8)
                        } else {
                            ForEach(matchedResults) { match in
                                RecipeCardView(recipe: match.recipe, matchExplanation: match.explanation, onRequireFinderConfirmation: { stage, recipe, continuation in
                                    self.pendingStageContinuation = continuation
                                    self.activeRecipeForConfirmation = recipe
                                    self.showingFinderConfirmation = true
                                })
                            }
                        }
                    }
                }
                
                // Common Subsystem Troubleshooters
                VStack(alignment: .leading, spacing: 12) {
                    Text("COMMON MAC ISSUES")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                        // Quick Look Card (Powered by full RepairEngine!)
                        if let qlRecipe = serviceManager.repairRecipes.first(where: { $0.id == "recipe_quicklook" }) {
                            QuickLookRecipeTroubleshootCard(recipe: qlRecipe, onRequireFinderConfirmation: { stage, recipe, continuation in
                                self.pendingStageContinuation = continuation
                                self.activeRecipeForConfirmation = recipe
                                self.showingFinderConfirmation = true
                            })
                        }
                        
                        // Remaining common issues
                        ForEach(TroubleshootItem.commonIssues.filter { $0.serviceId != "quicklook" }) { issue in
                            LegacyTroubleshootCard(issue: issue)
                        }
                    }
                }
            }
            .padding(18)
        }
        .onAppear {
            // Initial diagnostic probe load if empty
            if diagnosticsReport == nil && !isRunningDiagnostics {
                Task {
                    isRunningDiagnostics = true
                    diagnosticsReport = await QuickLookLayerProber.shared.runCompleteDiagnostics()
                    isRunningDiagnostics = false
                }
            }
        }
        .confirmationDialog(
            "Restart Finder to finish repair?",
            isPresented: $showingFinderConfirmation,
            titleVisibility: .visible
        ) {
            Button("Restart Finder", role: .destructive) {
                pendingStageContinuation?.resume(returning: true)
                pendingStageContinuation = nil
            }
            Button("Skip Finder Restart", role: .cancel) {
                pendingStageContinuation?.resume(returning: false)
                pendingStageContinuation = nil
            }
        } message: {
            Text("Quick Look is still not responding after service resets. The next repair stage restarts Finder. Open Finder windows will briefly close and reopen.")
        }
    }
}

// MARK: - Quick Look Layer Diagnostic Card
private struct QuickLookLayerDiagnosticCard: View {
    let report: QuickLookDiagnosticsReport?
    let isRunning: Bool
    let onRunDiagnostics: () -> Void
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "waveform.path.ecg")
                        .foregroundColor(.purple)
                        .font(.system(size: 14, weight: .semibold))
                    Text("Quick Look Subsystem Layer Diagnostics")
                        .font(.system(size: 13, weight: .bold))
                }
                
                Spacer()
                
                Button {
                    onRunDiagnostics()
                } label: {
                    HStack(spacing: 4) {
                        if isRunning {
                            ProgressView()
                                .controlSize(.small)
                                .scaleEffect(0.6)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 10))
                        }
                        Text(isRunning ? "Probing Layers..." : "Run Probes")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.12))
                    .foregroundColor(.purple)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(isRunning)
                
                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            if isExpanded {
                if let rep = report {
                    VStack(spacing: 8) {
                        ForEach(rep.probes) { probe in
                            LayerProbeRow(probe: probe)
                        }
                    }
                    .padding(.top, 4)
                } else {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                            .scaleEffect(0.7)
                        Text("Gathering multi-layer Quick Look diagnostics...")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.purple.opacity(0.15), lineWidth: 1)
        )
    }
}

private struct LayerProbeRow: View {
    let probe: QuickLookProbeResult
    @State private var showingInfo = false
    
    private var statusColor: Color {
        switch probe.status {
        case .healthy:
            return .green
        case .problemDetected:
            return .red
        case .degraded:
            return .orange
        case .unknown:
            return .yellow
        case .unsupported:
            return .secondary
        }
    }
    
    private var statusIcon: String {
        switch probe.status {
        case .healthy:
            return "checkmark.circle.fill"
        case .problemDetected:
            return "xmark.circle.fill"
        case .degraded:
            return "exclamationmark.triangle.fill"
        case .unknown:
            return "questionmark.circle.fill"
        case .unsupported:
            return "minus.circle"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                    .font(.system(size: 12))
                    .padding(.top, 2)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(probe.layer.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                        
                        Text(probe.status == .unknown ? "Unknown (Non-invasive)" : probe.status.rawValue)
                            .font(.system(size: 9, weight: .semibold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(statusColor.opacity(0.12))
                            .foregroundColor(statusColor)
                            .clipShape(Capsule())
                        
                        Spacer()
                        
                        Text("\(String(format: "%.0f", probe.latencyMs))ms")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                    Text(probe.details)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    if let note = probe.limitationNote {
                        HStack(alignment: .top, spacing: 4) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                                .padding(.top, 1)
                            Text(note)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary.opacity(0.85))
                        }
                        .padding(.top, 2)
                    }
                }
            }
        }
        .padding(8)
        .background(Color.primary.opacity(0.025))
        .cornerRadius(6)
    }
}

// MARK: - Recipe Card View
private struct RecipeCardView: View {
    @EnvironmentObject var serviceManager: ServiceManager
    let recipe: RepairRecipe
    let matchExplanation: String
    let onRequireFinderConfirmation: (RepairStage, RepairRecipe, CheckedContinuation<Bool, Never>) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(recipe.name)
                            .font(.system(size: 15, weight: .semibold))
                        Text("Subsystem: \(recipe.subsystemName)")
                            .font(.system(size: 10))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.12))
                            .foregroundColor(.purple)
                            .clipShape(Capsule())
                    }
                    Text(matchExplanation)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                RepairRecipeActionButton(
                    recipe: recipe,
                    onRequireFinderConfirmation: onRequireFinderConfirmation
                )
            }
            
            // Live Status banner if repairing or done
            if let status = serviceManager.activeRepairStatus[recipe.id], status != .idle {
                HStack(spacing: 6) {
                    if !status.isTerminal {
                        ProgressView()
                            .controlSize(.small)
                            .scaleEffect(0.7)
                    } else if status == .fixed {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                    }
                    
                    Text(serviceManager.activeRepairMessage[recipe.id] ?? status.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(status == .fixed ? .green : (status.isTerminal ? .orange : .primary))
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.primary.opacity(0.04))
                .cornerRadius(6)
            }
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Quick Look Troubleshoot Card
private struct QuickLookRecipeTroubleshootCard: View {
    @EnvironmentObject var serviceManager: ServiceManager
    let recipe: RepairRecipe
    let onRequireFinderConfirmation: (RepairStage, RepairRecipe, CheckedContinuation<Bool, Never>) -> Void
    
    private var activeStatus: RepairStatus? {
        serviceManager.activeRepairStatus[recipe.id]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: "eye.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.purple)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Spacebar & Force Click Previews")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Subsystem: Quick Look")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            Text("Spacebar file preview shows a blank box, thumbnails won't load, or Force Click stops opening previews.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(3)
                .frame(minHeight: 36, alignment: .topLeading)
            
            Divider()
            
            if let status = activeStatus, !status.isTerminal {
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.7)
                    Text(serviceManager.activeRepairMessage[recipe.id] ?? "Repairing...")
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color.primary.opacity(0.06))
                .cornerRadius(6)
            } else if let status = activeStatus, status == .fixed {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Verified Repaired")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.12))
                .cornerRadius(6)
            } else {
                RepairRecipeActionButton(
                    recipe: recipe,
                    title: "Diagnose & Repair",
                    onRequireFinderConfirmation: onRequireFinderConfirmation
                )
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Action Button
private struct RepairRecipeActionButton: View {
    @EnvironmentObject var serviceManager: ServiceManager
    let recipe: RepairRecipe
    var title: String = "Repair"
    let onRequireFinderConfirmation: (RepairStage, RepairRecipe, CheckedContinuation<Bool, Never>) -> Void
    
    private var isRunning: Bool {
        if let st = serviceManager.activeRepairStatus[recipe.id] {
            return !st.isTerminal
        }
        return false
    }
    
    var body: some View {
        Button {
            Task {
                _ = await serviceManager.executeRepair(
                    for: recipe,
                    isAutomatic: false,
                    confirmationProvider: { stage in
                        await withCheckedContinuation { continuation in
                            Task { @MainActor in
                                onRequireFinderConfirmation(stage, recipe, continuation)
                            }
                        }
                    }
                )
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 10))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .disabled(isRunning)
    }
}

// MARK: - Legacy Troubleshoot Card (for remaining manual services)
private struct LegacyTroubleshootCard: View {
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
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 34, height: 34)
                    
                    Image(systemName: issue.iconName)
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(issue.title)
                        .font(.system(size: 14, weight: .semibold))
                    if let s = service {
                        Text("Direct Command: \(s.name)")
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
                        Text("Restarting...")
                            .font(.system(size: 12, weight: .medium))
                    } else if let result = lastResult, Date().timeIntervalSince(result.timestamp) < 5 {
                        if result.isSuccess {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                            Text("Command Completed")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text("Command Failed")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.red)
                        }
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11))
                        Text(issue.recommendedActionTitle)
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isRestarting ? Color.primary.opacity(0.06) : Color.blue)
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
