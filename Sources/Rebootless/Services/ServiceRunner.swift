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
    
    private func executeUserProcess(service: ServiceItem, startTime: Date) async -> RestartResult {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/bin/zsh")
                process.arguments = ["-c", service.command]
                
                let outputPipe = Pipe()
                let errorPipe = Pipe()
                process.standardOutput = outputPipe
                process.standardError = errorPipe
                
                do {
                    try process.run()
                    process.waitUntilExit()
                    
                    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    
                    let output = String(data: outputData, encoding: .utf8) ?? ""
                    let error = String(data: errorData, encoding: .utf8) ?? ""
                    let duration = Date().timeIntervalSince(startTime)
                    
                    let isSuccess = (process.terminationStatus == 0)
                    let errorMsg = isSuccess ? nil : (error.isEmpty ? "Command exited with status \(process.terminationStatus)" : error.trimmingCharacters(in: .whitespacesAndNewlines))
                    
                    let result = RestartResult(
                        serviceId: service.id,
                        serviceName: service.name,
                        command: service.command,
                        timestamp: Date(),
                        duration: duration,
                        isSuccess: isSuccess,
                        output: output.trimmingCharacters(in: .whitespacesAndNewlines),
                        errorMessage: errorMsg
                    )
                    continuation.resume(returning: result)
                } catch {
                    let duration = Date().timeIntervalSince(startTime)
                    let result = RestartResult(
                        serviceId: service.id,
                        serviceName: service.name,
                        command: service.command,
                        timestamp: Date(),
                        duration: duration,
                        isSuccess: false,
                        output: "",
                        errorMessage: error.localizedDescription
                    )
                    continuation.resume(returning: result)
                }
            }
        }
    }
    
    private func executeWithAdminPrivileges(service: ServiceItem, startTime: Date) async -> RestartResult {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // Prepare AppleScript to run command with admin privileges (prompts for Touch ID / Password)
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
                    let output = descriptor?.stringValue ?? "Success"
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
