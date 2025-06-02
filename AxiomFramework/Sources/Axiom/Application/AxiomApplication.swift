import Foundation
import SwiftUI

// MARK: - AxiomApplication Protocol

/// The core protocol for Axiom applications that provides global configuration and lifecycle management
@MainActor
public protocol AxiomApplication: ObservableObject {
    associatedtype AppConfiguration: AxiomApplicationConfiguration
    associatedtype RootContext: AxiomContext
    
    /// The application configuration
    var configuration: AppConfiguration { get }
    
    /// The capability manager for the entire application
    var capabilityManager: CapabilityManager { get }
    
    /// The intelligence system for the application
    var intelligence: AxiomIntelligence { get }
    
    /// The root context factory
    var contextFactory: ContextFactory { get }
    
    // MARK: Lifecycle
    
    /// Called when the application launches
    func onLaunch() async throws
    
    /// Called when the application enters the background
    func onBackground() async
    
    /// Called when the application enters the foreground
    func onForeground() async
    
    /// Called when the application is about to terminate
    func onTerminate() async
    
    // MARK: Context Management
    
    /// Creates the root context for the application
    func createRootContext() async throws -> RootContext
    
    /// Manages context lifecycle and dependencies
    func manageContext<T: AxiomContext>(_ context: T) async
}

// MARK: - AxiomApplicationConfiguration Protocol

/// Configuration protocol for Axiom applications
public protocol AxiomApplicationConfiguration: Sendable {
    /// The available capabilities for the application
    var availableCapabilities: Set<Capability> { get }
    
    /// The enabled intelligence features
    var intelligenceFeatures: Set<IntelligenceFeature> { get }
    
    /// The capability validation configuration
    var capabilityValidationConfig: CapabilityValidationConfig { get }
    
    /// Performance monitoring configuration
    var performanceConfig: PerformanceConfiguration { get }
    
    /// Development environment configuration
    var developmentConfig: DevelopmentConfiguration { get }
}

// MARK: - DevelopmentConfiguration

/// Configuration for development environment features
public struct DevelopmentConfiguration: Sendable {
    public let enableDebugLogging: Bool
    public let enablePerformanceLogging: Bool
    public let enableIntelligenceDebugging: Bool
    public let enableArchitecturalValidation: Bool
    public let enableConstraintChecking: Bool
    
    public init(
        enableDebugLogging: Bool = false,
        enablePerformanceLogging: Bool = false,
        enableIntelligenceDebugging: Bool = false,
        enableArchitecturalValidation: Bool = true,
        enableConstraintChecking: Bool = true
    ) {
        self.enableDebugLogging = enableDebugLogging
        self.enablePerformanceLogging = enablePerformanceLogging
        self.enableIntelligenceDebugging = enableIntelligenceDebugging
        self.enableArchitecturalValidation = enableArchitecturalValidation
        self.enableConstraintChecking = enableConstraintChecking
    }
    
    /// Production configuration with minimal debugging
    public static var production: DevelopmentConfiguration {
        DevelopmentConfiguration(
            enableDebugLogging: false,
            enablePerformanceLogging: false,
            enableIntelligenceDebugging: false,
            enableArchitecturalValidation: true,
            enableConstraintChecking: true
        )
    }
    
    /// Development configuration with full debugging
    public static var development: DevelopmentConfiguration {
        DevelopmentConfiguration(
            enableDebugLogging: true,
            enablePerformanceLogging: true,
            enableIntelligenceDebugging: true,
            enableArchitecturalValidation: true,
            enableConstraintChecking: true
        )
    }
    
    /// Default configuration for general use
    public static var `default`: DevelopmentConfiguration {
        development
    }
}

// MARK: - Default Application Configuration

/// Default implementation of AxiomApplicationConfiguration
public struct DefaultAxiomApplicationConfiguration: AxiomApplicationConfiguration {
    public let availableCapabilities: Set<Capability>
    public let intelligenceFeatures: Set<IntelligenceFeature>
    public let capabilityValidationConfig: CapabilityValidationConfig
    public let performanceConfig: PerformanceConfiguration
    public let developmentConfig: DevelopmentConfiguration
    
