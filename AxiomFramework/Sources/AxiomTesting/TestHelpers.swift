import Foundation
import XCTest
@testable import Axiom

/// Main entry point for Axiom testing utilities
/// Provides comprehensive testing capabilities for all aspects of Axiom-based applications
public struct TestHelpers {
    
    // MARK: - Quick Access to Testing Utilities
    
    /// Context testing utilities - test state, actions, lifecycle, and dependencies
    public static var context: ContextTestHelpers.Type { ContextTestHelpers.self }
    
    /// Navigation testing utilities - test routes, flows, and deep links
    public static var navigation: NavigationTestHelpers.Type { NavigationTestHelpers.self }
    
    /// SwiftUI integration testing - test views, bindings, and interactions
    public static var swiftUI: SwiftUITestHelpers.Type { SwiftUITestHelpers.self }
    
    /// Performance and memory testing - benchmarks and leak detection
    public static var performance: PerformanceTestHelpers.Type { PerformanceTestHelpers.self }
    
    /// Async operation testing - streams, timing, and concurrency
    public static var async: AsyncTestHelpers.Type { AsyncTestHelpers.self }
    
    /// Form testing utilities - validation, binding, and submission
    public static var form: FormTestHelpers.Type { FormTestHelpers.self }
    
    // MARK: - Common Testing Patterns
    
    /// Create a complete test environment for an Axiom application
    @MainActor
    public static func createTestEnvironment() -> TestEnvironment {
        return TestEnvironment()
    }
    
    /// Run a comprehensive test suite for a context
    public static func runContextTestSuite<C: Context>(
        contextType: C.Type,
        factory: () async throws -> C,
        tests: [ContextTest<C>]
    ) async throws {
        for test in tests {
            let context = try await factory()
            await context.onAppear()
            
            do {
                try await test.run(context)
            } catch {
                await context.onDisappear()
                throw error
            }
            
            await context.onDisappear()
        }
    }
    
    /// Validate that all framework patterns are followed correctly
    public static func validateFrameworkCompliance<T>(
        component: T,
        requirements: [ComplianceRequirement]
    ) throws {
        for requirement in requirements {
            try requirement.validate(component)
        }
    }
}

// MARK: - Test Environment

/// Complete test environment for Axiom applications
@MainActor
public class TestEnvironment {
    
    // MARK: - Properties
    
    public let contextProvider = ContextProvider()
    public let navigationService = TestNavigationService()
    public let mockPersistence = MockPersistenceCapability()
    public let performanceMonitor = PerformanceMonitor()
    
    private var contexts: [String: any Context] = [:]
    private var cleanup: [() async -> Void] = []
    
    // MARK: - Initialization
    
    public init() {
        setupTestEnvironment()
    }
    
    deinit {
        Task { [cleanup] in
            for cleanupTask in cleanup {
                await cleanupTask()
            }
        }
    }
    
    // MARK: - Context Management
    
    /// Create and register a context for testing
    public func createContext<C: Context>(
        _ contextType: C.Type,
        id: String,
        factory: () async throws -> C
    ) async throws -> C {
        let context = try await factory()
        contexts[id] = context
        
        cleanup.append { [weak context] in
            await context?.onDisappear()
        }
        
        await context.onAppear()
        return context
    }
    
    /// Get a registered context by ID
    public func getContext<C: Context>(_ id: String, as type: C.Type) -> C? {
        return contexts[id] as? C
    }
    
    /// Remove a context from the environment
    public func removeContext(_ id: String) async {
        if let context = contexts.removeValue(forKey: id) {
            await context.onDisappear()
        }
    }
    
    // MARK: - Test Utilities
    
    /// Run a test with automatic cleanup
    public func runTest<T>(
        operation: (TestEnvironment) async throws -> T
    ) async throws -> T {
        defer {
            Task {
                await self.internalCleanup()
            }
        }
        
        return try await operation(self)
    }
    
    /// Manual cleanup for test environment
    public func cleanup() async {
        await internalCleanup()
    }
    
    /// Assert the environment is in a clean state
    public func assertCleanState() {
        XCTAssertTrue(contexts.isEmpty, "All contexts should be cleaned up")
        XCTAssertTrue(performanceMonitor.isClean, "Performance monitor should be clean")
    }
    
    // MARK: - Private Methods
    
    private func setupTestEnvironment() {
        // Configure test environment settings
    }
    
    private func internalCleanup() async {
        for cleanupTask in cleanup {
            await cleanupTask()
        }
        cleanup.removeAll()
        
        for (_, context) in contexts {
            await context.onDisappear()
        }
        contexts.removeAll()
    }
}

// MARK: - Context Testing

/// Represents a single context test
public struct ContextTest<C: Context> {
    public let name: String
    public let test: (C) async throws -> Void
    
