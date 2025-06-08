import Foundation

// MARK: - Legacy Task Model (V1)

struct TaskV1: Codable, Equatable {
    let id: UUID
    let title: String
    let isCompleted: Bool
}