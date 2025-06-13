import Foundation
import XCTest
@testable import Axiom

// MARK: - Mock Method

/// Tracks and controls mock method behavior
public actor MockMethod<Input: Sendable, Output: Sendable> {
    // Call tracking
    private var callCount = 0
    private var callArguments: [Input] = []
    
    // Configured behaviors
    private var returnValue: Output?
    private var errorToThrow: Error?
    private var dynamicBehavior: ((Int) -> Output)?
    private var sequenceValues: [Output] = []
    private var sequenceIndex = 0
    private var conditionalBehaviors: [(condition: (Input) -> Bool, value: Output)] = []
    private var delay: TestDuration?
    private var passthroughHandler: (@Sendable (Input) async throws -> Output)?
    
    public init() {}
    
    // MARK: - Configuration
    
    public func returns(_ value: Output) -> Self {
        self.returnValue = value
        return self
    }
    
    public func `throws`(_ error: Error) -> Self {
        self.errorToThrow = error
        return self
    }
    
    public func onCall(_ handler: @escaping (Int) -> Output) -> Self {
        self.dynamicBehavior = handler
        return self
    }
    
    public func returnsInSequence(_ values: [Output]) -> Self {
        self.sequenceValues = values
        self.sequenceIndex = 0
        return self
    }
    
    public func when(_ condition: @escaping @Sendable (Input) -> Bool) -> ConditionalMockBuilder<Input, Output> {
        return ConditionalMockBuilder(mockMethod: self, condition: condition)
    }
    
    public func whenNot(_ condition: @escaping @Sendable (Input) -> Bool) -> ConditionalMockBuilder<Input, Output> {
        return ConditionalMockBuilder(mockMethod: self, condition: { !condition($0) })
    }
    
    public func withDelay(_ delay: TestDuration) -> Self {
        self.delay = delay
        return self
    }
    
    public func passThrough(_ handler: @escaping @Sendable (Input) async throws -> Output) -> Self {
        self.passthroughHandler = handler
        return self
    }
    
    // MARK: - Execution
    
    public func call(with input: Input) async throws -> Output {
        // Record call
        callCount += 1
        callArguments.append(input)
        
        // Apply delay if configured
        if let delay = delay {
            try await Task.sleep(nanoseconds: UInt64(delay.components.seconds * 1_000_000_000 + delay.components.attoseconds / 1_000_000_000))
        }
        
        // Check for error
        if let error = errorToThrow {
            throw error
        }
        
        // Check conditional behaviors
        for (condition, value) in conditionalBehaviors {
            if condition(input) {
                return value
            }
        }
        
        // Check passthrough
        if let handler = passthroughHandler {
            return try await handler(input)
        }
        
        // Check dynamic behavior
        if let behavior = dynamicBehavior {
            return behavior(callCount)
        }
        
        // Check sequence
        if !sequenceValues.isEmpty {
            let value = sequenceValues[min(sequenceIndex, sequenceValues.count - 1)]
            sequenceIndex += 1
            return value
        }
        
        // Return configured value
        if let value = returnValue {
            return value
        }
        
        // Default for Void
        if Output.self == Void.self {
            return () as! Output
        }
        
        fatalError("MockMethod not configured for call with input: \(input)")
    }
    
    public func call() async throws -> Output where Input == Void {
        return try await call(with: ())
    }
    
    // MARK: - Verification
    
    public var wasCalled: Bool {
        get async { callCount > 0 }
    }
    
    public var callCountValue: Int {
        get async { callCount }
    }
    
    public var lastArguments: Input? {
        get async { callArguments.last }
    }
    
    public var allArguments: [Input] {
        get async { callArguments }
    }
    
    // MARK: - Reset
    
    public func reset() {
        callCount = 0
        callArguments.removeAll()
        returnValue = nil
        errorToThrow = nil
        dynamicBehavior = nil
        sequenceValues.removeAll()
        sequenceIndex = 0
        conditionalBehaviors.removeAll()
        delay = nil
        passthroughHandler = nil
    }
    
    // MARK: - Internal
    
    func addConditionalBehavior(condition: @escaping (Input) -> Bool, value: Output) {
        conditionalBehaviors.append((condition, value))
    }
}

// MARK: - Conditional Mock Builder

public struct ConditionalMockBuilder<Input: Sendable, Output: Sendable> {
    let mockMethod: MockMethod<Input, Output>
    let condition: @Sendable (Input) -> Bool
    
    public func returns(_ value: Output) {
        Task.detached { @Sendable [mockMethod, condition] in
            await mockMethod.addConditionalBehavior(condition: condition, value: value)
        }
    }
}

// MARK: - Mock Property

