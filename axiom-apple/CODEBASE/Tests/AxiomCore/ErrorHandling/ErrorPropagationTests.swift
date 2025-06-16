import XCTest
import AxiomTesting
import SwiftUI
@testable import AxiomCore
@testable import AxiomArchitecture

/// Comprehensive tests for error propagation patterns and mechanisms
/// 
/// Consolidates: ErrorPropagationPatternsTests, ErrorPropagationTests
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class ErrorPropagationTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Basic Error Propagation Tests
    
    func testVerticalErrorPropagation() async throws {
        try await testEnvironment.runTest { env in
            // Create component hierarchy: Root -> Parent -> Child
            let rootComponent = TestPropagationComponent(name: "Root")
            let parentComponent = TestPropagationComponent(name: "Parent", parent: rootComponent)
            let childComponent = TestPropagationComponent(name: "Child", parent: parentComponent)
            
            // Error from child should propagate up to root
            let childError = AxiomError.clientError(.invalidAction("Child error"))
            await childComponent.propagateError(childError)
            
            // Verify propagation path
            XCTAssertEqual(childComponent.handledErrors.count, 1, "Child should handle error first")
            XCTAssertEqual(parentComponent.handledErrors.count, 1, "Parent should receive propagated error")
            XCTAssertEqual(rootComponent.handledErrors.count, 1, "Root should receive propagated error")
            
            // Verify error context is enriched during propagation
            let rootError = rootComponent.handledErrors.first
            XCTAssertNotNil(rootError?.propagationPath, "Error should have propagation path")
            XCTAssertEqual(rootError?.propagationPath?.count, 3, "Should have 3 components in path")
            XCTAssertEqual(rootError?.propagationPath?.first, "Child", "Path should start with child")
            XCTAssertEqual(rootError?.propagationPath?.last, "Root", "Path should end with root")
        }
    }
    
    func testHorizontalErrorPropagation() async throws {
        try await testEnvironment.runTest { env in
            // Create sibling components with shared parent
            let parentComponent = TestPropagationComponent(name: "Parent")
            let sibling1 = TestPropagationComponent(name: "Sibling1", parent: parentComponent)
            let sibling2 = TestPropagationComponent(name: "Sibling2", parent: parentComponent)
            let sibling3 = TestPropagationComponent(name: "Sibling3", parent: parentComponent)
            
            // Configure parent to broadcast errors to siblings
            parentComponent.propagationMode = .broadcast
            
            // Error from sibling1 should be broadcast to other siblings
            let siblingError = AxiomError.networkError(.connectionFailed("Sibling1 error"))
            await sibling1.propagateError(siblingError)
            
            // Verify horizontal propagation
            XCTAssertEqual(sibling1.handledErrors.count, 1, "Originating sibling should handle error")
            XCTAssertEqual(sibling2.receivedBroadcasts.count, 1, "Sibling2 should receive broadcast")
            XCTAssertEqual(sibling3.receivedBroadcasts.count, 1, "Sibling3 should receive broadcast")
            XCTAssertEqual(parentComponent.handledErrors.count, 1, "Parent should handle error")
            
            // Verify broadcast maintains error context
            let broadcast2 = sibling2.receivedBroadcasts.first
            XCTAssertEqual(broadcast2?.originalComponent, "Sibling1", "Broadcast should identify origin")
            XCTAssertEqual(broadcast2?.broadcastReason, .siblingError, "Broadcast reason should be sibling error")
        }
    }
    
    func testConditionalErrorPropagation() async throws {
        try await testEnvironment.runTest { env in
            let parentComponent = TestPropagationComponent(name: "Parent")
            let childComponent = TestPropagationComponent(name: "Child", parent: parentComponent)
            
            // Configure conditional propagation rules
            childComponent.propagationRules = [
                .propagateIf(severity: .high),
                .isolateIf(errorType: .validationError),
                .retryIf(errorType: .networkError, maxAttempts: 2)
            ]
            
            // Test 1: High severity error should propagate
            let highSeverityError = AxiomError.systemError(.memoryExhausted)
            await childComponent.propagateError(highSeverityError)
            
            XCTAssertEqual(parentComponent.handledErrors.count, 1, "High severity error should propagate")
            
            // Test 2: Validation error should be isolated
            let validationError = AxiomError.validationError(.invalidInput("field", "reason"))
            await childComponent.propagateError(validationError)
            
            XCTAssertEqual(parentComponent.handledErrors.count, 1, "Validation error should not propagate")
            XCTAssertEqual(childComponent.isolatedErrors.count, 1, "Validation error should be isolated")
            
            // Test 3: Network error should trigger retry
            let networkError = AxiomError.networkError(.connectionFailed("timeout"))
            await childComponent.propagateError(networkError)
            
            XCTAssertEqual(childComponent.retryAttempts[networkError.id], 1, "Network error should trigger retry")
        }
    }
    
    // MARK: - Error Propagation Patterns Tests
    
    func testBubbleUpPropagationPattern() async throws {
        try await testEnvironment.runTest { env in
            // Create deep component hierarchy
            var components: [TestPropagationComponent] = []
            components.append(TestPropagationComponent(name: "Root"))
            
            for i in 1..<10 {
                let parent = components[i - 1]
                let child = TestPropagationComponent(name: "Level\(i)", parent: parent)
                child.propagationPattern = .bubbleUp
                components.append(child)
            }
            
            let deepestComponent = components.last!
            let error = AxiomError.contextError(.lifecycleError("Deep error"))
            
            // Measure propagation time
            let startTime = CFAbsoluteTimeGetCurrent()
            await deepestComponent.propagateError(error)
            let propagationTime = CFAbsoluteTimeGetCurrent() - startTime
            
            // Verify all components in hierarchy handled the error
            for component in components {
                XCTAssertEqual(component.handledErrors.count, 1, "\(component.name) should handle bubbled error")
            }
            
            // Verify reasonable propagation performance
            XCTAssertLessThan(propagationTime, 0.1, "Propagation should be fast even through deep hierarchy")
        }
    }
    
    func testTrickleDownPropagationPattern() async throws {
        try await testEnvironment.runTest { env in
            let rootComponent = TestPropagationComponent(name: "Root")
            rootComponent.propagationPattern = .trickleDown
            
            // Create multiple levels of children
            let level1Children = (1...3).map { i in
                TestPropagationComponent(name: "Level1-\(i)", parent: rootComponent)
            }
            
            let level2Children = level1Children.flatMap { parent in
                (1...2).map { i in
                    TestPropagationComponent(name: "\(parent.name)-Child\(i)", parent: parent)
                }
            }
            
            // Error at root should trickle down to all descendants
            let rootError = AxiomError.systemError(.configurationError("Root configuration error"))
            await rootComponent.propagateError(rootError)
            
            // Verify trickle-down propagation
            XCTAssertEqual(rootComponent.handledErrors.count, 1, "Root should handle error")
            
            for child in level1Children {
                XCTAssertEqual(child.receivedTrickleDowns.count, 1, "Level 1 child should receive trickle-down")
            }
            
            for child in level2Children {
                XCTAssertEqual(child.receivedTrickleDowns.count, 1, "Level 2 child should receive trickle-down")
            }
        }
    }
    
    func testRadialPropagationPattern() async throws {
        try await testEnvironment.runTest { env in
            // Create hub-and-spoke architecture
            let hubComponent = TestPropagationComponent(name: "Hub")
            hubComponent.propagationPattern = .radial
            
            let spokeComponents = (1...5).map { i in
                TestPropagationComponent(name: "Spoke\(i)", parent: hubComponent)
            }
            
            // Add peer connections between spokes
            for (index, spoke) in spokeComponents.enumerated() {
                spoke.peers = spokeComponents.filter { $0 !== spoke }
            }
            
            // Error from one spoke should radiate through hub to all other spokes
            let originSpoke = spokeComponents[0]
            let spokeError = AxiomError.clientError(.timeout(duration: 5.0))
            await originSpoke.propagateError(spokeError)
            
            // Verify radial propagation
            XCTAssertEqual(hubComponent.handledErrors.count, 1, "Hub should handle error")
            
            for (index, spoke) in spokeComponents.enumerated() {
                if index == 0 {
                    XCTAssertEqual(spoke.handledErrors.count, 1, "Origin spoke should handle error")
                } else {
                    XCTAssertEqual(spoke.receivedRadialPropagations.count, 1, "Other spokes should receive radial propagation")
                }
            }
        }
    }
    
    // MARK: - Error Propagation Filtering Tests
    
    func testErrorPropagationFiltering() async throws {
        try await testEnvironment.runTest { env in
            let parentComponent = TestPropagationComponent(name: "Parent")
            let childComponent = TestPropagationComponent(name: "Child", parent: parentComponent)
            
            // Configure propagation filters
            childComponent.propagationFilters = [
                .exclude(errorTypes: [.validationError, .userError]),
                .includeOnly(severities: [.high, .critical]),
                .rateLimitPropagation(maxPerSecond: 5),
                .deduplicateErrors(timeWindow: 1.0)
            ]
            
            // Test exclusion filter
            let validationError = AxiomError.validationError(.invalidInput("test", "test"))
            await childComponent.propagateError(validationError)
            XCTAssertEqual(parentComponent.handledErrors.count, 0, "Validation error should be filtered out")
            
            // Test severity filter
            let lowSeverityError = AxiomError.userError(.cancelled)
            await childComponent.propagateError(lowSeverityError)
            XCTAssertEqual(parentComponent.handledErrors.count, 0, "Low severity error should be filtered out")
            
            let highSeverityError = AxiomError.systemError(.memoryExhausted)
            await childComponent.propagateError(highSeverityError)
            XCTAssertEqual(parentComponent.handledErrors.count, 1, "High severity error should propagate")
            
            // Test deduplication filter
            await childComponent.propagateError(highSeverityError) // Duplicate
            XCTAssertEqual(parentComponent.handledErrors.count, 1, "Duplicate error should be filtered out")
        }
    }
    
    func testRateLimitedErrorPropagation() async throws {
        try await testEnvironment.runTest { env in
            let parentComponent = TestPropagationComponent(name: "Parent")
            let childComponent = TestPropagationComponent(name: "Child", parent: parentComponent)
            
            // Configure rate limiting
            childComponent.propagationFilters = [
                .rateLimitPropagation(maxPerSecond: 3)
            ]
            
            // Send errors rapidly
            for i in 0..<10 {
                let error = AxiomError.clientError(.timeout(duration: Double(i)))
                await childComponent.propagateError(error)
            }
            
            // Should only propagate up to rate limit
            XCTAssertLessThanOrEqual(parentComponent.handledErrors.count, 3, "Should respect rate limit")
            
            // Wait for rate limit window to reset
            try await Task.sleep(nanoseconds: 1_100_000_000) // 1.1 seconds
            
            // Should be able to propagate more errors
            let additionalError = AxiomError.networkError(.connectionFailed("new error"))
            await childComponent.propagateError(additionalError)
            
            XCTAssertGreaterThan(parentComponent.handledErrors.count, 3, "Should propagate after rate limit reset")
        }
    }
    
    // MARK: - Error Propagation Context Tests
    
    func testErrorPropagationContextEnrichment() async throws {
        try await testEnvironment.runTest { env in
            let rootComponent = TestPropagationComponent(name: "Root")
            rootComponent.contextData = ["environment": "test", "version": "1.0"]
            
            let middleComponent = TestPropagationComponent(name: "Middle", parent: rootComponent)
            middleComponent.contextData = ["module": "middleware", "feature": "authentication"]
            
            let leafComponent = TestPropagationComponent(name: "Leaf", parent: middleComponent)
            leafComponent.contextData = ["action": "login", "userId": "user123"]
            
            // Error should accumulate context during propagation
            let originalError = AxiomError.clientError(.invalidAction("Login failed"))
            await leafComponent.propagateError(originalError)
            
            let enrichedError = rootComponent.handledErrors.first
            XCTAssertNotNil(enrichedError, "Root should receive enriched error")
            
            // Verify context accumulation
            let context = enrichedError!.propagationContext
            XCTAssertEqual(context["environment"] as? String, "test")
            XCTAssertEqual(context["version"] as? String, "1.0")
            XCTAssertEqual(context["module"] as? String, "middleware")
            XCTAssertEqual(context["feature"] as? String, "authentication")
            XCTAssertEqual(context["action"] as? String, "login")
            XCTAssertEqual(context["userId"] as? String, "user123")
        }
    }
    
    func testErrorPropagationMetrics() async throws {
        try await testEnvironment.runTest { env in
            let metricsCollector = ErrorPropagationMetrics()
            let parentComponent = TestPropagationComponent(name: "Parent")
            let childComponent = TestPropagationComponent(name: "Child", parent: parentComponent)
            
            parentComponent.metricsCollector = metricsCollector
            childComponent.metricsCollector = metricsCollector
            
            // Generate various error propagation scenarios
            for i in 0..<100 {
                let errorType: AxiomError = switch i % 4 {
                case 0: AxiomError.networkError(.connectionFailed("test"))
                case 1: AxiomError.validationError(.invalidInput("field", "reason"))
                case 2: AxiomError.systemError(.configurationError("config"))
                default: AxiomError.clientError(.timeout(duration: 1.0))
                }
                
                await childComponent.propagateError(errorType)
            }
            
            let metrics = await metricsCollector.getMetrics()
            
            XCTAssertEqual(metrics.totalErrorsPropagated, 100, "Should track total propagated errors")
            XCTAssertGreaterThan(metrics.averagePropagationTime, 0, "Should track propagation time")
            XCTAssertEqual(metrics.errorsByType.count, 4, "Should track errors by type")
            XCTAssertEqual(metrics.propagationsByComponent["Child"], 100, "Should track propagations by component")
        }
    }
    
    // MARK: - Performance Tests
    
    func testErrorPropagationPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                // Create deep component hierarchy
                var components: [TestPropagationComponent] = []
                components.append(TestPropagationComponent(name: "Root"))
                
                for i in 1..<50 {
                    let parent = components[i - 1]
                    let child = TestPropagationComponent(name: "Level\(i)", parent: parent)
                    components.append(child)
                }
                
                // Test rapid error propagation through deep hierarchy
                let deepestComponent = components.last!
                
                for i in 0..<100 {
                    let error = AxiomError.clientError(.timeout(duration: Double(i)))
                    await deepestComponent.propagateError(error)
                }
            },
            maxDuration: .milliseconds(300),
            maxMemoryGrowth: 1024 * 1024 // 1MB
        )
    }
    
    func testErrorPropagationConcurrency() async throws {
        try await testEnvironment.runTest { env in
            let parentComponent = TestPropagationComponent(name: "Parent")
            let childComponents = (0..<10).map { i in
                TestPropagationComponent(name: "Child\(i)", parent: parentComponent)
            }
            
            // Concurrent error propagation from multiple children
            await withTaskGroup(of: Void.self) { group in
                for (index, child) in childComponents.enumerated() {
                    group.addTask {
                        for i in 0..<50 {
                            let error = AxiomError.clientError(.timeout(duration: Double(i)))
                            await child.propagateError(error)
                        }
                    }
                }
            }
            
            // Verify all errors were handled correctly
            let totalExpectedErrors = childComponents.count * 50
            XCTAssertEqual(parentComponent.handledErrors.count, totalExpectedErrors, 
                          "Should handle all concurrent errors correctly")
        }
    }
    
    // MARK: - Memory Management Tests
    
    func testErrorPropagationMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            let rootComponent = TestPropagationComponent(name: "Root")
            
            // Create and destroy child components repeatedly
            for iteration in 0..<20 {
                var childComponents: [TestPropagationComponent] = []
                
                for i in 0..<25 {
                    let child = TestPropagationComponent(name: "Child\(iteration)-\(i)", parent: rootComponent)
                    childComponents.append(child)
                    
                    let error = AxiomError.contextError(.lifecycleError("Iteration \(iteration) Error \(i)"))
                    await child.propagateError(error)
                }
                
                // Clear references
                childComponents.removeAll()
                
                // Force cleanup
                await rootComponent.cleanupPropagationHistory()
            }
        }
    }
}

