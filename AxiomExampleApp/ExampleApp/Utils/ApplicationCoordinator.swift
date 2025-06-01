import Foundation
import SwiftUI

#if canImport(Axiom)
import Axiom

// MARK: - Multi-Domain Application Coordinator

/// Sophisticated application coordinator managing multi-domain architecture
/// Demonstrates User domain, Data domain, and cross-domain orchestration
@MainActor
final class MultiDomainApplicationCoordinator: ObservableObject {
    
    // MARK: - Published State
    
    @Published var isInitialized: Bool = false
    @Published var initializationError: (any AxiomError)?
    @Published var initializationProgress: Double = 0.0
    @Published var currentInitializationStep: String = ""
    
    // MARK: - Domain Contexts
    
    @Published var userContext: SimpleUserContext?
    @Published var dataContext: SimpleDataContext?
    
    // MARK: - Application Builder
    
    private let appBuilder = AxiomApplicationBuilder.counterApp()
    
    // MARK: - Convenience Properties
    
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
            
            // Step 2: Initialize User domain
            currentInitializationStep = "Initializing User domain..."
            initializationProgress = 0.4
            try await initializeUserDomain()
            
            // Step 3: Initialize Data domain  
            currentInitializationStep = "Initializing Data domain..."
            initializationProgress = 0.7
            try await initializeDataDomain()
            
            // Step 4: Finalize initialization
            currentInitializationStep = "Finalizing initialization..."
            initializationProgress = 1.0
            
            await MainActor.run {
                self.isInitialized = true
                self.currentInitializationStep = "Initialization complete"
            }
            
            print("🚀 MultiDomainApplicationCoordinator: Full framework initialization complete!")
            
        } catch {
            let axiomError = error as? any AxiomError ?? ApplicationCoordinatorError.initializationFailed(underlying: error)
            
            await MainActor.run {
                self.initializationError = axiomError
                self.isInitialized = false
            }
            
            print("❌ MultiDomainApplicationCoordinator: Initialization failed: \(error)")
        }
    }
    
    private func initializeUserDomain() async throws {
        let (client, intelligence) = try await appBuilder.createCounterContext { capabilityManager in
            return RealCounterClient(capabilities: capabilityManager)
        }
        
        let newUserContext = SimpleUserContext(client: client, intelligence: intelligence)
        
        await MainActor.run {
            self.userContext = newUserContext
        }
        
        print("👤 User domain initialized successfully")
    }
    
    private func initializeDataDomain() async throws {
        let (client, intelligence) = try await appBuilder.createCounterContext { capabilityManager in
            return RealCounterClient(capabilities: capabilityManager)
        }
        
        let newDataContext = SimpleDataContext(client: client, intelligence: intelligence)
        
        await MainActor.run {
            self.dataContext = newDataContext
        }
        
        print("🗃️ Data domain initialized successfully")
    }
    
    // MARK: - Lifecycle Management
    
    func shutdown() async {
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

// MARK: - Legacy Application Coordinator (for backward compatibility)

@MainActor
final class RealAxiomApplication: ObservableObject {
    @Published var context: RealCounterContext?
    @Published var isInitialized: Bool = false
    @Published var initializationError: (any AxiomError)?
    
    #if canImport(Axiom)
    private let appBuilder = AxiomApplicationBuilder.counterApp()
    #endif
    
    func initialize() async {
        #if canImport(Axiom)
        // Use Axiom framework when available
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
            
            print("✅ RealAxiomApplication: Legacy initialization complete!")
            
        } catch {
            let axiomError = error as? any AxiomError ?? ApplicationCoordinatorError.initializationFailed(underlying: error)
            
            await MainActor.run {
                self.initializationError = axiomError
                self.isInitialized = false
            }
            
            print("❌ RealAxiomApplication: Legacy initialization failed: \(error)")
        }
        #else
        // Create fallback client and context when Axiom not available
        let client = RealCounterClient()
        try? await client.initialize()
        
        let newContext = RealCounterContext(counterClient: client)
        
        await MainActor.run {
            self.context = newContext
            self.isInitialized = true
        }
        
        print("⚠️ RealAxiomApplication: Fallback initialization complete")
        #endif
    }
    
    func shutdown() async {
        #if canImport(Axiom)
        guard let context = context else { return }
        await context.counterClient.shutdown()
        #endif
        
        await MainActor.run {
            self.context = nil
            self.isInitialized = false
        }
        
        print("🔄 RealAxiomApplication: Legacy shutdown complete")
    }
    
    func reinitialize() async {
        await shutdown()
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        await initialize()
    }
}

#endif

// MARK: - Simple Context Types

/// Simple User Context for multi-domain architecture demonstration
@MainActor
final class SimpleUserContext: ObservableObject {
    let client: RealCounterClient
    let intelligence: AxiomIntelligence
    
    @Published var isAuthenticated: Bool = false
    @Published var username: String = "Demo User"
    @Published var userActions: [String] = []
    
