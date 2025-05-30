import Foundation

// MARK: - GlobalCapabilityManager

/// Global singleton for managing capability availability across the application
/// Provides centralized capability configuration and validation
public actor GlobalCapabilityManager {
    
    // MARK: - Singleton
    
    public static let shared = GlobalCapabilityManager()
    
    // MARK: - State
    
    private var capabilityManager: CapabilityManager?
    private var isConfigured: Bool = false
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Configuration
    
    /// Configures the global capability manager with available capabilities
    public func configure(availableCapabilities: Set<CapabilityType>) async {
        let manager = CapabilityManager()
        await manager.configure(availableCapabilities: availableCapabilities)
        
        self.capabilityManager = manager
        self.isConfigured = true
        
        print("✅ GlobalCapabilityManager: Configured with \(availableCapabilities.count) capabilities")
    }
    
    /// Gets the configured capability manager
    public func getManager() async -> CapabilityManager {
        if let manager = capabilityManager, isConfigured {
            return manager
        }
        
        // Auto-configure with default capabilities if not configured
        let defaultCapabilities: Set<CapabilityType> = [.businessLogic, .stateManagement]
        await configure(availableCapabilities: defaultCapabilities)
        
        return capabilityManager!
    }
    
    /// Checks if the manager is configured
    public func isManagerConfigured() async -> Bool {
        return isConfigured
    }
    
    /// Resets the global manager (useful for testing)
    public func reset() async {
        capabilityManager = nil
        isConfigured = false
        print("🔄 GlobalCapabilityManager: Reset")
    }
}

// MARK: - GlobalIntelligenceManager

/// Global singleton for managing intelligence system across the application
/// Provides centralized access to architectural intelligence capabilities
public actor GlobalIntelligenceManager {
    
    // MARK: - Singleton
    
    public static let shared = GlobalIntelligenceManager()
    
    // MARK: - State
    
    private var intelligence: AxiomIntelligence?
    private var isConfigured: Bool = false
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Configuration
    
    /// Configures the global intelligence system
    public func configure() async {
        let intelligence = AxiomIntelligence()
        await intelligence.initialize()
        
        self.intelligence = intelligence
        self.isConfigured = true
        
        print("✅ GlobalIntelligenceManager: Intelligence system configured")
    }
    
    /// Gets the configured intelligence system
    public func getIntelligence() async -> AxiomIntelligence {
        if let intelligence = intelligence, isConfigured {
            return intelligence
        }
        
        // Auto-configure if not configured
        await configure()
        
        return intelligence!
    }
    
    /// Checks if the intelligence system is configured
    public func isIntelligenceConfigured() async -> Bool {
        return isConfigured
    }
    
    /// Resets the global intelligence system (useful for testing)
    public func reset() async {
        intelligence = nil
        isConfigured = false
        print("🔄 GlobalIntelligenceManager: Reset")
    }
}

// MARK: - GlobalPerformanceMonitor

/// Global singleton for managing performance monitoring across the application
/// Provides centralized performance tracking and analytics
public actor GlobalPerformanceMonitor {
    
    // MARK: - Singleton
    
    public static let shared = GlobalPerformanceMonitor()
    
    // MARK: - State
    
    private var performanceMonitor: PerformanceMonitor?
    private var isConfigured: Bool = false
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Configuration
    
    /// Configures the global performance monitor
    public func configure() async {
        let monitor = PerformanceMonitor()
        await monitor.initialize()
        
        self.performanceMonitor = monitor
        self.isConfigured = true
        
        print("✅ GlobalPerformanceMonitor: Performance monitoring configured")
    }
    
    /// Gets the configured performance monitor
    public func getMonitor() async -> PerformanceMonitor {
        if let monitor = performanceMonitor, isConfigured {
            return monitor
        }
        
        // Auto-configure if not configured
        await configure()
        
        return performanceMonitor!
    }
    
    /// Checks if the performance monitor is configured
    public func isMonitorConfigured() async -> Bool {
        return isConfigured
    }
    
    /// Resets the global performance monitor (useful for testing)
    public func reset() async {
        performanceMonitor = nil
        isConfigured = false
        print("🔄 GlobalPerformanceMonitor: Reset")
    }
}

// MARK: - Usage Documentation

/*
 GLOBAL MANAGER USAGE:
 
 APPLICATION SETUP:
 ```swift
 // Configure capabilities
 let capabilityManager = await GlobalCapabilityManager.shared.getManager()
 await capabilityManager.configure(availableCapabilities: [.businessLogic, .stateManagement])
 
 // Get intelligence system
 let intelligence = await GlobalIntelligenceManager.shared.getIntelligence()
 
 // Start performance monitoring
 let performanceMonitor = await GlobalPerformanceMonitor.shared.getMonitor()
 await performanceMonitor.startMonitoring()
 ```
 
 CONTEXT USAGE:
 ```swift
 @MainActor
 class MyContext: AxiomContext {
     func capabilityManager() async throws -> CapabilityManager {
         return await GlobalCapabilityManager.shared.getManager()
     }
     
     func performanceMonitor() async throws -> PerformanceMonitor {
         return await GlobalPerformanceMonitor.shared.getMonitor()
     }
 }
 ```
 
 BENEFITS:
 - Centralized configuration management
 - Automatic lazy initialization
 - Thread-safe actor-based implementation
 - Easy testing with reset capabilities
 */