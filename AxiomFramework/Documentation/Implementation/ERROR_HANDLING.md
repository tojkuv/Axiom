# Error Handling Guide

Comprehensive guide for implementing error handling, recovery strategies, and graceful degradation in the Axiom framework.

## Overview

The Axiom framework provides structured error handling through typed errors, recovery mechanisms, and graceful degradation strategies. This guide covers error types, handling patterns, and best practices for robust application behavior.

## Error Types

### Framework Error Hierarchy

```swift
import Axiom

// Base framework error
public enum AxiomError: Error {
    case capabilityUnavailable(String)
    case stateCorruption(String)
    case architecturalViolation(String)
    case performanceThresholdExceeded(String)
    case configurationError(String)
    case unknownError(underlying: Error)
}

// Client-specific errors
public enum ClientError: Error {
    case invalidState
    case concurrencyViolation
    case updateFailed(underlying: Error)
    case isolationBreach
    case actorDeallocation
}

// Context-specific errors
public enum ContextError: Error {
    case bindingFailure(property: String)
    case orchestrationError(clients: [String])
    case stateObservationFailed
    case uiUpdateFailed(underlying: Error)
}

// Capability-specific errors
public enum CapabilityError: Error {
    case capabilityUnavailable(String)
    case requirementNotMet(CapabilityRequirement)
    case validationTimeout
    case executionFailed(underlying: Error)
    case fallbackUnavailable
}
```

### Domain-Specific Error Types

```swift
// User domain errors
enum UserError: Error, LocalizedError {
    case invalidCredentials
    case authenticationFailed
    case accountLocked
    case profileIncomplete
    case networkUnavailable
    case storageUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid username or password"
        case .authenticationFailed:
            return "Authentication failed. Please try again."
        case .accountLocked:
            return "Account is temporarily locked. Please contact support."
        case .profileIncomplete:
            return "Please complete your profile to continue"
        case .networkUnavailable:
            return "Network connection is required for this operation"
        case .storageUnavailable:
            return "Unable to save data. Please check storage permissions."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidCredentials:
            return "Check your credentials and try again"
        case .authenticationFailed:
            return "Verify your internet connection and retry"
        case .accountLocked:
            return "Contact customer support for assistance"
        case .profileIncomplete:
            return "Complete the required profile fields"
        case .networkUnavailable:
            return "Connect to the internet and try again"
        case .storageUnavailable:
            return "Grant storage permission in Settings"
        }
    }
}

// Order domain errors
enum OrderError: Error, LocalizedError {
    case insufficientInventory
    case paymentFailed
    case shippingUnavailable
    case orderNotFound
    case cancellationNotAllowed
    
    var errorDescription: String? {
        switch self {
        case .insufficientInventory:
            return "Insufficient inventory for this item"
        case .paymentFailed:
            return "Payment processing failed"
        case .shippingUnavailable:
            return "Shipping is not available to this location"
        case .orderNotFound:
            return "Order not found"
        case .cancellationNotAllowed:
            return "This order cannot be cancelled"
        }
    }
}
```

## Recovery Strategies

### Automatic Recovery

```swift
actor UserClient: AxiomClient {
    private var retryAttempts: [String: Int] = [:]
    private let maxRetryAttempts = 3
    
    func performOperationWithRetry<T>(
        operation: () async throws -> T,
        operationId: String = UUID().uuidString
    ) async throws -> T {
        let currentAttempts = retryAttempts[operationId] ?? 0
        
        do {
            let result = try await operation()
            // Success - clear retry count
            retryAttempts.removeValue(forKey: operationId)
            return result
            
        } catch {
            guard currentAttempts < maxRetryAttempts else {
                // Max retries exceeded
                retryAttempts.removeValue(forKey: operationId)
                throw error
            }
            
            // Increment retry count
            retryAttempts[operationId] = currentAttempts + 1
            
            // Apply backoff strategy
            let delay = TimeInterval(pow(2.0, Double(currentAttempts))) // Exponential backoff
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            // Handle specific error types
            switch error {
            case CapabilityError.capabilityUnavailable:
                await handleCapabilityUnavailable()
                
            case ClientError.invalidState:
                await handleInvalidState()
                
            case UserError.networkUnavailable:
                await handleNetworkUnavailable()
                
            default:
                break
            }
            
            // Retry operation
            return try await performOperationWithRetry(
                operation: operation,
                operationId: operationId
            )
        }
    }
    
    private func handleCapabilityUnavailable() async {
        // Attempt to re-register capabilities
        await setupCapabilities()
    }
    
    private func handleInvalidState() async {
        // Reset to known good state
        await updateState { state in
            state = UserState.defaultState()
        }
    }
    
    private func handleNetworkUnavailable() async {
        // Switch to offline mode
        await updateState { state in
            state.isOfflineMode = true
        }
    }
}
```

