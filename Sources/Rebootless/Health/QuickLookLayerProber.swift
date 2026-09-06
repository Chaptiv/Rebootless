import Foundation
import Quartz
import AppKit

public final class QuickLookLayerProber: Sendable {
    public static let shared = QuickLookLayerProber()
    
    private init() {}
    
    // MARK: - Layer 1: Generation Layer Probe
    public func probeGenerationLayer() async -> QuickLookProbeResult {
        let startTime = Date()
        let result = await ServiceRunner.shared.executeCommand("qlmanage -m plugins 2>&1", timeoutSeconds: 3.0)
        let latency = Date().timeIntervalSince(startTime) * 1000.0
        
        guard result.isSuccess else {
            return QuickLookProbeResult(
                layer: .generation,
                probeName: "qlmanage -m plugins",
                status: .problemDetected,
                latencyMs: latency,
                details: result.errorMessage ?? "Plugin manager returned non-zero status.",
                isVerifiableNonInvasively: true
            )
        }
        
        let lines = result.output.components(separatedBy: .newlines)
        let pluginLines = lines.filter { $0.contains("->") || $0.contains(".qlgenerator") || $0.contains(".appex") }
        
        if result.output.contains("plugins:") && !pluginLines.isEmpty {
            return QuickLookProbeResult(
                layer: .generation,
                probeName: "qlmanage -m plugins",
                status: .healthy,
                latencyMs: latency,
                details: "\(pluginLines.count) generator plugins loaded and active in registry.",
                isVerifiableNonInvasively: true
            )
        } else {
            return QuickLookProbeResult(
                layer: .generation,
                probeName: "qlmanage -m plugins",
                status: .problemDetected,
                latencyMs: latency,
                details: "No active Quick Look generator plugins reported.",
                isVerifiableNonInvasively: true
            )
        }
    }
    
    // MARK: - Layer 2: Daemon Layer Probe
    public func probeDaemonLayer() async -> QuickLookProbeResult {
        let startTime = Date()
        
        // Check 1: Server IPC
        let serverResult = await ServiceRunner.shared.executeCommand("qlmanage -m server 2>&1", timeoutSeconds: 3.0)
        guard serverResult.isSuccess && (serverResult.output.contains("server:") || serverResult.output.contains("arch:")) else {
            let latency = Date().timeIntervalSince(startTime) * 1000.0
            return QuickLookProbeResult(
                layer: .daemon,
                probeName: "qlmanage -m server",
                status: .problemDetected,
                latencyMs: latency,
                details: "quicklookd daemon failed to respond to IPC status query.",
                isVerifiableNonInvasively: true
            )
        }
        
        // Check 2: Actual functional thumbnail synthesis
        let thumbCmd = "qlmanage -t -s 32 -o /tmp /System/Library/CoreServices/SystemVersion.plist 2>&1"
        let thumbResult = await ServiceRunner.shared.executeCommand(thumbCmd, timeoutSeconds: 4.0)
        let latency = Date().timeIntervalSince(startTime) * 1000.0
        
        _ = await ServiceRunner.shared.executeCommand("rm -f /tmp/SystemVersion.plist.png")
        
        if thumbResult.isSuccess && (thumbResult.output.contains("produced") || thumbResult.output.contains("Done producing")) {
            return QuickLookProbeResult(
                layer: .daemon,
                probeName: "quicklookd & thumbnail probe",
                status: .healthy,
                latencyMs: latency,
                details: "quicklookd is responsive and successfully synthesized thumbnail metadata.",
                isVerifiableNonInvasively: true
            )
        } else {
            return QuickLookProbeResult(
                layer: .daemon,
                probeName: "quicklookd & thumbnail probe",
                status: .problemDetected,
                latencyMs: latency,
                details: "Thumbnail synthesis probe timed out or failed in daemon layer.",
                isVerifiableNonInvasively: true
            )
        }
    }
    
