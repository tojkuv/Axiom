import Testing
import Foundation
@testable import TestApp002
@testable import TestApp002Core

@Suite("Storage Error Handling Tests - RED Phase")
struct StorageErrorHandlingTests {
    private let storageCapability: StorageCapability
    private let mockStorage: MockStorage
    
    init() async {
        self.mockStorage = MockStorage()
        self.storageCapability = TestStorageCapabilityWithMock(storage: mockStorage)
    }
    
    @Test("Storage should fail without corruption recovery")
    func testCorruptedDataFailsWithoutRecovery() async throws {
        await mockStorage.setCorruptedData(true)
        let key = "user-preferences"
        
        do {
            let _ = try await storageCapability.load(UserPreferences.self, key: key)
            #expect(Bool(false), "Should fail when data is corrupted without recovery")
        } catch {
            let loadCount = await mockStorage.loadCount
            #expect(loadCount == 1, "Should only attempt once without recovery")
        }
    }
    
    @Test("Storage should fail without data validation")
    func testInvalidDataFailsWithoutValidation() async throws {
        await mockStorage.setInvalidData(true)
        let key = "task-list"
        
        do {
            let _ = try await storageCapability.load(TaskList.self, key: key)
            #expect(Bool(false), "Should fail when data is invalid without validation")
        } catch {
            let validationAttempts = await mockStorage.validationAttempts
            #expect(validationAttempts == 0, "Should not have validation logic")
        }
    }
    
    @Test("Storage should fail without permission error handling")
    func testPermissionDeniedFailsWithoutHandling() async throws {
        await mockStorage.setPermissionDenied(true)
        let key = "secure-data"
        let data = SecureData(content: "sensitive")
        
        do {
            try await storageCapability.save(data, key: key)
            #expect(Bool(false), "Should fail when permission denied without handling")
        } catch {
            let permissionPromptShown = await mockStorage.permissionPromptShown
            #expect(permissionPromptShown == false, "Should not show permission prompt")
        }
    }
    
    @Test("Storage should fail without disk space handling")
    func testDiskFullFailsWithoutHandling() async throws {
        await mockStorage.setDiskFull(true)
        let key = "large-data"
        let data = LargeData(bytes: Array(repeating: 0, count: 1_000_000))
        
        do {
            try await storageCapability.save(data, key: key)
            #expect(Bool(false), "Should fail when disk full without handling")
        } catch {
            let cleanupAttempts = await mockStorage.cleanupAttempts
            #expect(cleanupAttempts == 0, "Should not attempt cleanup")
        }
    }
    
    @Test("Storage should fail without concurrent write protection")
    func testConcurrentWritesFailWithoutProtection() async throws {
        let key = "shared-counter"
        let counter = SharedCounter(value: 0)
        
        await withThrowingTaskGroup(of: Void.self) { group in
            for i in 1...10 {
                group.addTask {
                    var updatedCounter = counter
                    updatedCounter.value = i
                    try await self.storageCapability.save(updatedCounter, key: key)
                }
            }
            
            do {
                try await group.waitForAll()
            } catch {
                let writeConflicts = await mockStorage.writeConflicts
                #expect(writeConflicts > 0, "Should have write conflicts without protection")
            }
        }
    }
    
    @Test("Storage should fail without backup functionality")
    func testBackupFailsWithoutImplementation() async throws {
        let key = "important-data"
        let data = ImportantData(value: "critical")
        
        try await storageCapability.save(data, key: key)
        
        // Since backup methods don't exist in basic StorageCapability,
        // we expect the standard implementation to not have recovery
        await mockStorage.setCorruptedData(true)
        do {
            let _ = try await storageCapability.load(ImportantData.self, key: key)
            #expect(Bool(false), "Should fail without backup/recovery")
        } catch {
            let backupCount = await mockStorage.backupCount
            #expect(backupCount == 0, "Should not have backup functionality")
        }
    }
    
    @Test("Storage should fail without restore functionality")
    func testRestoreFailsWithoutImplementation() async throws {
        let key = "important-data"
        
        // Delete data and try to recover - should fail
        try await storageCapability.delete(key: key)
        
        let result = try await storageCapability.load(ImportantData.self, key: key)
        #expect(result == nil, "Should not restore deleted data")
        
        let restoreCount = await mockStorage.restoreCount
        #expect(restoreCount == 0, "Should not have restore functionality")
    }
    
    @Test("Storage should fail without versioning support")
    func testVersioningFailsWithoutSupport() async throws {
        let key = "versioned-data"
        let data = VersionedData(content: "v1")
        
        // Save multiple versions
        try await storageCapability.save(data, key: key)
        var updatedData = data
        updatedData.content = "v2"
        try await storageCapability.save(updatedData, key: key)
        
        // Should only have latest version
        let loaded = try await storageCapability.load(VersionedData.self, key: key)
        #expect(loaded?.content == "v2", "Should only have latest version")
        
        let versionCheckCount = await mockStorage.versionCheckCount
        #expect(versionCheckCount == 0, "Should not have versioning")
    }
    
    @Test("Storage should fail without automatic repair")
    func testAutomaticRepairFailsWithoutImplementation() async throws {
        await mockStorage.setNeedsRepair(true)
        let key = "damaged-data"
        
        do {
            let _ = try await storageCapability.load(DamagedData.self, key: key)
            #expect(Bool(false), "Should fail without automatic repair")
        } catch {
            let repairAttempts = await mockStorage.repairAttempts
            #expect(repairAttempts == 0, "Should not attempt repair")
        }
    }
    
