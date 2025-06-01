import SwiftUI

#if canImport(Axiom)
import Axiom

// MARK: - Real Counter Context with Streamlined APIs

/// AxiomContext implementation demonstrating:
/// - AxiomApplicationBuilder integration
/// - ContextStateBinder for automatic state synchronization  
/// - Type-safe client-context relationships
@MainActor
final class RealCounterContext: ObservableObject, AxiomContext {
    
    // MARK: - AxiomContext Protocol
    
    public typealias View = RealCounterView
    public typealias Clients = RealCounterClients
    
    public var clients: RealCounterClients {
        RealCounterClients(counterClient: counterClient)
    }
    
    public let intelligence: AxiomIntelligence
    
    // MARK: - Clients
    
    let counterClient: RealCounterClient
    
    // MARK: - State (AUTOMATICALLY SYNCHRONIZED!)
    
    @Published var currentCount: Int = 0  // No more manual sync needed!
    @Published var isLoading: Bool = false
    @Published var lastError: (any AxiomError)?
    @Published var lastIntelligenceResponse: String = ""
    
    // MARK: - Automatic State Binding
    
    private let stateBinder = ContextStateBinder()
    
    // MARK: - Streamlined Initialization
    
    init(counterClient: RealCounterClient, intelligence: AxiomIntelligence) {
        self.counterClient = counterClient
        self.intelligence = intelligence
        
        // OLD WAY: Manual observer setup + manual state copying
        // NEW WAY: Automatic binding handles everything
        Task {
            await counterClient.addObserver(self)
            
            // Set up automatic state binding - eliminates manual synchronization!
            await bindClientProperty(
                counterClient,
                property: \.count,        // Client state property  
                to: \.currentCount,      // Context @Published property
                using: stateBinder
            )
            
            print("🎯 Real Context: Automatic state binding active!")
        }
    }
    
    // MARK: - AxiomContext Protocol Methods
    
    public func capabilityManager() async throws -> CapabilityManager {
        return await GlobalCapabilityManager.shared.getManager()
    }
    
    public func trackAnalyticsEvent(_ event: String, parameters: [String: Any]) async {
        print("📊 Real Analytics: \(event) - \(parameters)")
    }
    
    public func onAppear() async {
        print("👁️ Real Context appeared")
        await trackAnalyticsEvent("counter_screen_viewed", parameters: [:])
    }
    
    public func onDisappear() async {
        print("👁️ Real Context disappeared")
    }
    
    public func onClientStateChange<T: AxiomClient>(_ client: T) async {
        // OLD WAY: Manual type checking, manual state access, manual UI updates
        // NEW WAY: Automatic binding handles everything!
        await stateBinder.updateAllBindings()
        
        print("🔄 Real Context: State automatically synchronized via binding!")
        
        // Custom logic can still be added here if needed
        await trackAnalyticsEvent("client_state_changed", parameters: ["client_type": String(describing: T.self)])
    }
    
    public func handleError(_ error: any AxiomError) async {
        lastError = error
        print("❌ Real Error handled: \(error)")
    }
    
    // MARK: - Counter Actions
    
    func incrementCounter() async {
        await counterClient.increment()
        await trackAnalyticsEvent("counter_incremented", parameters: ["new_value": currentCount])
    }
    
    func decrementCounter() async {
        await counterClient.decrement()
        await trackAnalyticsEvent("counter_decremented", parameters: ["new_value": currentCount])
    }
    
    func resetCounter() async {
        await counterClient.reset()
        await trackAnalyticsEvent("counter_reset", parameters: [:])
    }
    
    func askIntelligence() async {
        do {
            let query = "What is the significance of the number \(currentCount)?"
            let response = try await intelligence.processQuery(query)
            lastIntelligenceResponse = response.answer
            print("🧠 Real Intelligence: \(response.answer)")
            await trackAnalyticsEvent("intelligence_query", parameters: ["confidence": response.confidence])
        } catch {
            await handleError(error as? any AxiomError ?? RealAxiomError(underlying: error))
        }
    }
}

// MARK: - Supporting Error Type

struct RealAxiomError: AxiomError {
    let id = UUID()
    let underlying: Error
    
    var category: ErrorCategory { .architectural }
    var severity: ErrorSeverity { .error }
    var context: ErrorContext {
        ErrorContext(component: ComponentID("RealCounterContext"), timestamp: Date(), additionalInfo: [:])
    }
    var recoveryActions: [RecoveryAction] { [] }
    var userMessage: String { underlying.localizedDescription }
    
    var errorDescription: String? {
        underlying.localizedDescription
    }
}

#else

// MARK: - Fallback Context (when Axiom not available)

@MainActor
final class RealCounterContext: ObservableObject {
    @Published var currentCount: Int = 0
    @Published var lastIntelligenceResponse: String = ""
    
    private var counterClient: RealCounterClient
    
    init(counterClient: RealCounterClient, intelligence: Any? = nil) {
        self.counterClient = counterClient
    }
    
    func incrementCounter() async {
        await counterClient.increment()
        currentCount = await counterClient.getCurrentCount()
    }
    
    func decrementCounter() async {
        await counterClient.decrement() 
        currentCount = await counterClient.getCurrentCount()
    }
    
    func resetCounter() async {
        await counterClient.reset()
        currentCount = await counterClient.getCurrentCount()
    }
    
    func askIntelligence() async {
        lastIntelligenceResponse = "Fallback response for \(currentCount) - Add Axiom package for real intelligence!"
        print("⚠️ Fallback Context: Intelligence query")
    }
    
    func onAppear() async {
        print("⚠️ Fallback Context appeared")
    }
    
    func onDisappear() async {
        print("⚠️ Fallback Context disappeared")
    }
}

#endif