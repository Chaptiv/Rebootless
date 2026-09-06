import Foundation
import AppKit

public final class ServiceRunner: Sendable {
    public static let shared = ServiceRunner()
    
    private init() {}
    
    public func execute(service: ServiceItem) async -> RestartResult {
        let startTime = Date()
        
        if service.requiresAdmin {
            return await executeWithAdminPrivileges(service: service, startTime: startTime)
        } else {
            return await executeUserProcess(service: service, startTime: startTime)
        }
    }
    
    public func executeCommand(_ command: String, timeoutSeconds: Double = 5.0) async -> (isSuccess: Bool, output: String, errorMessage: String?) {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/bin/zsh")
                process.arguments = ["-c", command]
                
                let outputPipe = Pipe()
                let errorPipe = Pipe()
                process.standardOutput = outputPipe
                process.standardError = errorPipe
                
                var hasResumed = false
                let lock = NSLock()
                
                // Watchdog timer for timeout
                let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
                timer.schedule(deadline: .now() + timeoutSeconds)
                timer.setEventHandler {
                    lock.lock()
                    defer { lock.unlock() }
                    if !hasResumed {
                        hasResumed = true
                        if process.isRunning {
                            process.terminate()
                        }
                        continuation.resume(returning: (false, "", "Command timed out after \(timeoutSeconds)s"))
                    }
                }
                timer.resume()
                
                do {
                    try process.run()
                    process.waitUntilExit()
                    timer.cancel()
                    
                    lock.lock()
                    defer { lock.unlock() }
                    if !hasResumed {
                        hasResumed = true
                        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                        
                        let output = String(data: outputData, encoding: .utf8) ?? ""
                        let error = String(data: errorData, encoding: .utf8) ?? ""
                        let isSuccess = (process.terminationStatus == 0)
                        let errorMsg = isSuccess ? nil : (error.isEmpty ? "Exit status \(process.terminationStatus)" : error.trimmingCharacters(in: .whitespacesAndNewlines))
                        continuation.resume(returning: (isSuccess, output.trimmingCharacters(in: .whitespacesAndNewlines), errorMsg))
                    }
                } catch {
                    timer.cancel()
                    lock.lock()
                    defer { lock.unlock() }
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume(returning: (false, "", error.localizedDescription))
                    }
                }
            }
        }
    }
    
    private func executeUserProcess(service: ServiceItem, startTime: Date) async -> RestartResult {
        let (isSuccess, output, errorMsg) = await executeCommand(service.command, timeoutSeconds: 15.0)
        let duration = Date().timeIntervalSince(startTime)
        
        return RestartResult(
            serviceId: service.id,
            serviceName: service.name,
            command: service.command,
            timestamp: Date(),
            duration: duration,
            isSuccess: isSuccess,
            output: output,
            errorMessage: errorMsg
        )
    }
    
    private func executeWithAdminPrivileges(service: ServiceItem, startTime: Date) async -> RestartResult {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let escapedCommand = service.command
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "\"", with: "\\\"")
                
                let scriptSource = "do shell script \"\(escapedCommand)\" with administrator privileges"
                
                var errorDict: NSDictionary?
                let appleScript = NSAppleScript(source: scriptSource)
                let descriptor = appleScript?.executeAndReturnError(&errorDict)
                
                let duration = Date().timeIntervalSince(startTime)
                
                if let errorDict = errorDict {
                    let errorNumber = errorDict[NSAppleScript.errorNumber] as? Int ?? 0
                    let isUserCancelled = (errorNumber == -128)
                    let errorMsg = isUserCancelled
                        ? "Authorization cancelled by user"
                        : (errorDict[NSAppleScript.errorMessage] as? String ?? "Execution error")
                    
                    let result = RestartResult(
                        serviceId: service.id,
                        serviceName: service.name,
                        command: service.command,
                        timestamp: Date(),
                        duration: duration,
                        isSuccess: false,
                        output: "",
                        errorMessage: errorMsg
                    )
                    continuation.resume(returning: result)
                } else {
                    let output = descriptor?.stringValue ?? "Command completed"
                    let result = RestartResult(
                        serviceId: service.id,
                        serviceName: service.name,
                        command: service.command,
                        timestamp: Date(),
                        duration: duration,
                        isSuccess: true,
                        output: output,
                        errorMessage: nil
                    )
                    continuation.resume(returning: result)
                }
            }
        }
    }
}