### Manual Recovery

```swift
@MainActor
class UserContext: AxiomContext, ObservableObject {
    @Published var errorState: ErrorState?
    @Published var isRecovering = false
    
    func handleError(_ error: Error) async {
        errorState = ErrorState(error: error)
        
        // Attempt automatic recovery for certain errors
        switch error {
        case UserError.networkUnavailable:
            await attemptNetworkRecovery()
            
        case CapabilityError.capabilityUnavailable(let capability):
            await attemptCapabilityRecovery(capability)
            
        case ClientError.invalidState:
            await attemptStateRecovery()
            
        default:
            // Require manual user intervention
            errorState?.requiresManualRecovery = true
        }
    }
    
    func retryLastOperation() async {
        guard let errorState = errorState else { return }
        
        isRecovering = true
        defer { isRecovering = false }
        
        do {
            try await errorState.retryOperation()
            // Success - clear error state
            self.errorState = nil
            
        } catch {
            // Update error state with new error
            self.errorState = ErrorState(error: error)
        }
    }
    
    func dismissError() {
        errorState = nil
    }
    
    private func attemptNetworkRecovery() async {
        // Wait and retry network connection
        for attempt in 1...3 {
            try? await Task.sleep(nanoseconds: UInt64(attempt * 2_000_000_000)) // 2, 4, 6 seconds
            
            if await NetworkMonitor.shared.isConnected {
                // Network restored
                await userClient.updateState { state in
                    state.isOfflineMode = false
                }
                errorState = nil
                return
            }
        }
        
        // Network still unavailable - switch to offline mode
        await userClient.updateState { state in
            state.isOfflineMode = true
        }
        errorState = ErrorState.networkOffline
    }
    
    private func attemptCapabilityRecovery(_ capability: String) async {
        // Re-validate capability
        if let capabilityType = getCapabilityType(for: capability),
           await userClient.capabilities.validate(capabilityType) {
            
            // Capability restored
            errorState = nil
        } else {
            // Capability still unavailable - enable fallback mode
            await enableFallbackMode(for: capability)
        }
    }
}

struct ErrorState {
    let error: Error
    let timestamp: Date
    var requiresManualRecovery: Bool
    let retryOperation: (() async throws -> Void)?
    
    init(error: Error, retryOperation: (() async throws -> Void)? = nil) {
        self.error = error
        self.timestamp = Date()
        self.requiresManualRecovery = false
        self.retryOperation = retryOperation
    }
    
    static let networkOffline = ErrorState(
        error: UserError.networkUnavailable,
        retryOperation: nil
    )
}
```

### Circuit Breaker Pattern

