import Foundation
import SwiftUI
import Combine

@MainActor
public final class ServiceManager: ObservableObject {
    public static let shared = ServiceManager()
    
    // MARK: - Published Properties
    @Published public var services: [ServiceItem] = []
    @Published public var customServices: [ServiceItem] = []
    @Published public var restartingServiceIds: Set<String> = []
    @Published public var recentResults: [String: RestartResult] = [:]
    @Published public var history: [RestartResult] = []
    
    // Search & Filter
    @Published public var searchText: String = ""
    @Published public var selectedCategory: ServiceCategory = .all
    
    // Preferences
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
    
    private init() {
        self.notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
        self.soundEnabled = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
        self.confirmDangerousActions = UserDefaults.standard.object(forKey: "confirmDangerousActions") as? Bool ?? true
        
        loadServices()
        loadHistory()
    }
    
    // MARK: - Data Loading
    private func loadServices() {
        // Load custom services
        var loadedCustom: [ServiceItem] = []
        if let data = UserDefaults.standard.data(forKey: customServicesKey),
           let items = try? JSONDecoder().decode([ServiceItem].self, from: data) {
            loadedCustom = items
        }
        self.customServices = loadedCustom
        
        // Load favorites
        let favoriteIds: Set<String>
        if let savedFavorites = UserDefaults.standard.stringArray(forKey: favoritesKey) {
            favoriteIds = Set(savedFavorites)
        } else {
            // Default favorites
            favoriteIds = ["finder", "dock", "coreaudio", "dnscache", "wifi"]
        }
        
        // Merge built-in and custom
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
        // Keep max 50 items
        let trimmed = Array(history.prefix(50))
        if let data = try? JSONEncoder().encode(trimmed) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
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
        
        // Notifications & Sound
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
        UserDefaults.standard.removeObject(forKey: historyKey)
    }
    
    public func getService(byId id: String) -> ServiceItem? {
        services.first { $0.id == id }
    }
}
