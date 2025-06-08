import Foundation

// MARK: - Persistence Error

enum PersistenceError: Error, Equatable {
    case writeFailed
    case readFailed
    case dataCorrupted
    case migrationFailed
}