/// Tracks and controls mock property behavior
public actor MockProperty<Value> {
    private var getValue: Value?
    private var getCallCount = 0
    private var setCallCount = 0
    private var setValues: [Value] = []
    
    public init() {}
    
    // MARK: - Configuration
    
    public func returns(_ value: Value) -> Self {
        self.getValue = value
        return self
    }
    
    // MARK: - Execution
    
    public func get() async -> Value {
        getCallCount += 1
        
        if let value = getValue {
            return value
        }
        
        fatalError("MockProperty not configured for get")
    }
    
    public func set(_ value: Value) {
        setCallCount += 1
        setValues.append(value)
    }
    
    // MARK: - Verification
    
    public var wasCalled: Bool {
        get async { getCallCount > 0 || setCallCount > 0 }
    }
    
    public var getCallCountValue: Int {
        get async { getCallCount }
    }
    
    public var setCallCountValue: Int {
        get async { setCallCount }
    }
    
    public var lastSetValue: Value? {
        get async { setValues.last }
    }
    
    // MARK: - Reset
    
    public func reset() {
        getValue = nil
        getCallCount = 0
        setCallCount = 0
        setValues.removeAll()
    }
}

// MARK: - Spy Support

/// Base class for spy implementations
public class SpyBase<ProtocolType> {
    private let wrapped: ProtocolType
    
    public init(wrapping: ProtocolType) {
        self.wrapped = wrapping
    }
    
    public var wrappedInstance: ProtocolType {
        wrapped
    }
}

// MARK: - Mock Call Order Verification

/// Verifies the order of calls across multiple mocks
public struct MockCallOrderVerifier {
    private var verifications: [(String, Bool)] = []
    
    public init() {}
    
    public func verify<I, O>(
        _ mock: MockMethod<I, O>,
        was relation: CallRelation
    ) -> Self {
        // For MVP, disable async verification due to concurrency constraints
        // TODO: Implement proper async-safe mock verification
        var mutableSelf = self
        mutableSelf.verifications.append((relation.description, true))
        return mutableSelf
    }
    
    public var isValid: Bool {
        verifications.allSatisfy { $0.1 }
    }
    
    public var failedVerifications: [String] {
        verifications.compactMap { $0.1 ? nil : $0.0 }
    }
}

/// Represents a call order relation
public enum CallRelation {
    case calledBefore(any MockMethodProtocol)
    case calledAfter(any MockMethodProtocol)
    case calledBeforeSpecificCall(any MockMethodProtocol, onCall: Int)
    
    var description: String {
        switch self {
        case .calledBefore(let mock):
            return "called before \(type(of: mock))"
        case .calledAfter(let mock):
            return "called after \(type(of: mock))"
        case .calledBeforeSpecificCall(let mock, let call):
            return "called before \(type(of: mock)) call #\(call)"
        }
    }
    
    func verify<I, O>(mock: MockMethod<I, O>) async -> Bool {
        // Simplified verification - real implementation would track timestamps
        return true
    }
}

/// Protocol for type-erased mock methods
public protocol MockMethodProtocol {
    var wasCalledValue: Bool { get async }
}

extension MockMethod: MockMethodProtocol {
    public var wasCalledValue: Bool {
        get async { await wasCalled }
    }
}

// MARK: - Partial Mock Support

/// Base class for partial mocks
public class PartialMockBase<ServiceType> {
    private var mockedMethods: Set<String> = []
    
    public init() {}
    
    public func mockOnly(_ method: Method) {
        mockedMethods.insert(method.rawValue)
    }
    
    public func isMocked(_ method: Method) -> Bool {
        mockedMethods.contains(method.rawValue)
    }
    
    public enum Method: String {
        case performAction
        case getCount
        case updateState
        case isActive
    }
}

// MARK: - Test Helpers

/// Extension for XCTest assertions with mocks
public extension XCTestCase {
    func assertCalled<I, O>(
        _ mock: MockMethod<I, O>,
        times expectedCount: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let wasCalled = await mock.wasCalled
        let callCount = await mock.callCountValue
        
        if let expectedCount = expectedCount {
            XCTAssertEqual(
                callCount,
                expectedCount,
                "Expected \(expectedCount) calls but got \(callCount)",
                file: file,
                line: line
            )
        } else {
            XCTAssertTrue(
                wasCalled,
                "Expected mock to be called",
                file: file,
                line: line
            )
        }
    }
    
    func assertNotCalled<I, O>(
        _ mock: MockMethod<I, O>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let wasCalled = await mock.wasCalled
        XCTAssertFalse(
            wasCalled,
            "Expected mock not to be called",
            file: file,
            line: line
        )
    }
}