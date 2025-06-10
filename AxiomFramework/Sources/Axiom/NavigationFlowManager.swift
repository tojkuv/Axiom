import Foundation

// MARK: - NavigationFlowManager

/// Flow orchestration functionality for managing navigation flows
/// Handles multi-step navigation sequences and flow state management
@MainActor
public final class NavigationFlowManager {
    
    // MARK: - State
    
    /// Active navigation flows
    private var activeFlows: [NavigationFlow] = []
    
    /// Flow completion handlers
    private var flowCompletionHandlers: [UUID: () async -> Void] = [:]
    
    /// Reference to core navigation for executing flow steps
    private weak var navigationCore: NavigationCore?
    
    public init(navigationCore: NavigationCore? = nil) {
        self.navigationCore = navigationCore
    }
    
    // MARK: - Flow Management
    
    /// Start a navigation flow
    public func startFlow(_ flow: NavigationFlow) async {
        activeFlows.append(flow)
        
        // Execute flow steps
        if let core = navigationCore {
            await flow.start(using: core)
        }
    }
    
    /// Complete the current flow
    public func completeFlow() async {
        guard let flow = activeFlows.last else { return }
        
        // Execute completion handler if exists
        if let handler = flowCompletionHandlers[flow.id] {
            await handler()
            flowCompletionHandlers.removeValue(forKey: flow.id)
        }
        
        activeFlows.removeLast()
    }
    
    /// Cancel the current flow
    public func cancelFlow() async {
        guard !activeFlows.isEmpty else { return }
        activeFlows.removeLast()
        
        // Navigate back to flow start if possible
        if let core = navigationCore {
            _ = await core.navigateBack()
        }
    }
    
    /// Register flow completion handler
    public func onFlowCompletion(_ flowId: UUID, handler: @escaping () async -> Void) {
        flowCompletionHandlers[flowId] = handler
    }
    
    // MARK: - Flow State
    
    /// Get current active flow
    public var currentFlow: NavigationFlow? {
        return activeFlows.last
    }
    
    /// Check if a flow is active
    public var hasActiveFlow: Bool {
        return !activeFlows.isEmpty
    }
    
    /// Get all active flows
    public var allActiveFlows: [NavigationFlow] {
        return activeFlows
    }
    
    /// Clear all flows
    public func clearAllFlows() {
        activeFlows.removeAll()
        flowCompletionHandlers.removeAll()
    }
}

// MARK: - NavigationFlow

/// Represents a multi-step navigation flow
public struct NavigationFlow: Identifiable {
    public let id = UUID()
    public let name: String
    public let steps: [Route]
    private var currentStepIndex: Int = 0
    
    public init(name: String, steps: [Route]) {
        self.name = name
        self.steps = steps
    }
    
    /// Start the flow
    public func start(using core: NavigationCore) async {
        guard !steps.isEmpty else { return }
        _ = await core.navigate(to: steps[0])
    }
    
    /// Move to next step
    public mutating func nextStep(using core: NavigationCore) async -> Bool {
        guard currentStepIndex < steps.count - 1 else { return false }
        currentStepIndex += 1
        _ = await core.navigate(to: steps[currentStepIndex])
        return true
    }
    
    /// Get current step
    public var currentStep: Route? {
        guard currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex]
    }
    
    /// Check if flow is complete
    public var isComplete: Bool {
        return currentStepIndex >= steps.count - 1
    }
}