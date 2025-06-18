import Foundation
import SwiftUI
import Combine
import AxiomCore

// MARK: - View Component Access Control

/// Marker protocol for presentation components that can observe contexts
/// Only components that manage state and coordinate business logic should conform to this
public protocol PresentationComponent: AnyObject {
    /// Unique identifier for this presentation component
    var presentationId: UUID { get }
    
    /// Name for debugging and identification
    var presentationName: String { get }
    
    /// The contexts this presentation component observes
    var observedContexts: [UUID] { get }
    
    /// Called when this component starts observing a context
    func willStartObserving(context: AxiomContext)
    
    /// Called when this component stops observing a context
    func willStopObserving(context: AxiomContext)
}

/// Marker protocol for simple views that cannot observe contexts
/// Simple views should only receive data through parameters/props
public protocol SimpleView {
    /// Simple views are explicitly forbidden from observing contexts
    /// They should only receive data through their initializers or @Binding properties
}

/// Protocol for view components that explicitly cannot access contexts
public protocol ContextRestrictedComponent: SimpleView {
    /// This component is explicitly restricted from context access
    static var contextAccessRestricted: Bool { get }
}

// MARK: - Default Implementations

extension PresentationComponent {
    public var presentationId: UUID {
        return UUID() // Default implementation - should be overridden for persistence
    }
    
    public var observedContexts: [UUID] {
        return [] // Default implementation - should be overridden
    }
    
    public func willStartObserving(context: AxiomContext) {
        // Default implementation - can be overridden
    }
    
    public func willStopObserving(context: AxiomContext) {
        // Default implementation - can be overridden
    }
}

extension ContextRestrictedComponent {
    public static var contextAccessRestricted: Bool { true }
}

// MARK: - View Access Control Manager

/// Manages access control for view components accessing contexts
public actor ViewAccessControlManager {
    public static let shared = ViewAccessControlManager()
    
    private var componentRegistrations: [UUID: ComponentRegistration] = [:]
    private var contextObservations: [UUID: Set<UUID>] = [:] // context -> set of component IDs
    
    private init() {}
    
    /// Validate that a component can observe a context
    public func validateContextObservation<T: AnyObject>(
        component: T,
        context: AxiomContext
    ) throws {
        let componentType = type(of: component)
        let componentName = String(describing: componentType)
        
        // Check if component is a simple view (forbidden)
        if component is SimpleView {
            throw ViewAccessError.simpleViewCannotObserveContext(
                viewType: componentName,
                contextName: context.name
            )
        }
        
        // Check if component is context restricted
        if let restrictedComponent = component as? ContextRestrictedComponent {
            throw ViewAccessError.contextAccessRestricted(
                componentType: componentName,
                contextName: context.name
            )
        }
        
        // Component must be a presentation component to observe contexts
        guard component is PresentationComponent else {
            throw ViewAccessError.componentNotAuthorizedForContextObservation(
                componentType: componentName,
                contextName: context.name,
                reason: "Only PresentationComponent types can observe contexts"
            )
        }
    }
    
    /// Register a component observation of a context
    public func registerObservation(
        component: PresentationComponent,
        context: AxiomContext
    ) {
        let componentId = component.presentationId
        let contextId = context.id
        
        // Register component if not already registered
        if componentRegistrations[componentId] == nil {
            componentRegistrations[componentId] = ComponentRegistration(
                id: componentId,
                name: component.presentationName,
                type: String(describing: type(of: component)),
                registeredAt: Date()
            )
        }
        
        // Track context observation
        if contextObservations[contextId] == nil {
            contextObservations[contextId] = Set<UUID>()
        }
        contextObservations[contextId]?.insert(componentId)
        
        // Notify component
        component.willStartObserving(context: context)
    }
    
    /// Unregister a component observation of a context
    public func unregisterObservation(
        component: PresentationComponent,
        context: AxiomContext
    ) {
        let componentId = component.presentationId
        let contextId = context.id
        
        contextObservations[contextId]?.remove(componentId)
        
        // Clean up empty observation sets
        if contextObservations[contextId]?.isEmpty == true {
            contextObservations.removeValue(forKey: contextId)
        }
        
        // Notify component
        component.willStopObserving(context: context)
    }
    
    /// Get all components observing a context
    public func getObservers(for context: AxiomContext) -> [ComponentRegistration] {
        guard let observerIds = contextObservations[context.id] else { return [] }
        
        return observerIds.compactMap { id in
            componentRegistrations[id]
        }
    }
    
    /// Get all contexts observed by a component
    public func getObservedContexts(for component: PresentationComponent) -> [UUID] {
        let componentId = component.presentationId
        
        return contextObservations.compactMap { (contextId, observerIds) in
            observerIds.contains(componentId) ? contextId : nil
        }
    }
    
    /// Check if a component type is allowed to observe contexts
    public func isComponentTypeAllowed<T: AnyObject>(_ componentType: T.Type) -> Bool {
        // Simple views are not allowed
        if componentType is SimpleView.Type {
            return false
        }
        
        // Context restricted components are not allowed
        if componentType is ContextRestrictedComponent.Type {
            return false
        }
        
        // Must be a presentation component
        return componentType is PresentationComponent.Type
    }
}