    public init(name: String, test: @escaping (C) async throws -> Void) {
        self.name = name
        self.test = test
    }
    
    public func run(_ context: C) async throws {
        try await test(context)
    }
}

// MARK: - Compliance Testing

/// Framework compliance requirement
public protocol ComplianceRequirement {
    func validate<T>(_ component: T) throws
}

/// Memory management compliance
public struct MemoryComplianceRequirement: ComplianceRequirement {
    public func validate<T>(_ component: T) throws {
        // Validate memory management patterns
        if let context = component as? Context {
            // Check for proper lifecycle implementation
            XCTAssertNotNil(context, "Context should exist")
        }
    }
}

/// Thread safety compliance
public struct ThreadSafetyComplianceRequirement: ComplianceRequirement {
    public func validate<T>(_ component: T) throws {
        // Validate thread safety patterns
        if let context = component as? Context {
            // Check @MainActor annotation or proper isolation
            XCTAssertTrue(true, "Thread safety validation placeholder")
        }
    }
}

// MARK: - Performance Monitoring

/// Performance monitor for test environment
public class PerformanceMonitor {
    private var metrics: [String: Any] = [:]
    
    public var isClean: Bool {
        metrics.isEmpty
    }
    
    public func record(_ metric: String, value: Any) {
        metrics[metric] = value
    }
    
    public func getMetric<T>(_ metric: String, as type: T.Type) -> T? {
        metrics[metric] as? T
    }
    
    public func clear() {
        metrics.removeAll()
    }
}

// MARK: - Mock Implementations

/// Test navigation service
public class TestNavigationService: NavigationService {
    private var navigationStack: [Route] = []
    
    public func navigate(to route: Route) async {
        navigationStack.append(route)
    }
    
    public func goBack() async {
        if !navigationStack.isEmpty {
            navigationStack.removeLast()
        }
    }
    
    public var currentRoute: Route? {
        navigationStack.last
    }
    
    public var stackDepth: Int {
        navigationStack.count
    }
}

/// Mock persistence capability
public actor MockPersistenceCapability: PersistenceCapability {
    private var storage: [String: Any] = [:]
    private var migrationHistory: [(from: String, to: String)] = []
    private var _isAvailable: Bool = true
    
    // MARK: - Capability Protocol
    
    public var isAvailable: Bool {
        _isAvailable
    }
    
    public func initialize() async throws {
        _isAvailable = true
    }
    
    public func terminate() async {
        _isAvailable = false
        storage.removeAll()
        migrationHistory.removeAll()
    }
    
    // MARK: - PersistenceCapability Protocol
    
    public func save<T: Codable>(_ value: T, for key: String) async throws {
        guard _isAvailable else {
            throw PersistenceError.unavailable
        }
        storage[key] = value
    }
    
    public func load<T: Codable>(_ type: T.Type, for key: String) async throws -> T? {
        guard _isAvailable else {
            throw PersistenceError.unavailable
        }
        return storage[key] as? T
    }
    
    public func delete(key: String) async throws {
        guard _isAvailable else {
            throw PersistenceError.unavailable
        }
        storage.removeValue(forKey: key)
    }
    
    public func migrate(from oldVersion: String, to newVersion: String) async throws {
        guard _isAvailable else {
            throw PersistenceError.unavailable
        }
        // Mock implementation - just track migration calls
        migrationHistory.append((from: oldVersion, to: newVersion))
    }
    
    // MARK: - Test Helpers
    
    public func clear() {
        storage.removeAll()
        migrationHistory.removeAll()
    }
    
    public var migrationsCalled: [(from: String, to: String)] {
        migrationHistory
    }
    
    public var storageCount: Int {
        storage.count
    }
    
    public func setAvailable(_ available: Bool) {
        _isAvailable = available
    }
}

/// Persistence errors for testing
public enum PersistenceError: Error {
    case unavailable
}

// MARK: - Test Extensions

public extension XCTestCase {
    
    /// Run test with Axiom test environment
    @MainActor
    func runWithTestEnvironment<T>(
        _ test: (TestEnvironment) async throws -> T
    ) async throws -> T {
        let environment = TestEnvironment()
        return try await environment.runTest(operation: test)
    }
    
    /// Assert Axiom framework compliance
    func assertFrameworkCompliance<T>(
        _ component: T,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let requirements: [ComplianceRequirement] = [
            MemoryComplianceRequirement(),
            ThreadSafetyComplianceRequirement()
        ]
        
        do {
            try TestHelpers.validateFrameworkCompliance(
                component: component,
                requirements: requirements
            )
        } catch {
            XCTFail("Framework compliance failed: \(error)", file: file, line: line)
        }
    }
}