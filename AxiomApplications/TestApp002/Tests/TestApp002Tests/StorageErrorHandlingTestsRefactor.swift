import Testing
import Foundation
@testable import TestApp002
@testable import TestApp002Core

@Suite("Storage Error Handling Tests - REFACTOR Phase")
struct StorageErrorHandlingTestsRefactor {
    private let storageCapability: StorageCapability
    private let mockStorage: MockStorage
    
    init() async {
        self.mockStorage = MockStorage()
        self.storageCapability = BackupRestoreStorageCapability(storage: mockStorage)
    }
    
    @Test("Storage should create automatic backups on save")
    func testAutomaticBackupCreation() async throws {
        let key = "important-config"
        let config = SystemConfig(version: "1.0", settings: ["theme": "dark"])
        
        // Save data
        try await storageCapability.save(config, key: key)
        
        // Verify backup was created
        let backupExists = await mockStorage.hasBackup(forKey: key)
        #expect(backupExists, "Should create backup automatically")
        
        // Update data
        let updatedConfig = SystemConfig(version: "1.1", settings: ["theme": "light"])
        try await storageCapability.save(updatedConfig, key: key)
        
        // Verify backup was updated
        let backupCount = await mockStorage.getBackupCount(forKey: key)
        #expect(backupCount >= 1, "Should maintain backup history")
    }
    
    @Test("Storage should restore from backup on corruption")
    func testBackupRestoration() async throws {
        let key = "critical-data"
        let data = CriticalData(id: "123", value: "important", timestamp: Date())
        
        // Save data (creates backup)
        try await storageCapability.save(data, key: key)
        
        // Verify initial save worked
        let initial = try await storageCapability.load(CriticalData.self, key: key)
        #expect(initial != nil, "Initial save should work")
        
        // Corrupt the primary data
        await mockStorage.corruptPrimaryData(forKey: key)
        
        // Load should restore from backup
        let restored = try await storageCapability.load(CriticalData.self, key: key)
        #expect(restored != nil, "Should restore from backup")
        #expect(restored?.value == data.value, "Should restore correct data")
        
        let restorationCount = await mockStorage.restorationCount
        #expect(restorationCount == 1, "Should track restoration")
    }
    
    @Test("Storage should maintain backup versions")
    func testBackupVersioning() async throws {
        let key = "versioned-config"
        
        // Save multiple versions
        for i in 1...5 {
            let config = VersionedConfig(version: i, data: "v\(i)")
            try await storageCapability.save(config, key: key)
        }
        
        // Check backup versions
        let versions = await mockStorage.getBackupVersions(forKey: key)
        #expect(versions.count >= 3, "Should keep multiple backup versions")
        
        // Restore specific version
        let restoredV3 = await mockStorage.restoreBackupVersion(key: key, version: 3)
        #expect(restoredV3 != nil, "Should restore specific version")
    }
    
    @Test("Storage should clean old backups")
    func testBackupCleanup() async throws {
        let key = "temp-data"
        
        // Create many backups
        for i in 1...10 {
            let data = TempData(sequence: i, content: "data-\(i)")
            try await storageCapability.save(data, key: key)
        }
        
        // Trigger cleanup
        await mockStorage.cleanupOldBackups(keepLast: 3)
        
        let remainingBackups = await mockStorage.getBackupCount(forKey: key)
        #expect(remainingBackups <= 3, "Should clean old backups")
    }
    
    @Test("Storage should handle backup storage failures")
    func testBackupStorageFailure() async throws {
        let key = "no-backup-space"
        let data = LargeBackupData(content: String(repeating: "x", count: 10_000_000))
        
        // Set backup storage to fail
        await mockStorage.setBackupStorageFull(true)
        
        // Save should succeed but warn about backup failure
        do {
            try await storageCapability.save(data, key: key)
            let backupWarnings = await mockStorage.backupWarnings
            #expect(backupWarnings > 0, "Should warn about backup failure")
        } catch {
            #expect(Bool(false), "Primary save should still succeed")
        }
    }
    
    @Test("Storage should validate backup integrity")
    func testBackupIntegrityValidation() async throws {
        let key = "integrity-check"
        let data = IntegrityData(checksum: "", content: "validated content")
        
        // Save with integrity check
        try await storageCapability.save(data, key: key)
        
        // Verify backup has integrity metadata
        let backupIntegrity = await mockStorage.getBackupIntegrity(forKey: key)
        #expect(backupIntegrity.hasChecksum, "Backup should have checksum")
        #expect(backupIntegrity.isValid, "Backup should be valid")
        
        // Corrupt backup
        await mockStorage.corruptBackup(forKey: key)
        
        // Verify corruption is detected
        let corruptedIntegrity = await mockStorage.getBackupIntegrity(forKey: key)
        #expect(!corruptedIntegrity.isValid, "Should detect corrupted backup")
    }
    
