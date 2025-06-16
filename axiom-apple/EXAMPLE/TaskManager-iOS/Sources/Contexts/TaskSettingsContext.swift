import Foundation
import SwiftUI
import Axiom

// Import shared Task Manager components
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared
@_implementationOnly import TaskManager_Shared

// MARK: - Task Settings Context (iOS)

/// Context for managing app settings and preferences on iOS
@MainActor
public final class TaskSettingsContext: ObservableContext {
    
    // MARK: - Properties
    private let client: TaskClient
    private let storage: any TaskStorageCapability
    
    // MARK: - Published Properties
    @Published public private(set) var storageInfo: StorageInfo?
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var error: String? = nil
    
    // App settings
    @Published public var defaultCategory: Category = .personal
    @Published public var defaultPriority: Priority = .medium
    @Published public var defaultSortOrder: Task.SortOrder = .createdDate
    @Published public var defaultSortAscending: Bool = false
    @Published public var showCompletedTasks: Bool = true
    @Published public var enableNotifications: Bool = true
    @Published public var notificationTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    
    // Data management
    @Published public private(set) var lastSyncDate: Date?
    @Published public private(set) var lastBackupDate: Date?
    @Published public private(set) var totalTasks: Int = 0
    @Published public private(set) var completedTasks: Int = 0
    
    // Export/Import states
    @Published public private(set) var isExporting: Bool = false
    @Published public private(set) var isImporting: Bool = false
    @Published public private(set) var exportSuccess: Bool = false
    @Published public private(set) var importSuccess: Bool = false
    
    // MARK: - Initialization
    
    public required init() {
        fatalError("Use init(client:storage:) instead")
    }
    
    public init(client: TaskClient, storage: any TaskStorageCapability) {
        self.client = client
        self.storage = storage
        super.init()
        loadSettings()
    }
    
    // MARK: - Lifecycle
    
    public override func appeared() async {
        await super.appeared()
        await loadStorageInfo()
        await loadStatistics()
    }
    
    // MARK: - Settings Management
    
    private func loadSettings() {
        // In a real app, these would be loaded from UserDefaults
        defaultCategory = UserDefaults.standard.object(forKey: "defaultCategory") as? Category ?? .personal
        defaultPriority = UserDefaults.standard.object(forKey: "defaultPriority") as? Priority ?? .medium
        defaultSortOrder = UserDefaults.standard.object(forKey: "defaultSortOrder") as? Task.SortOrder ?? .createdDate
        defaultSortAscending = UserDefaults.standard.bool(forKey: "defaultSortAscending")
        showCompletedTasks = UserDefaults.standard.object(forKey: "showCompletedTasks") as? Bool ?? true
        enableNotifications = UserDefaults.standard.object(forKey: "enableNotifications") as? Bool ?? true
        
        if let timeData = UserDefaults.standard.object(forKey: "notificationTime") as? Data,
           let time = try? JSONDecoder().decode(Date.self, from: timeData) {
            notificationTime = time
        }
        
        lastSyncDate = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date
        lastBackupDate = UserDefaults.standard.object(forKey: "lastBackupDate") as? Date
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(defaultCategory.rawValue, forKey: "defaultCategory")
        UserDefaults.standard.set(defaultPriority.rawValue, forKey: "defaultPriority")
        UserDefaults.standard.set(defaultSortOrder.rawValue, forKey: "defaultSortOrder")
        UserDefaults.standard.set(defaultSortAscending, forKey: "defaultSortAscending")
        UserDefaults.standard.set(showCompletedTasks, forKey: "showCompletedTasks")
        UserDefaults.standard.set(enableNotifications, forKey: "enableNotifications")
        
        if let timeData = try? JSONEncoder().encode(notificationTime) {
            UserDefaults.standard.set(timeData, forKey: "notificationTime")
        }
        
        UserDefaults.standard.set(lastSyncDate, forKey: "lastSyncDate")
        UserDefaults.standard.set(lastBackupDate, forKey: "lastBackupDate")
    }
    
    // MARK: - Setting Updates
    
    public func updateDefaultCategory(_ category: Category) async {
        await MainActor.run {
            defaultCategory = category
            saveSettings()
        }
    }
    
    public func updateDefaultPriority(_ priority: Priority) async {
        await MainActor.run {
            defaultPriority = priority
            saveSettings()
        }
    }
    
    public func updateDefaultSortOrder(_ sortOrder: Task.SortOrder, ascending: Bool) async {
        await MainActor.run {
            defaultSortOrder = sortOrder
            defaultSortAscending = ascending
            saveSettings()
        }
    }
    
    public func updateShowCompletedTasks(_ show: Bool) async {
        await MainActor.run {
            showCompletedTasks = show
            saveSettings()
        }
    }
    
    public func updateEnableNotifications(_ enable: Bool) async {
        await MainActor.run {
            enableNotifications = enable
            saveSettings()
        }
    }
    
    public func updateNotificationTime(_ time: Date) async {
        await MainActor.run {
            notificationTime = time
            saveSettings()
        }
    }
    
    // MARK: - Data Management
    
    public func loadStorageInfo() async {
        await setLoading(true)
        
        do {
            let info = try await storage.getStorageInfo()
            await MainActor.run {
                storageInfo = info
            }
        } catch {
            await setError("Failed to load storage info: \(error.localizedDescription)")
        }
        
        await setLoading(false)
    }
    
    public func loadStatistics() async {
        let stats = await client.getStatistics()
        await MainActor.run {
            totalTasks = stats.totalTasks
            completedTasks = stats.completedTasks
        }
    }
    
    // MARK: - Export/Import
    
