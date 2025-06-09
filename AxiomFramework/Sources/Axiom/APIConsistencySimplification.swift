import Foundation

// MARK: - Simplified Context Builder

/// Simplified context builder with progressive disclosure and sensible defaults
public struct ContextBuilder<C: Context> {
    private let contextType: C.Type
    private var configuration = ContextConfiguration()
    
    /// Initialize builder with context type
    public init(_ contextType: C.Type) {
        self.contextType = contextType
        
        // Apply intelligent defaults based on context type
        if contextType is any MainActor.Type {
            configuration.performance = .ui
        }
    }
    
    /// Apply default configuration (covers 90% of use cases)
    public func withDefaults() -> Self {
        var builder = self
        builder.configuration = .recommended
        return builder
    }
    
    /// Configure persistence (progressive disclosure)
    public func persistence(_ config: PersistenceConfig) -> Self {
        var builder = self
        builder.configuration.persistence = config
        return builder
    }
    
    /// Configure performance (progressive disclosure)
    public func performance(_ config: PerformanceConfig) -> Self {
        var builder = self
        builder.configuration.performance = config
        return builder
    }
    
    /// Configure error handling (progressive disclosure)
    public func errorHandling(_ config: ErrorConfig) -> Self {
        var builder = self
        builder.configuration.errorHandling = config
        return builder
    }
    
    /// Build the context
    @MainActor
    public func build() async throws -> C {
        // Simplified context creation with configuration
        let context = await contextType.init()
        
        // Apply configuration
        await applyConfiguration(to: context)
        
        return context
    }
    
    @MainActor
    private func applyConfiguration(to context: C) async {
        // Apply error handling configuration
        await context.configureErrorRecovery(configuration.errorHandling.recoveryStrategy)
        
        // Additional configuration would be applied here
    }
}

// MARK: - Configuration Types

/// Context configuration with sensible defaults
public struct ContextConfiguration {
    public var persistence: PersistenceConfig = .default
    public var performance: PerformanceConfig = .default
    public var errorHandling: ErrorConfig = .default
    public var navigation: NavigationConfig = .default
    
    /// Recommended configuration for most use cases
    public static let recommended = ContextConfiguration()
    
    /// Testing configuration
    public static let testing = ContextConfiguration(
        persistence: .memory,
        performance: .testing,
        errorHandling: .strict
    )
    
    /// Production configuration
    public static let production = ContextConfiguration(
        persistence: .fileSystem,
        performance: .optimized,
        errorHandling: .userFriendly
    )
}

/// Persistence configuration options
public enum PersistenceConfig {
    case `default`    // UserDefaults for simple data
    case memory       // In-memory only (testing)
    case fileSystem   // File-based persistence
    case database     // Core Data or SQLite
    case cloud        // CloudKit integration
    
    var storageAdapter: any StorageAdapter {
        switch self {
        case .default, .memory:
            return InMemoryStorageAdapter()
        case .fileSystem:
            return FileSystemStorageAdapter()
        case .database:
            return DatabaseStorageAdapter()
        case .cloud:
            return CloudStorageAdapter()
        }
    }
}

/// Performance configuration options
public enum PerformanceConfig {
    case `default`    // Balanced performance
    case ui           // Optimized for UI responsiveness
    case background   // Optimized for background processing
    case optimized    // Maximum performance
    case testing      // Predictable for tests
    
    var settings: PerformanceSettings {
        switch self {
        case .default:
            return PerformanceSettings(priority: .medium, caching: true)
        case .ui:
            return PerformanceSettings(priority: .userInitiated, caching: true)
        case .background:
            return PerformanceSettings(priority: .background, caching: false)
        case .optimized:
            return PerformanceSettings(priority: .high, caching: true)
        case .testing:
            return PerformanceSettings(priority: .medium, caching: false)
        }
    }
}

/// Error handling configuration options
public enum ErrorConfig {
    case `default`     // Standard error handling
    case strict        // Fail fast (development/testing)
    case userFriendly  // User-facing error recovery
    case silent        // Log only, no user interruption
    case standard      // Alias for default
    
    var recoveryStrategy: ErrorRecoveryStrategy {
        switch self {
        case .default, .standard:
            return .propagate
        case .strict:
            return .propagate
        case .userFriendly:
            return .retry(attempts: 3)
        case .silent:
            return .silent
        }
    }
}

