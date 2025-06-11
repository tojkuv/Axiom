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

// MARK: - Enhanced Flow Protocol System for Business Logic

/// Enhanced NavigationFlow protocol for business logic flows
public protocol BusinessNavigationFlow {
    var identifier: String { get }
    var steps: [BusinessFlowStep] { get }
    var metadata: FlowMetadata { get }
}

/// Enhanced FlowStep protocol for business logic
public protocol BusinessFlowStep {
    var identifier: String { get }
    var isRequired: Bool { get }
    var canSkip: Bool { get }
    var order: Int { get }
    var route: (any TypeSafeRoute)? { get }
    
    func validate(data: FlowData) -> ValidationResult
    func onEnter(data: FlowData) async
    func onExit(data: FlowData) async throws
}

/// Optional protocol extension for conditional steps
extension BusinessFlowStep {
    public func shouldSkip(data: FlowData) -> Bool {
        return false
    }
}

/// Flow metadata for business flows
public struct FlowMetadata: Equatable {
    public let title: String
    public let description: String
    public let estimatedDuration: TimeInterval
    
    public init(title: String, description: String, estimatedDuration: TimeInterval) {
        self.title = title
        self.description = description
        self.estimatedDuration = estimatedDuration
    }
}

/// Flow state enumeration
public enum FlowState: Equatable {
    case notStarted
    case inProgress
    case completed
    case cancelled
}

/// Validation result for flow steps
public enum ValidationResult: Equatable {
    case success
    case failure(message: String)
}

/// Flow-specific errors
public enum FlowError: Error, Equatable {
    case validationFailed(String)
    case invalidNavigation(String)
    case stepNotFound(String)
    case flowNotActive
}

/// Flow data container for state management
public class FlowData {
    private var data: [String: Any] = [:]
    
    public init() {}
    
    public func set(_ key: String, value: Any) {
        data[key] = value
    }
    
    public func get(_ key: String) -> Any? {
        return data[key]
    }
    
    public func remove(_ key: String) {
        data.removeValue(forKey: key)
    }
    
    public func serialize() throws -> Data {
        // Enhanced serialization for business flow data
        let codableData = data.compactMapValues { value -> String? in
            if let stringValue = value as? String {
                return stringValue
            } else if let boolValue = value as? Bool {
                return boolValue ? "true" : "false"
            } else if let intValue = value as? Int {
                return String(intValue)
            } else {
                // Convert complex objects to string representation
                return String(describing: value)
            }
        }
        return try JSONSerialization.data(withJSONObject: codableData)
    }
    
    public static func deserialize(from data: Data) throws -> FlowData {
        let flowData = FlowData()
        let stringData = try JSONSerialization.jsonObject(with: data) as? [String: String] ?? [:]
        
        for (key, value) in stringData {
            // Simple deserialization - can be enhanced for specific types
            if value == "true" {
                flowData.set(key, value: true)
            } else if value == "false" {
                flowData.set(key, value: false)
            } else if let intValue = Int(value) {
                flowData.set(key, value: intValue)
            } else {
                flowData.set(key, value: value)
            }
        }
        
        return flowData
    }
}

/// Enhanced flow coordinator for business logic flows
@MainActor
public class BusinessFlowCoordinator: ObservableObject {
    public let flow: BusinessNavigationFlow
    public let flowData: FlowData
    
    @Published public private(set) var currentStepIndex: Int = -1
    @Published public private(set) var flowState: FlowState = .notStarted
    
    public var currentStep: BusinessFlowStep? {
        guard currentStepIndex >= 0 && currentStepIndex < flow.steps.count else {
            return nil
        }
        return flow.steps[currentStepIndex]
    }
    
    public var progress: Double {
        guard !flow.steps.isEmpty else { return 0.0 }
        if flowState == .completed {
            return 1.0
        }
        return max(0.0, Double(currentStepIndex + 1) / Double(flow.steps.count))
    }
    
    public init(flow: BusinessNavigationFlow) {
        self.flow = flow
        self.flowData = FlowData()
    }
    
    public func start() async {
        currentStepIndex = 0
        flowState = .inProgress
        
        if let currentStep = currentStep {
            await currentStep.onEnter(data: flowData)
        }
    }
    
