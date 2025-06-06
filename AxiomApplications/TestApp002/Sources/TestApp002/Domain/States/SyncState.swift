import Foundation

struct SyncState: State, Equatable, Hashable {
    let isSyncing: Bool
    let progress: Double
    let lastSyncDate: Date?
    let pendingChanges: Int
    let conflicts: [SyncConflict]
    let isOffline: Bool
    let syncLogs: [SyncLogEntry]
    let currentStatus: String
    
    init(
        isSyncing: Bool = false,
        progress: Double = 0.0,
        lastSyncDate: Date? = nil,
        pendingChanges: Int = 0,
        conflicts: [SyncConflict] = [],
        isOffline: Bool = false,
        syncLogs: [SyncLogEntry] = [],
        currentStatus: String = "Ready"
    ) {
        self.isSyncing = isSyncing
        self.progress = progress
        self.lastSyncDate = lastSyncDate
        self.pendingChanges = pendingChanges
        self.conflicts = conflicts
        self.isOffline = isOffline
        self.syncLogs = syncLogs
        self.currentStatus = currentStatus
    }
    
    // REFACTOR: Enhanced UI feedback with computed properties
    var progressPercentage: Int {
        Int(progress * 100)
    }
    
    var statusMessage: String {
        if isOffline {
            return "Offline - Sync disabled"
        } else if isSyncing {
            return "Syncing... \(progressPercentage)%"
        } else if conflicts.count > 0 {
            return "Sync conflicts need resolution"
        } else if lastSyncDate != nil {
            return "Last sync: \(lastSyncDate!.formatted(.relative(presentation: .named)))"
        } else {
            return currentStatus
        }
    }
}

struct SyncLogEntry: Equatable, Hashable, Identifiable, Codable {
    let id: String
    let timestamp: Date
    let level: LogLevel
    let message: String
    let details: [String: String]?
    
    init(
        id: String = UUID().uuidString,
        timestamp: Date = Date(),
        level: LogLevel,
        message: String,
        details: [String: String]? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.message = message
        self.details = details
    }
}

enum LogLevel: String, Codable, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
}

struct SyncConflict: Equatable, Hashable, Identifiable, Codable {
    let id: String
    let taskId: String
    let localVersion: Task
    let remoteVersion: Task
    let timestamp: Date
    
    init(
        id: String = UUID().uuidString,
        taskId: String,
        localVersion: Task,
        remoteVersion: Task,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.taskId = taskId
        self.localVersion = localVersion
        self.remoteVersion = remoteVersion
        self.timestamp = timestamp
    }
}