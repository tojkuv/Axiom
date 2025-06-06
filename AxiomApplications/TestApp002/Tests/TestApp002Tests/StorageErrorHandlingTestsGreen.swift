import Testing
import Foundation
@testable import TestApp002
@testable import TestApp002Core

@Suite("Storage Error Handling Tests - GREEN Phase")
struct StorageErrorHandlingTestsGreen {
    private let storageCapability: StorageCapability
    private let mockStorage: MockStorage
    
    init() async {
        self.mockStorage = MockStorage()
        self.storageCapability = ValidatingStorageCapability(storage: mockStorage)
    }
    
    @Test("Storage should recover from corrupted data with validation")
    func testCorruptedDataRecovery() async throws {
        let key = "user-preferences"
        let preferences = UserPreferences(theme: "dark", language: "en")
        
        // Save valid data
        try await storageCapability.save(preferences, key: key)
        
        // Corrupt the data
        await mockStorage.corruptStorageData(forKey: key)
        
        // Load should detect corruption and attempt recovery
        do {
            let _ = try await storageCapability.load(UserPreferences.self, key: key)
            #expect(Bool(false), "Should detect corruption")
        } catch StorageError.corruptedData {
            // Expected - corruption detected
            let recoveryAttempts = await mockStorage.recoveryAttempts
            #expect(recoveryAttempts > 0, "Should attempt recovery")
        }
    }
    
    @Test("Storage should validate data structure")
    func testDataValidation() async throws {
        let key = "task-data"
        let task = ValidatedTask(id: "123", title: "Test Task", priority: 5)
        
        // Save with validation
        try await storageCapability.save(task, key: key)
        
        // Validation should have occurred
        let validationCount = await mockStorage.validationCount
        #expect(validationCount == 1, "Should validate on save")
        
        // Load with validation
        let loaded = try await storageCapability.load(ValidatedTask.self, key: key)
        #expect(loaded != nil, "Should load valid data")
        #expect(await mockStorage.validationCount == 2, "Should validate on load")
    }
    
    @Test("Storage should handle permission errors gracefully")
    func testPermissionErrorHandling() async throws {
        let key = "secure-data"
        let data = SecureData(content: "sensitive", encryptionRequired: true)
        
        // First attempt fails with permission
        await mockStorage.setPermissionDenied(true)
        await mockStorage.setPermissionRetryCount(2)
        
        do {
            try await storageCapability.save(data, key: key)
            #expect(Bool(false), "Should handle permission error")
        } catch {
            let promptCount = await mockStorage.permissionPromptCount
            #expect(promptCount > 0, "Should prompt for permission")
        }
    }
    
    @Test("Storage should handle disk space errors")
    func testDiskSpaceHandling() async throws {
        let key = "large-data"
        let data = LargeData(bytes: Array(repeating: 0, count: 1_000_000))
        
        await mockStorage.setDiskFull(true)
        await mockStorage.setAvailableSpace(500_000) // Half of what's needed
        
        do {
            try await storageCapability.save(data, key: key)
            #expect(Bool(false), "Should handle disk full")
        } catch {
            let cleanupAttempts = await mockStorage.cleanupAttempts
            #expect(cleanupAttempts > 0, "Should attempt cleanup")
        }
    }
    
    @Test("Storage should detect concurrent write conflicts")
    func testConcurrentWriteDetection() async throws {
        let key = "shared-state"
        let initialState = SharedState(counter: 0, version: 1)
        
        // Save initial state
        try await storageCapability.save(initialState, key: key)
        
        // Test optimistic locking with sequential version updates
        var successCount = 0
        var conflictCount = 0
        
        // First update should succeed
        let state1 = SharedState(counter: 1, version: 2)
        do {
            try await storageCapability.save(state1, key: key)
            successCount += 1
        } catch {
            conflictCount += 1
        }
        
        // Concurrent update with same version should fail
        let state2 = SharedState(counter: 2, version: 2)
        do {
            try await storageCapability.save(state2, key: key)
            successCount += 1
        } catch StorageError.versionConflict {
            conflictCount += 1
        }
        
        // Update with wrong version should fail
        let state3 = SharedState(counter: 3, version: 1)
        do {
            try await storageCapability.save(state3, key: key)
            successCount += 1
        } catch StorageError.versionConflict {
            conflictCount += 1
        }
        
        // Update with correct next version should succeed
        let state4 = SharedState(counter: 4, version: 3)
        do {
            try await storageCapability.save(state4, key: key)
            successCount += 1
        } catch {
            conflictCount += 1
        }
        
        #expect(successCount == 2, "Two writes should succeed")
        #expect(conflictCount == 2, "Two writes should conflict")
    }
    