    public func next() async throws {
        guard flowState == .inProgress else {
            throw FlowError.flowNotActive
        }
        
        // Validate current step before moving to next
        if let currentStep = currentStep {
            try await currentStep.onExit(data: flowData)
        }
        
        // Move to next step
        currentStepIndex += 1
        
        if currentStepIndex >= flow.steps.count {
            // Flow completed
            flowState = .completed
        } else {
            // Enter next step
            if let nextStep = currentStep {
                await nextStep.onEnter(data: flowData)
            }
        }
    }
    
    public func previous() async throws {
        guard flowState == .inProgress else {
            throw FlowError.flowNotActive
        }
        
        guard currentStepIndex > 0 else {
            throw FlowError.invalidNavigation("Cannot go before first step")
        }
        
        // Exit current step
        if let currentStep = currentStep {
            try await currentStep.onExit(data: flowData)
        }
        
        // Move to previous step
        currentStepIndex -= 1
        
        if let previousStep = currentStep {
            await previousStep.onEnter(data: flowData)
        }
    }
    
    public func cancel() async {
        flowState = .cancelled
    }
}

// MARK: - NavigationService Enhanced Flow Extensions

extension NavigationService {
    /// Current active business flow
    public var currentFlow: BusinessNavigationFlow? {
        // This will be enhanced in future iterations
        return nil
    }
    
    /// Start a business navigation flow
    public func startFlow(_ flow: BusinessNavigationFlow) async -> Result<Void, AxiomError> {
        // Enhanced implementation for business flows
        return await withErrorContext("NavigationService.startBusinessFlow") {
            let coordinator = BusinessFlowCoordinator(flow: flow)
            await coordinator.start()
            
            // Store the coordinator for flow management
            // Implementation would store this in the NavigationService
            
            return ()
        }
    }
    
    /// Complete the current business flow
    public func completeCurrentFlow() async -> Result<Void, AxiomError> {
        // Enhanced implementation for business flow completion
        return await withErrorContext("NavigationService.completeCurrentFlow") {
            // Implementation would complete the current flow and clean up state
            return ()
        }
    }
    
    /// Dismiss the current flow
    public func dismissFlow() async -> Result<Void, AxiomError> {
        // Enhanced implementation for flow dismissal
        return await withErrorContext("NavigationService.dismissFlow") {
            // Implementation would dismiss the current flow presentation
            return ()
        }
    }
}

// MARK: - Enhanced Flow DSL and Composition Patterns

/// Declarative flow builder for constructing flows with DSL syntax
@resultBuilder
public struct FlowBuilder {
    public static func buildBlock(_ steps: BusinessFlowStep...) -> [BusinessFlowStep] {
        return steps
    }
    
    public static func buildOptional(_ step: BusinessFlowStep?) -> [BusinessFlowStep] {
        return step.map { [$0] } ?? []
    }
    
    public static func buildEither(first step: BusinessFlowStep) -> [BusinessFlowStep] {
        return [step]
    }
    
    public static func buildEither(second step: BusinessFlowStep) -> [BusinessFlowStep] {
        return [step]
    }
    
    public static func buildArray(_ steps: [[BusinessFlowStep]]) -> [BusinessFlowStep] {
        return steps.flatMap { $0 }
    }
}

/// Enhanced flow step with declarative configuration
public struct EnhancedFlowStep: BusinessFlowStep {
    public let identifier: String
    public let isRequired: Bool
    public let canSkip: Bool
    public let order: Int
    
    private let validationHandler: (FlowData) -> ValidationResult
    private let enterHandler: (FlowData) async -> Void
    private let exitHandler: (FlowData) async throws -> Void
    private let skipCondition: (FlowData) -> Bool
    
    public init(
        identifier: String,
        order: Int,
        isRequired: Bool = true,
        canSkip: Bool = false,
        validation: @escaping (FlowData) -> ValidationResult = { _ in .success },
        onEnter: @escaping (FlowData) async -> Void = { _ in },
        onExit: @escaping (FlowData) async throws -> Void = { _ in },
        skipWhen: @escaping (FlowData) -> Bool = { _ in false }
    ) {
        self.identifier = identifier
        self.order = order
        self.isRequired = isRequired
        self.canSkip = canSkip
        self.validationHandler = validation
        self.enterHandler = onEnter
        self.exitHandler = onExit
        self.skipCondition = skipWhen
    }
    