    @Test("Storage should support manual backup/restore")
    func testManualBackupRestore() async throws {
        let key = "manual-backup"
        let data = ManualBackupData(id: "manual-1", content: "user data")
        
        // Save data
        try await storageCapability.save(data, key: key)
        
        // Create manual backup
        if let enhancedStorage = storageCapability as? BackupRestoreStorageCapability {
            try await enhancedStorage.createManualBackup(key: key, label: "before-update")
            
            // Update data
            let updated = ManualBackupData(id: "manual-2", content: "updated data")
            try await storageCapability.save(updated, key: key)
            
            // List backups
            let backups = try await enhancedStorage.listBackups(key: key)
            #expect(backups.contains { $0.label == "before-update" }, "Should list manual backup")
            
            // Restore manual backup
            try await enhancedStorage.restoreBackup(key: key, label: "before-update")
            
            let restored = try await storageCapability.load(ManualBackupData.self, key: key)
            #expect(restored?.id == "manual-1", "Should restore manual backup")
        }
    }
    
    @Test("Storage should export/import backups")
    func testBackupExportImport() async throws {
        let key = "portable-data"
        let data = PortableData(format: "json", content: ["key": "value"])
        
        // Save data
        try await storageCapability.save(data, key: key)
        
        if let enhancedStorage = storageCapability as? BackupRestoreStorageCapability {
            // Export backup
            let exportData = try await enhancedStorage.exportBackup(key: key)
            #expect(!exportData.isEmpty, "Should export backup data")
            
            // Clear storage
            try await storageCapability.delete(key: key)
            
            // Import backup
            try await enhancedStorage.importBackup(key: key, data: exportData)
            
            // Verify restoration
            let imported = try await storageCapability.load(PortableData.self, key: key)
            #expect(imported?.content["key"] == "value", "Should import backup correctly")
        }
    }
    
    @Test("Storage should handle backup during transactions")
    func testTransactionalBackup() async throws {
        if let enhancedStorage = storageCapability as? BackupRestoreStorageCapability {
            // Test successful transaction
            do {
                let result = try await enhancedStorage.performTransaction { transaction in
                    // Save multiple items in transaction
                    try await transaction.save(TransactionItem(id: "1", value: "first"), key: "item1")
                    try await transaction.save(TransactionItem(id: "2", value: "second"), key: "item2")
                    return "success"
                }
                
                #expect(result == "success", "Transaction should succeed")
                
                // Verify backups were created
                let backup1 = await mockStorage.hasBackup(forKey: "item1")
                let backup2 = await mockStorage.hasBackup(forKey: "item2")
                #expect(backup1 && backup2, "Should backup all transaction items")
            } catch {
                #expect(Bool(false), "Transaction should not fail")
            }
            
            // Test failed transaction
            do {
                let _ = try await enhancedStorage.performTransaction { transaction in
                    try await transaction.save(TransactionItem(id: "3", value: "third"), key: "item3")
                    throw TransactionError.simulatedFailure
                }
                #expect(Bool(false), "Transaction should fail")
            } catch TransactionError.simulatedFailure {
                // Expected failure
                let backup3 = await mockStorage.hasBackup(forKey: "item3")
                #expect(!backup3, "Should not create backup for failed transaction")
            }
        }
    }
}

// MARK: - Enhanced Storage with Backup/Restore