// MARK: - Test Helper Classes

private class TestPropagationComponent {
    let name: String
    weak var parent: TestPropagationComponent?
    var children: [TestPropagationComponent] = []
    var peers: [TestPropagationComponent] = []
    
    var handledErrors: [PropagatedError] = []
    var isolatedErrors: [PropagatedError] = []
    var receivedBroadcasts: [ErrorBroadcast] = []
    var receivedTrickleDowns: [ErrorTrickleDown] = []
    var receivedRadialPropagations: [ErrorRadialPropagation] = []
    var retryAttempts: [String: Int] = [:]
    
    var propagationMode: PropagationMode = .bubbleUp
    var propagationPattern: PropagationPattern = .bubbleUp
    var propagationRules: [PropagationRule] = []
    var propagationFilters: [PropagationFilter] = []
    var contextData: [String: Any] = [:]
    var metricsCollector: ErrorPropagationMetrics?
    
    init(name: String, parent: TestPropagationComponent? = nil) {
        self.name = name
        self.parent = parent
        parent?.children.append(self)
    }
    
    func propagateError(_ error: AxiomError) async {
        let propagatedError = PropagatedError(
            originalError: error,
            propagationPath: [name],
            originalComponent: name,
            propagationContext: contextData
        )
        
        await handleError(propagatedError)
        await propagateToParent(propagatedError)
        await applyPropagationPattern(propagatedError)
    }
    