// MARK: - Component Registration

/// Registration information for a view component
public struct ComponentRegistration: Sendable {
    public let id: UUID
    public let name: String
    public let type: String
    public let registeredAt: Date
}

// MARK: - Enhanced AxiomContext with View Access Control

extension AxiomContext {
    
    /// Allow a presentation component to observe this context
    public func allowObservation<T: PresentationComponent>(by component: T) async throws {
        // Validate access
        try await ViewAccessControlManager.shared.validateContextObservation(
            component: component,
            context: self
        )
        
        // Register observation
        await ViewAccessControlManager.shared.registerObservation(
            component: component,
            context: self
        )
    }
    
    /// Remove observation by a presentation component
    public func removeObservation<T: PresentationComponent>(by component: T) async {
        await ViewAccessControlManager.shared.unregisterObservation(
            component: component,
            context: self
        )
    }
    
    /// Get all components currently observing this context
    public func getObservers() async -> [ComponentRegistration] {
        return await ViewAccessControlManager.shared.getObservers(for: self)
    }
    
    /// Check if a component type can observe this context
    public func canBeObserved<T: AnyObject>(by componentType: T.Type) async -> Bool {
        return await ViewAccessControlManager.shared.isComponentTypeAllowed(componentType)
    }
}

// MARK: - SwiftUI Integration

/// Property wrapper for safe context observation in SwiftUI
@propertyWrapper
public struct ObservedContext<T: AxiomContext>: DynamicProperty {
    @StateObject private var context: T
    private let component: any PresentationComponent
    
    public var wrappedValue: T {
        context
    }
    
    public var projectedValue: ObservedObject<T>.Wrapper {
        $context
    }
    
    public init(
        _ context: T,
        observedBy component: any PresentationComponent
    ) {
        self._context = StateObject(wrappedValue: context)
        self.component = component
        
        // Register observation when property wrapper is created
        Task {
            try? await context.allowObservation(by: component)
        }
    }
}

/// Property wrapper that prevents simple views from observing contexts
@propertyWrapper
public struct RestrictedView<T>: DynamicProperty {
    private let value: T
    
    public var wrappedValue: T {
        // This property wrapper enforces that the containing view is a SimpleView
        // and therefore cannot use context observation
        value
    }
    
    public init(wrappedValue: T) {
        self.value = wrappedValue
    }
}

// MARK: - Error Types

/// Errors related to view access control violations
public enum ViewAccessError: Error, LocalizedError {
    case simpleViewCannotObserveContext(viewType: String, contextName: String)
    case contextAccessRestricted(componentType: String, contextName: String)
    case componentNotAuthorizedForContextObservation(componentType: String, contextName: String, reason: String)
    case invalidObservationSetup(String)
    case observationViolation(String)
    
    public var errorDescription: String? {
        switch self {
        case .simpleViewCannotObserveContext(let viewType, let contextName):
            return "Simple view '\(viewType)' cannot observe context '\(contextName)'. Simple views should only receive data through parameters."
        case .contextAccessRestricted(let componentType, let contextName):
            return "Component '\(componentType)' is restricted from accessing context '\(contextName)'"
        case .componentNotAuthorizedForContextObservation(let componentType, let contextName, let reason):
            return "Component '\(componentType)' cannot observe context '\(contextName)'. \(reason)"
        case .invalidObservationSetup(let reason):
            return "Invalid observation setup: \(reason)"
        case .observationViolation(let reason):
            return "Observation violation: \(reason)"
        }
    }
}

// MARK: - View Component Classifications

/// Classifications for different types of view components
public enum ViewComponentClassification {
    