    public init(
        availableCapabilities: Set<Capability> = Set(Capability.allCases),
        intelligenceFeatures: Set<IntelligenceFeature> = [.componentRegistry, .performanceMonitoring],
        capabilityValidationConfig: CapabilityValidationConfig = .default,
        performanceConfig: PerformanceConfiguration = PerformanceConfiguration(),
        developmentConfig: DevelopmentConfiguration = .default
    ) {
        self.availableCapabilities = availableCapabilities
        self.intelligenceFeatures = intelligenceFeatures
        self.capabilityValidationConfig = capabilityValidationConfig
        self.performanceConfig = performanceConfig
        self.developmentConfig = developmentConfig
    }
    
    /// Standard production configuration
    public static var production: DefaultAxiomApplicationConfiguration {
        DefaultAxiomApplicationConfiguration(
            intelligenceFeatures: [.componentRegistry, .performanceMonitoring, .capabilityValidation],
            performanceConfig: PerformanceConfiguration(samplingRate: 0.1, enableAlerts: true),
            developmentConfig: .production
        )
    }
    
    /// Development configuration with enhanced debugging
    public static var development: DefaultAxiomApplicationConfiguration {
        DefaultAxiomApplicationConfiguration(
            intelligenceFeatures: Set(IntelligenceFeature.allCases),
            performanceConfig: PerformanceConfiguration(),
            developmentConfig: .development
        )
    }
}

// MARK: - ContextFactory Protocol

/// Factory for creating and configuring contexts with proper dependency injection
public protocol ContextFactory: Sendable {
    /// Creates a context with automatic dependency injection
    func createContext<T: AxiomContext>(
        _ contextType: T.Type,
        capabilityManager: CapabilityManager,
        intelligence: AxiomIntelligence
    ) async throws -> T
    
    /// Configures a context with cross-cutting concerns
    func configureContext<T: AxiomContext>(_ context: T) async throws
    
    /// Validates context dependencies and relationships
    func validateContextDependencies<T: AxiomContext>(_ context: T) async throws
}

// MARK: - Supporting Infrastructure

/// Simple client registry for dependency management
public actor ClientRegistry {
    private var registeredClients: [String: any AxiomClient] = [:]
    
    public init() {}
    
    public func register<T: AxiomClient>(_ client: T, forType type: T.Type) {
        registeredClients[String(describing: type)] = client
    }
    
    public func resolve<T: AxiomClient>(_ type: T.Type) -> T? {
        return registeredClients[String(describing: type)] as? T
    }
}

/// Simple dependency resolver for contexts
public actor DependencyResolver {
    public init() {}
    
    public func resolveClients<T: ClientDependencies>(
        for clientsType: T.Type,
        capabilityManager: CapabilityManager
    ) async throws -> T {
        // For now, return a basic instance - this would be enhanced with actual DI
        return T()
    }
}

/// Application lifecycle management
public actor ApplicationLifecycleManager {
    private var backgroundCallback: (() async -> Void)?
    private var foregroundCallback: (() async -> Void)?
    private var terminateCallback: (() async -> Void)?
    
    public init() {}
    
    public func registerCallbacks(
        onBackground: @escaping () async -> Void,
        onForeground: @escaping () async -> Void,
        onTerminate: @escaping () async -> Void
    ) {
        self.backgroundCallback = onBackground
        self.foregroundCallback = onForeground
        self.terminateCallback = onTerminate
    }
}

// MARK: - Default ContextFactory

/// Default implementation of ContextFactory with automatic dependency resolution
public actor DefaultContextFactory: ContextFactory {
    private let clientRegistry: ClientRegistry
    private let dependencyResolver: DependencyResolver
    
    public init() {
        self.clientRegistry = ClientRegistry()
        self.dependencyResolver = DependencyResolver()
    }
    
    public func createContext<T: AxiomContext>(
        _ contextType: T.Type,
        capabilityManager: CapabilityManager,
        intelligence: AxiomIntelligence
    ) async throws -> T {
        // For this basic implementation, we'll create a simplified context
        // In a full implementation, this would do sophisticated dependency injection
        
        // Note: This is a simplified implementation for Task 3.9
        // Real context creation would involve complex dependency resolution
        throw AxiomApplicationError.dependencyResolutionFailed("Context creation requires macro-generated initializers")
    }
    
    public func configureContext<T: AxiomContext>(_ context: T) async throws {
        // Configure cross-cutting concerns would go here
        // For now, this is a placeholder
    }
    
    public func validateContextDependencies<T: AxiomContext>(_ context: T) async throws {
        // Dependency validation would go here
        // For now, this is a placeholder
    }
}