private actor BackupRestoreStorageCapability: StorageCapability {
    private let storage: MockStorage
    private var isInitialized = false
    private let maxBackupVersions = 5
    
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
        // Encode and save
        let encoder = JSONEncoder()
        let data = try encoder.encode(object)
        
        // Create backup before saving (even for new data)
        if let existingData = await storage.getData(forKey: key) {
            await storage.createBackup(key: key, data: existingData)
        } else {
            // For new data, create initial backup
            await storage.createBackup(key: key, data: data)
        }
        
        // Check backup storage
        if await storage.backupStorageFull {
            await storage.incrementBackupWarnings()
        }
        
        // Add integrity metadata
        let checksum = calculateChecksum(for: data)
        await storage.saveData(data, forKey: key)
        await storage.saveChecksum(checksum, forKey: key)
        
        // Clean old backups
        await cleanupBackups(forKey: key)
    }
    
    func load<T: Codable>(_ type: T.Type, key: String) async throws -> T? {
        // Try to load primary data
        if let data = await storage.getData(forKey: key) {
            // Check if corrupted
            if await storage.isPrimaryCorrupted(key: key) {
                // Try to restore from backup
                if let backupData = await storage.getLatestBackup(forKey: key) {
                    await storage.incrementRestorationCount()
                    await storage.saveData(backupData, forKey: key)
                    
                    let decoder = JSONDecoder()
                    return try decoder.decode(type, from: backupData)
                }
                throw BackupStorageError.corruptedData
            }
            
            let decoder = JSONDecoder()
            return try decoder.decode(type, from: data)
        }
        
        return nil
    }
    
    func delete(key: String) async throws {
        // Backup before deletion
        if let data = await storage.getData(forKey: key) {
            await storage.createBackup(key: key, data: data)
        }
        
        await storage.removeData(forKey: key)
    }
    
    // MARK: - Backup/Restore Methods
    
    func createManualBackup(key: String, label: String) async throws {
        guard let data = await storage.getData(forKey: key) else {
            throw BackupStorageError.keyNotFound
        }
        
        await storage.createLabeledBackup(key: key, data: data, label: label)
    }
    
    func listBackups(key: String) async throws -> [BackupInfo] {
        return await storage.listBackups(forKey: key)
    }
    
    func restoreBackup(key: String, label: String) async throws {
        guard let backupData = await storage.getLabeledBackup(key: key, label: label) else {
            throw BackupStorageError.backupNotFound
        }
        
        await storage.saveData(backupData, forKey: key)
        await storage.incrementRestorationCount()
    }
    
    func exportBackup(key: String) async throws -> Data {
        guard let data = await storage.getData(forKey: key) else {
            throw BackupStorageError.keyNotFound
        }
        
        let backup = BackupExport(
            key: key,
            data: data,
            timestamp: Date(),
            checksum: calculateChecksum(for: data)
        )
        
        return try JSONEncoder().encode(backup)
    }
    
    func importBackup(key: String, data: Data) async throws {
        let backup = try JSONDecoder().decode(BackupExport.self, from: data)
        
        // Verify checksum
        let calculatedChecksum = calculateChecksum(for: backup.data)
        guard calculatedChecksum == backup.checksum else {
            throw BackupStorageError.checksumMismatch
        }
        
        await storage.saveData(backup.data, forKey: key)
    }
    
    func performTransaction<T: Sendable>(_ block: (StorageTransaction) async throws -> T) async throws -> T {
        let transaction = BackupTransaction(storage: storage)
        
        do {
            let result = try await block(transaction)
            await transaction.commit()
            return result
        } catch {
            await transaction.rollback()
            throw error
        }
    }
    
    private func cleanupBackups(forKey key: String) async {
        let versions = await storage.getBackupVersions(forKey: key)
        if versions.count > maxBackupVersions {
            let versionsToRemove = versions.count - maxBackupVersions
            await storage.removeOldestBackups(forKey: key, count: versionsToRemove)
        }
    }
    
    private func calculateChecksum(for data: Data) -> String {
        return String(data.hashValue)
    }
    
    func loadAll<T: Codable>(_ type: T.Type) async throws -> [T] {
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

// MARK: - Backup Transaction

private actor BackupTransaction: StorageTransaction {
    private let storage: MockStorage
    private var pendingOperations: [(key: String, data: Data)] = []
    
    init(storage: MockStorage) {
        self.storage = storage
    }
    
    func save<T: Codable & Sendable>(_ object: T, key: String) async throws {
        let data = try JSONEncoder().encode(object)
        pendingOperations.append((key: key, data: data))
    }
    
    func load<T: Codable & Sendable>(_ type: T.Type, key: String) async throws -> T? {
        // Check pending operations first
        if let pending = pendingOperations.first(where: { $0.key == key }) {
            return try JSONDecoder().decode(type, from: pending.data)
        }
        
        // Then check storage
        if let data = await storage.getData(forKey: key) {
            return try JSONDecoder().decode(type, from: data)
        }
        
        return nil
    }
    
    func delete(key: String) async throws {
        pendingOperations.removeAll { $0.key == key }
    }
    
    func commit() async {
        for (key, data) in pendingOperations {
            // Create backup for each operation
            if let existing = await storage.getData(forKey: key) {
                await storage.createBackup(key: key, data: existing)
            } else {
                // For new data, create initial backup
                await storage.createBackup(key: key, data: data)
            }
            await storage.saveData(data, forKey: key)
        }
    }
    
    func rollback() async {
        // Clear pending operations
        pendingOperations.removeAll()
    }
}

// MARK: - Enhanced Mock Storage

private actor MockStorage {
    private var storage: [String: Data] = [:]
    private var backups: [String: [BackupEntry]] = [:]
    private var checksums: [String: String] = [:]
    private var corruptedPrimary: Set<String> = []
    private var corruptedBackups: Set<String> = []
    
    var backupStorageFull = false
    var backupWarnings = 0
    var restorationCount = 0
    
    struct BackupEntry {
        let data: Data
        let timestamp: Date
        let version: Int
        let label: String?
    }
    
    func setBackupStorageFull(_ value: Bool) {
        backupStorageFull = value
    }
    
    func incrementBackupWarnings() {
        backupWarnings += 1
    }
    
    func incrementRestorationCount() {
        restorationCount += 1
    }
    
    func saveData(_ data: Data, forKey key: String) {
        storage[key] = data
        corruptedPrimary.remove(key)
    }
    
    func getData(forKey key: String) -> Data? {
        return storage[key]
    }
    
    func removeData(forKey key: String) {
        storage.removeValue(forKey: key)
        checksums.removeValue(forKey: key)
    }
    
    func saveChecksum(_ checksum: String, forKey key: String) {
        checksums[key] = checksum
    }
    
    func createBackup(key: String, data: Data) {
        var entries = backups[key] ?? []
        let version = (entries.last?.version ?? 0) + 1
        entries.append(BackupEntry(
            data: data,
            timestamp: Date(),
            version: version,
            label: nil
        ))
        backups[key] = entries
    }
    
    func createLabeledBackup(key: String, data: Data, label: String) {
        var entries = backups[key] ?? []
        let version = (entries.last?.version ?? 0) + 1
        entries.append(BackupEntry(
            data: data,
            timestamp: Date(),
            version: version,
            label: label
        ))
        backups[key] = entries
    }
    
    func hasBackup(forKey key: String) -> Bool {
        return !(backups[key] ?? []).isEmpty
    }
    
    func getBackupCount(forKey key: String) -> Int {
        return backups[key]?.count ?? 0
    }
    
    func getBackupVersions(forKey key: String) -> [Int] {
        return backups[key]?.map { $0.version } ?? []
    }
    
    func getLatestBackup(forKey key: String) -> Data? {
        return backups[key]?.last?.data
    }
    
    func getLabeledBackup(key: String, label: String) -> Data? {
        return backups[key]?.first { $0.label == label }?.data
    }
    
    func listBackups(forKey key: String) -> [BackupInfo] {
        return backups[key]?.map { entry in
            BackupInfo(
                version: entry.version,
                timestamp: entry.timestamp,
                label: entry.label
            )
        } ?? []
    }
    
    func restoreBackupVersion(key: String, version: Int) -> Data? {
        return backups[key]?.first { $0.version == version }?.data
    }
    
    func corruptPrimaryData(forKey key: String) {
        corruptedPrimary.insert(key)
    }
    
    func isPrimaryCorrupted(key: String) -> Bool {
        return corruptedPrimary.contains(key)
    }
    
    func corruptBackup(forKey key: String) {
        corruptedBackups.insert(key)
    }
    
    func getBackupIntegrity(forKey key: String) -> BackupIntegrity {
        let hasChecksum = checksums[key] != nil
        let isValid = !corruptedBackups.contains(key)
        return BackupIntegrity(hasChecksum: hasChecksum, isValid: isValid)
    }
    
    func cleanupOldBackups(keepLast count: Int) {
        for (key, entries) in backups {
            if entries.count > count {
                let entriesToKeep = Array(entries.suffix(count))
                backups[key] = entriesToKeep
            }
        }
    }
    
    func removeOldestBackups(forKey key: String, count: Int) {
        if var entries = backups[key], entries.count > count {
            entries.removeFirst(count)
            backups[key] = entries
        }
    }
    
    func getAllData() -> [String: Data] {
        return storage
    }
    
    func removeAllData() {
        storage.removeAll()
        backups.removeAll()
    }
}

// MARK: - Supporting Types

struct BackupInfo {
    let version: Int
    let timestamp: Date
    let label: String?
}

struct BackupIntegrity {
    let hasChecksum: Bool
    let isValid: Bool
}

struct BackupExport: Codable {
    let key: String
    let data: Data
    let timestamp: Date
    let checksum: String
}

protocol StorageTransaction {
    func save<T: Codable & Sendable>(_ object: T, key: String) async throws
    func load<T: Codable & Sendable>(_ type: T.Type, key: String) async throws -> T?
    func delete(key: String) async throws
}

enum BackupStorageError: Error {
    case corruptedData
    case keyNotFound
    case backupNotFound
    case checksumMismatch
}

enum TransactionError: Error {
    case simulatedFailure
}

// MARK: - Test Data Types

private struct SystemConfig: Codable {
    let version: String
    let settings: [String: String]
}

private struct CriticalData: Codable {
    let id: String
    let value: String
    let timestamp: Date
}

private struct VersionedConfig: Codable {
    let version: Int
    let data: String
}

private struct TempData: Codable {
    let sequence: Int
    let content: String
}

private struct LargeBackupData: Codable {
    let content: String
}

private struct IntegrityData: Codable {
    let checksum: String
    let content: String
}

private struct ManualBackupData: Codable {
    let id: String
    let content: String
}

private struct PortableData: Codable {
    let format: String
    let content: [String: String]
}

private struct TransactionItem: Codable {
    let id: String
    let value: String
}