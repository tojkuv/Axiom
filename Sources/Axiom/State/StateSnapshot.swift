import Foundation

// MARK: - State Snapshot Protocol

/// Protocol for creating efficient snapshots of state
public protocol StateSnapshotting {
    associatedtype State: Sendable
    
    /// Creates a snapshot of the current state
    func createSnapshot() -> StateSnapshot<State>
    
    /// Creates a snapshot with metadata
    func createSnapshot(metadata: SnapshotMetadata) -> StateSnapshot<State>
}

// MARK: - Copy-on-Write State Snapshot

/// High-performance state snapshot with copy-on-write optimization
public struct StateSnapshot<State: Sendable>: Sendable {
    // MARK: Properties
    
    /// The immutable state data (copy-on-write optimized)
    private let _storage: StateStorage<State>
    
    /// Metadata about this snapshot
    public let metadata: SnapshotMetadata
    
    /// Direct access to the state (no copying unless modified)
    public var state: State {
        _storage.value
    }
    
    /// Unique identifier for this snapshot
    public let id: SnapshotID
    
    /// The version of the state when this snapshot was created
    public let version: StateVersion
    
    /// Timestamp when this snapshot was created
    public let timestamp: Date
    
    // MARK: Initialization
    
    public init(
        state: State,
        version: StateVersion = StateVersion(),
        metadata: SnapshotMetadata = SnapshotMetadata()
    ) {
        self._storage = StateStorage(state)
        self.metadata = metadata
        self.id = SnapshotID()
        self.version = version
        self.timestamp = Date()
    }
    
    // MARK: Snapshot Operations
    
    /// Creates a new snapshot with updated state
    public func updated(state: State, version: StateVersion) -> StateSnapshot<State> {
        StateSnapshot(
            state: state,
            version: version,
            metadata: metadata.incrementingSequence()
        )
    }
    
    /// Creates a diff between this snapshot and another
    public func diff(against other: StateSnapshot<State>) -> StateDiff<State> {
        StateDiff<State>.calculateBasic(from: other, to: self)
    }
    
    /// Validates the integrity of this snapshot
    public func validate() -> Bool {
        // Verify snapshot integrity
        return _storage.isValid && !metadata.isExpired
    }
    
    /// Returns memory footprint information
    public func memoryFootprint() -> SnapshotMemoryInfo {
        SnapshotMemoryInfo(
            stateSize: _storage.estimatedSize,
            metadataSize: metadata.estimatedSize,
            totalSize: _storage.estimatedSize + metadata.estimatedSize
        )
    }
}

// MARK: - Copy-on-Write Storage

/// Internal storage that implements copy-on-write semantics
private final class StateStorage<State: Sendable>: @unchecked Sendable {
    private let _value: State
    private let _lock = NSLock()
    private var _isValid: Bool = true
    
    var value: State {
        _lock.lock()
        defer { _lock.unlock() }
        return _value
    }
    
    var isValid: Bool {
        _lock.lock()
        defer { _lock.unlock() }
        return _isValid
    }
    
    var estimatedSize: Int {
        // Simplified size estimation
        return MemoryLayout<State>.size
    }
    
    init(_ value: State) {
        self._value = value
    }
    
    func invalidate() {
        _lock.lock()
        defer { _lock.unlock() }
        _isValid = false
    }
}

// MARK: - Snapshot Metadata

/// Metadata associated with a state snapshot
public struct SnapshotMetadata: Sendable {
    public let createdBy: ComponentID
    public let purpose: SnapshotPurpose
    public let sequence: UInt64
    public let ttl: TimeInterval?
    public let tags: Set<String>
    
    public init(
        createdBy: ComponentID = ComponentID("Unknown"),
        purpose: SnapshotPurpose = .checkpoint,
        sequence: UInt64 = 0,
        ttl: TimeInterval? = nil,
        tags: Set<String> = []
    ) {
        self.createdBy = createdBy
        self.purpose = purpose
        self.sequence = sequence
        self.ttl = ttl
        self.tags = tags
    }
    
    /// Whether this metadata has expired based on TTL
    public var isExpired: Bool {
        guard let ttl = ttl else { return false }
        return Date().timeIntervalSince1970 > ttl
    }
    
