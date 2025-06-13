import Foundation
@testable import Axiom

// MARK: - Example Mock Implementations

/// Example of a manually created mock for TestService protocol
public class MockTestService: TestService {
    public let performActionMock = MockMethod<String, String>()
    public let getCountMock = MockMethod<Void, Int>()
    public let updateStateMock = MockMethod<Int, Void>()
    public let isActiveMock = MockProperty<Bool>()
    
    public init() {}
    
    public func performAction(_ action: String) async throws -> String {
        try await performActionMock.call(with: action)
    }
    
    public func getCount() async -> Int {
        (try? await getCountMock.call()) ?? 0
    }
    
    public func updateState(value: Int) async throws {
        try await updateStateMock.call(with: value)
    }
    
    public var isActive: Bool {
        get async {
            await isActiveMock.get()
        }
    }
    
    public func reset() {
        Task.detached { @Sendable [performActionMock, getCountMock, updateStateMock, isActiveMock] in
            await performActionMock.reset()
            await getCountMock.reset()
            await updateStateMock.reset()
            await isActiveMock.reset()
        }
    }
}

/// Example of a spy implementation
public class SpyTestService: TestService {
    private let wrapped: TestService
    public let performActionMock = MockMethod<String, String>()
    
    public init(wrapping service: TestService) {
        self.wrapped = service
    }
    
    public func performAction(_ action: String) async throws -> String {
        // Record the call
        _ = try? await performActionMock.call(with: action)
        
        // Pass through to wrapped service
        return try await wrapped.performAction(action)
    }
    
    public func getCount() async -> Int {
        await wrapped.getCount()
    }
    
    public func updateState(value: Int) async throws {
        try await wrapped.updateState(value: value)
    }
    
    public var isActive: Bool {
        get async {
            await wrapped.isActive
        }
    }
}

/// Example of a partial mock
public class PartialMockTestService: PartialMockBase<TestService>, TestService {
    private let realService: TestService
    public let performActionMock = MockMethod<String, String>()
    
    public init(realService: TestService = RealTestService()) {
        self.realService = realService
        super.init()
    }
    
    public func performAction(_ action: String) async throws -> String {
        if isMocked(.performAction) {
            return try await performActionMock.call(with: action)
        } else {
            return try await realService.performAction(action)
        }
    }
    
    public func getCount() async -> Int {
        // Always use real implementation for this method
        await realService.getCount()
    }
    
    public func updateState(value: Int) async throws {
        // Always use real implementation for this method
        try await realService.updateState(value: value)
    }
    
    public var isActive: Bool {
        get async {
            // Always use real implementation for this property
            await realService.isActive
        }
    }
}

// MARK: - Test Protocol Definitions

/// Example test service protocol (referenced in tests)
public protocol TestService {
    func performAction(_ action: String) async throws -> String
    func getCount() async -> Int
    func updateState(value: Int) async throws
    var isActive: Bool { get async }
}

/// Real implementation for testing
public class RealTestService: TestService {
    public init() {}
    
    public func performAction(_ action: String) async throws -> String {
        return "Real: \(action)"
    }
    
    public func getCount() async -> Int {
        return 42
    }
    
    public func updateState(value: Int) async throws {
        // Real implementation
    }
    
    public var isActive: Bool {
        get async { true }
    }
}

// MARK: - AutoMockable Examples

/// When @AutoMockable macro is implemented, this will generate MockTestDataSource
/// Deferred until AutoMockable macro is available in AxiomMacros module
// @AutoMockable
public protocol TestDataSource {
    func fetchData(id: String) async throws -> TestData
    func saveData(_ data: TestData) async throws
    func deleteData(id: String) async throws -> Bool
}

public struct TestData: Equatable, Sendable {
    public let id: String
    public let value: String
    public let timestamp: Date
    
    public init(id: String, value: String, timestamp: Date) {
        self.id = id
        self.value = value
        self.timestamp = timestamp
    }
}

/// Manual mock implementation (until macro generates it)
public class MockTestDataSource: TestDataSource {
    public let fetchDataMock = MockMethod<String, TestData>()
    public let saveDataMock = MockMethod<TestData, Void>()
    public let deleteDataMock = MockMethod<String, Bool>()
    
    public init() {}
    
    public func fetchData(id: String) async throws -> TestData {
        try await fetchDataMock.call(with: id)
    }
    
    public func saveData(_ data: TestData) async throws {
        try await saveDataMock.call(with: data)
    }
    
    public func deleteData(id: String) async throws -> Bool {
        try await deleteDataMock.call(with: id)
    }
    
    public func reset() {
        Task.detached { @Sendable [fetchDataMock, saveDataMock, deleteDataMock] in
            await fetchDataMock.reset()
            await saveDataMock.reset()
            await deleteDataMock.reset()
        }
    }
}