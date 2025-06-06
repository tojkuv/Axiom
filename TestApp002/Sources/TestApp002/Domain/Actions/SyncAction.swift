import Foundation

enum SyncAction {
    case startSync
    case cancelSync
    case resolveConflict(conflictId: String, resolution: ConflictResolution)
    case retryFailedSync
}

enum ConflictResolution {
    case useLocal
    case useRemote
    case merge
}