    /// Creates new metadata with incremented sequence
    public func incrementingSequence() -> SnapshotMetadata {
        SnapshotMetadata(
            createdBy: createdBy,
            purpose: purpose,
            sequence: sequence + 1,
            ttl: ttl,
            tags: tags
        )
    }
    
    /// Estimated memory size of metadata
    public var estimatedSize: Int {
        return MemoryLayout<SnapshotMetadata>.size + 
               (tags.count * 20) // Approximate string overhead
    }
}

// MARK: - Snapshot Purpose

/// The purpose for creating a snapshot
public enum SnapshotPurpose: String, Sendable, CaseIterable {
    case checkpoint = "checkpoint"
    case debugging = "debugging"
    case rollback = "rollback"
    case testing = "testing"
    case performance = "performance"
    case audit = "audit"
}

// MARK: - Snapshot ID

/// Unique identifier for snapshots
public struct SnapshotID: Hashable, Sendable, CustomStringConvertible {
    private let value: String
    
    public init() {
        self.value = UUID().uuidString
    }
    
    public var description: String { value }
}

// MARK: - State Diff

/// Represents the difference between two state snapshots
public struct StateDiff<State: Sendable>: Sendable {
    public let fromSnapshot: SnapshotID
    public let toSnapshot: SnapshotID
    public let changes: [StateChange]
    public let timestamp: Date
    
    public init(
        fromSnapshot: SnapshotID,
        toSnapshot: SnapshotID,
        changes: [StateChange]
    ) {
        self.fromSnapshot = fromSnapshot
        self.toSnapshot = toSnapshot
        self.changes = changes
        self.timestamp = Date()
    }
    
    /// Whether this diff represents any actual changes
    public var hasChanges: Bool {
        !changes.isEmpty
    }
    
    /// Number of changes in this diff
    public var changeCount: Int {
        changes.count
    }
    
    /// Calculate basic diff between two snapshots
    public static func calculateBasic<T: Sendable>(
        from: StateSnapshot<T>,
        to: StateSnapshot<T>
    ) -> StateDiff<T> {
        // Basic implementation - can be enhanced for specific state types
        let changes: [StateChange] = []
        return StateDiff<T>(
            fromSnapshot: from.id,
            toSnapshot: to.id,
            changes: changes
        )
    }
    
    /// Calculate diff between two snapshots with comparable states
    public static func calculate<T: StateComparable>(
        from: StateSnapshot<T>,
        to: StateSnapshot<T>
    ) -> StateDiff<T> {
        let changes = T.calculateChanges(from: from.state, to: to.state)
        return StateDiff<T>(
            fromSnapshot: from.id,
            toSnapshot: to.id,
            changes: changes
        )
    }
}

// MARK: - State Change

/// Represents a single change in state
public struct StateChange: Sendable {
    public let path: String
    public let changeType: ChangeType
    public let oldValue: String?
    public let newValue: String?
    
    public enum ChangeType: String, Sendable {
        case added = "added"
        case removed = "removed"
        case modified = "modified"
    }
    
    public init(
        path: String,
        changeType: ChangeType,
        oldValue: String? = nil,
        newValue: String? = nil
    ) {
        self.path = path
        self.changeType = changeType
        self.oldValue = oldValue
        self.newValue = newValue
    }
}

// MARK: - State Comparable Protocol

/// Protocol for states that can be compared for differences
public protocol StateComparable {
    /// Calculate changes between two instances
    static func calculateChanges(from: Self, to: Self) -> [StateChange]
}

// MARK: - Snapshot Cache

