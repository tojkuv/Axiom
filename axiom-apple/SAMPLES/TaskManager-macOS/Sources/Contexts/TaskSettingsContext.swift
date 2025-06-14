import Foundation
import SwiftUI
import Combine
import Axiom

// Import shared Task Manager components
import TaskManager_Shared

// MARK: - Task Settings Context (macOS)

/// Settings and preferences context for macOS Task Manager with comprehensive desktop features
@MainActor
public final class TaskSettingsContext: ObservableContext {
    
    // MARK: - Dependencies
    private let client: TaskClient
    private let storage: any TaskStorageCapability
    
    // MARK: - Published Properties
    
    // User Preferences
    @Published public private(set) var defaultPriority: Priority = .medium
    @Published public private(set) var defaultCategory: TaskManager_Shared.Category = .personal
    @Published public private(set) var defaultSortOrder: Task.SortOrder = .createdDate
    @Published public private(set) var defaultSortAscending: Bool = false
    @Published public private(set) var showCompletedTasks: Bool = true
    @Published public private(set) var autoArchiveCompleted: Bool = false
    @Published public private(set) var autoArchiveDays: Int = 30
    
    // Notification Settings
    @Published public private(set) var enableNotifications: Bool = false
    @Published public private(set) var notificationTime: Date = Date()
    @Published public private(set) var reminderOffset: TimeInterval = -3600 // 1 hour before
    @Published public private(set) var soundEnabled: Bool = true
    @Published public private(set) var badgeEnabled: Bool = true
    
    // Window and Display Settings
    @Published public private(set) var windowOpacity: Double = 1.0
    @Published public private(set) var useNativeMenuBar: Bool = true
    @Published public private(set) var showInDock: Bool = true
    @Published public private(set) var launchAtLogin: Bool = false
    @Published public private(set) var defaultViewMode: ViewMode = .list
    @Published public private(set) var compactMode: Bool = false
    @Published public private(set) var showToolbar: Bool = true
    @Published public private(set) var showStatusBar: Bool = true
    @Published public private(set) var colorScheme: AppearanceMode = .system
    
    // Advanced Settings
    @Published public private(set) var enableDebugMode: Bool = false
    @Published public private(set) var enableAnalytics: Bool = false
    @Published public private(set) var autoSaveInterval: TimeInterval = 30
    @Published public private(set) var backupEnabled: Bool = true
    @Published public private(set) var backupFrequency: BackupFrequency = .daily
    @Published public private(set) var maxBackups: Int = 10
    
    // State Management
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var isSaving: Bool = false
    @Published public private(set) var isExporting: Bool = false
    @Published public private(set) var isImporting: Bool = false
    @Published public private(set) var error: String? = nil
    @Published public private(set) var exportSuccess: Bool = false
    @Published public private(set) var importSuccess: Bool = false
    @Published public private(set) var resetSuccess: Bool = false
    
    // Storage and Statistics
    @Published public private(set) var storageInfo: StorageInfo?
    @Published public private(set) var statistics: TaskStatistics?
    @Published public private(set) var totalTasks: Int = 0
    @Published public private(set) var completedTasks: Int = 0
    @Published public private(set) var lastBackupDate: Date?
    @Published public private(set) var storageUsage: Int64 = 0
    
    // Import/Export Status
    @Published public private(set) var exportProgress: Double = 0.0
    @Published public private(set) var importProgress: Double = 0.0
    @Published public private(set) var exportURL: URL?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var settingsUpdateDebouncer: AnyCancellable?
    
    // MARK: - Initialization
    
    public required init() {
        fatalError("Use init(client:storage:) instead")
    }
    
    public init(client: TaskClient, storage: any TaskStorageCapability) {
        self.client = client
        self.storage = storage
        super.init()
        setupSettingsObservation()
    }
    
    // MARK: - Lifecycle
    
    public override func appeared() async {
        await super.appeared()
        await loadSettings()
        await loadStorageInfo()
        await loadStatistics()
    }
    
    // MARK: - Settings Management
    