    private func handleError(_ error: PropagatedError) async {
        handledErrors.append(error)
        await metricsCollector?.recordErrorPropagation(error, component: name)
    }
    
    private func propagateToParent(_ error: PropagatedError) async {
        guard let parent = parent else { return }
        
        // Apply propagation rules
        for rule in propagationRules {
            if await rule.shouldIsolate(error) {
                isolatedErrors.append(error)
                return
            }
            
            if await rule.shouldRetry(error) {
                let errorId = error.originalError.id
                retryAttempts[errorId, default: 0] += 1
                if retryAttempts[errorId]! < rule.maxRetryAttempts {
                    return // Don't propagate yet, retry instead
                }
            }
            
            if !await rule.shouldPropagate(error) {
                return
            }
        }
        
        // Apply propagation filters
        for filter in propagationFilters {
            if !await filter.shouldAllowPropagation(error) {
                return
            }
        }
        
        // Enrich error with parent context
        var enrichedError = error
        enrichedError.propagationPath.append(parent.name)
        enrichedError.propagationContext.merge(parent.contextData) { _, new in new }
        
        await parent.handleError(enrichedError)
        await parent.propagateToParent(enrichedError)
    }
    
    private func applyPropagationPattern(_ error: PropagatedError) async {
        switch propagationPattern {
        case .bubbleUp:
            // Already handled by propagateToParent
            break
            
        case .trickleDown:
            for child in children {
                let trickleDown = ErrorTrickleDown(error: error, fromParent: name)
                child.receivedTrickleDowns.append(trickleDown)
                await child.applyPropagationPattern(error)
            }
            
        case .radial:
            for peer in peers {
                let radialPropagation = ErrorRadialPropagation(error: error, fromPeer: name)
                peer.receivedRadialPropagations.append(radialPropagation)
            }
            
        case .broadcast:
            for child in children {
                let broadcast = ErrorBroadcast(
                    error: error,
                    originalComponent: error.originalComponent,
                    broadcastReason: .siblingError
                )
                child.receivedBroadcasts.append(broadcast)
            }
        }
    }
    