// MARK: - DefaultAxiomApplication

/// Default implementation of AxiomApplication
@MainActor
public class DefaultAxiomApplication<AppConfig: AxiomApplicationConfiguration, RootCtx: AxiomContext>: AxiomApplication {
    public typealias AppConfiguration = AppConfig
    public typealias RootContext = RootCtx
    
    @Published public private(set) var isLaunched: Bool = false
    @Published public private(set) var currentState: ApplicationState = .idle
    @Published public private(set) var lastError: (any AxiomError)?
    
    public let configuration: AppConfiguration
    public let capabilityManager: CapabilityManager
    public let intelligence: AxiomIntelligence
    public let contextFactory: ContextFactory
    
    private let lifecycleManager: ApplicationLifecycleManager
    private let performanceMonitor: PerformanceMonitor
    
    public init(
        configuration: AppConfiguration,
        contextFactory: ContextFactory = DefaultContextFactory()
    ) async {
        self.configuration = configuration
        self.contextFactory = contextFactory
        
        // Initialize capability manager with configuration
        self.capabilityManager = CapabilityManager(config: configuration.capabilityValidationConfig)
        await self.capabilityManager.configure(availableCapabilities: configuration.availableCapabilities)
        
        // Initialize intelligence system with configuration
        self.intelligence = await GlobalIntelligenceManager.shared.getIntelligence()
        
        // Initialize lifecycle and performance monitoring
        self.lifecycleManager = ApplicationLifecycleManager()
        self.performanceMonitor = PerformanceMonitor(configuration: configuration.performanceConfig)
    }
    
    // MARK: Lifecycle Management
    
    public func onLaunch() async throws {
        currentState = .launching
        
        do {
            // Initialize capability manager
            try await capabilityManager.initialize()
            
            // Initialize intelligence system
            try await GlobalIntelligenceManager.shared.initialize()
            
            // Initialize performance monitoring
            await performanceMonitor.start()
            
            // Register lifecycle callbacks
            await lifecycleManager.registerCallbacks(
                onBackground: { [weak self] in await self?.onBackground() },
                onForeground: { [weak self] in await self?.onForeground() },
                onTerminate: { [weak self] in await self?.onTerminate() }
            )
            
            isLaunched = true
            currentState = .running
            
            // Record successful launch for intelligence
            await GlobalIntelligenceManager.shared.recordApplicationEvent(ApplicationEvent(type: .stateAccess, metadata: ["event": "launched"]))
            
        } catch {
            currentState = .error
            lastError = error as? any AxiomError
            throw error
        }
    }
    
    public func onBackground() async {
        currentState = .backgrounded
        
        // Suspend non-critical operations
        await performanceMonitor.suspendNonCriticalMonitoring()
        
        // Save critical state
        await GlobalIntelligenceManager.shared.saveState()
        
        await GlobalIntelligenceManager.shared.recordApplicationEvent(ApplicationEvent(type: .stateUpdate, metadata: ["event": "backgrounded"]))
    }
    
    public func onForeground() async {
        currentState = .running
        
        // Resume operations
        await performanceMonitor.resumeFullMonitoring()
        
        // Refresh capabilities if needed
        await capabilityManager.refreshCapabilities()
        
        await GlobalIntelligenceManager.shared.recordApplicationEvent(ApplicationEvent(type: .stateUpdate, metadata: ["event": "foregrounded"]))
    }
    
    public func onTerminate() async {
        currentState = .terminating
        
        // Graceful shutdown sequence
        await GlobalIntelligenceManager.shared.saveState()
        await performanceMonitor.finalizeMetrics()
        await capabilityManager.shutdown()
        await GlobalIntelligenceManager.shared.shutdown()
        
        currentState = .terminated
    }
    
    // MARK: Context Management
    
