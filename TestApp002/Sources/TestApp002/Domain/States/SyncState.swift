import Foundation
import Axiom

struct SyncState: State, Equatable, Hashable {
    let isSyncing: Bool
    let progress: Double
    let lastSyncDate: Date?
    let pendingChanges: Int
    let conflicts: [SyncConflict]
    
    init(
        isSyncing: Bool = false,
        progress: Double = 0.0,
        lastSyncDate: Date? = nil,
        pendingChanges: Int = 0,
        conflicts: [SyncConflict] = []
    ) {
        self.isSyncing = isSyncing
        self.progress = progress
        self.lastSyncDate = lastSyncDate
        self.pendingChanges = pendingChanges
        self.conflicts = conflicts
    }
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