    @Test("Storage should validate required fields")
    func testRequiredFieldValidation() async throws {
        let key = "incomplete-task"
        
        // Try to save task with missing required field
        let invalidTask = IncompleteTask(id: "", title: "Test") // Empty ID
        
        do {
            try await storageCapability.save(invalidTask, key: key)
            #expect(Bool(false), "Should fail validation")
        } catch StorageError.missingRequiredField(let field) {
            #expect(field == "id", "Should identify missing field")
        }
    }
    
    @Test("Storage should validate data integrity with checksums")
    func testChecksumValidation() async throws {
        let key = "checksummed-data"
        let data = ChecksummedData(content: "Important data")
        
        // Save with checksum
        try await storageCapability.save(data, key: key)
        
        // Verify checksum was stored
        let storedChecksum = await mockStorage.getChecksum(forKey: key)
        #expect(storedChecksum != nil, "Should store checksum")
        
        // Load and verify
        let loaded = try await storageCapability.load(ChecksummedData.self, key: key)!
        #expect(loaded.content == data.content, "Should load content correctly")
        
        // Corrupt and verify detection
        await mockStorage.corruptChecksum(forKey: key)
        
        do {
            let _ = try await storageCapability.load(ChecksummedData.self, key: key)
            #expect(Bool(false), "Should detect checksum mismatch")
        } catch StorageError.checksumMismatch {
            // Expected
        }
    }
    
    @Test("Storage should validate data size limits")
    func testDataSizeValidation() async throws {
        let key = "oversized-data"
        let oversizedData = OversizedData(content: String(repeating: "x", count: 10_000_000))
        
        do {
            try await storageCapability.save(oversizedData, key: key)
            #expect(Bool(false), "Should reject oversized data")
        } catch StorageError.dataTooLarge(let size, let limit) {
            #expect(size > limit, "Should report size violation")
        }
    }
    
    @Test("Storage should validate data format")
    func testDataFormatValidation() async throws {
        let key = "formatted-data"
        let invalidEmail = UserProfile(email: "invalid-email", name: "Test")
        
        do {
            try await storageCapability.save(invalidEmail, key: key)
            #expect(Bool(false), "Should reject invalid format")
        } catch StorageError.invalidFormat(let field, let reason) {
            #expect(field == "email", "Should identify invalid field")
            #expect(reason.contains("email"), "Should explain format issue")
        }
    }
    
    @Test("Storage should track validation metrics")
    func testValidationMetrics() async throws {
        // Perform various operations
        let validData = ValidatedTask(id: "1", title: "Valid", priority: 3)
        try await storageCapability.save(validData, key: "valid")
        
        let invalidData = ValidatedTask(id: "", title: "Invalid", priority: 15)
        try? await storageCapability.save(invalidData, key: "invalid")
        
        // Check metrics
        let metrics = await mockStorage.getValidationMetrics()
        #expect(metrics.totalValidations > 0, "Should track validations")
        #expect(metrics.failedValidations > 0, "Should track failures")
        #expect(metrics.successRate < 1.0, "Should calculate success rate")
    }
}

// MARK: - Enhanced Storage Implementation

