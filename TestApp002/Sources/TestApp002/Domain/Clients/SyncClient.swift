import Foundation
import Axiom

// GREEN Phase: SyncClient implementation to pass tests
actor SyncClient: Client {
    typealias StateType = SyncState
    typealias ActionType = SyncAction
    
    private var state: SyncState
    private let stateStreamContinuation: AsyncStream<SyncState>.Continuation
    private let _stateStream: AsyncStream<SyncState>
    private var syncTask: _Concurrency.Task<Void, Error>?
    
    var stateStream: AsyncStream<SyncState> {
        _stateStream
    }
    
    init() {
        self.state = SyncState()
        
        // Create state stream
        (_stateStream, stateStreamContinuation) = AsyncStream<SyncState>.makeStream()
        
        // Emit initial state
        stateStreamContinuation.yield(state)
    }
    
    func process(_ action: SyncAction) async throws {
        switch action {
        case .startSync:
            guard !state.isSyncing else { return }
            
            state = SyncState(
                isSyncing: true,
                progress: 0.0,
                lastSyncDate: state.lastSyncDate,
                pendingChanges: state.pendingChanges,
                conflicts: state.conflicts
            )
            stateStreamContinuation.yield(state)
            
            // Start background sync simulation
            syncTask = _Concurrency.Task { [weak self] in
                await self?.performSync()
            }
            
        case .cancelSync:
            syncTask?.cancel()
            syncTask = nil
            
            state = SyncState(
                isSyncing: false,
                progress: 0.0,
                lastSyncDate: state.lastSyncDate,
                pendingChanges: state.pendingChanges,
                conflicts: state.conflicts
            )
            stateStreamContinuation.yield(state)
            
        case .resolveConflict(let conflictId, let resolution):
            // Remove the resolved conflict
            var updatedConflicts = state.conflicts
            updatedConflicts.removeAll { $0.id == conflictId }
            
            state = SyncState(
                isSyncing: state.isSyncing,
                progress: state.progress,
                lastSyncDate: state.lastSyncDate,
                pendingChanges: state.pendingChanges,
                conflicts: updatedConflicts
            )
            stateStreamContinuation.yield(state)
            
        case .retryFailedSync:
            // Reset failed state and restart sync
            try await process(.startSync)
        }
    }
    
    private func performSync() async {
        // Simulate sync progress updates
        let progressSteps = [0.1, 0.3, 0.5, 0.7, 0.9, 1.0]
        
        for progress in progressSteps {
            try? await _Concurrency.Task.sleep(nanoseconds: 50_000_000) // 50ms between updates
            
            // Check if cancelled
            if _Concurrency.Task.isCancelled { return }
            
            state = SyncState(
                isSyncing: progress < 1.0,
                progress: progress,
                lastSyncDate: progress >= 1.0 ? Date() : state.lastSyncDate,
                pendingChanges: max(0, state.pendingChanges - Int(progress * 10)),
                conflicts: state.conflicts
            )
            stateStreamContinuation.yield(state)
        }
        
        syncTask = nil
    }
}