import Foundation

// MARK: - Base Mock Capability

/// Base actor implementation providing common mock capability behaviors
/// 
/// This actor provides:
/// - State management with thread-safe transitions
/// - Error simulation for testing
/// - Delay simulation for timing tests
/// - State observation support
public actor BaseMockCapability: ExtendedCapability {
    /// Current state of the capability
    public private(set) var state: CapabilityState = .unknown
    
    /// Stream of state changes for observation
    private var stateStreamContinuation: AsyncStream<CapabilityState>.Continuation?
    
    /// Creates a stream of state changes
    public var stateStream: AsyncStream<CapabilityState> {
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                await self?.setStreamContinuation(continuation)
                if let currentState = await self?.state {
                    continuation.yield(currentState)
                }
            }
        }
    }
    
    private func setStreamContinuation(_ continuation: AsyncStream<CapabilityState>.Continuation) {
        self.stateStreamContinuation = continuation
    }
    
    /// Indicates whether the capability is currently available
    public var isAvailable: Bool {
        state == .available
    }
    
    // Simulation controls
    public private(set) var simulatedErrors: [Error] = []
    public private(set) var operationDelays: [String: Duration] = [:]
    
    public init() {}
    
    /// Initialize the capability
    public func initialize() async throws {
        if let error = simulatedErrors.first {
            simulatedErrors.removeFirst()
            throw error
        }
        await transitionTo(.available)
    }
    
    /// Terminate the capability and clean up resources
    public func terminate() async {
        await transitionTo(.unavailable)
        stateStreamContinuation?.finish()
    }
    
    /// Check if the capability is supported on this device
    public func isSupported() async -> Bool {
        true // Configurable in subclasses
    }
    
    /// Request permission if required
    public func requestPermission() async throws {
        // Override in subclasses
    }
    
    /// Transition to a new state
    /// - Parameter newState: The state to transition to
    public func transitionTo(_ newState: CapabilityState) {
        guard state != newState else { return }
        state = newState
        stateStreamContinuation?.yield(newState)
    }
    
    // Test helpers
    
    /// Simulate an error for the next operation
    public func simulateError(_ error: Error) {
        simulatedErrors.append(error)
    }
    
    /// Simulate a delay for a specific operation
    public func simulateDelay(for operation: String, duration: Duration) {
        operationDelays[operation] = duration
    }
}

// MARK: - Mock System Capability Factory

/// Factory for creating mock system capabilities
public enum MockSystemCapability {
    /// Create a mock notification capability
    public static func notifications(
        initialPermission: MockNotificationCapability.PermissionState = .notDetermined
    ) -> MockNotificationCapability {
        MockNotificationCapability(permission: initialPermission)
    }
    
    /// Create a mock shortcut capability
    public static func shortcuts(maxShortcuts: Int = 4) -> MockShortcutCapability {
        MockShortcutCapability(maxShortcuts: maxShortcuts)
    }
    
    /// Create a mock widget capability
    public static func widgets() -> MockWidgetCapability {
        MockWidgetCapability()
    }
}

// MARK: - Mock Notification Capability

/// Mock implementation of notification capabilities for testing
public actor MockNotificationCapability: ExtendedCapability {
    public enum PermissionState: Equatable {
        case notDetermined, denied, authorized, provisional
    }
    
    // Base capability behaviors
    private let baseCapability = BaseMockCapability()
    
    // Notification-specific state
    public private(set) var permission: PermissionState
    public private(set) var scheduledNotifications: [MockNotification] = []
    public private(set) var deliveredNotifications: [MockNotification] = []
    public private(set) var removedIdentifiers: Set<String> = []
    
    // Delegate to base capability
    public var state: CapabilityState {
        get async { await baseCapability.state }
    }
    
    public var stateStream: AsyncStream<CapabilityState> {
        get async { await baseCapability.stateStream }
    }
    
    public var isAvailable: Bool {
        get async { await baseCapability.isAvailable }
    }
    
    init(permission: PermissionState) {
        self.permission = permission
    }
    
    public func initialize() async throws {
        try await baseCapability.initialize()
    }
    
    public func terminate() async {
        await baseCapability.terminate()
    }
    
    public func isSupported() async -> Bool {
        await baseCapability.isSupported()
    }
    
    public func requestPermission() async throws {
        // Simulate permission request
        let delays = await baseCapability.operationDelays
        if let delay = delays["requestPermission"] {
            try await Task.sleep(for: delay)
        }
        
        switch permission {
        case .notDetermined:
            permission = .authorized // Simulate grant
            await baseCapability.transitionTo(.available)
        case .denied:
            throw CapabilityError.permissionRequired
        case .authorized, .provisional:
            // Already authorized
            await baseCapability.transitionTo(.available)
        }
    }
    
    public func schedule(_ notification: MockNotification) async throws {
        guard permission == .authorized || permission == .provisional else {
            throw CapabilityError.permissionRequired
        }
        
        scheduledNotifications.append(notification)
    }
    
    public func removeScheduled(withIdentifiers identifiers: [String]) async {
        scheduledNotifications.removeAll { identifiers.contains($0.identifier) }
    }
    
    public func simulateDelivery(identifier: String) async {
        if let notification = scheduledNotifications.first(where: { $0.identifier == identifier }) {
            deliveredNotifications.append(notification)
            scheduledNotifications.removeAll { $0.identifier == identifier }
        }
    }
    
    // Test inspection
    public func hasScheduledNotification(withIdentifier identifier: String) -> Bool {
        scheduledNotifications.contains { $0.identifier == identifier }
    }
    
    // Test helpers from base
    public func simulateError(_ error: Error) async {
        await baseCapability.simulateError(error)
    }
    
    public func simulateDelay(for operation: String, duration: Duration) async {
        await baseCapability.simulateDelay(for: operation, duration: duration)
    }
}

