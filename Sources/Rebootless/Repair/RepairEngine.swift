import Foundation

public actor RepairEngine {
    public static let shared = RepairEngine()
    
    public init() {}
    
    public func execute(
        recipe: RepairRecipe,
        isAutomatic: Bool = false,
        onStatusChange: (@Sendable (RepairStatus, String) -> Void)? = nil,
        confirmationProvider: (@Sendable (RepairStage) async -> Bool)? = nil
    ) async -> RepairExecutionResult {
        let startTime = Date()
        var executedStageNames: [String] = []
        var lastVerificationText: String? = nil
        
        onStatusChange?(.diagnosing, "Diagnosing \(recipe.subsystemName)...")
        
        // Optional pre-diagnostic
        for diag in recipe.diagnosticChecks {
            _ = await diag.diagnose()
        }
        
        // Iterate through stages sequentially
        for stage in recipe.repairStages {
            // Check if stage requires user confirmation (e.g. Stage 3 - Finder restart)
            if stage.requiresConfirmation {
                if let confirm = confirmationProvider {
                    let allowed = await confirm(stage)
                    if !allowed {
                        // User opted not to escalate
                        continue
                    }
                }
            }
            
            onStatusChange?(.repairing, "Applying \(stage.name)...")
            executedStageNames.append(stage.name)
            
            let (actionSuccess, _) = await stage.executeAction()
            if !actionSuccess {
                // Command failed to execute
                onStatusChange?(.failed, "\(stage.name) execution failed.")
            }
            
            // Verification step
            onStatusChange?(.verifying, "Verifying \(recipe.subsystemName) recovery...")
            
            if recipe.verificationChecks.isEmpty {
                let duration = Date().timeIntervalSince(startTime)
                let summary = "Repair executed for \(recipe.name), but automatic verification is unavailable. Please verify manually."
                onStatusChange?(.repairExecutedButUnverified, summary)
                return RepairExecutionResult(
                    recipeId: recipe.id,
                    recipeName: recipe.name,
                    subsystemName: recipe.subsystemName,
                    startedAt: startTime,
                    duration: duration,
                    status: .repairExecutedButUnverified,
                    executedStages: executedStageNames,
                    verificationDetails: nil,
                    summaryMessage: summary,
                    isAutomatic: isAutomatic
                )
            }
            
            var allHealthy = true
            var latestDetails = ""
            
            for check in recipe.verificationChecks {
                let vResult = await check.verify()
                latestDetails = vResult.details
                lastVerificationText = latestDetails
                
                if !vResult.isHealthy {
                    allHealthy = false
                    break
                }
            }
            
            if allHealthy {
                // VERIFIED FIXED! Stop escalation immediately!
                let duration = Date().timeIntervalSince(startTime)
                let summary = "✓ \(recipe.name) repaired: \(stage.name) succeeded. \(latestDetails)"
                onStatusChange?(.fixed, summary)
                return RepairExecutionResult(
                    recipeId: recipe.id,
                    recipeName: recipe.name,
                    subsystemName: recipe.subsystemName,
                    startedAt: startTime,
                    duration: duration,
                    status: .fixed,
                    executedStages: executedStageNames,
                    verificationDetails: latestDetails,
                    summaryMessage: summary,
                    isAutomatic: isAutomatic
                )
            }
            
            // If we are here, this stage did not fix it; loop continues to escalate to next stage
        }
        
        // If all stages ran and still not verified healthy
        let duration = Date().timeIntervalSince(startTime)
        let summary = "\(recipe.name) is still not responding. Rebootless tried all supported safe repair steps."
        onStatusChange?(.stillBroken, summary)
        return RepairExecutionResult(
            recipeId: recipe.id,
            recipeName: recipe.name,
            subsystemName: recipe.subsystemName,
            startedAt: startTime,
            duration: duration,
            status: .stillBroken,
            executedStages: executedStageNames,
            verificationDetails: lastVerificationText,
            summaryMessage: summary,
            isAutomatic: isAutomatic
        )
    }
}
