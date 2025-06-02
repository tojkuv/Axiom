# Client Implementation Guide

Comprehensive guide for implementing actor-based clients with thread-safe state management in the Axiom framework.

## Overview

AxiomClient provides the foundation for actor-based state management, ensuring thread safety, performance, and architectural consistency. This guide covers implementation patterns, best practices, and advanced techniques.

## Actor-based State Management

### Core Principles

1. **Single Ownership**: Each client owns exactly one domain model
2. **Actor Isolation**: All state mutations occur within actor boundaries
3. **Immutable State**: State is exposed as read-only snapshots
4. **Async Operations**: All client interactions are asynchronous

### Basic Implementation

```swift
import Axiom

// Define your domain model as a value object
struct UserState {
    var id: UUID = UUID()
    var name: String = ""
    var email: String = ""
    var lastLogin: Date?
    var preferences: UserPreferences = UserPreferences()
    var metadata: UserMetadata = UserMetadata()
}

// Manual actor implementation
actor UserClient: AxiomClient {
    typealias State = UserState
    
    // Read-only state snapshot
    private(set) var stateSnapshot = UserState()
    
    // Capability management
    let capabilities: CapabilityManager
    
    // Required initializer
    init(capabilities: CapabilityManager) {
        self.capabilities = capabilities
    }
    
    // Thread-safe state mutation
    func updateState(_ update: @Sendable (inout State) -> Void) async {
        update(&stateSnapshot)
        await notifyStateChange()
    }
    
    // State change notification
    private func notifyStateChange() async {
        // Notify observers (contexts) of state changes
        // Framework handles observer notification automatically
    }
}
```

### Macro-Generated Implementation

```swift
// Automatic actor generation using @Client macro
@Client
struct UserState {
    var id: UUID = UUID()
    var name: String = ""
    var email: String = ""
    var lastLogin: Date?
}

// Generated code:
actor UserClient: AxiomClient {
    typealias State = UserState
    private(set) var stateSnapshot = UserState()
    let capabilities: CapabilityManager
    
    init(capabilities: CapabilityManager) {
        self.capabilities = capabilities
    }
    
    func updateState(_ update: @Sendable (inout State) -> Void) async {
        update(&stateSnapshot)
        await notifyStateChange()
    }
    
    private func notifyStateChange() async {
        // Framework-generated notification logic
    }
}
```

## State Mutations

### Simple State Updates

```swift
extension UserClient {
    func updateName(_ newName: String) async {
        await updateState { state in
            state.name = newName
        }
    }
    
    func updateEmail(_ newEmail: String) async {
        await updateState { state in
            state.email = newEmail
            state.lastModified = Date()
        }
    }
    
    func recordLogin() async {
        await updateState { state in
            state.lastLogin = Date()
            state.loginCount += 1
        }
    }
}
```

### Complex State Transactions

```swift
extension UserClient {
    func updateProfile(_ profile: UserProfile) async {
        await updateState { state in
            // Atomic update of multiple properties
            state.name = profile.name
            state.email = profile.email
            state.preferences.theme = profile.theme
            state.preferences.notifications = profile.notifications
            state.lastModified = Date()
            state.version += 1
        }
    }
    
    func resetUserData() async {
        await updateState { state in
            // Complete state reset while preserving identity
            let id = state.id
            state = UserState()
            state.id = id
        }
    }
}
```

### Conditional State Updates

```swift
extension UserClient {
    func attemptLogin(credentials: LoginCredentials) async throws -> LoginResult {
        // Validate capability before state mutation
        guard await capabilities.validate(AuthenticationCapability.self) else {
            throw UserError.authenticationUnavailable
        }
        
        // Execute authentication through capability system
        let result = try await capabilities.execute(
            AuthenticationCapability.self,
            with: credentials
        )
        
        // Update state based on result
        if result.success {
            await updateState { state in
                state.isAuthenticated = true
                state.lastLogin = Date()
                state.authToken = result.token
            }
        }
        
        return result
    }
    
    func updatePreferencesIfValid(_ preferences: UserPreferences) async -> Bool {
        // Validate preferences before applying
        guard preferences.isValid else {
            return false
        }
        
        await updateState { state in
            state.preferences = preferences
            state.lastModified = Date()
        }
        
        return true
    }
}
```

## Client Isolation

### Thread Safety Guarantees

```swift
// ✅ Safe: All operations are async and actor-isolated
actor UserClient: AxiomClient {
    private var internalCounter = 0
    
    func performOperation() async {
        // Safe to access actor properties within actor methods
        internalCounter += 1
        
        await updateState { state in
            state.operationCount = internalCounter
        }
    }
    
    // Safe: State snapshot is immutable and Sendable
    var currentState: State {
        stateSnapshot
    }
}

// ❌ Unsafe: Direct property access from outside actor
func unsafeAccess(client: UserClient) {
    // This would cause compilation error:
    // let count = client.internalCounter  // Error: actor property access
}

// ✅ Safe: Proper async access
func safeAccess(client: UserClient) async {
    let state = await client.stateSnapshot  // Safe: async property access
    let name = state.name                   // Safe: immutable value access
}
```

