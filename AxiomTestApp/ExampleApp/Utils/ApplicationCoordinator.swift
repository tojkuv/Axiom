import Foundation
import SwiftUI

#if canImport(Axiom)
import Axiom

// MARK: - Application Coordinator with Streamlined APIs

/// Coordinates application lifecycle and demonstrates streamlined Axiom APIs
/// Uses AxiomApplicationBuilder for simplified setup and dependency management
@MainActor
final class RealAxiomApplication: ObservableObject {
    
    // MARK: - Published State
    
    @Published var context: RealCounterContext?
    @Published var isInitialized: Bool = false
    @Published var initializationError: (any AxiomError)?
    
    // MARK: - Streamlined Setup
    
    private let appBuilder = AxiomApplicationBuilder.counterApp()
    
    // MARK: - Initialization
    
    func initialize() async {
        // OLD WAY: 25+ lines of manual setup  
        // NEW WAY: Single builder handles everything
        await appBuilder.build()
        
        do {
            let (client, intelligence) = try await appBuilder.createCounterContext { capabilityManager in
                return RealCounterClient(capabilities: capabilityManager)
            }
            
            let newContext = RealCounterContext(
                counterClient: client,
                intelligence: intelligence
            )
            
            await MainActor.run {
                self.context = newContext
                self.isInitialized = true
                self.initializationError = nil
            }
            
            print("✅ RealAxiomApplication: Streamlined initialization complete!")
            
        } catch {
            let axiomError = error as? any AxiomError ?? ApplicationCoordinatorError.initializationFailed(underlying: error)
            
            await MainActor.run {
                self.initializationError = axiomError
                self.isInitialized = false
            }
            
            print("❌ RealAxiomApplication: Streamlined initialization failed: \(error)")
        }
    }
    
    // MARK: - Lifecycle Management
    
    func shutdown() async {
        guard let context = context else { return }
        
        await context.counterClient.shutdown()
        
        await MainActor.run {
            self.context = nil
            self.isInitialized = false
        }
        
        print("🔄 RealAxiomApplication: Shutdown complete")
    }
    
    // MARK: - Development Helpers
    
    func reinitialize() async {
        await shutdown()
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        await initialize()
    }
}

// MARK: - Application Coordinator Errors

enum ApplicationCoordinatorError: AxiomError {
    case initializationFailed(underlying: Error)
    case configurationError(String)
    case contextCreationFailed(String)
    
    var id: UUID { UUID() }
    var category: ErrorCategory { .architectural }
    var severity: ErrorSeverity { .error }
    
    var context: ErrorContext {
        ErrorContext(
            component: ComponentID("ApplicationCoordinator"),
            timestamp: Date(),
            additionalInfo: [:]
        )
    }
    
    var recoveryActions: [RecoveryAction] { [] }
    
    var userMessage: String {
        switch self {
        case .initializationFailed(let underlying):
            return "Failed to initialize application: \(underlying.localizedDescription)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .contextCreationFailed(let reason):
            return "Failed to create context: \(reason)"
        }
    }
    
    var errorDescription: String? {
        userMessage
    }
}

#else

// MARK: - Fallback Application Coordinator (when Axiom not available)

@MainActor
final class RealAxiomApplication: ObservableObject {
    @Published var context: RealCounterContext?
    @Published var isInitialized: Bool = false
    
    func initialize() async {
        // Create fallback client and context
        let client = RealCounterClient()
        try? await client.initialize()
        
        let newContext = RealCounterContext(counterClient: client)
        
        await MainActor.run {
            self.context = newContext
            self.isInitialized = true
        }
        
        print("⚠️ RealAxiomApplication: Fallback initialization complete")
    }
    
    func shutdown() async {
        await MainActor.run {
            self.context = nil
            self.isInitialized = false
        }
    }
    
    func reinitialize() async {
        await shutdown()
        await initialize()
    }
}

#endif

// MARK: - Usage Documentation

/*
 STREAMLINED APPLICATION SETUP COMPARISON:
 
 BEFORE (Manual Setup - 25+ lines):
 ```swift
 func initialize() async {
     do {
         let capabilityManager = await GlobalCapabilityManager.shared.getManager()
         await capabilityManager.configure(availableCapabilities: [.businessLogic, .stateManagement])
         
         let intelligence = await GlobalIntelligenceManager.shared.getIntelligence()
         
         let counterClient = RealCounterClient(capabilities: capabilityManager)
         try await counterClient.initialize()
         
         let newContext = RealCounterContext(
             counterClient: counterClient,
             intelligence: intelligence
         )
         
         self.context = newContext
         
     } catch {
         print("Failed to initialize application: \(error)")
     }
 }
 ```
 
 AFTER (Streamlined Setup - 7 lines):
 ```swift
 func initialize() async {
     await appBuilder.build()
     
     let (client, intelligence) = try await appBuilder.createCounterContext { capabilityManager in
         return RealCounterClient(capabilities: capabilityManager)
     }
     
     let newContext = RealCounterContext(counterClient: client, intelligence: intelligence)
     self.context = newContext
 }
 ```
 
 BENEFITS:
 - 70% reduction in initialization boilerplate
 - Automatic capability management
 - Type-safe dependency injection  
 - Error handling built-in
 - Easy to test and iterate
 */