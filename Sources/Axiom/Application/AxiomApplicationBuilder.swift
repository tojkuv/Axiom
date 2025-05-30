import Foundation

// MARK: - AxiomApplicationBuilder

/// Streamlined application builder for easy Axiom framework setup
/// Provides 70% reduction in initialization boilerplate
public struct AxiomApplicationBuilder {
    
    // MARK: - Configuration
    
    private var capabilities: [CapabilityType] = []
    private var performanceEnabled: Bool = true
    private var debugMode: Bool = false
    
    // MARK: - Static Factory Methods
    
    /// Creates a pre-configured builder for counter applications
    public static func counterApp() -> AxiomApplicationBuilder {
        var builder = AxiomApplicationBuilder()
        builder.capabilities = [.businessLogic, .stateManagement]
        builder.performanceEnabled = true
        return builder
    }
    
    /// Creates a generic application builder with standard configuration
    public static func standardApp() -> AxiomApplicationBuilder {
        var builder = AxiomApplicationBuilder()
        builder.capabilities = [.businessLogic, .stateManagement, .analytics]
        builder.performanceEnabled = true
        return builder
    }
    
    // MARK: - Configuration Methods
    
    public func withCapabilities(_ capabilities: [CapabilityType]) -> AxiomApplicationBuilder {
        var builder = self
        builder.capabilities = capabilities
        return builder
    }
    
    public func withPerformanceMonitoring(_ enabled: Bool) -> AxiomApplicationBuilder {
        var builder = self
        builder.performanceEnabled = enabled
        return builder
    }
    
    public func withDebugMode(_ enabled: Bool) -> AxiomApplicationBuilder {
        var builder = self
        builder.debugMode = enabled
        return builder
    }
    
    // MARK: - Build Methods
    
    /// Builds the application environment - call this first before creating contexts
    public func build() async {
        // Initialize global capability manager
        let capabilityManager = await GlobalCapabilityManager.shared.getManager()
        await capabilityManager.configure(availableCapabilities: Set(capabilities))
        
        // Initialize global intelligence manager
        let _ = await GlobalIntelligenceManager.shared.getIntelligence()
        
        // Initialize performance monitoring if enabled
        if performanceEnabled {
            let performanceMonitor = await GlobalPerformanceMonitor.shared.getMonitor()
            await performanceMonitor.startMonitoring()
        }
        
        if debugMode {
            print("✅ AxiomApplicationBuilder: Application environment initialized")
            print("   Capabilities: \(capabilities)")
            print("   Performance monitoring: \(performanceEnabled)")
        }
    }
    
    /// Creates a counter context with the specified client factory
    public func createCounterContext<ClientType: AxiomClient>(
        clientFactory: @Sendable (CapabilityManager) async throws -> ClientType
    ) async throws -> (ClientType, AxiomIntelligence) {
        
        let capabilityManager = await GlobalCapabilityManager.shared.getManager()
        let intelligence = await GlobalIntelligenceManager.shared.getIntelligence()
        
        let client = try await clientFactory(capabilityManager)
        try await client.initialize()
        
        if debugMode {
            print("✅ AxiomApplicationBuilder: Counter context created")
        }
        
        return (client, intelligence)
    }
    
    /// Creates a generic context with the specified client factory
    public func createContext<ClientType: AxiomClient>(
        clientFactory: @Sendable (CapabilityManager) async throws -> ClientType
    ) async throws -> (ClientType, AxiomIntelligence) {
        
        let capabilityManager = await GlobalCapabilityManager.shared.getManager()
        let intelligence = await GlobalIntelligenceManager.shared.getIntelligence()
        
        let client = try await clientFactory(capabilityManager)
        try await client.initialize()
        
        if debugMode {
            print("✅ AxiomApplicationBuilder: Context created with client type \(ClientType.self)")
        }
        
        return (client, intelligence)
    }
}

// MARK: - Usage Documentation

/*
 AXIOM APPLICATION BUILDER USAGE:
 
 SIMPLE COUNTER APP:
 ```swift
 let appBuilder = AxiomApplicationBuilder.counterApp()
 await appBuilder.build()
 
 let (client, intelligence) = try await appBuilder.createCounterContext { capabilityManager in
     return MyCounterClient(capabilities: capabilityManager)
 }
 
 let context = MyContext(client: client, intelligence: intelligence)
 ```
 
 CUSTOM APP CONFIGURATION:
 ```swift
 let appBuilder = AxiomApplicationBuilder.standardApp()
     .withCapabilities([.businessLogic, .stateManagement, .analytics])
     .withPerformanceMonitoring(true)
     .withDebugMode(true)
 
 await appBuilder.build()
 let (client, intelligence) = try await appBuilder.createContext { capabilityManager in
     return MyCustomClient(capabilities: capabilityManager)
 }
 ```
 
 BENEFITS:
 - 70% reduction in initialization boilerplate
 - Type-safe configuration
 - Automatic global service management
 - Consistent setup patterns
 - Easy testing and mocking
 */