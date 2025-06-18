import Foundation
import CoreData
import AxiomCore
import AxiomCapabilities

public actor CoreDataCapability: AxiomCapability {
    public let id = UUID()
    public let name = "CoreData"
    public let version = "1.0.0"
    
    private let modelName: String
    private let storeType: String
    private let storeURL: URL?
    
    private var _persistentContainer: NSPersistentContainer?
    
    private var persistentContainer: NSPersistentContainer {
        if let container = _persistentContainer {
            return container
        }
        
        let container = NSPersistentContainer(name: modelName)
        
        if let storeURL = storeURL {
            let description = NSPersistentStoreDescription(url: storeURL)
            description.type = storeType
            container.persistentStoreDescriptions = [description]
        }
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data failed to load store: \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        _persistentContainer = container
        return container
    }
    
    public var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    public init(
        modelName: String,
        storeType: String = NSSQLiteStoreType,
        storeURL: URL? = nil
    ) {
        self.modelName = modelName
        self.storeType = storeType
        self.storeURL = storeURL
    }
    
    public func activate() async throws {
        _ = persistentContainer
    }
    
    public func deactivate() async {
    }
    
    public var isAvailable: Bool {
        return true
    }
    
    public func save() async throws {
        let context = viewContext
        
        if context.hasChanges {
            try context.save()
        }
    }
    
    public func saveInBackground() async throws {
        try await withCheckedThrowingContinuation { continuation in
            persistentContainer.performBackgroundTask { context in
                do {
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
    
    public func fetch<T: NSManagedObject>(
        _ entityType: T.Type,
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor] = [],
        limit: Int? = nil
    ) async throws -> [T] {
        let request = NSFetchRequest<T>(entityName: String(describing: entityType))
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        
        if let limit = limit {
            request.fetchLimit = limit
        }
        
        return try viewContext.fetch(request)
    }
    
    public func fetchFirst<T: NSManagedObject>(
        _ entityType: T.Type,
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor] = []
    ) async throws -> T? {
        let results = try await fetch(entityType, predicate: predicate, sortDescriptors: sortDescriptors, limit: 1)
        return results.first
    }
    
    public func count<T: NSManagedObject>(
        _ entityType: T.Type,
        predicate: NSPredicate? = nil
    ) async throws -> Int {
        let request = NSFetchRequest<T>(entityName: String(describing: entityType))
        request.predicate = predicate
        request.includesSubentities = false
        
        return try viewContext.count(for: request)
    }
    
    public func delete(_ object: NSManagedObject) async throws {
        viewContext.delete(object)
        try await save()
    }
    
    public func deleteAll<T: NSManagedObject>(_ entityType: T.Type, predicate: NSPredicate? = nil) async throws {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: entityType))
        request.predicate = predicate
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        deleteRequest.resultType = .resultTypeObjectIDs
        
        let result = try viewContext.execute(deleteRequest) as? NSBatchDeleteResult
        
        if let objectIDs = result?.result as? [NSManagedObjectID] {
            let changes = [NSDeletedObjectsKey: objectIDs]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [viewContext])
        }
    }
    
    public func createEntity<T: NSManagedObject>(_ entityType: T.Type) -> T {
        let entityName = String(describing: entityType)
        return NSEntityDescription.insertNewObject(forEntityName: entityName, into: viewContext) as! T
    }
    
    public func performBackgroundTask<T: Sendable>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            persistentContainer.performBackgroundTask { context in
                do {
                    let result = try block(context)
                    try context.save()
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func batchUpdate<T: NSManagedObject>(
        _ entityType: T.Type,
        predicate: NSPredicate? = nil,
        properties: [String: Any]
    ) async throws {
        let request = NSBatchUpdateRequest(entityName: String(describing: entityType))
        request.predicate = predicate
        request.propertiesToUpdate = properties
        request.resultType = .updatedObjectIDsResultType
        
        let result = try viewContext.execute(request) as? NSBatchUpdateResult
        
        if let objectIDs = result?.result as? [NSManagedObjectID] {
            let changes = [NSUpdatedObjectsKey: objectIDs]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [viewContext])
        }
    }
    
    public func exportData() async throws -> Data {
        let stores = persistentContainer.persistentStoreCoordinator.persistentStores
        guard let store = stores.first else {
            throw CoreDataError.noStoreFound
        }
        
        return try Data(contentsOf: store.url!)
    }
    
    public func importData(from data: Data) async throws {
        guard let storeURL = storeURL else {
            throw CoreDataError.noStoreURL
        }
        
        try data.write(to: storeURL)
        
        try await withCheckedThrowingContinuation { continuation in
            persistentContainer.performBackgroundTask { context in
                do {
                    context.refreshAllObjects()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func resetStore() async throws {
        let coordinator = persistentContainer.persistentStoreCoordinator
        
        for store in coordinator.persistentStores {
            try coordinator.remove(store)
            if let storeURL = store.url {
                try FileManager.default.removeItem(at: storeURL)
            }
        }
        
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to reload store after reset: \(error)")
            }
        }
    }
    
    public func objectExists<T: NSManagedObject>(_ object: T) -> Bool {
        return !object.objectID.isTemporaryID && viewContext.object(with: object.objectID) != nil
    }
    
    public func refresh(_ object: NSManagedObject, mergeChanges: Bool = true) {
        viewContext.refresh(object, mergeChanges: mergeChanges)
    }
    
    public func rollback() {
        viewContext.rollback()
    }
}

public enum CoreDataError: Error, LocalizedError {
    case noStoreFound
    case noStoreURL
    case fetchFailed(Error)
    case saveFailed(Error)
    case deleteFailed(Error)
    case invalidEntity
    case contextNotAvailable
    
    public var errorDescription: String? {
        switch self {
        case .noStoreFound:
            return "No persistent store found"
        case .noStoreURL:
            return "No store URL configured"
        case .fetchFailed(let error):
            return "Fetch failed: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Save failed: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Delete failed: \(error.localizedDescription)"
        case .invalidEntity:
            return "Invalid entity type"
        case .contextNotAvailable:
            return "Managed object context not available"
        }
    }
}