import Foundation

enum SyncAction {
    case startSync
    case cancelSync
    case resolveConflict(conflictId: String, resolution: ConflictResolution)
    case retryFailedSync
    case setOfflineMode(Bool)
    case manualSync(force: Bool)
}

enum ConflictResolution {
    case useLocal
    case useRemote
    case merge
}