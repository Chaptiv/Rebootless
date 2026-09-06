import Foundation
import SwiftUI
import Combine

@MainActor
public final class ServiceManager: ObservableObject {
    public static let shared = ServiceManager()
    
    // MARK: - Published Properties (Services & Direct Restarts)
    @Published public var services: [ServiceItem] = []
    @Published public var customServices: [ServiceItem] = []
    @Published public var restartingServiceIds: Set<String> = []
    @Published public var recentResults: [String: RestartResult] = [:]
    @Published public var history: [RestartResult] = []
    
    // MARK: - Published Properties (Health & Repair Subsystems)
    @Published public var repairRecipes: [RepairRecipe] = []
    @Published public var activeIssues: [ActiveIssue] = []
    @Published public var subsystemHealth: [String: SubsystemHealthStatus] = [:]
    @Published public var activeRepairStatus: [String: RepairStatus] = [:]
    @Published public var activeRepairMessage: [String: String] = [:]
    @Published public var historyRecords: [HistoryRecord] = []
    
    // Search & Filter
    @Published public var searchText: String = ""
    @Published public var selectedCategory: ServiceCategory = .all
    
    // Preferences
    @Published public var isMonitoringEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isMonitoringEnabled, forKey: "isMonitoringEnabled")
            Task {
                await HealthMonitor.shared.startBackgroundMonitoring(intervalSeconds: 60.0)
            }
        }
    }
    @Published public var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        }
    }
    @Published public var soundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled")
        }
    }
    @Published public var confirmDangerousActions: Bool {
        didSet {
            UserDefaults.standard.set(confirmDangerousActions, forKey: "confirmDangerousActions")
        }
    }
    
    private let favoritesKey = "rebootless_favorites"
    private let customServicesKey = "rebootless_custom_services"
    private let historyKey = "rebootless_history"
    private let historyRecordsKey = "rebootless_history_records"
    
    private init() {
        self.isMonitoringEnabled = UserDefaults.standard.object(forKey: "isMonitoringEnabled") as? Bool ?? true
        self.notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
        self.soundEnabled = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
        self.confirmDangerousActions = UserDefaults.standard.object(forKey: "confirmDangerousActions") as? Bool ?? true
        
        // Initialize recipes with Quick Look as reference implementation
        self.repairRecipes = [RepairRecipe.makeQuickLookRecipe()]
        self.subsystemHealth["quicklook"] = .healthy
        
        loadServices()
        loadHistory()
        loadHistoryRecords()
        setupHealthMonitorBridge()
        setupNotificationActionBridge()
    }
    
    // MARK: - Health Monitor Bridge
    private func setupHealthMonitorBridge() {
        Task {
            await HealthMonitor.shared.setCallbacks(
                onProblemConfirmed: { [weak self] issue in
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        self.handleProblemConfirmed(issue)
                    }
                },
                onSubsystemRecovered: { [weak self] subsystemId in
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        self.handleSubsystemRecovered(subsystemId)
                    }
                }
            )
            
            if self.isMonitoringEnabled {
                await HealthMonitor.shared.startBackgroundMonitoring(intervalSeconds: 60.0)
            }
        }
    }
    
    private func setupNotificationActionBridge() {
        NotificationManager.shared.onRepairActionTriggered = { [weak self] recipeId in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if let recipe = self.repairRecipes.first(where: { $0.id == recipeId }) {
                    _ = await self.executeRepair(for: recipe, isAutomatic: true)
                }
            }
        }
    }
    
    private func handleProblemConfirmed(_ issue: ActiveIssue) {
        if !activeIssues.contains(where: { $0.id == issue.id }) {
            activeIssues.append(issue)
        }
        subsystemHealth[issue.id] = .problemDetected
        
        let record = HistoryRecord.fromProblemDetected(issue)
        addHistoryRecord(record)
        
        if notificationsEnabled {
            NotificationManager.shared.sendIssueNotification(issue: issue)
        }
        if soundEnabled {
            NotificationManager.shared.playErrorFeedback()
        }
    }
    
    private func handleSubsystemRecovered(_ subsystemId: String) {
        activeIssues.removeAll(where: { $0.id == subsystemId })
        subsystemHealth[subsystemId] = .healthy
        
        let subsystemName = repairRecipes.first(where: { $0.id == "recipe_\(subsystemId)" })?.subsystemName ?? subsystemId.capitalized
        let record = HistoryRecord.fromRecovery(subsystemName: subsystemName)
        addHistoryRecord(record)
    }
    
    // MARK: - Repair Execution
    public func executeRepair(
        for recipe: RepairRecipe,
        isAutomatic: Bool = false,
        confirmationProvider: (@Sendable (RepairStage) async -> Bool)? = nil
    ) async -> RepairExecutionResult {
        activeRepairStatus[recipe.id] = .diagnosing
        activeRepairMessage[recipe.id] = "Diagnosing \(recipe.subsystemName)..."
        
        let result = await RepairEngine.shared.execute(
            recipe: recipe,
            isAutomatic: isAutomatic,
            onStatusChange: { [weak self] status, msg in
                Task { @MainActor [weak self] in
                    self?.activeRepairStatus[recipe.id] = status
                    self?.activeRepairMessage[recipe.id] = msg
                }
            },
            confirmationProvider: confirmationProvider
        )
        
        activeRepairStatus[recipe.id] = result.status
        activeRepairMessage[recipe.id] = result.summaryMessage
        
        if result.status == .fixed {
            activeIssues.removeAll(where: { $0.recipeId == recipe.id })
            if recipe.id == "recipe_quicklook" {
                subsystemHealth["quicklook"] = .healthy
            }
        }
        
        let record = HistoryRecord.fromRepairResult(result)
        addHistoryRecord(record)
        
        if notificationsEnabled {
            NotificationManager.shared.sendRepairResultNotification(result: result)
        }
        if soundEnabled {
            if result.status.isSuccess {
                NotificationManager.shared.playSuccessFeedback()
            } else {
                NotificationManager.shared.playErrorFeedback()
            }
        }
        
        return result
    }
    
    // MARK: - Data Loading
    private func loadServices() {
        var loadedCustom: [ServiceItem] = []
        if let data = UserDefaults.standard.data(forKey: customServicesKey),
           let items = try? JSONDecoder().decode([ServiceItem].self, from: data) {
            loadedCustom = items
        }
        self.customServices = loadedCustom
        
        let favoriteIds: Set<String>
        if let savedFavorites = UserDefaults.standard.stringArray(forKey: favoritesKey) {
            favoriteIds = Set(savedFavorites)
        } else {
            favoriteIds = ["finder", "dock", "coreaudio", "dnscache", "wifi"]
        }
        
        var all = ServiceItem.builtInServices + loadedCustom
        for i in 0..<all.count {
            all[i].isFavorited = favoriteIds.contains(all[i].id)
        }
        self.services = all
    }
    
    private func saveFavorites() {
        let favoriteIds = services.filter { $0.isFavorited }.map { $0.id }
        UserDefaults.standard.set(favoriteIds, forKey: favoritesKey)
    }
    
    private func saveCustomServices() {
        if let data = try? JSONEncoder().encode(customServices) {
            UserDefaults.standard.set(data, forKey: customServicesKey)
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let items = try? JSONDecoder().decode([RestartResult].self, from: data) {
            self.history = items
        }
    }
    
    private func saveHistory() {
        let trimmed = Array(history.prefix(50))
        if let data = try? JSONEncoder().encode(trimmed) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }
    
    private func loadHistoryRecords() {
        if let data = UserDefaults.standard.data(forKey: historyRecordsKey),
           let items = try? JSONDecoder().decode([HistoryRecord].self, from: data) {
            self.historyRecords = items
        }
    }
    
    private func saveHistoryRecords() {
        let trimmed = Array(historyRecords.prefix(100))
        if let data = try? JSONEncoder().encode(trimmed) {
            UserDefaults.standard.set(data, forKey: historyRecordsKey)
        }
    }
    
    public func addHistoryRecord(_ record: HistoryRecord) {
        historyRecords.insert(record, at: 0)
        saveHistoryRecords()
    }
    
    // MARK: - Computed Properties
    public var favoriteServices: [ServiceItem] {
        services.filter { $0.isFavorited }
    }
    
    public var filteredServices: [ServiceItem] {
        services.filter { service in
            let matchesCategory: Bool
            if selectedCategory == .all {
                matchesCategory = true
            } else if selectedCategory == .custom {
                matchesCategory = !service.isBuiltIn
            } else {
                matchesCategory = service.category == selectedCategory
            }
            
            guard matchesCategory else { return false }
            
            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return true
            }
            
            let query = searchText.lowercased()
            let matchesName = service.name.lowercased().contains(query)
            let matchesSubtitle = service.subtitle.lowercased().contains(query)
            let matchesDescription = service.fixesDescription.lowercased().contains(query)
            let matchesKeywords = service.keywords.contains { $0.lowercased().contains(query) }
            
            return matchesName || matchesSubtitle || matchesDescription || matchesKeywords
        }
    }
    
    public var isAnyRestarting: Bool {
        !restartingServiceIds.isEmpty
    }
    
    // MARK: - Actions
    public func toggleFavorite(for serviceId: String) {
        if let index = services.firstIndex(where: { $0.id == serviceId }) {
            services[index].isFavorited.toggle()
            saveFavorites()
        }
    }
    
    public func restartService(_ service: ServiceItem) async -> RestartResult {
        restartingServiceIds.insert(service.id)
        
        let result = await ServiceRunner.shared.execute(service: service)
        
        restartingServiceIds.remove(service.id)
        recentResults[service.id] = result
        history.insert(result, at: 0)
        saveHistory()
        
        // Add to rich history records
        addHistoryRecord(HistoryRecord.fromRestartResult(result))
        
        if notificationsEnabled {
            NotificationManager.shared.sendNotification(for: result, soundEnabled: soundEnabled)
        } else if soundEnabled {
            if result.isSuccess {
                NotificationManager.shared.playSuccessFeedback()
            } else {
                NotificationManager.shared.playErrorFeedback()
            }
        }
        
        return result
    }
    
    public func restartAllFavorites() async {
        let favorites = favoriteServices
        for service in favorites {
            _ = await restartService(service)
        }
    }
    
    public func addCustomService(_ service: ServiceItem) {
        customServices.append(service)
        services.append(service)
        saveCustomServices()
        if service.isFavorited {
            saveFavorites()
        }
    }
    
    public func deleteCustomService(id: String) {
        customServices.removeAll { $0.id == id }
        services.removeAll { $0.id == id && !$0.isBuiltIn }
        saveCustomServices()
        saveFavorites()
    }
    
    public func clearHistory() {
        history.removeAll()
        historyRecords.removeAll()
        UserDefaults.standard.removeObject(forKey: historyKey)
        UserDefaults.standard.removeObject(forKey: historyRecordsKey)
    }
    
    public func getService(byId id: String) -> ServiceItem? {
        services.first { $0.id == id }
    }
}