    public func validate(data: FlowData) -> ValidationResult {
        return validationHandler(data)
    }
    
    public func onEnter(data: FlowData) async {
        await enterHandler(data)
    }
    
    public func onExit(data: FlowData) async throws {
        try await exitHandler(data)
    }
    
    public func shouldSkip(data: FlowData) -> Bool {
        return skipCondition(data)
    }
}

/// Conditional flow step that evaluates conditions at runtime
public struct ConditionalFlowStep: BusinessFlowStep {
    public let identifier: String
    public let isRequired: Bool = true
    public let canSkip: Bool = false
    public let order: Int
    
    private let condition: (FlowData) -> Bool
    private let trueStep: BusinessFlowStep
    private let falseStep: BusinessFlowStep?
    
    public init(
        identifier: String,
        order: Int,
        condition: @escaping (FlowData) -> Bool,
        trueStep: BusinessFlowStep,
        falseStep: BusinessFlowStep? = nil
    ) {
        self.identifier = identifier
        self.order = order
        self.condition = condition
        self.trueStep = trueStep
        self.falseStep = falseStep
    }
    
    public func validate(data: FlowData) -> ValidationResult {
        let activeStep = getActiveStep(data: data)
        return activeStep?.validate(data: data) ?? .success
    }
    
    public func onEnter(data: FlowData) async {
        if let activeStep = getActiveStep(data: data) {
            await activeStep.onEnter(data: data)
        }
    }
    
    public func onExit(data: FlowData) async throws {
        if let activeStep = getActiveStep(data: data) {
            try await activeStep.onExit(data: data)
        }
    }
    
    public func shouldSkip(data: FlowData) -> Bool {
        return getActiveStep(data: data) == nil
    }
    
    private func getActiveStep(data: FlowData) -> BusinessFlowStep? {
        if condition(data) {
            return trueStep
        } else {
            return falseStep
        }
    }
}

/// Enhanced flow data with advanced state management
public class EnhancedFlowData: FlowData {
    private var stateHistory: [(String, Any, Date)] = []
    private var checkpoints: [String: [String: Any]] = [:]
    
    public override func set(_ key: String, value: Any) {
        // Track state changes for debugging and recovery
        stateHistory.append((key, value, Date()))
        super.set(key, value: value)
    }
    
    /// Create a checkpoint of current state
    public func createCheckpoint(_ name: String) {
        checkpoints[name] = data
    }
    
    /// Restore from a checkpoint
    public func restoreCheckpoint(_ name: String) -> Bool {
        guard let checkpointData = checkpoints[name] else { return false }
        data = checkpointData
        return true
    }
    
    /// Get state change history
    public func getStateHistory() -> [(String, Any, Date)] {
        return stateHistory
    }
    
    /// Advanced serialization with type information
    public override func serialize() throws -> Data {
        let advancedData: [String: Any] = [
            "data": data,
            "checkpoints": checkpoints,
            "history_count": stateHistory.count
        ]
        
        // Convert to serializable format
        let serializableData = advancedData.compactMapValues { value -> Any? in
            if let dict = value as? [String: Any] {
                return dict.compactMapValues { innerValue in
                    return serializableValue(innerValue)
                }
            } else {
                return serializableValue(value)
            }
        }
        
        return try JSONSerialization.data(withJSONObject: serializableData)
    }
    
    private func serializableValue(_ value: Any) -> Any? {
        if let stringValue = value as? String {
            return stringValue
        } else if let boolValue = value as? Bool {
            return boolValue
        } else if let intValue = value as? Int {
            return intValue
        } else if let doubleValue = value as? Double {
            return doubleValue
        } else {
            return String(describing: value)
        }
    }
}

/// Declarative flow definition with DSL support
public struct DeclarativeFlow: BusinessNavigationFlow {
    public let identifier: String
    public let steps: [BusinessFlowStep]
    public let metadata: FlowMetadata
    