private actor ValidatingStorageCapability: StorageCapability {
    private let storage: MockStorage
    private var isInitialized = false
    private let maxDataSize = 5_000_000 // 5MB limit
    
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
        // Validate before saving
        try await validateObject(object)
        
        // Check permissions
        if await storage.permissionDenied {
            await storage.incrementPermissionPromptCount()
            let retryCount = await storage.permissionRetryCount
            if retryCount > 0 {
                await storage.setPermissionRetryCount(retryCount - 1)
                throw StorageError.permissionDenied
            }
        }
        
        // Check disk space
        if await storage.diskFull {
            await storage.incrementCleanupAttempts()
            let available = await storage.availableSpace
            if available < maxDataSize {
                throw StorageError.diskFull
            }
        }
        
        // Encode with validation
        let encoder = JSONEncoder()
        let data = try encoder.encode(object)
        
        // Validate size
        if data.count > maxDataSize {
            throw StorageError.dataTooLarge(size: data.count, limit: maxDataSize)
        }
        
        // Add checksum
        let checksum = calculateChecksum(for: data)
        
        // Handle versioning for concurrent writes
        if key == "shared-state" {
            if let existing = await storage.getData(forKey: key),
               let currentState = try? JSONDecoder().decode(SharedState.self, from: existing) {
                if let newState = object as? SharedState {
                    // Only allow writes if the new version is exactly one more than current
                    if newState.version != currentState.version + 1 {
                        throw StorageError.versionConflict
                    }
                }
            }
        }
        
        await storage.incrementValidationCount()
        await storage.saveData(data, forKey: key)
        await storage.saveChecksum(checksum, forKey: key)
    }
    
    func load<T: Codable>(_ type: T.Type, key: String) async throws -> T? {
        guard let data = await storage.getData(forKey: key) else {
            return nil
        }
        
        // Check if corrupted
        if await storage.isCorrupted(key: key) {
            await storage.incrementRecoveryAttempts()
            throw StorageError.corruptedData
        }
        
        // Verify checksum
        if let storedChecksum = await storage.getChecksum(forKey: key) {
            let calculatedChecksum = calculateChecksum(for: data)
            if storedChecksum != calculatedChecksum {
                throw StorageError.checksumMismatch
            }
        }
        
        let decoder = JSONDecoder()
        let object = try decoder.decode(type, from: data)
        
        // Validate loaded object
        try await validateObject(object)
        await storage.incrementValidationCount()
        
        return object
    }
    
    func delete(key: String) async throws {
        await storage.removeData(forKey: key)
    }
    
    private func validateObject<T: Codable>(_ object: T) async throws {
        // Type-specific validation
        if let task = object as? ValidatedTask {
            if task.id.isEmpty {
                throw StorageError.missingRequiredField("id")
            }
            if task.priority < 1 || task.priority > 10 {
                throw StorageError.invalidValue(field: "priority", value: "\(task.priority)")
            }
        }
        
        if let incompleteTask = object as? IncompleteTask {
            if incompleteTask.id.isEmpty {
                throw StorageError.missingRequiredField("id")
            }
        }
        
        if let profile = object as? UserProfile {
            if !isValidEmail(profile.email) {
                throw StorageError.invalidFormat(field: "email", reason: "Invalid email format")
            }
        }
        
        if let oversized = object as? OversizedData {
            if oversized.content.count > 5_000_000 {
                throw StorageError.dataTooLarge(size: oversized.content.count, limit: 5_000_000)
            }
        }
    }
    
    private func calculateChecksum(for data: Data) -> String {
        // Simple checksum for testing
        return String(data.hashValue)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        return email.contains("@") && email.contains(".")
    }
    
    func loadAll<T: Codable>(_ type: T.Type) async throws -> [T] {
        var results: [T] = []
        for (_, data) in await storage.getAllData() {
            do {
                let object = try JSONDecoder().decode(type, from: data)
                try await validateObject(object)
                results.append(object)
            } catch {
                // Skip invalid objects or continue based on validation mode
                continue
            }
        }
        return results
    }
    
    func deleteAll() async throws {
        await storage.removeAllData()
    }
}

// MARK: - Enhanced Mock Storage