    init(client: RealCounterClient, intelligence: AxiomIntelligence) {
        self.client = client
        self.intelligence = intelligence
        
        // Simulate authentication
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            await MainActor.run {
                self.isAuthenticated = true
                self.userActions.append("User authenticated")
            }
        }
    }
    
    func onAppear() async {
        userActions.append("User context appeared")
    }
    
    func onDisappear() async {
        userActions.append("User context disappeared")
    }
    
    func performAction(_ action: String) async {
        userActions.append(action)
        print("👤 User action: \(action)")
    }
}

/// Simple Data Context for multi-domain architecture demonstration
@MainActor  
final class SimpleDataContext: ObservableObject {
    let client: RealCounterClient
    let intelligence: AxiomIntelligence
    
    @Published var items: [String] = []
    @Published var isLoading: Bool = false
    @Published var dataQualityScore: Double = 0.95
    @Published var cacheEfficiency: Double = 0.88
    
    init(client: RealCounterClient, intelligence: AxiomIntelligence) {
        self.client = client
        self.intelligence = intelligence
        
        // Simulate data loading
        Task {
            await loadInitialData()
        }
    }
    
    func onAppear() async {
        print("🗃️ Data context appeared")
        await loadInitialData()
    }
    
    func onDisappear() async {
        print("🗃️ Data context disappeared")
    }
    
    private func loadInitialData() async {
        isLoading = true
        
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        await MainActor.run {
            self.items = [
                "Sample Data Item 1",
                "Sample Data Item 2", 
                "Sample Data Item 3",
                "User Preferences",
                "Analytics Data"
            ]
            self.isLoading = false
        }
        
        print("🗃️ Data loaded: \(items.count) items")
    }
    
    func addItem(_ item: String) async {
        await MainActor.run {
            self.items.append(item)
        }
        print("🗃️ Data item added: \(item)")
    }
}

/// Simple Integration Demo View for multi-domain showcase
struct SimpleIntegrationDemoView: View {
    @StateObject private var userContext: SimpleUserContext
    @StateObject private var dataContext: SimpleDataContext
    
    init(userContext: SimpleUserContext, dataContext: SimpleDataContext) {
        self._userContext = StateObject(wrappedValue: userContext)
        self._dataContext = StateObject(wrappedValue: dataContext)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    integrationHeader
                    
                    userDomainCard
                    
                    dataDomainCard
                    
                    crossDomainActionsCard
                }
                .padding()
            }
        }
        .navigationTitle("Multi-Domain Demo")
        .onAppear {
            Task {
                await userContext.onAppear()
                await dataContext.onAppear()
            }
        }
    }
    
    private var integrationHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundColor(.purple)
            
            Text("Multi-Domain Architecture Demo")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Showcasing User & Data Domain Integration")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.purple.opacity(0.1), .blue.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
    
    private var userDomainCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.circle")
                    .foregroundColor(.blue)
                Text("User Domain")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Circle()
                    .fill(userContext.isAuthenticated ? .green : .orange)
                    .frame(width: 12, height: 12)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Username: \(userContext.username)")
                    .font(.body)
                
                Text("Status: \(userContext.isAuthenticated ? "Authenticated" : "Pending")")
                    .font(.caption)
                    .foregroundColor(userContext.isAuthenticated ? .green : .orange)
                
                Text("Recent Actions:")
                    .font(.caption)
                    .fontWeight(.medium)
                
                ForEach(userContext.userActions.suffix(3), id: \.self) { action in
                    Text("• \(action)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Button("Perform User Action") {
                Task {
                    await userContext.performAction("Demo action at \(Date().timeIntervalSince1970)")
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var dataDomainCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cylinder")
                    .foregroundColor(.green)
                Text("Data Domain")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                if dataContext.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Items: \(dataContext.items.count)")
                    .font(.body)
                
                Text("Quality Score: \(Int(dataContext.dataQualityScore * 100))%")
                    .font(.caption)
                
                Text("Cache Efficiency: \(Int(dataContext.cacheEfficiency * 100))%")
                    .font(.caption)
                
                if !dataContext.items.isEmpty {
                    Text("Sample Items:")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    ForEach(dataContext.items.prefix(3), id: \.self) { item in
                        Text("• \(item)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Button("Add Data Item") {
                Task {
                    await dataContext.addItem("New item \(Date().timeIntervalSince1970)")
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var crossDomainActionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gearshape.2")
                    .foregroundColor(.purple)
                Text("Cross-Domain Actions")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            Text("Demonstrate coordination between User and Data domains")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Button("Sync User with Data") {
                    Task {
                        await userContext.performAction("Initiated data sync")
                        await dataContext.addItem("Sync from user: \(userContext.username)")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Generate User Report") {
                    Task {
                        await userContext.performAction("Generated report")
                        await dataContext.addItem("Report for: \(userContext.username)")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color.purple.opacity(0.05))
        .cornerRadius(12)
    }
}

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