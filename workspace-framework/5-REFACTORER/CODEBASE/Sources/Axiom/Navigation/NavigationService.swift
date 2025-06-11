import Foundation
import SwiftUI

// MARK: - Modular Navigation Service (Temporary stub for build compatibility)

/// Temporary stub for ModularNavigationService to ensure build compatibility
@MainActor
public final class ModularNavigationService: ObservableObject {
    @Published public var currentRoute: String = "/"
    @Published public var navigationStack: [String] = []
    
    public init() {}
    
    public func navigate(to route: String) async -> Result<Void, AxiomError> {
        currentRoute = route
        navigationStack.append(route)
        return .success(())
    }
    
    public func navigateBack() async -> Result<Void, AxiomError> {
        if !navigationStack.isEmpty {
            navigationStack.removeLast()
            currentRoute = navigationStack.last ?? "/"
        }
        return .success(())
    }
    
    public func navigateToRoot() async -> Result<Void, AxiomError> {
        navigationStack.removeAll()
        currentRoute = "/"
        return .success(())
    }
    
    public func dismiss() async -> Result<Void, AxiomError> {
        return await navigateBack()
    }
}