// MARK: - Mock Notification

public struct MockNotification: Equatable {
    public let identifier: String
    public let title: String
    public let body: String
    public let trigger: MockNotificationTrigger
    
    public init(
        identifier: String,
        title: String,
        body: String,
        trigger: MockNotificationTrigger
    ) {
        self.identifier = identifier
        self.title = title
        self.body = body
        self.trigger = trigger
    }
}

public enum MockNotificationTrigger: Equatable {
    case immediate
    case date(Date)
    case interval(TimeInterval)
}

// MARK: - Mock Shortcut Capability

/// Mock implementation of shortcut capabilities for testing
public actor MockShortcutCapability: ExtendedCapability {
    // Base capability behaviors
    private let baseCapability = BaseMockCapability()
    
    // Shortcut-specific state
    public private(set) var shortcuts: [MockShortcut] = []
    private let maxShortcuts: Int
    
    // Delegate to base capability
    public var state: CapabilityState {
        get async { await baseCapability.state }
    }
    
    public var stateStream: AsyncStream<CapabilityState> {
        get async { await baseCapability.stateStream }
    }
    
    public var isAvailable: Bool {
        get async { await baseCapability.isAvailable }
    }
    
    init(maxShortcuts: Int) {
        self.maxShortcuts = maxShortcuts
    }
    
    public func initialize() async throws {
        try await baseCapability.initialize()
    }
    
    public func terminate() async {
        await baseCapability.terminate()
    }
    
    public func isSupported() async -> Bool {
        await baseCapability.isSupported()
    }
    
    public func requestPermission() async throws {
        // Shortcuts don't need permission
        await baseCapability.transitionTo(.available)
    }
    
    public func updateShortcuts(_ shortcuts: [MockShortcut]) async throws {
        guard shortcuts.count <= maxShortcuts else {
            throw ShortcutError.tooManyShortcuts(max: maxShortcuts)
        }
        
        self.shortcuts = shortcuts
    }
    
    public func addShortcut(_ shortcut: MockShortcut) async throws {
        guard shortcuts.count < maxShortcuts else {
            throw ShortcutError.tooManyShortcuts(max: maxShortcuts)
        }
        
        shortcuts.append(shortcut)
    }
    
    public func removeAllShortcuts() async {
        shortcuts.removeAll()
    }
    
    // Test helpers
    public func simulateShortcutTap(_ identifier: String) async -> Bool {
        shortcuts.contains { $0.identifier == identifier }
    }
    
    public func simulateError(_ error: Error) async {
        await baseCapability.simulateError(error)
    }
    
    public func simulateDelay(for operation: String, duration: Duration) async {
        await baseCapability.simulateDelay(for: operation, duration: duration)
    }
}

// MARK: - Mock Shortcut

public struct MockShortcut: Equatable {
    public let identifier: String
    public let title: String
    public let symbolName: String?
    
    public init(identifier: String, title: String, symbolName: String? = nil) {
        self.identifier = identifier
        self.title = title
        self.symbolName = symbolName
    }
}

// MARK: - Shortcut Error

public enum ShortcutError: Error {
    case tooManyShortcuts(max: Int)
}

// MARK: - Mock Widget Capability

/// Mock implementation of widget capabilities for testing
public actor MockWidgetCapability: ExtendedCapability {
    // Base capability behaviors
    private let baseCapability = BaseMockCapability()
    
    // Widget-specific state
    public private(set) var reloadCount = 0
    public private(set) var lastReloadIdentifiers: Set<String> = []
    
    // Delegate to base capability
    public var state: CapabilityState {
        get async { await baseCapability.state }
    }
    
    public var stateStream: AsyncStream<CapabilityState> {
        get async { await baseCapability.stateStream }
    }
    
    public var isAvailable: Bool {
        get async { await baseCapability.isAvailable }
    }
    
    public func initialize() async throws {
        try await baseCapability.initialize()
    }
    
    public func terminate() async {
        await baseCapability.terminate()
    }
    
    public func isSupported() async -> Bool {
        await baseCapability.isSupported()
    }
    
    public func requestPermission() async throws {
        // Widgets don't need permission
        await baseCapability.transitionTo(.available)
    }
    
    public func reloadTimelines(ofKind kind: String) async {
        reloadCount += 1
        lastReloadIdentifiers.insert(kind)
    }
    
    public func reloadAllTimelines() async {
        reloadCount += 1
        lastReloadIdentifiers.insert("*")
    }
    
    // Test helpers
    public func simulateWidgetTap(kind: String, url: URL) async {
        // Simulate widget interaction
    }
    
    public func resetReloadTracking() {
        reloadCount = 0
        lastReloadIdentifiers.removeAll()
    }
    
    public func simulateError(_ error: Error) async {
        await baseCapability.simulateError(error)
    }
    
    public func simulateDelay(for operation: String, duration: Duration) async {
        await baseCapability.simulateDelay(for: operation, duration: duration)
    }
}