    // MARK: - Layer 3: UI / Presentation Layer Probe
    public func probeUIPresentationLayer() async -> QuickLookProbeResult {
        let startTime = Date()
        
        // 1. Check running QuickLookUIService processes for hung or zombie states
        let psResult = await ServiceRunner.shared.executeCommand("ps -eo pid,stat,%cpu,comm | grep -i QuickLookUIService | grep -v grep 2>&1", timeoutSeconds: 2.5)
        let latency = Date().timeIntervalSince(startTime) * 1000.0
        
        if psResult.isSuccess && !psResult.output.isEmpty {
            let lines = psResult.output.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            
            for line in lines {
                let parts = line.split(whereSeparator: \.isWhitespace)
                if parts.count >= 3 {
                    let stat = String(parts[1])
                    let cpuStr = String(parts[2]).replacingOccurrences(of: ",", with: ".")
                    let cpuVal = Double(cpuStr) ?? 0.0
                    
                    if stat.contains("Z") {
                        return QuickLookProbeResult(
                            layer: .uiPresentation,
                            probeName: "QuickLookUIService process inspect",
                            status: .problemDetected,
                            latencyMs: latency,
                            details: "Detected zombie QuickLookUIService instance (State: \(stat)).",
                            isVerifiableNonInvasively: true
                        )
                    }
                    if stat.contains("D") {
                        return QuickLookProbeResult(
                            layer: .uiPresentation,
                            probeName: "QuickLookUIService process inspect",
                            status: .problemDetected,
                            latencyMs: latency,
                            details: "Detected QuickLookUIService stuck in uninterruptible sleep (State: \(stat)).",
                            isVerifiableNonInvasively: true
                        )
                    }
                    if cpuVal > 90.0 {
                        return QuickLookProbeResult(
                            layer: .uiPresentation,
                            probeName: "QuickLookUIService process inspect",
                            status: .problemDetected,
                            latencyMs: latency,
                            details: "Detected QuickLookUIService pinning CPU at \(cpuVal)%.",
                            isVerifiableNonInvasively: true
                        )
                    }
                }
            }
        }
        
        // 2. In-process AppKit / Quartz runtime check
        let panel = await MainActor.run { QLPreviewPanel.shared() }
        guard panel != nil else {
            return QuickLookProbeResult(
                layer: .uiPresentation,
                probeName: "QuickLookUI QLPreviewPanel linkage",
                status: .problemDetected,
                latencyMs: latency,
                details: "Failed to link or instantiate QLPreviewPanel from QuickLookUI.framework.",
                isVerifiableNonInvasively: true
            )
        }
        
        // 3. Fallback to Unknown for full on-screen presentation
        // Rationale: macOS provides no non-invasive API to verify that an actual window can paint
        // on the screen without popping up a window in front of the user.
        return QuickLookProbeResult(
            layer: .uiPresentation,
            probeName: "QuickLookUIService & panel state",
            status: .unknown,
            latencyMs: latency,
            details: "UI framework loaded and processes show no hung/zombie states.",
            isVerifiableNonInvasively: false,
            limitationNote: "Active on-screen window presentation cannot be automatically tested without visibly opening a preview window over your desktop."
        )
    }
    
    // MARK: - Layer 4: Finder Integration Layer Probe
    public func probeFinderIntegrationLayer() async -> QuickLookProbeResult {
        let startTime = Date()
        
        // Test Finder main thread responsiveness with a 2-second timeout
        let script = "with timeout of 2 seconds\ntell application \"Finder\" to get name\nend timeout"
        let result = await ServiceRunner.shared.executeCommand("osascript -e '\(script)' 2>&1", timeoutSeconds: 2.5)
        let latency = Date().timeIntervalSince(startTime) * 1000.0
        
        if result.isSuccess && result.output.contains("Finder") {
            return QuickLookProbeResult(
                layer: .finderIntegration,
                probeName: "Finder AppleEvent ping",
                status: .healthy,
                latencyMs: latency,
                details: "Finder main thread event loop is responsive and handling IPC requests.",
                isVerifiableNonInvasively: true,
                limitationNote: "Finder's internal selection delegate hook cannot be tested without sending a simulated Spacebar keystroke into Finder."
            )
        } else {
            return QuickLookProbeResult(
                layer: .finderIntegration,
                probeName: "Finder AppleEvent ping",
                status: .problemDetected,
                latencyMs: latency,
                details: "Finder failed to respond within timeout. Finder may be beachballing or frozen.",
                isVerifiableNonInvasively: true,
                limitationNote: "Finder unresponsive: Spacebar and Force Click events will be dropped."
            )
        }
    }
    
    // MARK: - Run All Probes
    public func runCompleteDiagnostics() async -> QuickLookDiagnosticsReport {
        async let p1 = probeGenerationLayer()
        async let p2 = probeDaemonLayer()
        async let p3 = probeUIPresentationLayer()
        async let p4 = probeFinderIntegrationLayer()
        
        let probes = await [p1, p2, p3, p4]
        
        // Determine overall status
        let hasProblem = probes.contains { $0.status == .problemDetected }
        let hasDegraded = probes.contains { $0.status == .degraded }
        
        let overallStatus: SubsystemHealthStatus
        let explanation: String
        
        if hasProblem {
            overallStatus = .problemDetected
            let failingProbes = probes.filter { $0.status == .problemDetected }.map { $0.layer.rawValue }
            explanation = "Definite issue detected in layer(s): \(failingProbes.joined(separator: ", "))."
        } else if hasDegraded {
            overallStatus = .degraded
            explanation = "Subsystem is operational but performing abnormally."
        } else {
            // Note: Since UI presentation is marked unknown (cannot non-invasively paint window),
            // overall status is healthy for all verifiable layers!
            overallStatus = .healthy
            explanation = "All non-invasively verifiable layers (Generation, Daemon, and Finder Event Loop) are responding normally."
        }
        
        return QuickLookDiagnosticsReport(
            overallStatus: overallStatus,
            probes: probes,
            explanation: explanation
        )
    }
}