### Actor Boundaries

```swift
actor UserClient: AxiomClient {
    // Private actor state
    private var cache: [String: Any] = [:]
    private var operationQueue: [Operation] = []
    
    // Public interface methods
    func cacheValue(_ value: Any, for key: String) async {
        cache[key] = value
    }
    
    func getCachedValue(for key: String) async -> Any? {
        return cache[key]
    }
    
    func enqueueOperation(_ operation: Operation) async {
        operationQueue.append(operation)
        await processQueue()
    }
    
    // Private actor methods
    private func processQueue() async {
        while !operationQueue.isEmpty {
            let operation = operationQueue.removeFirst()
            await executeOperation(operation)
        }
    }
    
    private func executeOperation(_ operation: Operation) async {
        // Process operation and update state accordingly
        await updateState { state in
            // Apply operation effects to state
        }
    }
}
```

### Sendable Constraints

```swift
// State must conform to Sendable for thread safety
struct UserState: Sendable {
    let id: UUID                    // ✅ Sendable
    var name: String               // ✅ Sendable
    var preferences: UserPreferences // ✅ Must also be Sendable
}

struct UserPreferences: Sendable {
    var theme: Theme               // ✅ Enum is Sendable
    var notifications: Bool        // ✅ Bool is Sendable
    var customSettings: [String: String] // ✅ Dictionary of Sendable types
}

// Update closures must be @Sendable
func updateUserData() async {
    await userClient.updateState { state in // @Sendable closure
        state.name = "New Name"
        // All mutations must be within this closure
    }
}
```

## Performance Considerations

### Efficient State Updates

```swift
extension UserClient {
    // ✅ Efficient: Single state update
    func updateUserInfo(name: String, email: String, theme: Theme) async {
        await updateState { state in
            state.name = name
            state.email = email
            state.preferences.theme = theme
            state.lastModified = Date()
        }
    }
    
    // ❌ Inefficient: Multiple state updates
    func inefficientUpdate(name: String, email: String, theme: Theme) async {
        await updateState { state in state.name = name }
        await updateState { state in state.email = email }
        await updateState { state in state.preferences.theme = theme }
    }
}
```

### Memory Management

```swift
actor UserClient: AxiomClient {
    // ✅ Efficient: Value types for state
    typealias State = UserState  // Struct - efficient copying
    
    // ✅ Efficient: Minimal actor storage
    private var lastOperation: Date?
    private let maxCacheSize = 100
    
    func performLargeDataOperation() async {
        // ✅ Process data without storing in state
        let processedData = await processLargeDataset()
        
        // ✅ Store only essential information
        await updateState { state in
            state.lastProcessedCount = processedData.count
            state.lastProcessedTime = Date()
        }
        
        // Data is automatically released when function ends
    }
    
    func manageCacheSize() async {
        if cache.count > maxCacheSize {
            // Remove oldest entries
            let sortedKeys = cache.keys.sorted { ... }
            for key in sortedKeys.prefix(cache.count - maxCacheSize) {
                cache.removeValue(forKey: key)
            }
        }
    }
}
```

### Async Performance

```swift
extension UserClient {
    // ✅ Concurrent operations where possible
    func loadUserData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.loadBasicInfo()
            }
            group.addTask {
                await self.loadPreferences()
            }
            group.addTask {
                await self.loadHistory()
            }
        }
    }
    
    // ✅ Batch related operations
    func performMaintenanceTasks() async {
        await updateState { state in
            // Perform all maintenance updates in single transaction
            state.lastMaintenanceDate = Date()
            state.cacheCleared = true
            state.version += 1
        }
    }
}
```

## Capability Integration

### Basic Capability Usage

```swift
@Capabilities([.network, .storage, .analytics])
actor UserClient: AxiomClient {
    func saveUserData() async throws {
        // Validate storage capability
        guard await capabilities.validate(StorageCapability.self) else {
            throw UserError.storageUnavailable
        }
        
        // Execute with capability
        try await capabilities.execute(
            StorageCapability.self,
            with: StorageRequest(data: stateSnapshot)
        )
        
        // Update state to reflect save
        await updateState { state in
            state.lastSaved = Date()
            state.isDirty = false
        }
    }
    
    func loadUserData(for userID: UUID) async throws {
        guard await capabilities.validate(StorageCapability.self) else {
            // Graceful degradation - use default state
            await updateState { state in
                state = UserState()
                state.id = userID
            }
            return
        }
        
        // Load from storage
        let userData = try await capabilities.execute(
            StorageCapability.self,
            with: LoadRequest(id: userID)
        )
        
        await updateState { state in
            state = userData
        }
    }
}
```

### Advanced Capability Patterns