    private func setupSettingsObservation() {
        // Set up debounced settings updates
        settingsUpdateDebouncer = Publishers.CombineLatest4(
            $defaultPriority,
            $defaultCategory,
            $defaultSortOrder,
            $defaultSortAscending
        )
        .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            _Concurrency.Task { await self?.saveSettings() }
        }
    }
    
    private func loadSettings() async {
        await setLoading(true)
        
        // In a real implementation, this would load from UserDefaults or a settings file
        await MainActor.run {
            // Set default values - in reality these would be loaded from storage
            defaultPriority = .medium
            defaultCategory = .personal
            defaultSortOrder = .createdDate
            defaultSortAscending = false
            showCompletedTasks = true
            enableNotifications = false
            notificationTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
            windowOpacity = 1.0
            useNativeMenuBar = true
            showInDock = true
            launchAtLogin = false
            defaultViewMode = .list
            compactMode = false
            showToolbar = true
            showStatusBar = true
            colorScheme = .system
            enableDebugMode = false
            enableAnalytics = false
            autoSaveInterval = 30
            backupEnabled = true
            backupFrequency = .daily
            maxBackups = 10
        }
        
        await setLoading(false)
    }
    
    private func saveSettings() async {
        await setSaving(true)
        
        // In a real implementation, this would save to UserDefaults or a settings file
        try? await _Concurrency.Task.sleep(nanoseconds: 500_000_000) // Simulate save delay
        
        await setSaving(false)
    }
    
    // MARK: - Settings Updates
    
    public func updateDefaultPriority(_ priority: Priority) async {
        await MainActor.run {
            defaultPriority = priority
        }
    }
    
    public func updateDefaultCategory(_ category: TaskManager_Shared.Category) async {
        await MainActor.run {
            defaultCategory = category
        }
    }
    
    public func updateDefaultSortOrder(_ sortOrder: Task.SortOrder, ascending: Bool) async {
        await MainActor.run {
            defaultSortOrder = sortOrder
            defaultSortAscending = ascending
        }
    }
    
    public func updateShowCompletedTasks(_ show: Bool) async {
        await MainActor.run {
            showCompletedTasks = show
        }
        await saveSettings()
    }
    
    public func updateAutoArchiveCompleted(_ enabled: Bool) async {
        await MainActor.run {
            autoArchiveCompleted = enabled
        }
        await saveSettings()
    }
    
    public func updateAutoArchiveDays(_ days: Int) async {
        await MainActor.run {
            autoArchiveDays = max(1, min(365, days))
        }
        await saveSettings()
    }
    
    public func updateEnableNotifications(_ enabled: Bool) async {
        await MainActor.run {
            enableNotifications = enabled
        }
        await saveSettings()
    }
    
    public func updateNotificationTime(_ time: Date) async {
        await MainActor.run {
            notificationTime = time
        }
        await saveSettings()
    }
    
    public func updateReminderOffset(_ offset: TimeInterval) async {
        await MainActor.run {
            reminderOffset = offset
        }
        await saveSettings()
    }
    
    public func updateWindowOpacity(_ opacity: Double) async {
        await MainActor.run {
            windowOpacity = max(0.3, min(1.0, opacity))
        }
        await saveSettings()
    }
    
    public func updateUseNativeMenuBar(_ enabled: Bool) async {
        await MainActor.run {
            useNativeMenuBar = enabled
        }
        await saveSettings()
    }
    
    public func updateShowInDock(_ show: Bool) async {
        await MainActor.run {
            showInDock = show
        }
        await saveSettings()
    }
    
    public func updateLaunchAtLogin(_ enabled: Bool) async {
        await MainActor.run {
            launchAtLogin = enabled
        }
        await saveSettings()
        await configureLaunchAtLogin(enabled)
    }
    
    public func updateDefaultViewMode(_ mode: ViewMode) async {
        await MainActor.run {
            defaultViewMode = mode
        }
        await saveSettings()
    }
    
    public func updateCompactMode(_ enabled: Bool) async {
        await MainActor.run {
            compactMode = enabled
        }
        await saveSettings()
    }
    
    public func updateShowToolbar(_ show: Bool) async {
        await MainActor.run {
            showToolbar = show
        }
        await saveSettings()
    }
    
    public func updateShowStatusBar(_ show: Bool) async {
        await MainActor.run {
            showStatusBar = show
        }
        await saveSettings()
    }
    
    public func updateColorScheme(_ scheme: AppearanceMode) async {
        await MainActor.run {
            colorScheme = scheme
        }
        await saveSettings()
    }
    
    public func updateEnableDebugMode(_ enabled: Bool) async {
        await MainActor.run {
            enableDebugMode = enabled
        }
        await saveSettings()
    }
    
    public func updateEnableAnalytics(_ enabled: Bool) async {
        await MainActor.run {
            enableAnalytics = enabled
        }
        await saveSettings()
    }
    
    public func updateAutoSaveInterval(_ interval: TimeInterval) async {
        await MainActor.run {
            autoSaveInterval = max(10, min(300, interval))
        }
        await saveSettings()
    }
    
    public func updateBackupEnabled(_ enabled: Bool) async {
        await MainActor.run {
            backupEnabled = enabled
        }
        await saveSettings()
    }
    
    public func updateBackupFrequency(_ frequency: BackupFrequency) async {
        await MainActor.run {
            backupFrequency = frequency
        }
        await saveSettings()
    }
    
    public func updateMaxBackups(_ count: Int) async {
        await MainActor.run {
            maxBackups = max(1, min(100, count))
        }
        await saveSettings()
    }
    
    // MARK: - Data Management
    
    public func loadStorageInfo() async {
        do {
            let info = try await storage.getStorageInfo()
            await MainActor.run {
                storageInfo = info
                storageUsage = Int64(info.storageSize)
            }
        } catch {
            await setError("Failed to load storage info: \(error.localizedDescription)")
        }
    }
    
    public func loadStatistics() async {
        let stats = await client.getStatistics()
        await MainActor.run {
            statistics = stats
            totalTasks = stats.totalTasks
            completedTasks = stats.completedTasks
        }
    }
    
    public func exportTasks() async {
        await setExporting(true)
        await MainActor.run { exportProgress = 0.0 }
        
        do {
            // Simulate export progress
            for i in 1...10 {
                await MainActor.run { exportProgress = Double(i) / 10.0 }
                try await _Concurrency.Task.sleep(nanoseconds: 100_000_000)
            }
            
            try await client.process(.exportTasks)
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let exportURL = documentsURL.appendingPathComponent("tasks_export_\(Int(Date().timeIntervalSince1970)).json")
            
            await MainActor.run {
                self.exportURL = exportURL
                exportSuccess = true
            }
            
        } catch {
            await setError("Failed to export tasks: \(error.localizedDescription)")
        }
        
        await setExporting(false)
    }
    
    public func importTasks(from url: URL) async {
        await setImporting(true)
        await MainActor.run { importProgress = 0.0 }
        
        do {
            let importData = try Data(contentsOf: url)
            
            // Simulate import progress
            for i in 1...10 {
                await MainActor.run { importProgress = Double(i) / 10.0 }
                try await _Concurrency.Task.sleep(nanoseconds: 100_000_000)
            }
            
            let decoder = JSONDecoder()
            let tasks = try decoder.decode([Task].self, from: importData)
            try await client.process(.importTasks(tasks))
            
            await MainActor.run {
                importSuccess = true
            }
            
            await loadStatistics()
            
        } catch {
            await setError("Failed to import tasks: \(error.localizedDescription)")
        }
        
        await setImporting(false)
    }
    
    public func clearAllTasks() async {
        do {
            try await client.process(.clearAllTasks)
            await loadStatistics()
        } catch {
            await setError("Failed to clear tasks: \(error.localizedDescription)")
        }
    }
    
    public func deleteCompletedTasks() async {
        do {
            try await client.process(.deleteCompletedTasks)
            await loadStatistics()
        } catch {
            await setError("Failed to delete completed tasks: \(error.localizedDescription)")
        }
    }
    
    public func resetToDefaults() async {
        await MainActor.run {
            defaultPriority = .medium
            defaultCategory = .personal
            defaultSortOrder = .createdDate
            defaultSortAscending = false
            showCompletedTasks = true
            autoArchiveCompleted = false
            autoArchiveDays = 30
            enableNotifications = false
            notificationTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
            reminderOffset = -3600
            soundEnabled = true
            badgeEnabled = true
            windowOpacity = 1.0
            useNativeMenuBar = true
            showInDock = true
            launchAtLogin = false
            defaultViewMode = .list
            compactMode = false
            showToolbar = true
            showStatusBar = true
            colorScheme = .system
            enableDebugMode = false
            enableAnalytics = false
            autoSaveInterval = 30
            backupEnabled = true
            backupFrequency = .daily
            maxBackups = 10
            resetSuccess = true
        }
        
        await saveSettings()
    }
    
    public func createBackup() async {
        guard backupEnabled else { return }
        
        do {
            // Get current state and save as backup
            let currentState = await client.getCurrentState()
            try await storage.saveTasks(currentState.tasks)
            await MainActor.run {
                lastBackupDate = Date()
            }
        } catch {
            await setError("Failed to create backup: \(error.localizedDescription)")
        }
    }
    
    // MARK: - System Integration
    
    private func configureLaunchAtLogin(_ enabled: Bool) async {
        // In a real macOS app, this would configure launch at login
        // Using SMLoginItemSetEnabled or similar APIs
        print("Configure launch at login: \(enabled)")
    }
    
    // MARK: - Diagnostic Information
    
    public func generateDiagnosticInfo() async -> String {
        let systemInfo = await generateSystemInfo()
        let appInfo = await generateAppInfo()
        let storageInfo = await generateStorageInfo()
        let settingsInfo = await generateSettingsInfo()
        
        return """
        TASK MANAGER DIAGNOSTIC INFORMATION
        Generated: \(DateFormatter().string(from: Date()))
        
        \(systemInfo)
        
        \(appInfo)
        
        \(storageInfo)
        
        \(settingsInfo)
        """
    }
    
    private func generateSystemInfo() async -> String {
        let processInfo = ProcessInfo.processInfo
        return """
        SYSTEM INFORMATION
        macOS Version: \(processInfo.operatingSystemVersionString)
        Memory: \(processInfo.physicalMemory / 1_073_741_824) GB
        CPU Count: \(processInfo.processorCount)
        """
    }
    
    private func generateAppInfo() async -> String {
        return """
        APPLICATION INFORMATION
        Total Tasks: \(totalTasks)
        Completed Tasks: \(completedTasks)
        Storage Usage: \(storageUsageDescription)
        Debug Mode: \(enableDebugMode ? "Enabled" : "Disabled")
        """
    }
    
    private func generateStorageInfo() async -> String {
        guard let storage = storageInfo else {
            return "STORAGE INFORMATION\nUnavailable"
        }
        
        return """
        STORAGE INFORMATION
        Available: \(storage.isAvailable ? "Yes" : "No")
        Size: \(ByteCountFormatter.string(fromByteCount: Int64(storage.storageSize), countStyle: .file))
        Last Modified: \(storage.lastModified.map { DateFormatter().string(from: $0) } ?? "Unknown")
        """
    }
    
    private func generateSettingsInfo() async -> String {
        return """
        SETTINGS INFORMATION
        Default Priority: \(defaultPriority.displayName)
        Default Category: \(defaultCategory.displayName)
        View Mode: \(defaultViewMode.displayName)
        Notifications: \(enableNotifications ? "Enabled" : "Disabled")
        Backup: \(backupEnabled ? "Enabled" : "Disabled")
        Launch at Login: \(launchAtLogin ? "Enabled" : "Disabled")
        """
    }
    
    // MARK: - Helper Methods
    
    private func setLoading(_ loading: Bool) async {
        await MainActor.run {
            isLoading = loading
        }
    }
    
    private func setSaving(_ saving: Bool) async {
        await MainActor.run {
            isSaving = saving
        }
    }
    
    private func setExporting(_ exporting: Bool) async {
        await MainActor.run {
            isExporting = exporting
            if !exporting {
                exportProgress = 0.0
            }
        }
    }
    
    private func setImporting(_ importing: Bool) async {
        await MainActor.run {
            isImporting = importing
            if !importing {
                importProgress = 0.0
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
            resetSuccess = false
        }
    }
    
    // MARK: - Computed Properties
    
    public var hasRecentBackup: Bool {
        guard let lastBackup = lastBackupDate else { return false }
        return Date().timeIntervalSince(lastBackup) < 86400 // 24 hours
    }
    
    public var storageUsageDescription: String {
        ByteCountFormatter.string(fromByteCount: storageUsage, countStyle: .file)
    }
    
    public var tasksCompletionPercentage: Double {
        guard totalTasks > 0 else { return 0.0 }
        return Double(completedTasks) / Double(totalTasks)
    }
    
    public var reminderOffsetDescription: String {
        let hours = abs(reminderOffset) / 3600
        let minutes = (abs(reminderOffset).truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours >= 1 && minutes > 0 {
            return String(format: "%.0fh %.0fm before", hours, minutes)
        } else if hours >= 1 {
            return String(format: "%.0fh before", hours)
        } else {
            return String(format: "%.0fm before", minutes)
        }
    }
    
    // MARK: - Window Management Access
    
    public func getClient() -> TaskClient {
        return client
    }
    
    public func getStorage() -> any TaskStorageCapability {
        return storage
    }
}

// MARK: - Supporting Types

public enum AppearanceMode: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    public var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

public enum BackupFrequency: String, CaseIterable {
    case never = "never"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    
    public var displayName: String {
        switch self {
        case .never: return "Never"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}