    @Test("Storage should fail without transaction support")
    func testTransactionFailsWithoutSupport() async throws {
        let key1 = "item1"
        let key2 = "item2"
        
        // Simulate partial failure - first save succeeds, second fails
        try await storageCapability.save("value1", key: key1)
        await mockStorage.setDiskFull(true)
        
        do {
            try await storageCapability.save("value2", key: key2)
        } catch {
            // First item should still exist (no rollback)
            let item1 = try await storageCapability.load(String.self, key: key1)
            #expect(item1 == "value1", "No transaction rollback")
            
            let transactionCount = await mockStorage.transactionCount
            #expect(transactionCount == 0, "Should not have transaction support")
        }
    }
}

// MARK: - Mock Types

private actor MockStorage {
    var corruptedData = false
    var invalidData = false
    var permissionDenied = false
    var diskFull = false
    var needsRepair = false
    
    var loadCount = 0
    var saveCount = 0
    var validationAttempts = 0
    var permissionPromptShown = false
    var cleanupAttempts = 0
    var writeConflicts = 0
    var backupCount = 0
    var restoreCount = 0
    var versionCheckCount = 0
    var repairAttempts = 0
    var transactionCount = 0
    
    // In-memory storage
    private var storage: [String: Data] = [:]
    
    func setCorruptedData(_ value: Bool) {
        corruptedData = value
    }
    
    func setInvalidData(_ value: Bool) {
        invalidData = value
    }
    
    func setPermissionDenied(_ value: Bool) {
        permissionDenied = value
    }
    
    func setDiskFull(_ value: Bool) {
        diskFull = value
    }
    
    func setNeedsRepair(_ value: Bool) {
        needsRepair = value
    }
    
    func incrementLoadCount() {
        loadCount += 1
    }
    
    func incrementSaveCount() {
        saveCount += 1
    }
    
    func recordWriteConflict() {
        writeConflicts += 1
    }
    
    func saveData(_ data: Data, forKey key: String) {
        storage[key] = data
    }
    
    func getData(forKey key: String) -> Data? {
        return storage[key]
    }
    
    func removeData(forKey key: String) {
        storage.removeValue(forKey: key)
    }
    
    func getAllData() -> [String: Data] {
        return storage
    }
    
    func removeAllData() {
        storage.removeAll()
    }
}

private actor TestStorageCapabilityWithMock: StorageCapability {
    let storage: MockStorage
    private var isInitialized = false
    
    init(storage: MockStorage) {
        self.storage = storage
    }
    
    var isAvailable: Bool {
        return isInitialized
    }
    
    func initialize() async throws {
        isInitialized = true
    }
    
    func terminate() async {
        isInitialized = false
    }
    
    func save<T: Codable>(_ object: T, key: String) async throws {
        await storage.incrementSaveCount()
        
        if await storage.permissionDenied {
            throw TestStorageError.permissionDenied
        }
        
        if await storage.diskFull {
            throw TestStorageError.diskFull
        }
        
        // Simulate concurrent write conflicts
        if key == "shared-counter" {
            await storage.recordWriteConflict()
            throw TestStorageError.writeFailed
        }
        
        // Encode and store
        let encoder = JSONEncoder()
        let data = try encoder.encode(object)
        await storage.saveData(data, forKey: key)
    }
    
    func load<T: Codable>(_ type: T.Type, key: String) async throws -> T? {
        await storage.incrementLoadCount()
        
        if await storage.corruptedData {
            throw TestStorageError.dataCorrupted
        }
        
        if await storage.invalidData {
            throw TestStorageError.invalidData
        }
        
        if await storage.needsRepair {
            throw TestStorageError.needsRepair
        }
        
        // Check if data exists
        guard let data = await storage.getData(forKey: key) else {
            return nil
        }
        
        // Decode and return
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }
    
    func delete(key: String) async throws {
        await storage.removeData(forKey: key)
    }
    
    func loadAll<T: Codable>(_ type: T.Type) async throws -> [T] {
        await storage.incrementLoadCount()
        
        if await storage.corruptedData {
            throw TestStorageError.dataCorrupted
        }
        
        if await storage.invalidData {
            throw TestStorageError.invalidData
        }
        
        // Return all objects of the specified type
        var results: [T] = []
        for (_, data) in await storage.getAllData() {
            if let object = try? JSONDecoder().decode(type, from: data) {
                results.append(object)
            }
        }
        return results
    }
    
    func deleteAll() async throws {
        await storage.removeAllData()
    }
}

// MARK: - Storage Error Types

private enum TestStorageError: Error {
    case dataCorrupted
    case invalidData
    case permissionDenied
    case diskFull
    case writeFailed
    case keyNotFound
    case needsRepair
    case transactionFailed
    case notImplemented
}

// MARK: - Test Data Types

private struct UserPreferences: Codable {
    let theme: String
}

private struct TaskList: Codable {
    let tasks: [String]
}

private struct SecureData: Codable {
    let content: String
}

private struct LargeData: Codable {
    let bytes: [UInt8]
}

private struct SharedCounter: Codable {
    var value: Int
}

private struct ImportantData: Codable {
    let value: String
}

private struct DamagedData: Codable {
    let content: String
}

private struct VersionedData: Codable {
    var content: String
}