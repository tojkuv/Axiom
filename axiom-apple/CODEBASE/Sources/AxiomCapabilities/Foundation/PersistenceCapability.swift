import Foundation
import AxiomCore
import AxiomArchitecture
@preconcurrency import CoreData

// Core persistence capability protocol
public protocol PersistenceCapability: AxiomCapability {
    /// Save state to persistent storage
    func save<T: Codable>(_ value: T, for key: String) async throws
    
    /// Load state from persistent storage
    func load<T: Codable>(_ type: T.Type, for key: String) async throws -> T?
    
    /// Load raw data from persistent storage
    func load(key: String) async throws -> Data?
    
    /// Delete state from persistent storage
    func delete(key: String) async throws
    
    /// Check if key exists without loading data
    func exists(key: String) async -> Bool
    
    /// Batch save operations for performance
    func saveBatch<T: Codable>(_ items: [(key: String, value: T)]) async throws
    
    /// Batch delete operations
    func deleteBatch(keys: [String]) async throws
    
    /// Migrate data between versions
    func migrate(from oldVersion: String, to newVersion: String) async throws
}

// Persistable client protocol
public protocol Persistable: AxiomClient {
    /// Keys for persisted properties
    static var persistedKeys: [String] { get }
    
    /// Persistence capability instance
    var persistence: any PersistenceCapability { get }
    
    /// Persist current state
    func persistState() async throws
}

// Extension to provide default implementation
extension Persistable {
    public func persistState() async throws {
        // This will be implemented by concrete clients
        // Each client knows how to persist its own state
    }
}

// Mock persistence for testing
public actor MockPersistenceCapability: PersistenceCapability {
    private var storage: [String: Data] = [:]
    
    public var saveCount: Int = 0
    public var loadCount: Int = 0
    public var batchSaveCount: Int = 0
    public var batchDeleteCount: Int = 0
    
    public init() {}
    
    public func save<T: Codable & Sendable>(_ value: T, for key: String) async throws {
        saveCount += 1
        let data = try JSONEncoder().encode(value)
        storage[key] = data
    }
    
    public func load<T: Codable & Sendable>(_ type: T.Type, for key: String) async throws -> T? {
        loadCount += 1
        guard let data = storage[key] else { return nil }
        return try JSONDecoder().decode(type, from: data)
    }
    
    public func load(key: String) async throws -> Data? {
        loadCount += 1
        return storage[key]
    }
    
    public func delete(key: String) async throws {
        storage.removeValue(forKey: key)
    }
    
    public func exists(key: String) async -> Bool {
        return storage[key] != nil
    }
    
    public func saveBatch<T: Codable & Sendable>(_ items: [(key: String, value: T)]) async throws {
        batchSaveCount += 1
        let encoder = JSONEncoder()
        for (key, value) in items {
            let data = try encoder.encode(value)
            storage[key] = data
        }
    }
    
    public func deleteBatch(keys: [String]) async throws {
        batchDeleteCount += 1
        for key in keys {
            storage.removeValue(forKey: key)
        }
    }
    
    public func migrate(from oldVersion: String, to newVersion: String) async throws {
        // No-op for mock
    }
    
    // Capability protocol requirements
    public nonisolated var id: String { "mock-persistence" }
    
    public var isAvailable: Bool { true }
    
    public func activate() async throws {
        // No activation needed for mock
    }
    
    public func deactivate() async {
        // Clear storage on deactivation
        storage.removeAll()
    }
    
    public func shutdown() async throws {
        // Clear storage on shutdown
        storage.removeAll()
    }
}

// MARK: - Core Data Implementation

@globalActor
public actor CoreDataActor {
    public static let shared = CoreDataActor()
}

/// Core Data stack manager with CloudKit support
public final class CoreDataStack: @unchecked Sendable {
    public static let shared = CoreDataStack()
    
    private init() {}
    
    // MARK: - Core Data Stack
    
