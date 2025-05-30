import Foundation
import SwiftUI
import Axiom

// MARK: - Multi-Domain Application Coordinator

/// Sophisticated application coordinator that manages the complete multi-domain
/// architecture showcasing the full capabilities of the Axiom framework
@MainActor
final class MultiDomainApplicationCoordinator: ObservableObject {
    
    // MARK: - Published State
    
    @Published var isInitialized: Bool = false
    @Published var initializationError: (any AxiomError)?
    @Published var initializationProgress: Double = 0.0
    @Published var currentInitializationStep: String = ""
    
    // MARK: - Domain Contexts
    
    @Published var userContext: UserContext?
    @Published var dataContext: DataContext?
    
    // MARK: - Framework Components
    
    private var intelligence: AxiomIntelligence?
    private var capabilityManager: CapabilityManager?
    private var performanceMonitor: PerformanceMonitor?
    
    // MARK: - Application Builder
    
    private let appBuilder = AxiomApplicationBuilder.multiDomainApp()
    
    // MARK: - Initialization
    
    func initialize() async {
        guard !isInitialized else { return }
        
        initializationError = nil
        initializationProgress = 0.0
        
        do {
            // Step 1: Initialize framework core
            currentInitializationStep = "Initializing framework core..."
            initializationProgress = 0.1
            await appBuilder.build()
            
            // Step 2: Set up capability management
            currentInitializationStep = "Setting up capability management..."
            initializationProgress = 0.2
            capabilityManager = await GlobalCapabilityManager.shared.getManager()
            
            // Step 3: Initialize performance monitoring
            currentInitializationStep = "Initializing performance monitoring..."
            initializationProgress = 0.3
            performanceMonitor = await GlobalPerformanceMonitor.shared.getMonitor()
            
            // Step 4: Set up intelligence system
            currentInitializationStep = "Setting up intelligence system..."
            initializationProgress = 0.4
            intelligence = await GlobalIntelligenceManager.shared.getIntelligence()
            
            // Step 5: Initialize User domain
            currentInitializationStep = "Initializing User domain..."
            initializationProgress = 0.6
            await initializeUserDomain()
            
            // Step 6: Initialize Data domain  
            currentInitializationStep = "Initializing Data domain..."
            initializationProgress = 0.8
            await initializeDataDomain()
            
            // Step 7: Finalize initialization
            currentInitializationStep = "Finalizing initialization..."
            initializationProgress = 1.0
            
            await MainActor.run {
                self.isInitialized = true
                self.currentInitializationStep = "Initialization complete"
            }
            
            print("🚀 MultiDomainApplicationCoordinator: Full framework initialization complete!")
            
        } catch {
            let axiomError = error as? any AxiomError ?? MultiDomainApplicationError.initializationFailed(underlying: error)
            
            await MainActor.run {
                self.initializationError = axiomError
                self.isInitialized = false
            }
            
            print("❌ MultiDomainApplicationCoordinator: Initialization failed: \(error)")
        }
    }
    
    private func initializeUserDomain() async throws {
        guard let capabilityManager = capabilityManager,
              let intelligence = intelligence else {
            throw MultiDomainApplicationError.missingDependencies("Capability manager or intelligence not available")
        }
        
        // Create user client with sophisticated capabilities
        let userClient = UserClient(capabilities: capabilityManager)
        try await userClient.initialize()
        
        // Create user context with full integration
        let newUserContext = UserContext(userClient: userClient, intelligence: intelligence)
        
        await MainActor.run {
            self.userContext = newUserContext
        }
        
        print("👤 User domain initialized successfully")
    }
    
    private func initializeDataDomain() async throws {
        guard let capabilityManager = capabilityManager,
              let intelligence = intelligence else {
            throw MultiDomainApplicationError.missingDependencies("Capability manager or intelligence not available")
        }
        
        // Create data client with advanced repository capabilities
        let dataClient = DataClient(capabilities: capabilityManager)
        try await dataClient.initialize()
        
        // Create data context with full integration
        let newDataContext = DataContext(dataClient: dataClient, intelligence: intelligence)
        
        await MainActor.run {
            self.dataContext = newDataContext
        }
        
        print("🗃️ Data domain initialized successfully")
    }
    
    // MARK: - Re-initialization
    
    func reinitialize() async {
        await shutdown()
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        await initialize()
    }
    
    func shutdown() async {
        // Shutdown domains in reverse order
        if let dataContext = dataContext {
            await dataContext.onDisappear()
        }
        
        if let userContext = userContext {
            await userContext.onDisappear()
        }
        
        await MainActor.run {
            self.userContext = nil
            self.dataContext = nil
            self.isInitialized = false
            self.initializationProgress = 0.0
            self.currentInitializationStep = ""
        }
        
        print("🔄 MultiDomainApplicationCoordinator: Shutdown complete")
    }
    
    // MARK: - Domain Access
    
    var isFullyInitialized: Bool {
        return isInitialized && userContext != nil && dataContext != nil
    }
    
    var initializationStatus: String {
        if isFullyInitialized {
            return "✅ Multi-Domain Architecture Ready"
        } else if isInitialized {
            return "⚠️ Partially Initialized"
        } else if initializationError != nil {
            return "❌ Initialization Failed"
        } else {
            return "🔄 Initializing..."
        }
    }
}

// MARK: - Application Builder Extension

extension AxiomApplicationBuilder {
    
    /// Creates a sophisticated multi-domain application configuration
    static func multiDomainApp() -> AxiomApplicationBuilder {
        // This would be implemented in the actual framework
        // For now, return the counter app builder as a placeholder
        return AxiomApplicationBuilder.counterApp()
    }
}

// MARK: - Error Types

enum MultiDomainApplicationError: AxiomError {
    case initializationFailed(underlying: Error)
    case missingDependencies(String)
    case domainInitializationFailed(String)
    case configurationError(String)
    
    var id: UUID { UUID() }
    var category: ErrorCategory { .architectural }
    var severity: ErrorSeverity { .error }
    
    var context: ErrorContext {
        ErrorContext(
            component: ComponentID("MultiDomainApplicationCoordinator"),
            timestamp: Date(),
            additionalInfo: [:]
        )
    }
    
    var recoveryActions: [RecoveryAction] { [] }
    
    var userMessage: String {
        switch self {
        case .initializationFailed(let underlying):
            return "Failed to initialize multi-domain application: \(underlying.localizedDescription)"
        case .missingDependencies(let message):
            return "Missing required dependencies: \(message)"
        case .domainInitializationFailed(let domain):
            return "Failed to initialize \(domain) domain"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        }
    }
    
    var errorDescription: String? {
        userMessage
    }
}