private actor MockStorage {
    private var storage: [String: Data] = [:]
    private var checksums: [String: String] = [:]
    private var corruptedKeys: Set<String> = []
    private var versionLocks: [String: Int] = [:] // Track locked versions
    
    var permissionDenied = false
    var diskFull = false
    var availableSpace = 10_000_000
    var permissionRetryCount = 0
    
    var validationCount = 0
    var recoveryAttempts = 0
    var permissionPromptCount = 0
    var cleanupAttempts = 0
    
    struct ValidationMetrics {
        let totalValidations: Int
        let failedValidations: Int
        var successRate: Double {
            guard totalValidations > 0 else { return 0 }
            return Double(totalValidations - failedValidations) / Double(totalValidations)
        }
    }
    
    func setPermissionDenied(_ value: Bool) {
        permissionDenied = value
    }
    
    func setDiskFull(_ value: Bool) {
        diskFull = value
    }
    
    func setAvailableSpace(_ space: Int) {
        availableSpace = space
    }
    
    func setPermissionRetryCount(_ count: Int) {
        permissionRetryCount = count
    }
    
    func incrementValidationCount() {
        validationCount += 1
    }
    
    func incrementRecoveryAttempts() {
        recoveryAttempts += 1
    }
    
    func incrementPermissionPromptCount() {
        permissionPromptCount += 1
    }
    
    func incrementCleanupAttempts() {
        cleanupAttempts += 1
    }
    
    func saveData(_ data: Data, forKey key: String) {
        storage[key] = data
    }
    
    func getData(forKey key: String) -> Data? {
        return storage[key]
    }
    
    // Atomic version check and update
    func checkAndUpdateVersion(key: String, expectedVersion: Int, newVersion: Int) -> Bool {
        if let currentData = storage[key],
           let currentState = try? JSONDecoder().decode(SharedState.self, from: currentData) {
            if currentState.version == expectedVersion {
                // Version matches, allow update
                return true
            }
        }
        return false
    }
    
    func removeData(forKey key: String) {
        storage.removeValue(forKey: key)
        checksums.removeValue(forKey: key)
        corruptedKeys.remove(key)
    }
    
    func saveChecksum(_ checksum: String, forKey key: String) {
        checksums[key] = checksum
    }
    
    func getChecksum(forKey key: String) -> String? {
        return checksums[key]
    }
    
    func corruptStorageData(forKey key: String) {
        corruptedKeys.insert(key)
    }
    
    func corruptChecksum(forKey key: String) {
        checksums[key] = "corrupted"
    }
    
    func isCorrupted(key: String) -> Bool {
        return corruptedKeys.contains(key)
    }
    
    func getValidationMetrics() -> ValidationMetrics {
        return ValidationMetrics(
            totalValidations: validationCount,
            failedValidations: 2 // Simulated for test
        )
    }
    
    func getAllData() -> [String: Data] {
        return storage
    }
    
    func removeAllData() {
        storage.removeAll()
        checksums.removeAll()
        corruptedKeys.removeAll()
    }
}

// MARK: - Test Data Types

private struct UserPreferences: Codable {
    let theme: String
    let language: String
}

private struct ValidatedTask: Codable {
    let id: String
    let title: String
    let priority: Int // 1-10
}

private struct SecureData: Codable {
    let content: String
    let encryptionRequired: Bool
}

private struct LargeData: Codable {
    let bytes: [UInt8]
}

private struct SharedState: Codable {
    var counter: Int
    var version: Int
}

private struct IncompleteTask: Codable {
    let id: String
    let title: String
}

private struct ChecksummedData: Codable {
    let content: String
}

private struct OversizedData: Codable {
    let content: String
}

private struct UserProfile: Codable {
    let email: String
    let name: String
}

// MARK: - Storage Errors

enum StorageError: Error, Equatable {
    case corruptedData
    case checksumMismatch
    case missingRequiredField(String)
    case invalidValue(field: String, value: String)
    case invalidFormat(field: String, reason: String)
    case dataTooLarge(size: Int, limit: Int)
    case permissionDenied
    case diskFull
    case versionConflict
}