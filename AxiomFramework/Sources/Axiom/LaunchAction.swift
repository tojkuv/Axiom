import SwiftUI
import Combine

// MARK: - Quick Action Protocol

public protocol QuickAction: Equatable, Sendable {
    /// Unique identifier for the action
    var identifier: String { get }
    
    /// Convert to navigation route  
    func toRoute() -> Route?
}

// MARK: - Launch Action Property Wrapper

@propertyWrapper
@MainActor
public struct LaunchAction<ActionType> {
    private let storage = LaunchActionStorage<ActionType>()
    
    public init() {}
    
    public var wrappedValue: ActionType? {
        get { storage.currentAction }
        set { storage.queueAction(newValue) }
    }
    
    public var projectedValue: LaunchActionStorage<ActionType> {
        storage
    }
}

// MARK: - Launch Action Storage

@MainActor
public final class LaunchActionStorage<ActionType>: ObservableObject {
    @Published public private(set) var currentAction: ActionType?
    private var queuedActions: [ActionType] = []
    private var isReady = false
    
    public init() {}
    
    /// Queue an action for processing
    public func queueAction(_ action: ActionType?) {
        guard let action = action else { return }
        
        if isReady {
            currentAction = action
        } else {
            queuedActions.append(action)
        }
    }
    
    /// Mark the app as ready to process actions
    public func markReady() {
        isReady = true
        processQueuedActions()
    }
    
    /// Process all queued actions
    private func processQueuedActions() {
        guard !queuedActions.isEmpty else { return }
        
        // Process first action immediately
        if let firstAction = queuedActions.first {
            currentAction = firstAction
        }
        
        // Schedule remaining actions
        for (index, action) in queuedActions.dropFirst().enumerated() {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(100 * (index + 1)))
                self.currentAction = action
            }
        }
        
        queuedActions.removeAll()
    }
    
    /// Clear the current action
    public func clearAction() {
        currentAction = nil
    }
}

// MARK: - SwiftUI Integration

public extension View {
    /// Handle launch actions when the view appears
    func handleLaunchAction<ActionType: Equatable>(
        _ action: ActionType?,
        perform: @escaping (ActionType) async -> Void
    ) -> some View {
        self.task(id: action) {
            guard let action = action else { return }
            await perform(action)
        }
    }
    
    /// Mark the app as ready for launch actions
    func onLaunchReady<ActionType>(
        _ storage: LaunchActionStorage<ActionType>
    ) -> some View {
        self.onAppear {
            storage.markReady()
        }
    }
}

// MARK: - Common Quick Action Types

public enum CommonQuickAction: String, QuickAction, CaseIterable {
    case create = "com.app.create"
    case search = "com.app.search"
    case recent = "com.app.recent"
    
    public var identifier: String { rawValue }
    
    public func toRoute() -> Route? {
        // Override in app-specific extensions
        nil
    }
}

// MARK: - URL Launch Action Support

public struct URLLaunchAction: QuickAction {
    public let url: URL
    public let identifier: String = "com.app.url"
    
    public init(url: URL) {
        self.url = url
    }
    
    public func toRoute() -> Route? {
        // TODO: Use existing URLToRouteParser when available
        nil
    }
}

// MARK: - Platform Integration

#if canImport(UIKit)
import UIKit

public extension UIApplicationDelegate {
    /// Process shortcut item as launch action
    @MainActor
    func processShortcutItem(
        _ shortcutItem: UIApplicationShortcutItem,
        with storage: LaunchActionStorage<CommonQuickAction>
    ) {
        // Convert shortcut to quick action
        if let action = CommonQuickAction(rawValue: shortcutItem.type) {
            storage.queueAction(action)
        }
    }
}
#endif

#if canImport(AppKit)
import AppKit

public extension NSApplicationDelegate {
    /// Process dock menu item as launch action
    @MainActor
    func processDockMenuItem(
        _ identifier: String,
        with storage: LaunchActionStorage<CommonQuickAction>
    ) {
        // Convert identifier to quick action
        if let action = CommonQuickAction(rawValue: identifier) {
            storage.queueAction(action)
        }
    }
}
#endif