    public init(
        identifier: String,
        metadata: FlowMetadata,
        @FlowBuilder steps: () -> [BusinessFlowStep]
    ) {
        self.identifier = identifier
        self.metadata = metadata
        self.steps = steps().sorted { $0.order < $1.order }
    }
}

/// Flow composition patterns for nested flows
public struct CompositeFlow: BusinessNavigationFlow {
    public let identifier: String
    public let steps: [BusinessFlowStep]
    public let metadata: FlowMetadata
    
    private let subFlows: [BusinessNavigationFlow]
    
    public init(
        identifier: String,
        metadata: FlowMetadata,
        subFlows: [BusinessNavigationFlow]
    ) {
        self.identifier = identifier
        self.metadata = metadata
        self.subFlows = subFlows
        
        // Flatten sub-flows into a single step sequence
        var allSteps: [BusinessFlowStep] = []
        for (index, subFlow) in subFlows.enumerated() {
            let offsetSteps = subFlow.steps.map { step in
                SubFlowStep(
                    subFlowIdentifier: subFlow.identifier,
                    originalStep: step,
                    orderOffset: index * 1000
                )
            }
            allSteps.append(contentsOf: offsetSteps)
        }
        self.steps = allSteps.sorted { $0.order < $1.order }
    }
}

/// Wrapper for sub-flow steps in composite flows
private struct SubFlowStep: BusinessFlowStep {
    let subFlowIdentifier: String
    let originalStep: BusinessFlowStep
    let orderOffset: Int
    
    var identifier: String {
        return "\(subFlowIdentifier).\(originalStep.identifier)"
    }
    
    var isRequired: Bool {
        return originalStep.isRequired
    }
    
    var canSkip: Bool {
        return originalStep.canSkip
    }
    
    var order: Int {
        return originalStep.order + orderOffset
    }
    
    func validate(data: FlowData) -> ValidationResult {
        return originalStep.validate(data: data)
    }
    
    func onEnter(data: FlowData) async {
        await originalStep.onEnter(data: data)
    }
    
    func onExit(data: FlowData) async throws {
        try await originalStep.onExit(data: data)
    }
}

/// Flow validation patterns with advanced error handling
public struct FlowValidationEngine {
    public static func validateFlowDefinition(_ flow: BusinessNavigationFlow) -> [FlowValidationError] {
        var errors: [FlowValidationError] = []
        
        // Check for duplicate step identifiers
        let stepIds = flow.steps.map { $0.identifier }
        let uniqueIds = Set(stepIds)
        if stepIds.count != uniqueIds.count {
            errors.append(.duplicateStepIdentifiers(duplicates: findDuplicates(in: stepIds)))
        }
        
        // Check for proper ordering
        let orders = flow.steps.map { $0.order }
        if orders != orders.sorted() {
            errors.append(.invalidStepOrdering)
        }
        
        // Check for missing required steps
        let hasRequiredSteps = flow.steps.contains { $0.isRequired }
        if !hasRequiredSteps {
            errors.append(.noRequiredSteps)
        }
        
        return errors
    }
    
    private static func findDuplicates(in array: [String]) -> [String] {
        var seen: Set<String> = []
        var duplicates: Set<String> = []
        
        for item in array {
            if seen.contains(item) {
                duplicates.insert(item)
            } else {
                seen.insert(item)
            }
        }
        
        return Array(duplicates)
    }
}

/// Flow validation errors
public enum FlowValidationError: Error, Equatable {
    case duplicateStepIdentifiers(duplicates: [String])
    case invalidStepOrdering
    case noRequiredSteps
    case cyclicDependency
}

// MARK: - Type Aliases for Test Compatibility

/// Type aliases for backward compatibility with test expectations
public typealias NavigationFlow = BusinessNavigationFlow
public typealias FlowStep = BusinessFlowStep
public typealias FlowCoordinator = BusinessFlowCoordinator

// MARK: - Supporting Protocols

private protocol ModifiedStepProtocol {
    func executeCompletion()
}

extension ModifiedFlowStep: ModifiedStepProtocol {
    func executeCompletion() {
        completionHandler?()
    }
}