/// High-performance cache for state snapshots
public actor SnapshotCache<State: Sendable> {
    // MARK: Properties
    
    private var snapshots: [SnapshotID: StateSnapshot<State>] = [:]
    private var accessOrder: [SnapshotID] = []
    private let maxCacheSize: Int
    private let maxAge: TimeInterval
    
    // Performance metrics
    private var hitCount: Int = 0
    private var missCount: Int = 0
    
    // MARK: Initialization
    
    public init(maxCacheSize: Int = 100, maxAge: TimeInterval = 3600) {
        self.maxCacheSize = maxCacheSize
        self.maxAge = maxAge
    }
    
    // MARK: Cache Operations
    
    /// Stores a snapshot in the cache
    public func store(_ snapshot: StateSnapshot<State>) async {
        // Remove expired snapshots first
        await cleanupExpired()
        
        // Store the new snapshot
        snapshots[snapshot.id] = snapshot
        accessOrder.append(snapshot.id)
        
        // Enforce size limit
        if snapshots.count > maxCacheSize {
            await evictOldest()
        }
    }
    
    /// Retrieves a snapshot from the cache
    public func retrieve(id: SnapshotID) -> StateSnapshot<State>? {
        guard let snapshot = snapshots[id] else {
            missCount += 1
            return nil
        }
        
        // Check if expired
        if snapshot.metadata.isExpired {
            snapshots.removeValue(forKey: id)
            accessOrder.removeAll { $0 == id }
            missCount += 1
            return nil
        }
        
        // Update access order
        accessOrder.removeAll { $0 == id }
        accessOrder.append(id)
        
        hitCount += 1
        return snapshot
    }
    
    /// Invalidates a specific snapshot
    public func invalidate(id: SnapshotID) {
        snapshots.removeValue(forKey: id)
        accessOrder.removeAll { $0 == id }
    }
    
    /// Clears the entire cache
    public func clear() {
        snapshots.removeAll()
        accessOrder.removeAll()
        hitCount = 0
        missCount = 0
    }
    
    /// Returns cache statistics
    public func statistics() -> CacheStatistics {
        CacheStatistics(
            size: snapshots.count,
            maxSize: maxCacheSize,
            hitCount: hitCount,
            missCount: missCount,
            hitRate: calculateHitRate()
        )
    }
    
    // MARK: Private Methods
    
    private func cleanupExpired() async {
        let expiredIds = snapshots.compactMap { (id, snapshot) in
            snapshot.metadata.isExpired ? id : nil
        }
        
        for id in expiredIds {
            snapshots.removeValue(forKey: id)
            accessOrder.removeAll { $0 == id }
        }
    }
    
    private func evictOldest() async {
        guard let oldestId = accessOrder.first else { return }
        
        snapshots.removeValue(forKey: oldestId)
        accessOrder.removeFirst()
    }
    
    private func calculateHitRate() -> Double {
        let total = hitCount + missCount
        guard total > 0 else { return 0.0 }
        return Double(hitCount) / Double(total)
    }
}

// MARK: - Cache Statistics

/// Statistics about snapshot cache performance
public struct CacheStatistics: Sendable {
    public let size: Int
    public let maxSize: Int
    public let hitCount: Int
    public let missCount: Int
    public let hitRate: Double
    
    public init(size: Int, maxSize: Int, hitCount: Int, missCount: Int, hitRate: Double) {
        self.size = size
        self.maxSize = maxSize
        self.hitCount = hitCount
        self.missCount = missCount
        self.hitRate = hitRate
    }
}

// MARK: - Snapshot Memory Info

/// Information about memory usage of a snapshot
public struct SnapshotMemoryInfo: Sendable {
    public let stateSize: Int
    public let metadataSize: Int
    public let totalSize: Int
    
    public init(stateSize: Int, metadataSize: Int, totalSize: Int) {
        self.stateSize = stateSize
        self.metadataSize = metadataSize
        self.totalSize = totalSize
    }
    
    /// Human-readable size description
    public var description: String {
        "State: \(formatBytes(stateSize)), Metadata: \(formatBytes(metadataSize)), Total: \(formatBytes(totalSize))"
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Extensions

extension StateSnapshot: CustomStringConvertible {
    public var description: String {
        "StateSnapshot(id: \(id), version: \(version), timestamp: \(timestamp))"
    }
}

extension StateSnapshot: Equatable where State: Equatable {
    public static func == (lhs: StateSnapshot<State>, rhs: StateSnapshot<State>) -> Bool {
        lhs.id == rhs.id && lhs.version == rhs.version
    }
}

extension StateSnapshot: Hashable where State: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(version)
    }
}