```swift
extension UserClient {
    func syncUserData() async -> SyncResult {
        // Check network capability
        let hasNetwork = await capabilities.validate(NetworkCapability.self)
        let hasStorage = await capabilities.validate(StorageCapability.self)
        
        switch (hasNetwork, hasStorage) {
        case (true, true):
            // Full sync capability
            return await performFullSync()
            
        case (false, true):
            // Offline mode - queue for later sync
            return await queueForOfflineSync()
            
        case (true, false):
            // Network only - direct upload without local storage
            return await performDirectSync()
            
        case (false, false):
            // No capabilities - memory only
            return .memoryOnly
        }
    }
    
    private func performFullSync() async -> SyncResult {
        do {
            // Upload changes
            if stateSnapshot.isDirty {
                try await capabilities.execute(
                    NetworkCapability.self,
                    with: UploadRequest(data: stateSnapshot)
                )
            }
            
            // Download updates
            let remoteData = try await capabilities.execute(
                NetworkCapability.self,
                with: DownloadRequest(since: stateSnapshot.lastSync)
            )
            
            // Save locally
            try await capabilities.execute(
                StorageCapability.self,
                with: StorageRequest(data: remoteData)
            )
            
            // Update state
            await updateState { state in
                state.merge(with: remoteData)
                state.lastSync = Date()
                state.isDirty = false
            }
            
            return .success
            
        } catch {
            return .failed(error)
        }
    }
}
```

## Error Handling

### Client-Level Error Management

```swift
enum UserError: Error {
    case invalidData
    case authenticationFailed
    case storageUnavailable
    case networkError(underlying: Error)
    case capabilityUnavailable(String)
}

extension UserClient {
    func updateUserSafely(_ updates: UserUpdates) async -> Result<Void, UserError> {
        do {
            // Validate updates
            guard updates.isValid else {
                return .failure(.invalidData)
            }
            
            // Apply updates
            await updateState { state in
                state.apply(updates)
                state.lastModified = Date()
            }
            
            return .success(())
            
        } catch {
            return .failure(.networkError(underlying: error))
        }
    }
    
    func recoverFromError(_ error: UserError) async {
        switch error {
        case .storageUnavailable:
            // Switch to memory-only mode
            await updateState { state in
                state.isOfflineMode = true
            }
            
        case .authenticationFailed:
            // Clear authentication state
            await updateState { state in
                state.authToken = nil
                state.isAuthenticated = false
            }
            
        case .networkError:
            // Queue operations for retry
            await updateState { state in
                state.hasPendingOperations = true
            }
            
        default:
            break
        }
    }
}
```

## Testing Patterns

### Unit Testing Clients

```swift
import XCTest
@testable import Axiom

final class UserClientTests: XCTestCase {
    var client: UserClient!
    var mockCapabilities: MockCapabilityManager!
    
    override func setUp() {
        mockCapabilities = MockCapabilityManager()
        client = UserClient(capabilities: mockCapabilities)
    }
    
    func testStateUpdate() async {
        // Test basic state mutation
        await client.updateName("Test User")
        
        let state = await client.stateSnapshot
        XCTAssertEqual(state.name, "Test User")
    }
    
    func testCapabilityIntegration() async throws {
        // Mock capability availability
        mockCapabilities.setMockResult(for: StorageCapability.self, result: true)
        
        // Test capability-dependent operation
        try await client.saveUserData()
        
        let state = await client.stateSnapshot
        XCTAssertNotNil(state.lastSaved)
        XCTAssertFalse(state.isDirty)
    }
    
    func testErrorHandling() async {
        // Mock capability failure
        mockCapabilities.setMockResult(for: StorageCapability.self, result: false)
        
        // Test graceful degradation
        do {
            try await client.saveUserData()
            XCTFail("Should have thrown error")
        } catch UserError.storageUnavailable {
            // Expected error
        }
    }
}
```

### Integration Testing

```swift
final class UserClientIntegrationTests: XCTestCase {
    func testCompleteUserFlow() async throws {
        let capabilities = CapabilityManager()
        let client = UserClient(capabilities: capabilities)
        
        // Test complete user lifecycle
        await client.updateName("Integration Test User")
        try await client.saveUserData()
        
        let savedState = await client.stateSnapshot
        XCTAssertEqual(savedState.name, "Integration Test User")
        XCTAssertNotNil(savedState.lastSaved)
    }
}
```

## Best Practices

### State Design

1. **Keep State Minimal**: Store only essential data, derive computed properties
2. **Use Value Types**: Prefer structs over classes for state models
3. **Avoid Optionals**: Use default values instead of optionals when possible
4. **Version State**: Include version numbers for migration and conflict resolution

### Performance

1. **Batch Updates**: Group related changes in single `updateState` call
2. **Minimize State Size**: Keep state objects lightweight
3. **Use Async Patterns**: Leverage async/await for all client operations
4. **Monitor Performance**: Use built-in performance monitoring

### Architecture

1. **Single Responsibility**: Each client manages one domain area
2. **Capability Dependencies**: Use capability system for external dependencies
3. **Error Recovery**: Implement graceful degradation for capability failures
4. **Testing**: Comprehensive unit and integration testing

### Security

1. **Validate Inputs**: Always validate data before state updates
2. **Secure Storage**: Use secure capability implementations for sensitive data
3. **Access Control**: Implement proper access patterns through contexts
4. **Audit Trail**: Log important state changes for security auditing

---

**Client Implementation Guide** - Complete guide for actor-based state management with thread safety, performance optimization, and capability integration