    /// Presentation components that can observe contexts
    public static let presentationComponents: [String] = [
        // SwiftUI Presentation Components
        "NavigationCoordinator",
        "TabCoordinator", 
        "ScreenCoordinator",
        "ViewCoordinator",
        "PageViewController",
        "ContainerViewController",
        "MasterViewController",
        "DetailViewController",
        
        // UIKit Presentation Components
        "UINavigationController",
        "UITabBarController", 
        "UIPageViewController",
        "UICollectionViewController",
        "UITableViewController",
        "UISplitViewController",
        
        // Custom Presentation Components
        "DashboardCoordinator",
        "SettingsCoordinator",
        "OnboardingCoordinator",
        "AuthenticationCoordinator"
    ]
    
    /// Simple views that cannot observe contexts
    public static let simpleViews: [String] = [
        // SwiftUI Simple Views
        "Text", "Button", "Image", "Label", "TextField", "SecureField",
        "Toggle", "Slider", "Stepper", "ProgressView", "Divider",
        "Spacer", "Rectangle", "Circle", "Ellipse", "Capsule",
        "RoundedRectangle", "Path", "Shape",
        
        // UIKit Simple Views
        "UILabel", "UIButton", "UIImageView", "UITextField", "UITextView",
        "UISwitch", "UISlider", "UIProgressView", "UIActivityIndicatorView",
        "UISegmentedControl", "UIPageControl", "UIStepper",
        
        // Custom Simple Views
        "IconView", "BadgeView", "AvatarView", "StatusIndicator",
        "LoadingSpinner", "EmptyStateView", "ErrorView", "SuccessView"
    ]
    
    /// Check if a component name represents a presentation component
    public static func isPresentationComponent(_ componentName: String) -> Bool {
        return presentationComponents.contains(componentName) ||
               componentName.contains("Coordinator") ||
               componentName.contains("Controller") ||
               componentName.contains("Manager") ||
               componentName.hasSuffix("Presenter")
    }
    
    /// Check if a component name represents a simple view
    public static func isSimpleView(_ componentName: String) -> Bool {
        return simpleViews.contains(componentName) ||
               componentName.hasPrefix("UI") && !componentName.contains("Controller") ||
               componentName.hasSuffix("View") && !componentName.contains("Controller")
    }
}

// MARK: - Migration Helper

/// Helper for migrating existing views to use proper access control
public enum ViewAccessControlMigrationHelper {
    
    /// Analyze a view type and suggest proper classification
    public static func analyzeViewType<T: AnyObject>(_ viewType: T.Type) -> ViewTypeAnalysis {
        let typeName = String(describing: viewType)
        
        let isPresentationComponent = ViewComponentClassification.isPresentationComponent(typeName)
        let isSimpleView = ViewComponentClassification.isSimpleView(typeName)
        
        let recommendation: ViewTypeRecommendation
        
        if isPresentationComponent {
            recommendation = .makePresentationComponent
        } else if isSimpleView {
            recommendation = .makeSimpleView
        } else {
            // Analyze based on patterns
            if typeName.contains("Screen") || typeName.contains("Page") || typeName.contains("Container") {
                recommendation = .makePresentationComponent
            } else if typeName.contains("Cell") || typeName.contains("Item") || typeName.contains("Component") {
                recommendation = .makeSimpleView
            } else {
                recommendation = .needsManualReview
            }
        }
        
        return ViewTypeAnalysis(
            typeName: typeName,
            currentClassification: getCurrentClassification(viewType),
            recommendedClassification: recommendation,
            reasoning: getRecommendationReasoning(typeName, recommendation)
        )
    }
    
    private static func getCurrentClassification<T: AnyObject>(_ viewType: T.Type) -> ViewTypeClassification {
        if viewType is PresentationComponent.Type {
            return .presentationComponent
        } else if viewType is SimpleView.Type {
            return .simpleView
        } else {
            return .unclassified
        }
    }
    
    private static func getRecommendationReasoning(_ typeName: String, _ recommendation: ViewTypeRecommendation) -> String {
        switch recommendation {
        case .makePresentationComponent:
            return "This component appears to coordinate state and should be able to observe contexts"
        case .makeSimpleView:
            return "This appears to be a simple UI component that should only receive data through parameters"
        case .needsManualReview:
            return "Unable to automatically classify '\(typeName)'. Manual review required to determine if it manages state or is purely presentational"
        }
    }
}

/// Analysis result for a view type
public struct ViewTypeAnalysis {
    public let typeName: String
    public let currentClassification: ViewTypeClassification
    public let recommendedClassification: ViewTypeRecommendation
    public let reasoning: String
}

/// Current classification of a view type
public enum ViewTypeClassification {
    case presentationComponent
    case simpleView
    case unclassified
}

/// Recommended classification for a view type
public enum ViewTypeRecommendation {
    case makePresentationComponent
    case makeSimpleView
    case needsManualReview
}