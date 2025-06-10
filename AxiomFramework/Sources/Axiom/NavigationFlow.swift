import SwiftUI
import Foundation

// MARK: - Core Flow Protocols

public protocol NavigationFlow {
    associatedtype Body: FlowStep
    associatedtype FlowData
    
    var body: Body { get }
    var flowData: FlowData { get set }
}

public protocol FlowStep {
    associatedtype Content: View
    
    var id: String { get }
    var content: Content { get }
    var validation: FlowValidation? { get }
    var skipCondition: Bool { get }
    
    func flattened() -> [any FlowStep]
}

// MARK: - Flow Step Extensions

extension FlowStep {
    public func flattened() -> [any FlowStep] {
        return [self]
    }
    
    public func skippable(when condition: Bool) -> ModifiedFlowStep<Self> {
        return ModifiedFlowStep(base: self, skipCondition: condition)
    }
    
    public func onComplete(_ handler: @escaping () -> Void) -> ModifiedFlowStep<Self> {
        return ModifiedFlowStep(base: self, completionHandler: handler)
    }
}

// MARK: - Flow Step Implementation

public struct Step<Content: View>: FlowStep {
    public let id: String
    public let content: Content
    public var validation: FlowValidation?
    public var skipCondition: Bool = false
    
    public init(_ id: String, @ViewBuilder content: () -> Content) {
        self.id = id
        self.content = content()
    }
    
    public func validate(_ validation: @escaping (Any) -> Bool) -> Self {
        var copy = self
        copy.validation = FlowValidation(validation)
        return copy
    }
    
    public func skippable(when condition: Bool) -> Self {
        var copy = self
        copy.skipCondition = condition
        return copy
    }
}

// MARK: - Modified Flow Step

public struct ModifiedFlowStep<Base: FlowStep>: FlowStep {
    public let base: Base
    public var skipCondition: Bool
    public var completionHandler: (() -> Void)?
    
    public var id: String { base.id }
    public var content: Base.Content { base.content }
    public var validation: FlowValidation? { base.validation }
    
    public init(base: Base, skipCondition: Bool = false, completionHandler: (() -> Void)? = nil) {
        self.base = base
        self.skipCondition = skipCondition || base.skipCondition
        self.completionHandler = completionHandler
    }
}

// MARK: - Flow Validation

public struct FlowValidation {
    private let validator: (Any) -> Bool
    
    public init(_ validator: @escaping (Any) -> Bool) {
        self.validator = validator
    }
    
    public func validate(_ data: Any) -> Bool {
        return validator(data)
    }
}

// MARK: - Flow State Management

@propertyWrapper
public struct FlowState<Value> {
    private let key: String
    private let storage: FlowStorage
    private let initialValue: Value
    
    public init(key: String, storage: FlowStorage, initialValue: Value) {
        self.key = key
        self.storage = storage
        self.initialValue = initialValue
    }
    
    public var wrappedValue: Value {
        get { storage.get(key, default: initialValue) }
        set { storage.set(key, value: newValue) }
    }
    
    public var projectedValue: Binding<Value> {
        Binding(
            get: { storage.get(key, default: initialValue) },
            set: { storage.set(key, value: $0) }
        )
    }
}

public class FlowStorage {
    private var storage: [String: Any] = [:]
    
    public init() {}
    
    public func get<T>(_ key: String, default defaultValue: T) -> T {
        return storage[key] as? T ?? defaultValue
    }
    
    public func set<T>(_ key: String, value: T) {
        storage[key] = value
    }
    
    public func clear() {
        storage.removeAll()
    }
}

// MARK: - Flow Step Groups and Conditionals

public struct FlowStepGroup<Step: FlowStep>: FlowStep {
    public let steps: [Step]
    
    public var id: String { "group_\(steps.count)" }
    public var content: some View { EmptyView() }
    public var validation: FlowValidation? { nil }
    public var skipCondition: Bool { false }
    
    public init(steps: [Step]) {
        self.steps = steps
    }
    
    public func flattened() -> [any FlowStep] {
        return steps.flatMap { $0.flattened() }
    }
}

public enum ConditionalFlowStep<TrueStep: FlowStep, FalseStep: FlowStep>: FlowStep {
    case first(TrueStep)
    case second(FalseStep)
    
    public var id: String {
        switch self {
        case .first(let step): return step.id
        case .second(let step): return step.id
        }
    }
    
    public var content: some View {
        switch self {
        case .first(let step): return AnyView(step.content)
        case .second(let step): return AnyView(step.content)
        }
    }
    
