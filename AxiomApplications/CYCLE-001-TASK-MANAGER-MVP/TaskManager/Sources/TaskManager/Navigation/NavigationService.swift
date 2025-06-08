import Foundation

/// Protocol for navigation services in the task manager
@MainActor
protocol NavigationService: AnyObject {
    func navigate(to route: TaskRoute)
    func dismiss()
}