    public func createRootContext() async throws -> RootContext {
        guard isLaunched else {
            throw AxiomApplicationError.applicationNotLaunched
        }
        
        let context = try await contextFactory.createContext(
            RootContext.self,
            capabilityManager: capabilityManager,
            intelligence: intelligence
        )
        
        await manageContext(context)
        
        return context
    }
    
    public func manageContext<T: AxiomContext>(_ context: T) async {
        // Register context with intelligence system
        await GlobalIntelligenceManager.shared.registerComponent(context)
        
        // Set up performance monitoring for context
        await performanceMonitor.monitorContext(context)
        
        // Configure automatic error handling
        await context.configureErrorHandling { [weak self] error in
            await self?.handleContextError(error, from: context)
        }
    }
    
    // MARK: Private Methods
    
    private func handleContextError<T: AxiomContext>(_ error: any AxiomError, from context: T) async {
        lastError = error
        
        // Report to intelligence system for learning
        await GlobalIntelligenceManager.shared.recordError(error, context: String(describing: T.self))
        
        // Attempt recovery if possible
        if !error.recoveryActions.isEmpty {
            // In a full implementation, we'd execute recovery actions
            // For now, just record that recovery was attempted
        }
    }
}

// MARK: - Supporting Types

/// Application lifecycle states
public enum ApplicationState: String, Sendable, CaseIterable {
    case idle
    case launching
    case running
    case backgrounded
    case terminating
    case terminated
    case error
}

// ApplicationEvent is defined in AxiomIntelligence.swift

/// Application-specific errors
public enum AxiomApplicationError: Error, AxiomError {
    case applicationNotLaunched
    case invalidViewContextBinding(contextType: String, viewType: String)
    case dependencyResolutionFailed(String)
    case configurationError(String)
    
    public var id: UUID {
        UUID()
    }
    
    public var category: ErrorCategory {
        switch self {
        case .applicationNotLaunched, .configurationError:
            return .configuration
        case .invalidViewContextBinding:
            return .architectural
        case .dependencyResolutionFailed:
            return .configuration
        }
    }
    
    public var severity: ErrorSeverity {
        switch self {
        case .applicationNotLaunched:
            return .error
        case .invalidViewContextBinding:
            return .fatal
        case .dependencyResolutionFailed:
            return .error
        case .configurationError:
            return .error
        }
    }
    
    public var context: ErrorContext {
        ErrorContext(
            component: ComponentID("AxiomApplication"),
            timestamp: Date(),
            additionalInfo: [:]
        )
    }
    
    public var recoveryActions: [RecoveryAction] {
        switch self {
        case .applicationNotLaunched:
            return []
        case .invalidViewContextBinding:
            return []
        case .dependencyResolutionFailed:
            return []
        case .configurationError:
            return []
        }
    }
    
    public var userMessage: String {
        switch self {
        case .applicationNotLaunched:
            return "The application is still starting up. Please wait a moment and try again."
        case .invalidViewContextBinding:
            return "There's a critical configuration issue. Please restart the application."
        case .dependencyResolutionFailed:
            return "A required component could not be loaded. Please restart the application."
        case .configurationError(let message):
            return "Configuration issue: \(message). Please check your settings."
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .applicationNotLaunched:
            return "Application must be launched before creating contexts"
        case .invalidViewContextBinding(let contextType, let viewType):
            return "Invalid view-context binding: \(viewType) does not match \(contextType)"
        case .dependencyResolutionFailed(let dependency):
            return "Failed to resolve dependency: \(dependency)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        }
    }
}

// MARK: - Extensions for Configuration Collections

extension Set where Element == Capability {
    public static var foundation: Set<Capability> {
        [.stateManagement, .businessLogic, .cache]
    }
    
    public static var standard: Set<Capability> {
        foundation.union([.network, .storage, .analytics])
    }
    
    public static var full: Set<Capability> {
        Set(Capability.allCases)
    }
}

extension Set where Element == IntelligenceFeature {
    public static var foundation: Set<IntelligenceFeature> {
        [.componentRegistry, .performanceMonitoring]
    }
    
    public static var production: Set<IntelligenceFeature> {
        foundation.union([.capabilityValidation])
    }
    
    public static var development: Set<IntelligenceFeature> {
        Set(IntelligenceFeature.allCases)
    }
}