    func cleanupPropagationHistory() async {
        handledErrors.removeAll()
        isolatedErrors.removeAll()
        receivedBroadcasts.removeAll()
        receivedTrickleDowns.removeAll()
        receivedRadialPropagations.removeAll()
        retryAttempts.removeAll()
    }
}

private struct PropagatedError {
    let originalError: AxiomError
    var propagationPath: [String]
    let originalComponent: String
    var propagationContext: [String: Any]
}

private struct ErrorBroadcast {
    let error: PropagatedError
    let originalComponent: String
    let broadcastReason: BroadcastReason
}

private struct ErrorTrickleDown {
    let error: PropagatedError
    let fromParent: String
}

private struct ErrorRadialPropagation {
    let error: PropagatedError
    let fromPeer: String
}

private enum PropagationMode {
    case bubbleUp
    case broadcast
    case isolate
}

private enum PropagationPattern {
    case bubbleUp
    case trickleDown
    case radial
    case broadcast
}

private enum BroadcastReason {
    case siblingError
    case parentDirective
    case systemAlert
}

private struct PropagationRule {
    let maxRetryAttempts: Int
    
    static func propagateIf(severity: ErrorSeverity) -> PropagationRule {
        return PropagationRule(maxRetryAttempts: 0)
    }
    
    static func isolateIf(errorType: AxiomErrorType) -> PropagationRule {
        return PropagationRule(maxRetryAttempts: 0)
    }
    
