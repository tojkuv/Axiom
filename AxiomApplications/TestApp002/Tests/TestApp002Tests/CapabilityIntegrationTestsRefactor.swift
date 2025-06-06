import Testing
@testable import TestApp002Core
import Foundation

// REFACTOR Phase: Advanced fallback strategies and resilience patterns
@Suite("Capability Integration - REFACTOR Phase")
struct CapabilityIntegrationTestsRefactor {
    
    @Test("Circuit breaker pattern prevents cascade failures")
    func testCircuitBreakerPreventsCascadeFailures() async throws {
        // REFACTOR: Circuit breaker isolates failing capabilities
        let circuitBreaker = CapabilityCircuitBreaker()
        let failingCapability = MockConsistentlyFailingCapability()
        let taskClient = TaskClient()
        
        await taskClient.setStorageCapability(CircuitBreakerStorageCapability(
            underlying: failingCapability,
            circuitBreaker: circuitBreaker
        ))
        
        // First few failures should try the capability
        for i in 0..<5 {
            do {
                try await taskClient.process(.create(Task(
                    id: "\(i)",
                    title: "Task \(i)",
                    description: "Test",
                    dueDate: nil,
                    priority: .medium,
                    categoryId: nil,
                    isCompleted: false,
                    createdAt: Date(),
                    updatedAt: Date()
                )))
            } catch {
                // Expected failures
            }
        }
        
        // Circuit breaker should open after consecutive failures
        let state = await circuitBreaker.getState()
        #expect(state == .open, "Circuit breaker should open after consecutive failures")
        
        // Further requests should fail fast without hitting the capability
        let startTime = Date()
        do {
            try await taskClient.process(.create(Task(
                id: "fast-fail",
                title: "Fast Fail",
                description: "Test",
                dueDate: nil,
                priority: .medium,
                categoryId: nil,
                isCompleted: false,
                createdAt: Date(),
                updatedAt: Date()
            )))
        } catch {
            let elapsed = Date().timeIntervalSince(startTime)
            #expect(elapsed < 0.01, "Should fail fast when circuit breaker is open")
        }
        
        // Capability access count should not increase when circuit is open
        let finalCount = await failingCapability.getAccessCount()
        #expect(finalCount <= 5, "Capability should not be accessed when circuit is open")
    }
    
    @Test("Retry mechanism with exponential backoff handles transient failures")
    func testRetryMechanismWithExponentialBackoff() async throws {
        // REFACTOR: Intelligent retry with exponential backoff
        let retryManager = CapabilityRetryManager()
        let intermittentCapability = MockIntermittentFailureCapability()
        let syncClient = SyncClient()
        
        await syncClient.setNetworkCapability(RetryNetworkCapability(
            underlying: intermittentCapability,
            retryManager: retryManager
        ))
        
        // Set up intermittent failures (fail first 2 attempts, succeed on 3rd)
        await intermittentCapability.setFailurePattern([true, true, false])
        
        let startTime = Date()
        try await syncClient.process(.startSync)
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Should eventually succeed after retries
        let state = await syncClient.currentState
        #expect(state.isSyncing, "Should be syncing after successful retry")
        
        // Verify retry timing follows exponential backoff
        let attempts = await retryManager.getAttemptHistory()
        #expect(attempts.count == 3, "Should have made 3 attempts")
        #expect(elapsed >= 0.3, "Should have exponential delays: 100ms + 200ms + success")
        #expect(elapsed < 1.0, "Should not take too long with reasonable backoff")
    }
    
    @Test("Graceful degradation provides alternative functionality")
    func testGracefulDegradationProvidesAlternatives() async throws {
        // REFACTOR: Multiple fallback levels
        let degradationManager = GracefulDegradationManager()
        let taskClient = TaskClient()
        
        // Primary: Full storage capability (fails)
        // Secondary: In-memory storage (works)
        // Tertiary: Log-only storage (always works)
        let primaryStorage = MockFailingStorageCapability()
        let secondaryStorage = MockInMemoryStorageCapability()
        let tertiaryStorage = MockLogOnlyStorageCapability()
        
        await taskClient.setStorageCapability(DegradedStorageCapability(
            primary: primaryStorage,
            secondary: secondaryStorage,
            tertiary: tertiaryStorage,
            degradationManager: degradationManager
        ))
        
        // Create tasks - should succeed with secondary storage
        for i in 1...3 {
            try await taskClient.process(.create(Task(
                id: "\(i)",
                title: "Task \(i)",
                description: "Test",
                dueDate: nil,
                priority: .medium,
                categoryId: nil,
                isCompleted: false,
                createdAt: Date(),
                updatedAt: Date()
            )))
        }
        
        let state = await taskClient.currentState
        #expect(state.tasks.count == 3, "Should create tasks with degraded storage")
        
        // Verify degradation level
        let currentLevel = await degradationManager.getCurrentLevel()
        #expect(currentLevel == .secondary, "Should be using secondary storage")
        
        // Verify secondary storage was used
        let secondaryItems = await secondaryStorage.getStoredCount()
        #expect(secondaryItems == 3, "Secondary storage should have all items")
    }
    