    public lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "AxiomModel")
        
        // Configure for CloudKit sync
        let storeDescription = container.persistentStoreDescriptions.first
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        
        return container
    }()
    
    public var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    public func createBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        return context
    }
    
    @CoreDataActor
    public func save() async throws {
        let context = viewContext
        
        if context.hasChanges {
            try context.save()
        }
    }
    
    @CoreDataActor
    public func saveInBackground(_ block: @escaping @Sendable (NSManagedObjectContext) throws -> Void) async throws {
        let context = createBackgroundContext()
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                do {
                    try block(context)
                    
                    if context.hasChanges {
                        try context.save()
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

/// Core Data-based persistence capability implementation
public actor CoreDataPersistenceCapability: PersistenceCapability {
    private let coreDataStack = CoreDataStack.shared
    
    public nonisolated var id: String { "coredata-persistence" }
    public var isAvailable: Bool { true }
    
    public init() {}
    
    public func activate() async throws {
        // Initialize Core Data stack
        _ = coreDataStack.persistentContainer
    }
    
    public func deactivate() async {
        // Perform final save
        try? await coreDataStack.save()
    }
    
    public func shutdown() async throws {
        try await coreDataStack.save()
    }
    
    // MARK: - Persistence Operations
    
    public func save<T: Codable & Sendable>(_ value: T, for key: String) async throws {
        try await coreDataStack.saveInBackground { context in
            // Create or update stored value entity
            let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "StoredValue")
            request.predicate = NSPredicate(format: "key == %@", key)
            
            let existingObjects = try? context.fetch(request)
            let object = existingObjects?.first ?? NSManagedObject(
                entity: NSEntityDescription.entity(forEntityName: "StoredValue", in: context)!,
                insertInto: context
            )
            
            let data = try JSONEncoder().encode(value)
            object.setValue(key, forKey: "key")
            object.setValue(data, forKey: "data")
            object.setValue(Date(), forKey: "lastModified")
        }
    }
    
    public func load<T: Codable & Sendable>(_ type: T.Type, for key: String) async throws -> T? {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.viewContext.perform {
                do {
                    let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "StoredValue")
                    request.predicate = NSPredicate(format: "key == %@", key)
                    request.fetchLimit = 1
                    
                    let results = try self.coreDataStack.viewContext.fetch(request)
                    
                    guard let object = results.first,
                          let data = object.value(forKey: "data") as? Data else {
                        continuation.resume(returning: nil)
                        return
                    }
                    
                    let value = try JSONDecoder().decode(type, from: data)
                    continuation.resume(returning: value)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func load(key: String) async throws -> Data? {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.viewContext.perform {
                do {
                    let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "StoredValue")
                    request.predicate = NSPredicate(format: "key == %@", key)
                    request.fetchLimit = 1
                    
                    let results = try self.coreDataStack.viewContext.fetch(request)
                    
                    guard let object = results.first,
                          let data = object.value(forKey: "data") as? Data else {
                        continuation.resume(returning: nil)
                        return
                    }
                    
                    continuation.resume(returning: data)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func delete(key: String) async throws {
        try await coreDataStack.saveInBackground { context in
            let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "StoredValue")
            request.predicate = NSPredicate(format: "key == %@", key)
            
            let objects = try? context.fetch(request)
            objects?.forEach { context.delete($0) }
        }
    }
    
    public func exists(key: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            coreDataStack.viewContext.perform {
                let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "StoredValue")
                request.predicate = NSPredicate(format: "key == %@", key)
                request.fetchLimit = 1
                
                do {
                    let count = try self.coreDataStack.viewContext.count(for: request)
                    continuation.resume(returning: count > 0)
                } catch {
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    public func saveBatch<T: Codable & Sendable>(_ items: [(key: String, value: T)]) async throws {
        try await coreDataStack.saveInBackground { context in
            let encoder = JSONEncoder()
            
            for (key, value) in items {
                let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "StoredValue")
                request.predicate = NSPredicate(format: "key == %@", key)
                
                let existingObjects = try? context.fetch(request)
                let object = existingObjects?.first ?? NSManagedObject(
                    entity: NSEntityDescription.entity(forEntityName: "StoredValue", in: context)!,
                    insertInto: context
                )
                
                let data = try encoder.encode(value)
                object.setValue(key, forKey: "key")
                object.setValue(data, forKey: "data")
                object.setValue(Date(), forKey: "lastModified")
            }
        }
    }
    
    public func deleteBatch(keys: [String]) async throws {
        try await coreDataStack.saveInBackground { context in
            for key in keys {
                let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "StoredValue")
                request.predicate = NSPredicate(format: "key == %@", key)
                
                let objects = try? context.fetch(request)
                objects?.forEach { context.delete($0) }
            }
        }
    }
    
    public func migrate(from oldVersion: String, to newVersion: String) async throws {
        // Core Data handles migration automatically with lightweight migration
        // For complex migrations, implement custom migration logic here
    }
    
    // MARK: - Core Data Specific Operations
    
    public func fetch<T: NSManagedObject & Sendable>(_ request: NSFetchRequest<T>) async throws -> [T] {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.viewContext.perform {
                do {
                    let results = try self.coreDataStack.viewContext.fetch(request)
                    continuation.resume(returning: results)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func performBackgroundTask<T: Sendable>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            let context = coreDataStack.createBackgroundContext()
            context.perform {
                do {
                    let result = try block(context)
                    if context.hasChanges {
                        try context.save()
                    }
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Core Data Model Utilities

public extension NSManagedObjectContext {
    func saveIfNeeded() throws {
        if hasChanges {
            try save()
        }
    }
}