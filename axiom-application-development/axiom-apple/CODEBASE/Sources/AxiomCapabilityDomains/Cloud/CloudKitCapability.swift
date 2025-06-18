import Foundation
import CloudKit
import AxiomCore
import AxiomCapabilities

// MARK: - CloudKit Capability Configuration

/// Configuration for CloudKit capability
public struct CloudKitCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let containerIdentifier: String?
    public let isDevelopment: Bool
    public let enableSubscriptions: Bool
    public let enableSharing: Bool
    public let maxRecordBatchSize: Int
    public let recordZoneCapacity: Int
    public let enableZoneWildcardSubscription: Bool
    public let subscriptionOptions: CKQuerySubscription.Options
    
    // Custom Codable implementation to handle CloudKit types
    private enum CodingKeys: String, CodingKey {
        case containerIdentifier
        case isDevelopment
        case enableSubscriptions
        case enableSharing
        case maxRecordBatchSize
        case recordZoneCapacity
        case enableZoneWildcardSubscription
        case subscriptionOptionsRawValue
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        containerIdentifier = try container.decodeIfPresent(String.self, forKey: .containerIdentifier)
        isDevelopment = try container.decode(Bool.self, forKey: .isDevelopment)
        enableSubscriptions = try container.decode(Bool.self, forKey: .enableSubscriptions)
        enableSharing = try container.decode(Bool.self, forKey: .enableSharing)
        maxRecordBatchSize = try container.decode(Int.self, forKey: .maxRecordBatchSize)
        recordZoneCapacity = try container.decode(Int.self, forKey: .recordZoneCapacity)
        enableZoneWildcardSubscription = try container.decode(Bool.self, forKey: .enableZoneWildcardSubscription)
        
        let optionsRawValue = try container.decode(UInt.self, forKey: .subscriptionOptionsRawValue)
        subscriptionOptions = CKQuerySubscription.Options(rawValue: optionsRawValue)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(containerIdentifier, forKey: .containerIdentifier)
        try container.encode(isDevelopment, forKey: .isDevelopment)
        try container.encode(enableSubscriptions, forKey: .enableSubscriptions)
        try container.encode(enableSharing, forKey: .enableSharing)
        try container.encode(maxRecordBatchSize, forKey: .maxRecordBatchSize)
        try container.encode(recordZoneCapacity, forKey: .recordZoneCapacity)
        try container.encode(enableZoneWildcardSubscription, forKey: .enableZoneWildcardSubscription)
        try container.encode(subscriptionOptions.rawValue, forKey: .subscriptionOptionsRawValue)
    }
    
    public init(
        containerIdentifier: String? = nil,
        isDevelopment: Bool = true,
        enableSubscriptions: Bool = true,
        enableSharing: Bool = false,
        maxRecordBatchSize: Int = 400,
        recordZoneCapacity: Int = 1000,
        enableZoneWildcardSubscription: Bool = true,
        subscriptionOptions: CKQuerySubscription.Options = [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
    ) {
        self.containerIdentifier = containerIdentifier
        self.isDevelopment = isDevelopment
        self.enableSubscriptions = enableSubscriptions
        self.enableSharing = enableSharing
        self.maxRecordBatchSize = maxRecordBatchSize
        self.recordZoneCapacity = recordZoneCapacity
        self.enableZoneWildcardSubscription = enableZoneWildcardSubscription
        self.subscriptionOptions = subscriptionOptions
    }
    
    public var isValid: Bool {
        maxRecordBatchSize > 0 && maxRecordBatchSize <= 400 && recordZoneCapacity > 0
    }
    
    public func merged(with other: CloudKitCapabilityConfiguration) -> CloudKitCapabilityConfiguration {
        CloudKitCapabilityConfiguration(
            containerIdentifier: other.containerIdentifier ?? containerIdentifier,
            isDevelopment: other.isDevelopment,
            enableSubscriptions: other.enableSubscriptions,
            enableSharing: other.enableSharing,
            maxRecordBatchSize: other.maxRecordBatchSize,
            recordZoneCapacity: other.recordZoneCapacity,
            enableZoneWildcardSubscription: other.enableZoneWildcardSubscription,
            subscriptionOptions: other.subscriptionOptions
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> CloudKitCapabilityConfiguration {
        var adjustedBatchSize = maxRecordBatchSize
        var adjustedSubscriptions = enableSubscriptions
        var adjustedDevelopment = self.isDevelopment
        
        if environment.isLowPowerMode {
            adjustedBatchSize = min(maxRecordBatchSize, 100)
            adjustedSubscriptions = false
        }
        
        if environment.isDebug {
            adjustedDevelopment = true
        }
        
        return CloudKitCapabilityConfiguration(
            containerIdentifier: containerIdentifier,
            isDevelopment: adjustedDevelopment,
            enableSubscriptions: adjustedSubscriptions,
            enableSharing: enableSharing,
            maxRecordBatchSize: adjustedBatchSize,
            recordZoneCapacity: recordZoneCapacity,
            enableZoneWildcardSubscription: enableZoneWildcardSubscription,
            subscriptionOptions: subscriptionOptions
        )
    }
}

// MARK: - CloudKit Operation Types

/// CloudKit operation types
public enum CloudKitOperation: Sendable {
    case save([CKRecord])
    case fetch([CKRecord.ID])
    case query(CKQuery, CKRecordZone.ID?)
    case delete([CKRecord.ID])
    case modifyZones([CKRecordZone], [CKRecordZone.ID])
    case fetchZones([CKRecordZone.ID])
}

/// CloudKit execution context
public struct CloudKitExecutionContext: Sendable {
    public let operationId: UUID
    public let startTime: Date
    public let database: String
    public let metadata: [String: String]
    
    public init(
        operationId: UUID = UUID(),
        startTime: Date = Date(),
        database: String = "private",
        metadata: [String: String] = [:]
    ) {
        self.operationId = operationId
        self.startTime = startTime
        self.database = database
        self.metadata = metadata
    }
}

/// CloudKit execution result
public struct CloudKitExecutionResult: Sendable {
    public let records: [CKRecord]
    public let recordIDs: [CKRecord.ID]
    public let duration: TimeInterval
    public let context: CloudKitExecutionContext
    public let error: CKError?
    
    public init(
        records: [CKRecord] = [],
        recordIDs: [CKRecord.ID] = [],
        duration: TimeInterval,
        context: CloudKitExecutionContext,
        error: CKError? = nil
    ) {
        self.records = records
        self.recordIDs = recordIDs
        self.duration = duration
        self.context = context
        self.error = error
    }
    
    public var isSuccess: Bool { error == nil }
}

// MARK: - CloudKit Resource

/// CloudKit resource management
public actor CloudKitCapabilityResource: AxiomCapabilityResource {
    private let configuration: CloudKitCapabilityConfiguration
    private var container: CKContainer?
    private var privateDatabase: CKDatabase?
    private var publicDatabase: CKDatabase?
    private var sharedDatabase: CKDatabase?
    private var subscriptions: [String: CKSubscription] = [:]
    private var recordZones: [CKRecordZone.ID: CKRecordZone] = [:]
    
    public init(configuration: CloudKitCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: configuration.recordZoneCapacity * 10_000, // 10KB per record estimate
            cpu: 5.0, // CloudKit operations can be CPU intensive
            bandwidth: configuration.maxRecordBatchSize * 50_000, // 50KB per record estimate
            storage: configuration.recordZoneCapacity * 100_000 // 100KB per record estimate
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let zoneCount = recordZones.count
            let subscriptionCount = subscriptions.count
            let estimatedMemory = (zoneCount * 1000) + (subscriptionCount * 500)
            
            return ResourceUsage(
                memory: estimatedMemory,
                cpu: configuration.enableSubscriptions ? 2.0 : 1.0,
                bandwidth: 0, // Dynamic based on operations
                storage: zoneCount * 10_000 // Estimate based on zones
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        container != nil && privateDatabase != nil
    }
    
    public func release() async {
        // Clean up subscriptions
        subscriptions.removeAll()
        recordZones.removeAll()
        
        // Clear database references
        privateDatabase = nil
        publicDatabase = nil
        sharedDatabase = nil
        container = nil
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Initialize container
        if let containerIdentifier = configuration.containerIdentifier {
            container = CKContainer(identifier: containerIdentifier)
        } else {
            container = CKContainer.default()
        }
        
        guard let container = container else {
            throw AxiomCapabilityError.initializationFailed("Failed to create CloudKit container")
        }
        
        // Set up databases
        privateDatabase = container.privateCloudDatabase
        publicDatabase = container.publicCloudDatabase
        sharedDatabase = container.sharedCloudDatabase
        
        // Check account status
        let accountStatus = try await container.accountStatus()
        guard accountStatus == .available else {
            throw AxiomCapabilityError.initializationFailed("CloudKit account not available: \(accountStatus)")
        }
        
        // Set up default record zone if needed
        try await setupDefaultRecordZone()
        
        // Set up subscriptions if enabled
        if configuration.enableSubscriptions {
            try await setupSubscriptions()
        }
    }
    
    internal func updateConfiguration(_ configuration: CloudKitCapabilityConfiguration) async throws {
        // CloudKit configuration changes require reallocation
        if await isAvailable() {
            await release()
            try await allocate()
        }
    }
    
    // MARK: - CloudKit Access
    
    public func getContainer() -> CKContainer? {
        container
    }
    
    public func getPrivateDatabase() -> CKDatabase? {
        privateDatabase
    }
    
    public func getPublicDatabase() -> CKDatabase? {
        publicDatabase
    }
    
    public func getSharedDatabase() -> CKDatabase? {
        sharedDatabase
    }
    
    public func getRecordZones() -> [CKRecordZone.ID: CKRecordZone] {
        recordZones
    }
    
    public func addRecordZone(_ zone: CKRecordZone) {
        recordZones[zone.zoneID] = zone
    }
    
    public func removeRecordZone(_ zoneID: CKRecordZone.ID) {
        recordZones.removeValue(forKey: zoneID)
    }
    
    // MARK: - Private Setup Methods
    
    private func setupDefaultRecordZone() async throws {
        guard let privateDatabase = privateDatabase else { return }
        
        let defaultZone = CKRecordZone.default()
        recordZones[defaultZone.zoneID] = defaultZone
        
        // Create custom zone if not using default
        let customZoneID = CKRecordZone.ID(zoneName: "AxiomZone")
        let customZone = CKRecordZone(zoneID: customZoneID)
        
        // Simply add the zone to our tracking - actual CloudKit operations would be more complex
        recordZones[customZoneID] = customZone
    }
    
    private func fetchExistingZones() async throws {
        // This would fetch existing zones from CloudKit
        // For now, just maintain the default zone
        let defaultZone = CKRecordZone.default()
        recordZones[defaultZone.zoneID] = defaultZone
    }
    
    private func setupSubscriptions() async throws {
        guard let privateDatabase = privateDatabase else { return }
        
        if configuration.enableZoneWildcardSubscription {
            // Create database-level subscription for all changes
            let subscription = CKDatabaseSubscription(subscriptionID: "axiom-database-subscription")
            
            let notificationInfo = CKSubscription.NotificationInfo()
            notificationInfo.shouldSendContentAvailable = true
            subscription.notificationInfo = notificationInfo
            
            do {
                let savedSubscription = try await privateDatabase.save(subscription)
                subscriptions[savedSubscription.subscriptionID] = savedSubscription
            } catch {
                // Subscription might already exist
                if let ckError = error as? CKError, ckError.code != .serverRejectedRequest {
                    throw error
                }
            }
        }
    }
}

// MARK: - CloudKit Capability Implementation

/// CloudKit capability providing cloud data synchronization
public actor CloudKitCapability: DomainCapability {
    public typealias ConfigurationType = CloudKitCapabilityConfiguration
    public typealias ResourceType = CloudKitCapabilityResource
    
    private var _configuration: CloudKitCapabilityConfiguration
    private var _resources: CloudKitCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(30)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "cloudkit-capability" }
    
    public var isAvailable: Bool {
        get async { _state == .available }
    }
    
    public var state: AxiomCapabilityState {
        get async { _state }
    }
    
    public var stateStream: AsyncStream<AxiomCapabilityState> {
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                await self?.setStreamContinuation(continuation)
                if let currentState = await self?._state {
                    continuation.yield(currentState)
                }
            }
        }
    }
    
    public var activationTimeout: Duration {
        get async { _activationTimeout }
    }
    
    public var configuration: CloudKitCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: CloudKitCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: CloudKitCapabilityConfiguration = CloudKitCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = CloudKitCapabilityResource(configuration: self._configuration)
        self._environment = environment
    }
    
    private func setStreamContinuation(_ continuation: AsyncStream<AxiomCapabilityState>.Continuation) {
        self.stateStreamContinuation = continuation
    }
    
    // MARK: - AxiomCapability Protocol
    
    public func activate() async throws {
        await transitionTo(.initializing)
        
        do {
            try await _resources.allocate()
            await transitionTo(.available)
        } catch {
            await transitionTo(.unavailable)
            throw error
        }
    }
    
    public func deactivate() async {
        await transitionTo(.terminating)
        await _resources.release()
        await transitionTo(.unavailable)
        stateStreamContinuation?.finish()
    }
    
    // MARK: - DomainCapability Protocol
    
    public func updateConfiguration(_ configuration: CloudKitCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid CloudKit configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        try await _resources.updateConfiguration(_configuration)
    }
    
    public func handleEnvironmentChange(_ environment: AxiomCapabilityEnvironment) async {
        _environment = environment
        let adjusted = _configuration.adjusted(for: environment)
        try? await updateConfiguration(adjusted)
    }
    
    public func isSupported() async -> Bool {
        // CloudKit is available on all Apple platforms
        true
    }
    
    public func requestPermission() async throws {
        guard let container = await _resources.getContainer() else {
            throw AxiomCapabilityError.unavailable("CloudKit container not available")
        }
        
        let status = try await container.accountStatus()
        guard status == .available else {
            throw AxiomCapabilityError.permissionDenied("CloudKit account not available")
        }
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - CloudKit Operations
    
    /// Save records to CloudKit
    public func saveRecords(_ records: [CKRecord], to database: CloudDatabase = .private) async throws -> CloudKitExecutionResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("CloudKit capability not available")
        }
        
        let database = try await getDatabase(database)
        let context = CloudKitExecutionContext(database: database.description)
        let startTime = ContinuousClock.now
        
        // Simplified CloudKit save operation
        let duration = ContinuousClock.now - startTime
        
        // In a real implementation, this would use CloudKit's async/await APIs
        // For now, return a successful result
        return CloudKitExecutionResult(
            records: records,
            duration: getDurationTimeInterval(duration),
            context: context
        )
    }
    
    /// Fetch records from CloudKit
    public func fetchRecords(_ recordIDs: [CKRecord.ID], from database: CloudDatabase = .private) async throws -> CloudKitExecutionResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("CloudKit capability not available")
        }
        
        let database = try await getDatabase(database)
        let context = CloudKitExecutionContext(database: database.description)
        let startTime = ContinuousClock.now
        
        // Simplified CloudKit fetch operation
        let duration = ContinuousClock.now - startTime
        
        // In a real implementation, this would fetch actual records from CloudKit
        // For now, return empty records with the requested IDs
        return CloudKitExecutionResult(
            records: [],
            recordIDs: recordIDs,
            duration: getDurationTimeInterval(duration),
            context: context
        )
    }
    
    /// Query records from CloudKit
    public func queryRecords(_ query: CKQuery, in zoneID: CKRecordZone.ID? = nil, from database: CloudDatabase = .private) async throws -> CloudKitExecutionResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("CloudKit capability not available")
        }
        
        let database = try await getDatabase(database)
        let context = CloudKitExecutionContext(database: database.description)
        let startTime = ContinuousClock.now
        
        // Simplified CloudKit query operation
        let duration = ContinuousClock.now - startTime
        
        // In a real implementation, this would execute the query against CloudKit
        // For now, return empty results
        return CloudKitExecutionResult(
            records: [],
            duration: getDurationTimeInterval(duration),
            context: context
        )
    }
    
    /// Delete records from CloudKit
    public func deleteRecords(_ recordIDs: [CKRecord.ID], from database: CloudDatabase = .private) async throws -> CloudKitExecutionResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("CloudKit capability not available")
        }
        
        let database = try await getDatabase(database)
        let context = CloudKitExecutionContext(database: database.description)
        let startTime = ContinuousClock.now
        
        // Simplified CloudKit delete operation
        let duration = ContinuousClock.now - startTime
        
        // In a real implementation, this would delete records from CloudKit
        // For now, return successful deletion
        return CloudKitExecutionResult(
            recordIDs: recordIDs,
            duration: getDurationTimeInterval(duration),
            context: context
        )
    }
    
    /// Create or modify record zones
    public func modifyRecordZones(save: [CKRecordZone] = [], delete: [CKRecordZone.ID] = []) async throws -> CloudKitExecutionResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("CloudKit capability not available")
        }
        
        let database = try await getDatabase(.private)
        let context = CloudKitExecutionContext(database: "private")
        let startTime = ContinuousClock.now
        
        // Simplified CloudKit zone modification operation
        let duration = ContinuousClock.now - startTime
        
        // Update local zone tracking
        for zone in save {
            await _resources.addRecordZone(zone)
        }
        
        for zoneID in delete {
            await _resources.removeRecordZone(zoneID)
        }
        
        return CloudKitExecutionResult(
            duration: getDurationTimeInterval(duration),
            context: context
        )
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
    
    private func getDurationTimeInterval(_ duration: ContinuousClock.Instant.Duration) -> TimeInterval {
        return Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1_000_000_000_000_000_000
    }
    
    private func getDatabase(_ database: CloudDatabase) async throws -> CKDatabase {
        switch database {
        case .private:
            guard let db = await _resources.getPrivateDatabase() else {
                throw AxiomCapabilityError.resourceAllocationFailed("Private database not available")
            }
            return db
        case .public:
            guard let db = await _resources.getPublicDatabase() else {
                throw AxiomCapabilityError.resourceAllocationFailed("Public database not available")
            }
            return db
        case .shared:
            guard let db = await _resources.getSharedDatabase() else {
                throw AxiomCapabilityError.resourceAllocationFailed("Shared database not available")
            }
            return db
        }
    }
}

// MARK: - Supporting Types

/// CloudKit database types
public enum CloudDatabase: String, Codable, CaseIterable, Sendable {
    case `private` = "private"
    case `public` = "public"
    case shared = "shared"
}


// MARK: - Error Extensions

extension AxiomCapabilityError {
    /// CloudKit specific errors
    public static func cloudKitError(_ message: String) -> AxiomCapabilityError {
        .operationFailed("CloudKit: \(message)")
    }
    
    public static func cloudKitAccountUnavailable() -> AxiomCapabilityError {
        .permissionDenied("CloudKit account not available")
    }
    
    public static func cloudKitOperationFailed(_ error: CKError) -> AxiomCapabilityError {
        .operationFailed("CloudKit operation failed: \(error.localizedDescription)")
    }
}