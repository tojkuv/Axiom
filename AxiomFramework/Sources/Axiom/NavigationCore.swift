import Foundation
import SwiftUI

// MARK: - NavigationCore

/// Core navigation functionality handling basic navigation operations
/// Extracted from NavigationService to focus on stack management and route navigation
@MainActor
public final class NavigationCore: ObservableObject {
    
    // MARK: - Core State
    
    /// Current navigation route
    @Published public internal(set) var currentRoute: Route?
    
    /// Navigation history stack
    @Published public internal(set) var navigationHistory: [Route] = []
    
    /// Active navigation pattern
    public private(set) var currentPattern: NavigationPattern = .push
    
    /// Cancellation tokens for active navigations
    internal var cancellationTokens: Set<NavigationCancellationToken> = []
    
    public init() {}
    
    // MARK: - Core Navigation Operations
    
    /// Navigate to any routable destination
    public func navigate<T: Routable>(to route: T) async -> Result<Void, AxiomError> {
        return await withErrorContext("NavigationCore.navigate") {
            let token = NavigationCancellationToken()
            cancellationTokens.insert(token)
            
            defer { cancellationTokens.remove(token) }
            
            guard !token.isCancelled else {
                throw AxiomError.navigationError(.navigationBlocked("Navigation was cancelled"))
            }
            
            // Add current route to history if different
            if let current = currentRoute, current != route as? Route {
                navigationHistory.append(current)
            }
            
            // Update current route
            currentRoute = route as? Route
            
            // Execute navigation based on presentation style
            try await executeNavigation(route: route, token: token)
            
            return ()
        }
    }
    
    /// Navigate to route with options
    public func navigate(to route: Route, options: NavigationOptions = .default) async -> NavigationResult {
        return await withErrorContext("NavigationCore.navigate") {
            // Add to history
            if let current = currentRoute, current != route {
                navigationHistory.append(current)
            }
            
            currentRoute = route
            
            return .success
        }.mapToNavigationResult()
    }
    
    /// Navigate back in history
    public func navigateBack() async -> NavigationResult {
        return await withErrorContext("NavigationCore.navigateBack") {
            guard !navigationHistory.isEmpty else {
                throw AxiomError.navigationError(.stackError("No previous route to navigate back to"))
            }
            
            let previousRoute = navigationHistory.removeLast()
            currentRoute = previousRoute
            
            return .success
        }.mapToNavigationResult()
    }
    
    /// Pop to root of navigation stack
    public func navigateToRoot() async -> NavigationResult {
        return await withErrorContext("NavigationCore.navigateToRoot") {
            guard !navigationHistory.isEmpty else {
                return .success
            }
            
            navigationHistory.removeAll()
            currentRoute = nil
            
            return .success
        }.mapToNavigationResult()
    }
    
    /// Dismiss current presentation
    public func dismiss() async -> NavigationResult {
        return await navigateBack()
    }
    
    // MARK: - Navigation State
    
    /// Get current navigation depth
    public var navigationDepth: Int {
        return navigationHistory.count
    }
    
    /// Check if can navigate back
    public var canNavigateBack: Bool {
        return !navigationHistory.isEmpty
    }
    
    /// Set navigation pattern
    public func setPattern(_ pattern: NavigationPattern) {
        currentPattern = pattern
    }
    
    // MARK: - Cancellation
    
    /// Cancel all active navigations
    public func cancelAllNavigations() {
        for token in cancellationTokens {
            token.cancel()
        }
        cancellationTokens.removeAll()
    }
    
    /// Create navigation cancellation token
    public func createCancellationToken() -> NavigationCancellationToken {
        let token = NavigationCancellationToken()
        cancellationTokens.insert(token)
        return token
    }
    
    // MARK: - Private Implementation
    
    private func executeNavigation<T: Routable>(route: T, token: NavigationCancellationToken) async throws {
        guard !token.isCancelled else {
            throw AxiomError.navigationError(.navigationBlocked("Navigation cancelled"))
        }
        
        // Execute based on presentation style
        switch route.presentation {
        case .push:
            // Handle push navigation
            break
        case .present(_):
            // Handle modal presentation
            break
        case .replace:
            // Handle replacement navigation
            break
        }
    }
}