import Foundation
import SwiftUI

/// Default implementation of NavigationService using NavigationCoordinator
@MainActor
final class DefaultNavigationService: NavigationService, ObservableObject {
    static let shared = DefaultNavigationService()
    
    private let coordinator = NavigationCoordinator<TaskRoute>()
    
    func navigate(to route: TaskRoute) {
        switch route {
        case .list:
            // Pop to root
            coordinator.popToRoot()
        case .createTask:
            coordinator.present(route)
        case .editTask, .taskDetail:
            coordinator.push(route)
        case .search, .filteredList:
            coordinator.push(route)
        }
    }
    
    func dismiss() {
        coordinator.dismiss()
    }
    
    // Binding for sheet presentation
    var createTaskBinding: Binding<Bool> {
        Binding(
            get: { self.coordinator.presentedSheet == .createTask },
            set: { _ in self.coordinator.dismiss() }
        )
    }
    
    // Get the presented sheet for view building
    var presentedSheet: TaskRoute? {
        coordinator.presentedSheet
    }
}