```swift
actor CircuitBreaker {
    enum State {
        case closed    // Normal operation
        case open      // Failing fast
        case halfOpen  // Testing recovery
    }
    
    private var state: State = .closed
    private var failureCount = 0
    private var lastFailureTime: Date?
    private let failureThreshold: Int
    private let recoveryTimeout: TimeInterval
    
    init(failureThreshold: Int = 5, recoveryTimeout: TimeInterval = 60) {
        self.failureThreshold = failureThreshold
        self.recoveryTimeout = recoveryTimeout
    }
    
    func execute<T>(_ operation: () async throws -> T) async throws -> T {
        switch state {
        case .open:
            // Check if we should transition to half-open
            if let lastFailure = lastFailureTime,
               Date().timeIntervalSince(lastFailure) > recoveryTimeout {
                state = .halfOpen
                return try await executeInHalfOpenState(operation)
            } else {
                throw CircuitBreakerError.circuitOpen
            }
            
        case .halfOpen:
            return try await executeInHalfOpenState(operation)
            
        case .closed:
            return try await executeInClosedState(operation)
        }
    }
    
    private func executeInClosedState<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            let result = try await operation()
            // Success - reset failure count
            failureCount = 0
            return result
            
        } catch {
            failureCount += 1
            lastFailureTime = Date()
            
            if failureCount >= failureThreshold {
                state = .open
            }
            
            throw error
        }
    }
    
    private func executeInHalfOpenState<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            let result = try await operation()
            // Success - transition to closed
            state = .closed
            failureCount = 0
            return result
            
        } catch {
            // Failure - transition back to open
            state = .open
            lastFailureTime = Date()
            throw error
        }
    }
}

enum CircuitBreakerError: Error {
    case circuitOpen
}

// Usage in client
extension UserClient {
    private let networkCircuitBreaker = CircuitBreaker(failureThreshold: 3, recoveryTimeout: 30)
    
    func performNetworkOperation() async throws -> NetworkResult {
        return try await networkCircuitBreaker.execute {
            try await capabilities.execute(NetworkCapability.self, with: request)
        }
    }
}
```

## Graceful Degradation

### Feature Degradation

```swift
enum FeatureLevel {
    case full      // All features available
    case limited   // Some features available
    case basic     // Only essential features
    case offline   // No network features
    case minimal   // Core functionality only
}

@MainActor
class AppContext: AxiomContext, ObservableObject {
    @Published var currentFeatureLevel: FeatureLevel = .full
    @Published var degradationReason: String?
    
    func evaluateFeatureLevel() async {
        let availableCapabilities = await getAvailableCapabilities()
        let systemHealth = await getSystemHealth()
        
        let newLevel = determineFeatureLevel(
            capabilities: availableCapabilities,
            health: systemHealth
        )
        
        if newLevel != currentFeatureLevel {
            await transitionToFeatureLevel(newLevel)
        }
    }
    
    private func determineFeatureLevel(
        capabilities: Set<String>,
        health: SystemHealth
    ) -> FeatureLevel {
        // Critical system issues
        if health.memoryUsage > 0.9 || health.cpuUsage > 0.95 {
            return .minimal
        }
        
        // Network availability
        if !capabilities.contains("network") {
            return .offline
        }
        
        // Essential capabilities
        let essentialCapabilities: Set<String> = ["storage", "analytics"]
        if !essentialCapabilities.isSubset(of: capabilities) {
            return .basic
        }
        
        // Enhanced capabilities
        let enhancedCapabilities: Set<String> = ["camera", "location", "notifications"]
        if !enhancedCapabilities.isSubset(of: capabilities) {
            return .limited
        }
        
        return .full
    }
    
    private func transitionToFeatureLevel(_ level: FeatureLevel) async {
        currentFeatureLevel = level
        
        switch level {
        case .full:
            await enableAllFeatures()
            degradationReason = nil
            
        case .limited:
            await disableEnhancedFeatures()
            degradationReason = "Some advanced features are temporarily unavailable"
            
        case .basic:
            await enableOnlyBasicFeatures()
            degradationReason = "Running in basic mode due to system limitations"
            
        case .offline:
            await enableOfflineMode()
            degradationReason = "No network connection - offline mode active"
            
        case .minimal:
            await enableMinimalMode()
            degradationReason = "System resources limited - minimal mode active"
        }
        
        // Notify user of degradation
        if level != .full {
            await showDegradationNotification()
        }
    }
    
    private func enableOfflineMode() async {
        // Disable network-dependent features
        await userClient.updateState { state in
            state.features.remove(.cloudSync)
            state.features.remove(.socialSharing)
            state.features.remove(.realTimeUpdates)
        }
        
        // Enable offline alternatives
        await enableOfflineAlternatives()
    }
    
    private func enableMinimalMode() async {
        // Disable all non-essential features
        await userClient.updateState { state in
            state.features = [.basicProfile, .localData]
        }
        
        // Reduce resource usage
        await optimizeForMinimalResources()
    }
}
```

