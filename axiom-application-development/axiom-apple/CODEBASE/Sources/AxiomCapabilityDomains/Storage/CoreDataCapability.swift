import Foundation
import CoreData
import AxiomCore
import AxiomCapabilities

// MARK: - Core Data Capability Configuration

/// Configuration for Core Data capability
public struct CoreDataCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let storeType: String
    public let modelName: String
    public let enableAutomaticMigration: Bool
    public let enableLightweightMigration: Bool
    public let enableWALMode: Bool
    public let enablePredicateEvaluation: Bool
    public let maxConcurrentOperations: Int
    
    public init(
        storeType: String = NSSQLiteStoreType,
        modelName: String,
        enableAutomaticMigration: Bool = true,
        enableLightweightMigration: Bool = true,
        enableWALMode: Bool = true,
        enablePredicateEvaluation: Bool = true,
        maxConcurrentOperations: Int = 10
    ) {
        self.storeType = storeType
        self.modelName = modelName
        self.enableAutomaticMigration = enableAutomaticMigration
        self.enableLightweightMigration = enableLightweightMigration
        self.enableWALMode = enableWALMode
        self.enablePredicateEvaluation = enablePredicateEvaluation
        self.maxConcurrentOperations = maxConcurrentOperations
    }
    
    public var isValid: Bool {
        !modelName.isEmpty && maxConcurrentOperations > 0
    }
    
    public func merged(with other: CoreDataCapabilityConfiguration) -> CoreDataCapabilityConfiguration {
        CoreDataCapabilityConfiguration(
            storeType: other.storeType,
            modelName: other.modelName,
            enableAutomaticMigration: other.enableAutomaticMigration,
            enableLightweightMigration: other.enableLightweightMigration,
            enableWALMode: other.enableWALMode,
            enablePredicateEvaluation: other.enablePredicateEvaluation,
            maxConcurrentOperations: other.maxConcurrentOperations
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> CoreDataCapabilityConfiguration {
        var adjustedOperations = maxConcurrentOperations
        var adjustedWAL = enableWALMode
        
        if environment.isLowPowerMode {
            adjustedOperations = max(1, maxConcurrentOperations / 2)
            adjustedWAL = false
        }
        
        return CoreDataCapabilityConfiguration(
            storeType: storeType,
            modelName: modelName,
            enableAutomaticMigration: enableAutomaticMigration,
            enableLightweightMigration: enableLightweightMigration,
            enableWALMode: adjustedWAL,
            enablePredicateEvaluation: enablePredicateEvaluation,
            maxConcurrentOperations: adjustedOperations
        )
    }
}

// MARK: - Core Data Operations

/// Core Data operation types
public enum CoreDataOperation: Sendable {
    case fetch(String) // Entity name
    case save
    case delete(String) // Object ID string
    case batchUpdate(String) // Entity name
    case batchDelete(String) // Entity name
}

/// Core Data execution context
public struct CoreDataExecutionContext: Sendable {
    public let operationId: UUID
    public let startTime: Date
    public let operationType: String
    public let metadata: [String: String]
    
    public init(
        operationId: UUID = UUID(),
        startTime: Date = Date(),
        operationType: String,
        metadata: [String: String] = [:]
    ) {
        self.operationId = operationId
        self.startTime = startTime
        self.operationType = operationType
        self.metadata = metadata
    }
}

// MARK: - Core Data Resource

/// Core Data resource management
public actor CoreDataCapabilityResource: AxiomCapabilityResource {
    private let configuration: CoreDataCapabilityConfiguration
    private var persistentContainer: NSPersistentContainer?
    private var viewContext: NSManagedObjectContext?
    private var backgroundContext: NSManagedObjectContext?
    
    public init(configuration: CoreDataCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public func allocate() async throws {
        guard let modelURL = Bundle.main.url(forResource: configuration.modelName, withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            throw AxiomCapabilityError.initializationFailed("Core Data model '\(configuration.modelName)' not found")
        }
        
        persistentContainer = NSPersistentContainer(name: configuration.modelName, managedObjectModel: model)
        
        // Configure store description
        let storeDescription = persistentContainer!.persistentStoreDescriptions.first!
        storeDescription.type = configuration.storeType
        storeDescription.shouldMigrateStoreAutomatically = configuration.enableAutomaticMigration
        storeDescription.shouldInferMappingModelAutomatically = configuration.enableLightweightMigration
        
        if configuration.enableWALMode && configuration.storeType == NSSQLiteStoreType {
            storeDescription.setOption("WAL" as NSString, forKey: "journal_mode")
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            persistentContainer!.loadPersistentStores { _, error in
                if let error = error {
                    continuation.resume(throwing: AxiomCapabilityError.initializationFailed("Core Data store loading failed: \(error.localizedDescription)"))
                } else {
                    continuation.resume()
                }
            }
        }
        
        // Set up contexts
        viewContext = persistentContainer!.viewContext
        viewContext!.automaticallyMergesChangesFromParent = true
        
        backgroundContext = persistentContainer!.newBackgroundContext()
        backgroundContext!.automaticallyMergesChangesFromParent = true
    }
    
    public func deallocate() async {
        viewContext = nil
        backgroundContext = nil
        persistentContainer = nil
    }
    
    public var isAllocated: Bool {
        persistentContainer != nil
    }
    
    public func updateConfiguration(_ configuration: CoreDataCapabilityConfiguration) async throws {
        // Core Data configuration changes require reallocation
        if isAllocated {
            await deallocate()
            try await allocate()
        }
    }
    
    // MARK: - Core Data Access
    
    public var container: NSPersistentContainer? {
        persistentContainer
    }
    
    public var mainContext: NSManagedObjectContext? {
        viewContext
    }
    
    public func createBackgroundContext() -> NSManagedObjectContext? {
        persistentContainer?.newBackgroundContext()
    }
}

// MARK: - Core Data Capability Implementation

/// Core Data capability providing managed object persistence
public actor CoreDataCapability: DomainCapability {
    public typealias ConfigurationType = CoreDataCapabilityConfiguration
    public typealias ResourceType = CoreDataCapabilityResource
    
    private var _configuration: CoreDataCapabilityConfiguration
    private var _resources: CoreDataCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(30)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "core-data-capability" }
    
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
    
    public var configuration: CoreDataCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: CoreDataCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: CoreDataCapabilityConfiguration,
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = CoreDataCapabilityResource(configuration: self._configuration)
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
        await _resources.deallocate()
        await transitionTo(.unavailable)
        stateStreamContinuation?.finish()
    }
    
    // MARK: - DomainCapability Protocol
    
    public func updateConfiguration(_ configuration: CoreDataCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Core Data configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        try await _resources.updateConfiguration(_configuration)
    }
    
    public func isSupported() async -> Bool {
        // Core Data is available on all Apple platforms
        true
    }
    
    public func requestPermission() async throws {
        // Core Data doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Core Data Operations
    
    /// Perform a fetch operation
    public func fetch<T: NSManagedObject>(_ request: NSFetchRequest<T>) async throws -> [T] {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Core Data capability not available")
        }
        
        let context = await _resources.mainContext
        guard let context = context else {
            throw AxiomCapabilityError.resourceAllocationFailed("Core Data context not available")
        }
        
        return try await context.perform {
            try context.fetch(request)
        }
    }
    
    /// Perform a background fetch operation
    public func backgroundFetch<T: NSManagedObject>(_ request: NSFetchRequest<T>) async throws -> [T] {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Core Data capability not available")
        }
        
        let context = await _resources.createBackgroundContext()
        guard let context = context else {
            throw AxiomCapabilityError.resourceAllocationFailed("Core Data background context not available")
        }
        
        return try await context.perform {
            try context.fetch(request)
        }
    }
    
    /// Save the main context
    public func save() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Core Data capability not available")
        }
        
        let context = await _resources.mainContext
        guard let context = context else {
            throw AxiomCapabilityError.resourceAllocationFailed("Core Data context not available")
        }
        
        try await context.perform {
            if context.hasChanges {
                try context.save()
            }
        }
    }
    
    /// Perform a background save operation
    public func backgroundSave(operation: @escaping (NSManagedObjectContext) throws -> Void) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Core Data capability not available")
        }
        
        let context = await _resources.createBackgroundContext()
        guard let context = context else {
            throw AxiomCapabilityError.resourceAllocationFailed("Core Data background context not available")
        }
        
        try await context.perform {
            try operation(context)
            if context.hasChanges {
                try context.save()
            }
        }
    }
    
    /// Execute batch operation
    public func executeBatchRequest(_ request: NSPersistentStoreRequest) async throws -> NSPersistentStoreResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.capabilityUnavailable("Core Data capability not available")
        }
        
        let container = await _resources.container
        guard let container = container else {
            throw AxiomCapabilityError.resourceAllocationFailed("Core Data container not available")
        }
        
        let context = container.newBackgroundContext()
        return try await context.perform {
            try context.execute(request)
        }
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Extensions

extension AxiomCapabilityError {
    /// Core Data specific errors
    public static func coreDataError(_ message: String) -> AxiomCapabilityError {
        .operationFailed("Core Data: \(message)")
    }
    
    public static func coreDataModelNotFound(_ modelName: String) -> AxiomCapabilityError {
        .initializationFailed("Core Data model '\(modelName)' not found in bundle")
    }
    
    public static func coreDataStoreLoadFailed(_ error: Error) -> AxiomCapabilityError {
        .initializationFailed("Core Data store loading failed: \(error.localizedDescription)")
    }
}