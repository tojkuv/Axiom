import Foundation

/// Simple filter for quick action routes
enum TaskRouteFilter: Hashable {
    case priority(Priority)
    case category(UUID)
    case completed
    case overdue
}