### Contextual Error Handling

```swift
struct UserView: AxiomView {
    @ObservedObject var context: UserContext
    
    var body: some View {
        ZStack {
            MainContent(context: context)
            
            // Error overlay
            if let errorState = context.errorState {
                ErrorOverlay(errorState: errorState, context: context)
            }
            
            // Recovery indicator
            if context.isRecovering {
                RecoveryIndicator()
            }
        }
    }
}

struct ErrorOverlay: View {
    let errorState: ErrorState
    @ObservedObject var context: UserContext
    
    var body: some View {
        VStack(spacing: 16) {
            ErrorIcon(for: errorState.error)
            
            Text(errorMessage)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            if let suggestion = recoverySuggestion {
                Text(suggestion)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            HStack {
                if !errorState.requiresManualRecovery {
                    Button("Retry") {
                        Task {
                            await context.retryLastOperation()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Button("Dismiss") {
                    context.dismissError()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 8)
        .padding()
    }
    
    private var errorMessage: String {
        if let localizedError = errorState.error as? LocalizedError {
            return localizedError.errorDescription ?? "An error occurred"
        }
        return "An unexpected error occurred"
    }
    
    private var recoverySuggestion: String? {
        if let localizedError = errorState.error as? LocalizedError {
            return localizedError.recoverySuggestion
        }
        return nil
    }
}

struct ErrorIcon: View {
    let error: Error
    
    var body: some View {
        Group {
            switch error {
            case UserError.networkUnavailable:
                Image(systemName: "wifi.slash")
                    .foregroundColor(.orange)
                
            case CapabilityError.capabilityUnavailable:
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.yellow)
                
            case ClientError.invalidState:
                Image(systemName: "arrow.clockwise.circle")
                    .foregroundColor(.blue)
                
            default:
                Image(systemName: "exclamationmark.circle")
                    .foregroundColor(.red)
            }
        }
        .font(.largeTitle)
    }
}
```

## Best Practices

### Error Prevention

```swift
// Input validation to prevent errors
extension UserClient {
    func updateUserSafely(_ updates: UserUpdates) async -> Result<Void, UserError> {
        // Validate inputs before processing
        guard validateUserUpdates(updates) else {
            return .failure(.profileIncomplete)
        }
        
        // Check prerequisites
        guard await prerequisites.areMet() else {
            return .failure(.invalidCredentials)
        }
        
        // Perform operation with error handling
        do {
            await updateState { state in
                state.apply(updates)
            }
            return .success(())
            
        } catch {
            return .failure(.updateFailed(underlying: error))
        }
    }
    
    private func validateUserUpdates(_ updates: UserUpdates) -> Bool {
        // Validate required fields
        guard !updates.email.isEmpty,
              updates.email.contains("@"),
              !updates.name.trimmingCharacters(in: .whitespaces).isEmpty else {
            return false
        }
        
        // Validate business rules
        guard updates.age >= 13 else {
            return false
        }
        
        return true
    }
}
```

### Error Logging and Monitoring

```swift
protocol ErrorLogger {
    func log(_ error: Error, context: [String: Any])
    func logRecovery(_ error: Error, successful: Bool, context: [String: Any])
}

class FrameworkErrorLogger: ErrorLogger {
    func log(_ error: Error, context: [String: Any] = [:]) {
        let errorInfo: [String: Any] = [
            "error_type": String(describing: type(of: error)),
            "error_description": error.localizedDescription,
            "timestamp": Date(),
            "context": context
        ]
        
        // Log to analytics
        AnalyticsManager.shared.trackError(errorInfo)
        
        // Log to console in debug builds
        #if DEBUG
        print("🔴 Error: \(error)")
        print("Context: \(context)")
        #endif
        
        // Log to crash reporting service
        CrashReporter.shared.recordError(error, context: context)
    }
    
    func logRecovery(_ error: Error, successful: Bool, context: [String: Any] = [:]) {
        let recoveryInfo: [String: Any] = [
            "original_error": String(describing: type(of: error)),
            "recovery_successful": successful,
            "timestamp": Date(),
            "context": context
        ]
        
        AnalyticsManager.shared.trackRecovery(recoveryInfo)
    }
}

// Usage in framework components
extension UserClient {
    private let errorLogger = FrameworkErrorLogger()
    
    func performOperationWithLogging() async {
        do {
            try await riskyOperation()
            
        } catch {
            errorLogger.log(error, context: [
                "client_type": "UserClient",
                "operation": "riskyOperation",
                "state_version": stateSnapshot.version
            ])
            
            // Attempt recovery
            let recovered = await attemptRecovery(from: error)
            
            errorLogger.logRecovery(error, successful: recovered, context: [
                "recovery_strategy": "automatic"
            ])
            
            if !recovered {
                throw error
            }
        }
    }
}
```