    @Test("Capability health monitoring triggers automatic recovery")
    func testCapabilityHealthMonitoringTriggersRecovery() async throws {
        // REFACTOR: Proactive health monitoring and recovery
        let healthMonitor = CapabilityHealthMonitor()
        let recoveringCapability = MockRecoveringCapability()
        let taskClient = TaskClient()
        
        await taskClient.setStorageCapability(HealthMonitoredStorageCapability(
            underlying: recoveringCapability,
            healthMonitor: healthMonitor
        ))
        
        // Start with failing capability
        await recoveringCapability.setHealthy(false)
        
        // Attempt operations - should fail initially
        do {
            try await taskClient.process(.create(Task(
                id: "1",
                title: "Initial Task",
                description: "Test",
                dueDate: nil,
                priority: .medium,
                categoryId: nil,
                isCompleted: false,
                createdAt: Date(),
                updatedAt: Date()
            )))
        } catch {
            // Expected failure
        }
        
        // Simulate capability recovery
        await recoveringCapability.setHealthy(true)
        
        // Health monitor should detect recovery and retry
        try await _Concurrency.Task.sleep(nanoseconds: 200_000_000) // 200ms for health check
        
        // Now operations should succeed
        try await taskClient.process(.create(Task(
            id: "2",
            title: "Recovery Task",
            description: "Test",
            dueDate: nil,
            priority: .medium,
            categoryId: nil,
            isCompleted: false,
            createdAt: Date(),
            updatedAt: Date()
        )))
        
        let state = await taskClient.currentState
        #expect(state.tasks.count >= 1, "Should create tasks after recovery")
        
        // Verify health monitoring worked
        let healthHistory = await healthMonitor.getHealthHistory()
        #expect(healthHistory.contains { !$0 }, "Should have recorded unhealthy state")
        #expect(healthHistory.contains { $0 }, "Should have recorded recovery")
    }
    
    @Test("Adaptive capability selection optimizes for performance")
    func testAdaptiveCapabilitySelectionOptimizesPerformance() async throws {
        // REFACTOR: Performance-based capability selection
        let performanceMonitor = CapabilityPerformanceMonitor()
        let fastCapability = MockFastStorageCapability()
        let slowCapability = MockSlowStorageCapability()
        let syncClient = SyncClient()
        
        await syncClient.setStorageCapability(AdaptiveStorageCapability(
            capabilities: [fastCapability, slowCapability],
            performanceMonitor: performanceMonitor
        ))
        
        // Perform several operations to gather performance data
        for i in 1...10 {
            // Simulate different sync operations
            if i % 2 == 0 {
                try await syncClient.process(.startSync)
                try await syncClient.process(.resolveConflict(conflictId: "conflict-\(i)", resolution: .useLocal))
            }
        }
        
        // Check performance metrics
        let metrics = await performanceMonitor.getMetrics()
        #expect(metrics.count >= 2, "Should have metrics for both capabilities")
        
        // Fast capability should be preferred
        let selectedCapability = await performanceMonitor.getPreferredCapability()
        #expect(selectedCapability == "fast", "Should prefer fast capability")
        
        // Verify load balancing
        let fastOps = await fastCapability.getOperationCount()
        let slowOps = await slowCapability.getOperationCount()
        #expect(fastOps > slowOps, "Fast capability should handle more operations")
    }
    