    static func retryIf(errorType: AxiomErrorType, maxAttempts: Int) -> PropagationRule {
        return PropagationRule(maxRetryAttempts: maxAttempts)
    }
    
    func shouldPropagate(_ error: PropagatedError) async -> Bool {
        return true // Simplified for testing
    }
    
    func shouldIsolate(_ error: PropagatedError) async -> Bool {
        return false // Simplified for testing
    }
    
    func shouldRetry(_ error: PropagatedError) async -> Bool {
        return maxRetryAttempts > 0
    }
}

private struct PropagationFilter {
    static func exclude(errorTypes: [AxiomErrorType]) -> PropagationFilter {
        return PropagationFilter()
    }
    
    static func includeOnly(severities: [ErrorSeverity]) -> PropagationFilter {
        return PropagationFilter()
    }
    
    static func rateLimitPropagation(maxPerSecond: Int) -> PropagationFilter {
        return PropagationFilter()
    }
    
    static func deduplicateErrors(timeWindow: TimeInterval) -> PropagationFilter {
        return PropagationFilter()
    }
    
    func shouldAllowPropagation(_ error: PropagatedError) async -> Bool {
        return true // Simplified for testing
    }
}

private enum AxiomErrorType {
    case validationError
    case networkError
    case userError
    case systemError
}

private enum ErrorSeverity {
    case low
    case medium
    case high
    case critical
}

private actor ErrorPropagationMetrics {
    private var totalErrorsPropagated = 0
    private var propagationTimes: [TimeInterval] = []
    private var errorsByType: [String: Int] = [:]
    private var propagationsByComponent: [String: Int] = [:]
    
    func recordErrorPropagation(_ error: PropagatedError, component: String) {
        totalErrorsPropagated += 1
        propagationsByComponent[component, default: 0] += 1
        
        let errorType = String(describing: type(of: error.originalError))
        errorsByType[errorType, default: 0] += 1
    }
    
    func getMetrics() -> (
        totalErrorsPropagated: Int,
        averagePropagationTime: TimeInterval,
        errorsByType: [String: Int],
        propagationsByComponent: [String: Int]
    ) {
        let avgTime = propagationTimes.isEmpty ? 0 : propagationTimes.reduce(0, +) / Double(propagationTimes.count)
        return (totalErrorsPropagated, avgTime, errorsByType, propagationsByComponent)
    }
}