### Error Testing

```swift
// Mock error conditions for testing
class ErrorTestingClient: UserClient {
    var shouldFailNextOperation = false
    var errorToThrow: Error = UserError.networkUnavailable
    
    override func performOperation() async throws {
        if shouldFailNextOperation {
            shouldFailNextOperation = false
            throw errorToThrow
        }
        
        try await super.performOperation()
    }
}

final class ErrorHandlingTests: XCTestCase {
    @MainActor
    func testErrorRecovery() async throws {
        let errorClient = ErrorTestingClient(capabilities: MockCapabilityManager())
        let context = UserContext(userClient: errorClient, ...)
        
        // Simulate error condition
        errorClient.shouldFailNextOperation = true
        errorClient.errorToThrow = UserError.networkUnavailable
        
        // Attempt operation
        await context.performOperation()
        
        // Verify error was handled
        XCTAssertNotNil(context.errorState)
        XCTAssertEqual(context.errorState?.error as? UserError, .networkUnavailable)
        
        // Test recovery
        errorClient.shouldFailNextOperation = false
        await context.retryLastOperation()
        
        // Verify recovery
        XCTAssertNil(context.errorState)
    }
    
    func testCircuitBreakerPattern() async throws {
        let circuitBreaker = CircuitBreaker(failureThreshold: 2, recoveryTimeout: 1)
        
        // Test normal operation
        let result1 = try await circuitBreaker.execute { return "success" }
        XCTAssertEqual(result1, "success")
        
        // Test failure threshold
        do {
            try await circuitBreaker.execute { throw TestError.networkFailure }
        } catch {}
        
        do {
            try await circuitBreaker.execute { throw TestError.networkFailure }
        } catch {}
        
        // Circuit should be open now
        do {
            try await circuitBreaker.execute { return "should not execute" }
            XCTFail("Circuit breaker should be open")
        } catch CircuitBreakerError.circuitOpen {
            // Expected
        }
        
        // Test recovery after timeout
        try await Task.sleep(nanoseconds: 1_100_000_000) // 1.1 seconds
        
        let result2 = try await circuitBreaker.execute { return "recovered" }
        XCTAssertEqual(result2, "recovered")
    }
}

enum TestError: Error {
    case networkFailure
    case invalidInput
}
```

## Error Handling Checklist

### Implementation Checklist

- [ ] Define typed errors for each domain
- [ ] Implement automatic recovery for transient errors
- [ ] Provide manual recovery options for user errors
- [ ] Use circuit breaker pattern for external dependencies
- [ ] Implement graceful degradation for capability failures
- [ ] Log errors with sufficient context for debugging
- [ ] Test error scenarios and recovery mechanisms
- [ ] Provide clear user feedback for error conditions
- [ ] Monitor error rates and recovery success rates
- [ ] Document error handling strategies for each component

### User Experience Checklist

- [ ] Show meaningful error messages to users
- [ ] Provide actionable recovery suggestions
- [ ] Maintain application functionality during errors
- [ ] Prevent data loss during error conditions
- [ ] Offer alternative workflows when primary features fail
- [ ] Communicate system status clearly
- [ ] Allow users to retry failed operations
- [ ] Minimize user friction during error recovery

---

**Error Handling Guide** - Complete guide for error management, recovery strategies, and graceful degradation with comprehensive testing and monitoring approaches