import Foundation

enum SyncError: Error {
    case notImplemented
    case offlineMode
    case syncInProgress
}

// REFACTOR Phase: Enhanced SyncClient with logging and better UI feedback
actor SyncClient: Client {
    typealias StateType = SyncState
    typealias ActionType = SyncAction
    
    private var state: SyncState
    private let stateStreamContinuation: AsyncStream<SyncState>.Continuation
    private let _stateStream: AsyncStream<SyncState>
    private var syncTask: _Concurrency.Task<Void, Error>?
    private let maxLogEntries = 100 // Keep last 100 log entries
    
    // Dependencies for capability integration
    private var storageCapability: StorageCapability?
    private var networkCapability: NetworkCapability?
    
    var stateStream: AsyncStream<SyncState> {
        _stateStream
    }
    
    var currentState: SyncState {
        get async {
            state
        }
    }
    
    init() {
        self.state = SyncState()
        
        // Create state stream
        (_stateStream, stateStreamContinuation) = AsyncStream<SyncState>.makeStream()
        
        // Emit initial state
        stateStreamContinuation.yield(state)
    }
    
    // MARK: - Capability Management
    
    func setStorageCapability(_ capability: StorageCapability) async {
        self.storageCapability = capability
    }
    
    func setNetworkCapability(_ capability: NetworkCapability) async {
        self.networkCapability = capability
    }
    
    func process(_ action: SyncAction) async throws {
        switch action {
        case .startSync:
            guard !state.isSyncing else { return }
            guard !state.isOffline else { throw SyncError.offlineMode }
            
            state = addLogAndUpdateState(
                isSyncing: true,
                progress: 0.0,
                lastSyncDate: state.lastSyncDate,
                pendingChanges: state.pendingChanges,
                conflicts: state.conflicts,
                isOffline: state.isOffline,
                currentStatus: "Starting sync...",
                logLevel: .info,
                logMessage: "Sync started"
            )
            stateStreamContinuation.yield(state)
            
            // Start background sync simulation
            syncTask = _Concurrency.Task { [weak self] in
                await self?.performSync()
            }
            
        case .cancelSync:
            syncTask?.cancel()
            syncTask = nil
            
            state = addLogAndUpdateState(
                isSyncing: false,
                progress: 0.0,
                lastSyncDate: state.lastSyncDate,
                pendingChanges: state.pendingChanges,
                conflicts: state.conflicts,
                isOffline: state.isOffline,
                currentStatus: "Sync cancelled",
                logLevel: .warning,
                logMessage: "Sync cancelled by user"
            )
            stateStreamContinuation.yield(state)
            
        case .resolveConflict(let conflictId, let resolution):
            // Remove the resolved conflict
            var updatedConflicts = state.conflicts
            updatedConflicts.removeAll { $0.id == conflictId }
            
            state = addLogAndUpdateState(
                isSyncing: state.isSyncing,
                progress: state.progress,
                lastSyncDate: state.lastSyncDate,
                pendingChanges: state.pendingChanges,
                conflicts: updatedConflicts,
                isOffline: state.isOffline,
                currentStatus: "Conflict resolved",
                logLevel: .info,
                logMessage: "Resolved conflict: \(conflictId)"
            )
            stateStreamContinuation.yield(state)
            
        case .retryFailedSync:
            // Reset failed state and restart sync
            try await process(.startSync)
            
        case .setOfflineMode(let isOffline):
            // GREEN phase: Proper offline mode implementation
            if isOffline {
                // Cancel any ongoing sync when going offline
                syncTask?.cancel()
                syncTask = nil
            }
            
            state = addLogAndUpdateState(
                isSyncing: isOffline ? false : state.isSyncing,
                progress: isOffline ? 0.0 : state.progress,
                lastSyncDate: state.lastSyncDate,
                pendingChanges: state.pendingChanges,
                conflicts: state.conflicts,
                isOffline: isOffline,
                currentStatus: isOffline ? "Offline" : "Online",
                logLevel: isOffline ? .warning : .info,
                logMessage: isOffline ? "Went offline - sync disabled" : "Back online - sync enabled"
            )
            stateStreamContinuation.yield(state)
            
        case .manualSync(let force):
            // GREEN phase: Manual sync implementation
            guard !state.isOffline else { throw SyncError.offlineMode }
            
            if state.isSyncing && !force {
                throw SyncError.syncInProgress
            }
            
            // Cancel existing sync if force is true
            if force {
                syncTask?.cancel()
                syncTask = nil
            }
            
            // Start manual sync (same as regular sync)
            try await process(.startSync)
        }
    }
    
    private func performSync() async {
        // Simulate sync progress updates
        let progressSteps = [0.1, 0.3, 0.5, 0.7, 0.9, 1.0]
        
        for progress in progressSteps {
            try? await _Concurrency.Task.sleep(nanoseconds: 200_000_000) // 200ms between updates (5Hz)
            
            // Check if cancelled
            if _Concurrency.Task.isCancelled { return }
            
            let isComplete = progress >= 1.0
            let currentStatus = isComplete ? "Sync completed" : "Syncing... \(Int(progress * 100))%"
            
            state = addLogAndUpdateState(
                isSyncing: !isComplete,
                progress: progress,
                lastSyncDate: isComplete ? Date() : state.lastSyncDate,
                pendingChanges: max(0, state.pendingChanges - Int(progress * 10)),
                conflicts: state.conflicts,
                isOffline: state.isOffline,
                currentStatus: currentStatus,
                logLevel: isComplete ? .info : .debug,
                logMessage: isComplete ? "Sync completed successfully" : "Sync progress: \(Int(progress * 100))%"
            )
            stateStreamContinuation.yield(state)
        }
        
        syncTask = nil
    }
    
    // REFACTOR: Helper method for consistent logging and state updates
    private func addLogAndUpdateState(
        isSyncing: Bool,
        progress: Double,
        lastSyncDate: Date?,
        pendingChanges: Int,
        conflicts: [SyncConflict],
        isOffline: Bool,
        currentStatus: String,
        logLevel: LogLevel,
        logMessage: String,
        logDetails: [String: String]? = nil
    ) -> SyncState {
        let logEntry = SyncLogEntry(
            level: logLevel,
            message: logMessage,
            details: logDetails
        )
        
        // Keep only the last maxLogEntries
        var updatedLogs = state.syncLogs
        updatedLogs.append(logEntry)
        if updatedLogs.count > maxLogEntries {
            updatedLogs.removeFirst(updatedLogs.count - maxLogEntries)
        }
        
        return SyncState(
            isSyncing: isSyncing,
            progress: progress,
            lastSyncDate: lastSyncDate,
            pendingChanges: pendingChanges,
            conflicts: conflicts,
            isOffline: isOffline,
            syncLogs: updatedLogs,
            currentStatus: currentStatus
        )
    }
    
    // MARK: - Capability Management
    
    func setNetworkCapability(_ capability: NetworkCapability) {
        self.networkCapability = capability
    }
    
    func setStorageCapability(_ capability: StorageCapability) {
        self.storageCapability = capability
    }
}