    public var validation: FlowValidation? {
        switch self {
        case .first(let step): return step.validation
        case .second(let step): return step.validation
        }
    }
    
    public var skipCondition: Bool {
        switch self {
        case .first(let step): return step.skipCondition
        case .second(let step): return step.skipCondition
        }
    }
    
    public func flattened() -> [any FlowStep] {
        switch self {
        case .first(let step): return step.flattened()
        case .second(let step): return step.flattened()
        }
    }
}

// MARK: - NavigationService Flow Extensions

extension NavigationService {
    public func startFlow<Flow: NavigationFlow>(_ flow: Flow) async -> Result<Void, AxiomError> {
        let coordinator = FlowCoordinator(flow: flow, navigator: self)
        
        do {
            try await coordinator.start()
            return .success(())
        } catch {
            if let axiomError = error as? AxiomError {
                return .failure(axiomError)
            } else {
                return .failure(.navigationError(.invalidRoute("Flow start failed: \(error.localizedDescription)")))
            }
        }
    }
    
    public func completeCurrentFlow() async {
        // Implementation for completing current flow
        // This would integrate with the navigation state management
    }
    
    public func dismissFlow() async {
        // Implementation for dismissing current presentation
        // This would integrate with the navigation state management
    }
}

// MARK: - Flow Coordinator

@MainActor
public final class FlowCoordinator<Flow: NavigationFlow>: ObservableObject {
    @Published public var currentStep: Int = 0
    @Published public var canGoNext: Bool = true
    @Published public var canGoBack: Bool = false
    @Published public var progress: Double = 0.0
    
    private var flow: Flow
    private let navigator: NavigationService
    private var steps: [any FlowStep] = []
    
    public init(flow: Flow, navigator: NavigationService) {
        self.flow = flow
        self.navigator = navigator
        self.steps = flow.body.flattened()
        updateNavigationState()
    }
    
    public func start() async throws {
        guard !steps.isEmpty else {
            throw AxiomError.navigationError(.invalidRoute("Cannot start empty flow"))
        }
        
        try await showCurrentStep()
        updateNavigationState()
    }
    
    public func next() async throws {
        guard canGoNext else { return }
        
        // Validate current step if validation exists
        if let currentStepValidation = getCurrentStepValidation() {
            guard currentStepValidation.validate(flow.flowData) else {
                throw AxiomError.validationError(.ruleFailed(
                    field: "step_\(currentStep)",
                    rule: "flow_validation",
                    reason: "Step validation failed"
                ))
            }
        }
        
        // Move to next non-skipped step
        repeat {
            currentStep += 1
        } while currentStep < steps.count && steps[currentStep].skipCondition
        
        if currentStep >= steps.count {
            try await complete()
        } else {
            try await showCurrentStep()
        }
        
        updateNavigationState()
    }
    
    public func back() async throws {
        guard canGoBack else { return }
        
        // Move to previous non-skipped step
        repeat {
            currentStep -= 1
        } while currentStep >= 0 && steps[currentStep].skipCondition
        
        if currentStep >= 0 {
            try await showCurrentStep()
        }
        
        updateNavigationState()
    }
    
    public func cancel() async {
        _ = await navigator.dismiss()
        // Cleanup flow state if needed
    }
    
    private func complete() async throws {
        // Execute completion handlers
        for step in steps {
            if let modifiedStep = step as? any ModifiedStepProtocol {
                modifiedStep.executeCompletion()
            }
        }
        
        await navigator.completeCurrentFlow()
    }
    
    private func showCurrentStep() async throws {
        guard currentStep < steps.count else { return }
        // Implementation would show the current step view
        // This would integrate with the navigation system
    }
    
    private func getCurrentStepValidation() -> FlowValidation? {
        guard currentStep < steps.count else { return nil }
        return steps[currentStep].validation
    }
    
    private func updateNavigationState() {
        canGoBack = currentStep > 0
        canGoNext = currentStep < steps.count
        progress = steps.isEmpty ? 1.0 : Double(currentStep + 1) / Double(steps.count)
    }
    
    public var currentStepView: AnyView {
        guard currentStep < steps.count else {
            return AnyView(EmptyView())
        }
        let step = steps[currentStep]
        // Use type erasure to handle different view types
        if let concreteStep = step as? Step<AnyView> {
            return AnyView(concreteStep.content)
        } else {
            // Fallback for other step types
            return AnyView(EmptyView())
        }
    }
}

// MARK: - Supporting Protocols

private protocol ModifiedStepProtocol {
    func executeCompletion()
}

extension ModifiedFlowStep: ModifiedStepProtocol {
    func executeCompletion() {
        completionHandler?()
    }
}