/// Navigation configuration options
public enum NavigationConfig {
    case `default`    // Standard navigation
    case modal        // Modal presentation
    case stack        // Navigation stack
    case tab          // Tab-based navigation
    case custom       // Custom navigation pattern
}

// MARK: - Simplified Orchestrator Builder

/// Simplified orchestrator builder with progressive disclosure
public struct OrchestratorBuilder {
    private var config = OrchestratorConfiguration()
    
    public init() {}
    
    /// Apply default configuration
    public func withDefaults() -> Self {
        var builder = self
        builder.config = .recommended
        return builder
    }
    
    /// Configure navigation
    public func withNavigation(_ nav: NavigationConfig = .default) -> Self {
        var builder = self
        builder.config.navigation = nav
        return builder
    }
    
    /// Configure persistence
    public func withPersistence(_ persist: PersistenceConfig = .default) -> Self {
        var builder = self
        builder.config.persistence = persist
        return builder
    }
    
    /// Configure error handling
    public func withErrorHandling(_ errors: ErrorConfig = .default) -> Self {
        var builder = self
        builder.config.errorHandling = errors
        return builder
    }
    
    /// Build the orchestrator
    public func build() async -> any Orchestrator {
        // Create orchestrator with configuration
        let orchestrator = BaseOrchestrator()
        
        // Apply configuration
        // In production, this would configure the orchestrator
        // based on the selected options
        
        return orchestrator
    }
}

/// Simplified orchestrator configuration
extension OrchestratorConfiguration {
    public var navigation: NavigationConfig
    public var persistence: PersistenceConfig
    public var errorHandling: ErrorConfig
    
    /// Recommended configuration for most apps
    public static let recommended = OrchestratorConfiguration(
        navigationEnabled: true,
        capabilityMonitoringEnabled: true,
        maxContextCount: 50,
        contextCreationTimeout: .milliseconds(300)
    )
    
    /// Performance-optimized configuration
    public static let performant = OrchestratorConfiguration(
        navigationEnabled: true,
        capabilityMonitoringEnabled: false,
        maxContextCount: 20,
        contextCreationTimeout: .milliseconds(100),
        performanceMonitoringEnabled: true
    )
}

// MARK: - Standardized Lifecycle Protocol

/// Unified async lifecycle protocol - no more completion handlers or publishers
@MainActor
public protocol ContextLifecycle {
    /// Called when context appears
    func onAppear() async
    
    /// Called when context disappears
    func onDisappear() async
    
    /// Called when context is activated
    func onActivate() async
    
    /// Called when context is deactivated
    func onDeactivate() async
    
    /// Called when context is configured
    func onConfigured() async
}

/// Default implementations for lifecycle methods
extension ContextLifecycle {
    public func onAppear() async {
        // Default empty implementation
    }
    
    public func onDisappear() async {
        // Default empty implementation
    }
    
    public func onActivate() async {
        // Default empty implementation
    }
    
    public func onDeactivate() async {
        // Default empty implementation
    }
    
    public func onConfigured() async {
        // Default empty implementation
    }
}

// MARK: - Performance Settings

struct PerformanceSettings {
    let priority: TaskPriority
    let caching: Bool
    let maxConcurrency: Int
    
    init(priority: TaskPriority, caching: Bool, maxConcurrency: Int = 4) {
        self.priority = priority
        self.caching = caching
        self.maxConcurrency = maxConcurrency
    }
}

// MARK: - Configuration Profiles

/// Pre-configured profiles for common use cases
public struct ConfigurationProfiles {
    /// Simple app configuration
    public static let simple = (
        context: ContextConfiguration.recommended,
        orchestrator: OrchestratorConfiguration.recommended
    )
    
    /// Testing configuration
    public static let testing = (
        context: ContextConfiguration.testing,
        orchestrator: OrchestratorConfiguration(
            navigationEnabled: false,
            capabilityMonitoringEnabled: false,
            maxContextCount: 10
        )
    )
    
    /// High-performance configuration
    public static let performance = (
        context: ContextConfiguration(
            persistence: .memory,
            performance: .optimized,
            errorHandling: .silent
        ),
        orchestrator: OrchestratorConfiguration.performant
    )
}