import Testing
@testable import Axiom

@Test("Persistence capability exists check")
func testPersistenceCapabilityExistsCheck() async throws {
    let persistence = MockPersistenceCapability()
    
    // Test exists functionality
    let key = "test_key"
    let exists_before = await persistence.exists(key: key)
    #expect(exists_before == false)
    
    // Save data
    try await persistence.save("test_value", for: key)
    
    // Check exists after save
    let exists_after = await persistence.exists(key: key)
    #expect(exists_after == true)
}

@Test("UserDefaults storage adapter functionality")
func testUserDefaultsStorageAdapter() async throws {
    let adapter = UserDefaultsStorageAdapter()
    let key = "test_userdefaults_key"
    let data = "test_data".data(using: .utf8)!
    
    // Write data
    try await adapter.write(key: key, data: data)
    
    // Verify exists
    let exists = await adapter.exists(key: key)
    #expect(exists == true)
    
    // Read data
    let readData = try await adapter.read(key: key)
    #expect(readData == data)
    
    // Clean up
    try await adapter.delete(key: key)
    let existsAfterDelete = await adapter.exists(key: key)
    #expect(existsAfterDelete == false)
}

@Test("Memory storage adapter functionality")
func testMemoryStorageAdapter() async throws {
    let adapter = MemoryStorageAdapter()
    let key = "test_memory_key"
    let data = "test_data".data(using: .utf8)!
    
    // Write data
    try await adapter.write(key: key, data: data)
    
    // Verify exists
    let exists = await adapter.exists(key: key)
    #expect(exists == true)
    
    // Read data
    let readData = try await adapter.read(key: key)
    #expect(readData == data)
    
    // Clear memory
    await adapter.clear()
    let existsAfterClear = await adapter.exists(key: key)
    #expect(existsAfterClear == false)
}

@Test("Batch persistence operations")
func testBatchPersistenceOperations() async throws {
    let persistence = MockPersistenceCapability()
    
    // Prepare batch data
    let items = [
        ("key1", "value1"),
        ("key2", "value2"),
        ("key3", "value3")
    ]
    
    // Batch save
    try await persistence.saveBatch(items)
    
    // Verify all items exist
    for (key, expectedValue) in items {
        let exists = await persistence.exists(key: key)
        #expect(exists == true)
        
        let value: String? = try await persistence.load(String.self, for: key)
        #expect(value == expectedValue)
    }
    
    // Batch delete
    let keys = items.map { $0.0 }
    try await persistence.deleteBatch(keys: keys)
    
    // Verify all items deleted
    for key in keys {
        let exists = await persistence.exists(key: key)
        #expect(exists == false)
    }
}

@Test("Persistable client integration")
func testPersistableClientIntegration() async throws {
    let client = TestPersistableClient()
    
    // Update client state
    await client.updateValue("test_value")
    await client.updateCount(42)
    
    // Persist state
    try await client.persistState()
    
    // Create new client instance
    let newClient = TestPersistableClient()
    
    // Restore state
    try await newClient.restoreState()
    
    // Verify state restored
    let restoredValue = await newClient.getValue()
    let restoredCount = await newClient.getCount()
    
    #expect(restoredValue == "test_value")
    #expect(restoredCount == 42)
}

@Test("AdapterBasedPersistence with exists functionality")
func testAdapterBasedPersistenceExists() async throws {
    let adapter = MemoryStorageAdapter()
    let persistence = AdapterBasedPersistence(adapter: adapter)
    
    let key = "test_exists_key"
    let value = "test_value"
    
    // Check exists before save
    let existsBefore = await persistence.exists(key: key)
    #expect(existsBefore == false)
    
    // Save data
    try await persistence.save(value, for: key)
    
    // Check exists after save
    let existsAfter = await persistence.exists(key: key)
    #expect(existsAfter == true)
    
    // Delete data
    try await persistence.delete(key: key)
    
    // Check exists after delete
    let existsAfterDelete = await persistence.exists(key: key)
    #expect(existsAfterDelete == false)
}

@Test("AdapterBasedPersistence with batch operations")
func testAdapterBasedPersistenceBatch() async throws {
    let adapter = MemoryStorageAdapter()
    let persistence = AdapterBasedPersistence(adapter: adapter)
    
    // Prepare batch data
    let items = [
        ("batch_key1", "batch_value1"),
        ("batch_key2", "batch_value2"),
        ("batch_key3", "batch_value3")
    ]
    
    // Batch save
    try await persistence.saveBatch(items)
    
    // Verify all items exist and have correct values
    for (key, expectedValue) in items {
        let exists = await persistence.exists(key: key)
        #expect(exists == true)
        
        let loadedValue: String? = try await persistence.load(String.self, for: key)
        #expect(loadedValue == expectedValue)
    }
    
    // Batch delete
    let keys = items.map { $0.0 }
    try await persistence.deleteBatch(keys: keys)
    
    // Verify all items deleted
    for key in keys {
        let exists = await persistence.exists(key: key)
        #expect(exists == false)
    }
}

@Test("FileStorageAdapter with enhanced operations")
func testFileStorageAdapterEnhanced() async throws {
    // Create temporary directory
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("axiom-test-\(UUID().uuidString)")
    
    let adapter = FileStorageAdapter(directory: tempDir)
    let key = "file_test_key"
    let data = "file_test_data".data(using: .utf8)!
    
    // Test exists before write
    let existsBefore = await adapter.exists(key: key)
    #expect(existsBefore == false)
    
    // Write data
    try await adapter.write(key: key, data: data)
    
    // Test exists after write
    let existsAfter = await adapter.exists(key: key)
    #expect(existsAfter == true)
    
    // Read data
    let readData = try await adapter.read(key: key)
    #expect(readData == data)
    
    // Delete data
    try await adapter.delete(key: key)
    
    // Test exists after delete
    let existsAfterDelete = await adapter.exists(key: key)
    #expect(existsAfterDelete == false)
    
    // Cleanup
    try? FileManager.default.removeItem(at: tempDir)
}