    public func exportTasks() async {
        await setExporting(true)
        
        do {
            let currentState = await client.getCurrentState()
            try await storage.exportTasks(currentState.tasks)
            
            await MainActor.run {
                exportSuccess = true
                lastBackupDate = Date()
                saveSettings()
            }
        } catch {
            await setError("Failed to export tasks: \(error.localizedDescription)")
        }
        
        await setExporting(false)
    }
    
    public func importTasks(from data: Data) async {
        await setImporting(true)
        
        do {
            let tasks = try await storage.importTasks(from: data)
            try await client.process(.importTasks(tasks))
            
            await MainActor.run {
                importSuccess = true
            }
            
            await loadStatistics()
            await loadStorageInfo()
        } catch {
            await setError("Failed to import tasks: \(error.localizedDescription)")
        }
        
        await setImporting(false)
    }
    
    // MARK: - Data Operations
    
    public func clearAllTasks() async {
        await setLoading(true)
        
        do {
            try await client.process(.clearAllTasks)
            await loadStatistics()
            await loadStorageInfo()
        } catch {
            await setError("Failed to clear tasks: \(error.localizedDescription)")
        }
        
        await setLoading(false)
    }
    
    public func deleteCompletedTasks() async {
        await setLoading(true)
        
        do {
            try await client.process(.deleteCompletedTasks)
            await loadStatistics()
            await loadStorageInfo()
        } catch {
            await setError("Failed to delete completed tasks: \(error.localizedDescription)")
        }
        
        await setLoading(false)
    }
    
    public func resetToDefaults() async {
        await MainActor.run {
            defaultCategory = .personal
            defaultPriority = .medium
            defaultSortOrder = .createdDate
            defaultSortAscending = false
            showCompletedTasks = true
            enableNotifications = true
            notificationTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
            
            saveSettings()
        }
    }
    
    // MARK: - Diagnostic Information
    
    public func generateDiagnosticInfo() async -> String {
        let stats = await client.getStatistics()
        let metrics = await client.getPerformanceMetrics()
        
        var info = """
        Task Manager Diagnostic Information
        Generated: \(DateFormatter.localizedString(from: Date(), dateStyle: .full, timeStyle: .full))
        
        Statistics:
        - Total Tasks: \(stats.totalTasks)
        - Completed Tasks: \(stats.completedTasks)
        - Pending Tasks: \(stats.pendingTasks)
        - Overdue Tasks: \(stats.overdueTasks)
        - Due Today: \(stats.dueTodayTasks)
        - Due This Week: \(stats.dueThisWeekTasks)
        
        Performance:
        - Actions Processed: \(metrics.actionCount)
        - History Size: \(metrics.stateHistorySize)
        - Current History Index: \(metrics.currentHistoryIndex)
        """
        
        if let lastActionTime = metrics.lastActionTime {
            info += "\n- Last Action: \(DateFormatter.localizedString(from: lastActionTime, dateStyle: .short, timeStyle: .medium))"
        }
        
        if let storageInfo = storageInfo {
            info += """
            
            Storage:
            - Location: \(storageInfo.storageLocation)
            - Size: \(storageInfo.storageSize) bytes
            - Available: \(storageInfo.isAvailable ? "Yes" : "No")
            """
            
            if let lastModified = storageInfo.lastModified {
                info += "\n- Last Modified: \(DateFormatter.localizedString(from: lastModified, dateStyle: .short, timeStyle: .medium))"
            }
        }
        
        info += """
        
        Settings:
        - Default Category: \(defaultCategory.displayName)
        - Default Priority: \(defaultPriority.displayName)
        - Default Sort: \(defaultSortOrder.displayName) (\(defaultSortAscending ? "Ascending" : "Descending"))
        - Show Completed: \(showCompletedTasks ? "Yes" : "No")
        - Notifications: \(enableNotifications ? "Enabled" : "Disabled")
        """
        
        return info
    }
    
    // MARK: - Helper Methods
    
    private func setLoading(_ loading: Bool) async {
        await MainActor.run {
            isLoading = loading
        }
    }
    
    private func setExporting(_ exporting: Bool) async {
        await MainActor.run {
            isExporting = exporting
            if exporting {
                exportSuccess = false
            }
        }
    }
    
    private func setImporting(_ importing: Bool) async {
        await MainActor.run {
            isImporting = importing
            if importing {
                importSuccess = false
            }
        }
    }
    
    private func setError(_ errorMessage: String) async {
        await MainActor.run {
            error = errorMessage
        }
    }
    
    public func clearError() async {
        await MainActor.run {
            error = nil
        }
    }
    
    public func clearSuccessStates() async {
        await MainActor.run {
            exportSuccess = false
            importSuccess = false
        }
    }
    
    // MARK: - Public Access Methods
    
    public func getClient() -> TaskClient {
        return client
    }
    
    public func getStorage() -> any TaskStorageCapability {
        return storage
    }
    
    // MARK: - Computed Properties
    
    public var storageUsageDescription: String {
        guard let info = storageInfo else { return "Unknown" }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        
        return formatter.string(fromByteCount: Int64(info.storageSize))
    }
    
    public var tasksCompletionPercentage: Double {
        guard totalTasks > 0 else { return 0.0 }
        return Double(completedTasks) / Double(totalTasks)
    }
    
    public var hasRecentBackup: Bool {
        guard let lastBackup = lastBackupDate else { return false }
        let daysSinceBackup = Calendar.current.dateComponents([.day], from: lastBackup, to: Date()).day ?? 0
        return daysSinceBackup <= 7 // Consider backup recent if within 7 days
    }
}