    @Test("Capability composition enables complex workflows")
    func testCapabilityCompositionEnablesComplexWorkflows() async throws {
        // REFACTOR: Compose multiple capabilities for enhanced functionality
        let encryptionCapability = MockEncryptionCapability()
        let compressionCapability = MockCompressionCapability()
        let baseStorage = MockInMemoryStorageCapability()
        
        let composedCapability = ComposedStorageCapability()
        await composedCapability.addLayer(encryptionCapability)
        await composedCapability.addLayer(compressionCapability)
        await composedCapability.setBaseCapability(baseStorage)
        
        let taskClient = TaskClient()
        await taskClient.setStorageCapability(composedCapability)
        
        // Create a task - should be encrypted and compressed
        let largeTask = Task(
            id: "1",
            title: "Large Task",
            description: String(repeating: "Large description ", count: 100), // Create large content
            dueDate: nil,
            priority: .medium,
            categoryId: nil,
            isCompleted: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await taskClient.process(.create(largeTask))
        
        // Verify composition worked
        let encryptionStats = await encryptionCapability.getStats()
        #expect(encryptionStats.itemsEncrypted == 1, "Should have encrypted the task")
        
        let compressionStats = await compressionCapability.getStats()
        #expect(compressionStats.itemsCompressed == 1, "Should have compressed the task")
        #expect(compressionStats.compressionRatio > 0.5, "Should achieve significant compression")
        
        let state = await taskClient.currentState
        #expect(state.tasks.count == 1, "Should retrieve and decrypt task correctly")
        #expect(state.tasks.first?.description == largeTask.description, "Should preserve original content")
    }
    
    @Test("Capability isolation prevents cross-contamination")
    func testCapabilityIsolationPreventsContamination() async throws {
        // REFACTOR: Strict capability isolation
        let isolationManager = CapabilityIsolationManager()
        let isolatedCapability1 = MockIsolatedCapability(id: "cap1")
        let isolatedCapability2 = MockIsolatedCapability(id: "cap2")
        
        let taskClient1 = TaskClient()
        let taskClient2 = TaskClient()
        
        await taskClient1.setStorageCapability(IsolatedStorageCapability(
            underlying: isolatedCapability1,
            isolationManager: isolationManager,
            namespace: "client1"
        ))
        
        await taskClient2.setStorageCapability(IsolatedStorageCapability(
            underlying: isolatedCapability2,
            isolationManager: isolationManager,
            namespace: "client2"
        ))
        
        // Create tasks in both clients
        try await taskClient1.process(.create(Task(
            id: "1",
            title: "Client 1 Task",
            description: "Test",
            dueDate: nil,
            priority: .medium,
            categoryId: nil,
            isCompleted: false,
            createdAt: Date(),
            updatedAt: Date()
        )))
        
        try await taskClient2.process(.create(Task(
            id: "2",
            title: "Client 2 Task",
            description: "Test",
            dueDate: nil,
            priority: .medium,
            categoryId: nil,
            isCompleted: false,
            createdAt: Date(),
            updatedAt: Date()
        )))
        
        // Verify isolation
        let state1 = await taskClient1.currentState
        let state2 = await taskClient2.currentState
        
        #expect(state1.tasks.count == 1, "Client 1 should have 1 task")
        #expect(state2.tasks.count == 1, "Client 2 should have 1 task")
        #expect(state1.tasks.first?.title == "Client 1 Task", "Client 1 should see only its task")
        #expect(state2.tasks.first?.title == "Client 2 Task", "Client 2 should see only its task")
        
        // Verify no cross-contamination at capability level
        let cap1Namespaces = await isolatedCapability1.getNamespaces()
        let cap2Namespaces = await isolatedCapability2.getNamespaces()
        
        #expect(cap1Namespaces.contains("client1"), "Capability 1 should handle client1 namespace")
        #expect(!cap1Namespaces.contains("client2"), "Capability 1 should not see client2 namespace")
        #expect(cap2Namespaces.contains("client2"), "Capability 2 should handle client2 namespace")
        #expect(!cap2Namespaces.contains("client1"), "Capability 2 should not see client1 namespace")
    }
    
    @Test("Capability versioning enables seamless upgrades")
    func testCapabilityVersioningEnablesSeamlessUpgrades() async throws {
        // REFACTOR: Versioned capability upgrades
        let versionManager = CapabilityVersionManager()
        let v1Capability = MockVersionedStorageCapabilityRefactor(version: "1.0")
        let v2Capability = MockVersionedStorageCapabilityRefactor(version: "2.0")
        
        let taskClient = TaskClient()
        await taskClient.setStorageCapability(VersionedStorageCapability(
            currentVersion: v1Capability,
            versionManager: versionManager
        ))
        
        // Create data with v1 capability
        try await taskClient.process(.create(Task(
            id: "1",
            title: "V1 Task",
            description: "Test",
            dueDate: nil,
            priority: .medium,
            categoryId: nil,
            isCompleted: false,
            createdAt: Date(),
            updatedAt: Date()
        )))
        
        // Upgrade to v2 capability
        let versionedCapability = await taskClient.storageCapability as! VersionedStorageCapability
        await versionedCapability.upgradeToVersion(v2Capability)
        
        // Create data with v2 capability
        try await taskClient.process(.create(Task(
            id: "2",
            title: "V2 Task",
            description: "Test",
            dueDate: nil,
            priority: .medium,
            categoryId: nil,
            isCompleted: false,
            createdAt: Date(),
            updatedAt: Date()
        )))
        
        // Verify seamless upgrade
        let state = await taskClient.currentState
        #expect(state.tasks.count == 2, "Should have both v1 and v2 tasks")
        
        // Verify migration occurred
        let migrationStatus = await versionManager.getMigrationStatus()
        #expect(migrationStatus.wasSuccessful, "Migration should be successful")
        #expect(migrationStatus.migratedItems == 1, "Should have migrated 1 item from v1 to v2")
        
        // Verify v2 capability is active
        let currentVersion = await versionedCapability.getCurrentVersion()
        #expect(currentVersion == "2.0", "Should be using v2 capability")
    }
}

// MARK: - Advanced Capability Implementations

// Circuit Breaker Pattern
actor CapabilityCircuitBreaker {
    enum State {
        case closed, open, halfOpen
    }
    
    private var state: State = .closed
    private var failureCount = 0
    private var lastFailureTime: Date?
    private let failureThreshold = 3
    private let timeout: TimeInterval = 10.0
    
    func execute<T: Sendable>(_ operation: @Sendable () async throws -> T) async throws -> T {
        switch state {
        case .closed:
            do {
                let result = try await operation()
                reset()
                return result
            } catch {
                await recordFailure()
                throw error
            }
        case .open:
            if let lastFailure = lastFailureTime,
               Date().timeIntervalSince(lastFailure) > timeout {
                state = .halfOpen
                return try await execute(operation)
            } else {
                throw CircuitBreakerError.circuitOpen
            }
        case .halfOpen:
            do {
                let result = try await operation()
                reset()
                return result
            } catch {
                state = .open
                lastFailureTime = Date()
                throw error
            }
        }
    }
    
    private func recordFailure() async {
        failureCount += 1
        lastFailureTime = Date()
        if failureCount >= failureThreshold {
            state = .open
        }
    }
    
    private func reset() {
        state = .closed
        failureCount = 0
        lastFailureTime = nil
    }
    
    func getState() async -> State {
        return state
    }
}

// Retry Manager with Exponential Backoff
actor CapabilityRetryManager {
    private var attemptHistory: [Date] = []
    private let maxRetries = 3
    private let baseDelay: TimeInterval = 0.1
    
    func executeWithRetry<T: Sendable>(_ operation: @Sendable () async throws -> T) async throws -> T {
        attemptHistory.removeAll()
        
        for attempt in 0..<maxRetries {
            attemptHistory.append(Date())
            
            do {
                return try await operation()
            } catch {
                if attempt == maxRetries - 1 {
                    throw error
                }
                
                let delay = baseDelay * pow(2.0, Double(attempt))
                try await _Concurrency.Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        fatalError("Should not reach here")
    }
    
    func getAttemptHistory() async -> [Date] {
        return attemptHistory
    }
}

// Graceful Degradation Manager
actor GracefulDegradationManager {
    enum DegradationLevel {
        case primary, secondary, tertiary
    }
    
    private var currentLevel: DegradationLevel = .primary
    
    func getCurrentLevel() async -> DegradationLevel {
        return currentLevel
    }
    
    func degradeTo(_ level: DegradationLevel) async {
        currentLevel = level
    }
}

// Health Monitor
actor CapabilityHealthMonitor {
    private var healthHistory: [Bool] = []
    private var lastHealthCheck: Date?
    private let healthCheckInterval: TimeInterval = 0.1
    
    func recordHealth(_ isHealthy: Bool) async {
        healthHistory.append(isHealthy)
        lastHealthCheck = Date()
    }
    
    func shouldCheckHealth() async -> Bool {
        guard let lastCheck = lastHealthCheck else { return true }
        return Date().timeIntervalSince(lastCheck) > healthCheckInterval
    }
    
    func getHealthHistory() async -> [Bool] {
        return healthHistory
    }
}

// Performance Monitor
actor CapabilityPerformanceMonitor {
    struct PerformanceMetrics {
        let capabilityId: String
        let averageLatency: TimeInterval
        let operationCount: Int
    }
    
    private var metrics: [String: PerformanceMetrics] = [:]
    private var preferredCapability: String = ""
    
    func recordOperation(capabilityId: String, latency: TimeInterval) async {
        if let existing = metrics[capabilityId] {
            let totalLatency = existing.averageLatency * Double(existing.operationCount) + latency
            let newCount = existing.operationCount + 1
            metrics[capabilityId] = PerformanceMetrics(
                capabilityId: capabilityId,
                averageLatency: totalLatency / Double(newCount),
                operationCount: newCount
            )
        } else {
            metrics[capabilityId] = PerformanceMetrics(
                capabilityId: capabilityId,
                averageLatency: latency,
                operationCount: 1
            )
        }
        
        // Update preferred capability
        if let best = metrics.values.min(by: { $0.averageLatency < $1.averageLatency }) {
            preferredCapability = best.capabilityId
        }
    }
    
    func getMetrics() async -> [PerformanceMetrics] {
        return Array(metrics.values)
    }
    
    func getPreferredCapability() async -> String {
        return preferredCapability
    }
}

// Isolation Manager
actor CapabilityIsolationManager {
    private var namespaceMap: [String: Set<String>] = [:]
    
    func registerNamespace(_ namespace: String, for capabilityId: String) async {
        if namespaceMap[capabilityId] == nil {
            namespaceMap[capabilityId] = Set()
        }
        namespaceMap[capabilityId]?.insert(namespace)
    }
    
    func getNamespaces(for capabilityId: String) async -> Set<String> {
        return namespaceMap[capabilityId] ?? Set()
    }
}

// Version Manager
actor CapabilityVersionManager {
    struct MigrationStatus {
        let wasSuccessful: Bool
        let migratedItems: Int
    }
    
    private var migrationStatus = MigrationStatus(wasSuccessful: false, migratedItems: 0)
    
    func performMigration(itemCount: Int) async {
        migrationStatus = MigrationStatus(wasSuccessful: true, migratedItems: itemCount)
    }
    
    func getMigrationStatus() async -> MigrationStatus {
        return migrationStatus
    }
}

// MARK: - Supporting Types and Errors

enum CapabilityIntegrationError: Error {
    case allCapabilitiesFailed
    case degradationLimitReached
    case isolationViolation
}

// MARK: - Mock Implementations for REFACTOR Phase

actor MockConsistentlyFailingCapability: StorageCapability {
    var isAvailable: Bool { return true }
    func initialize() async throws {}
    func terminate() async {}
    
    private var accessCount = 0
    
    func save<T: Codable>(_ object: T, key: String) async throws {
        accessCount += 1
        throw StorageError.writeFailure
    }
    
    func load<T: Codable>(_ type: T.Type, key: String) async throws -> T? {
        accessCount += 1
        throw StorageError.readFailure
    }
    
    func delete(key: String) async throws {
        accessCount += 1
        throw StorageError.writeFailure
    }
    
    func loadAll<T: Codable>(_ type: T.Type) async throws -> [T] {
        accessCount += 1
        throw StorageError.readFailure
    }
    
    func deleteAll() async throws {
        accessCount += 1
        throw StorageError.writeFailure
    }
    
    func getAccessCount() async -> Int {
        return accessCount
    }
}

// Additional mock implementations would go here...
// For brevity, I'll include just the key ones needed for the tests

actor MockIntermittentFailureCapability: NetworkCapability {
    var isAvailable: Bool { return true }
    func initialize() async throws {}
    func terminate() async {}
    
    private var failurePattern: [Bool] = []
    private var currentIndex = 0
    
    func setFailurePattern(_ pattern: [Bool]) async {
        failurePattern = pattern
        currentIndex = 0
    }
    
    func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        defer { currentIndex += 1 }
        
        if currentIndex < failurePattern.count && failurePattern[currentIndex] {
            throw NetworkError.timeout
        }
        
        // Return success response
        if T.self == String.self {
            return "success" as! T
        }
        fatalError("Unsupported type in mock")
    }
    
    func upload<T: Encodable & Sendable>(_ data: T, to endpoint: Endpoint) async throws {
        // Similar logic
    }
}

// Placeholder for additional mock implementations
// In a real implementation, these would be fully implemented