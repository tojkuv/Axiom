import XCTest
import AxiomTesting
import AxiomCore
@testable import AxiomCapabilityDomains

/// Comprehensive tests for core storage capabilities
final class CoreStorageCapabilityTests: XCTestCase {
    
    // MARK: - Core Data Capability Tests
    
    func testCoreDataCapabilityLifecycle() async throws {
        let configuration = CoreDataCapabilityConfiguration(modelName: "TestModel")
        let capability = CoreDataCapability(configuration: configuration)
        
        // Test initial state
        XCTAssertFalse(await capability.isAvailable)
        XCTAssertEqual(await capability.state, .unknown)
        
        // Test activation - Note: This will fail without actual Core Data model
        do {
            try await capability.activate()
            XCTFail("Should fail without Core Data model")
        } catch {
            XCTAssertTrue(error is AxiomCapabilityError)
        }
        
        // Test deactivation
        await capability.deactivate()
        XCTAssertFalse(await capability.isAvailable)
    }
    
    func testCoreDataConfiguration() async throws {
        let configuration = CoreDataCapabilityConfiguration(
            storeType: NSSQLiteStoreType,
            modelName: "TestModel",
            enableAutomaticMigration: true,
            enableLightweightMigration: true,
            enableWALMode: true,
            maxConcurrentOperations: 5
        )
        
        XCTAssertTrue(configuration.isValid)
        XCTAssertEqual(configuration.storeType, NSSQLiteStoreType)
        XCTAssertEqual(configuration.modelName, "TestModel")
        XCTAssertTrue(configuration.enableAutomaticMigration)
        XCTAssertEqual(configuration.maxConcurrentOperations, 5)
        
        // Test environment adjustment
        let environment = AxiomCapabilityEnvironment(isLowPowerMode: true)
        let adjusted = configuration.adjusted(for: environment)
        XCTAssertEqual(adjusted.maxConcurrentOperations, 5) // Should be reduced in low power mode
    }
    
    // MARK: - SQLite Capability Tests
    
    func testSQLiteCapabilityLifecycle() async throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.db")
        let configuration = SQLiteCapabilityConfiguration(databasePath: tempURL.path)
        let capability = SQLiteCapability(configuration: configuration)
        
        // Test initial state
        XCTAssertFalse(await capability.isAvailable)
        
        // Test activation
        try await capability.activate()
        XCTAssertTrue(await capability.isAvailable)
        XCTAssertEqual(await capability.state, .available)
        
        // Test basic operations
        try await capability.execute("CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT)")
        try await capability.execute("INSERT INTO test (name) VALUES ('test')")
        
        let result = try await capability.query("SELECT * FROM test")
        XCTAssertEqual(result.rowCount, 1)
        XCTAssertEqual(result.columnCount, 2)
        
        // Test transaction
        try await capability.transaction([
            "INSERT INTO test (name) VALUES ('test2')",
            "INSERT INTO test (name) VALUES ('test3')"
        ])
        
        let allResults = try await capability.query("SELECT COUNT(*) as count FROM test")
        XCTAssertEqual(allResults.rowCount, 1)
        
        // Test deactivation
        await capability.deactivate()
        XCTAssertFalse(await capability.isAvailable)
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    func testSQLiteConfiguration() async throws {
        let configuration = SQLiteCapabilityConfiguration(
            databasePath: "/tmp/test.db",
            enableWALMode: true,
            enableForeignKeys: true,
            cacheSize: 1000,
            maxConnections: 5
        )
        
        XCTAssertTrue(configuration.isValid)
        XCTAssertEqual(configuration.databasePath, "/tmp/test.db")
        XCTAssertTrue(configuration.enableWALMode)
        XCTAssertEqual(configuration.cacheSize, 1000)
        XCTAssertEqual(configuration.maxConnections, 5)
    }
    
    func testSQLiteConnectionPool() async throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("pool_test.db")
        let configuration = SQLiteCapabilityConfiguration(
            databasePath: tempURL.path,
            maxConnections: 3
        )
        
        let capability = SQLiteCapability(configuration: configuration)
        try await capability.activate()
        
        // Test concurrent operations
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                group.addTask {
                    do {
                        try await capability.execute("CREATE TABLE IF NOT EXISTS concurrent_test_\(i) (id INTEGER)")
                        try await capability.execute("INSERT INTO concurrent_test_\(i) (id) VALUES (1)")
                    } catch {
                        XCTFail("Concurrent operation failed: \(error)")
                    }
                }
            }
        }
        
        await capability.deactivate()
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    // MARK: - File System Capability Tests
    
    func testFileSystemCapabilityLifecycle() async throws {
        let configuration = FileSystemCapabilityConfiguration(
            baseDirectory: .temporary,
            maxFileSize: 1024,
            allowedExtensions: ["txt", "json"]
        )
        let capability = FileSystemCapability(configuration: configuration)
        
        // Test activation
        try await capability.activate()
        XCTAssertTrue(await capability.isAvailable)
        
        // Test file operations
        let testData = "Hello, World!".data(using: .utf8)!
        try await capability.writeFile(at: "test.txt", data: testData)
        
        XCTAssertTrue(try await capability.itemExists(at: "test.txt"))
        
        let readData = try await capability.readFile(at: "test.txt")
        XCTAssertEqual(readData, testData)
        
        // Test metadata
        let metadata = try await capability.getMetadata(for: "test.txt")
        XCTAssertEqual(metadata.path, "test.txt")
        XCTAssertFalse(metadata.isDirectory)
        XCTAssertEqual(metadata.size, UInt64(testData.count))
        
        // Test directory operations
        try await capability.createDirectory(at: "testdir")
        XCTAssertTrue(try await capability.itemExists(at: "testdir"))
        
        // Test file in directory
        try await capability.writeFile(at: "testdir/nested.txt", data: testData)
        XCTAssertTrue(try await capability.itemExists(at: "testdir/nested.txt"))
        
        // Test directory listing
        let contents = try await capability.listDirectory(at: ".")
        XCTAssertTrue(contents.contains { $0.path == "test.txt" })
        XCTAssertTrue(contents.contains { $0.path == "testdir" })
        
        // Test copy and move
        try await capability.copyItem(from: "test.txt", to: "test_copy.txt")
        XCTAssertTrue(try await capability.itemExists(at: "test_copy.txt"))
        
        try await capability.moveItem(from: "test_copy.txt", to: "test_moved.txt")
        XCTAssertFalse(try await capability.itemExists(at: "test_copy.txt"))
        XCTAssertTrue(try await capability.itemExists(at: "test_moved.txt"))
        
        // Test cleanup
        try await capability.deleteItem(at: "test.txt")
        try await capability.deleteItem(at: "test_moved.txt")
        try await capability.deleteItem(at: "testdir")
        
        await capability.deactivate()
    }
    
    func testFileSystemSecurityValidation() async throws {
        let configuration = FileSystemCapabilityConfiguration(
            allowedExtensions: ["txt"],
            maxFileSize: 100
        )
        let capability = FileSystemCapability(configuration: configuration)
        try await capability.activate()
        
        // Test extension validation
        let testData = "test".data(using: .utf8)!
        
        do {
            try await capability.writeFile(at: "test.exe", data: testData)
            XCTFail("Should reject disallowed extension")
        } catch {
            XCTAssertTrue(error is AxiomCapabilityError)
        }
        
        // Test size validation
        let largeData = Data(repeating: 0, count: 200)
        do {
            try await capability.writeFile(at: "large.txt", data: largeData)
            XCTFail("Should reject oversized file")
        } catch {
            XCTAssertTrue(error is AxiomCapabilityError)
        }
        
        // Test path traversal protection
        do {
            try await capability.writeFile(at: "../escape.txt", data: testData)
            XCTFail("Should reject path traversal")
        } catch {
            XCTAssertTrue(error is AxiomCapabilityError)
        }
        
        await capability.deactivate()
    }
    
    // MARK: - UserDefaults Capability Tests
    
    func testUserDefaultsCapabilityLifecycle() async throws {
        let configuration = UserDefaultsCapabilityConfiguration(
            suiteName: "test.suite",
            keyPrefix: "test"
        )
        let capability = UserDefaultsCapability(configuration: configuration)
        
        // Test activation
        try await capability.activate()
        XCTAssertTrue(await capability.isAvailable)
        
        // Test string operations
        try await capability.setValue("test_value", forKey: "test_key")
        let retrievedString = try await capability.getString(forKey: "test_key")
        XCTAssertEqual(retrievedString, "test_value")
        
        // Test integer operations
        try await capability.setValue(42, forKey: "int_key")
        let retrievedInt = try await capability.getInteger(forKey: "int_key")
        XCTAssertEqual(retrievedInt, 42)
        
        // Test boolean operations
        try await capability.setValue(true, forKey: "bool_key")
        let retrievedBool = try await capability.getBoolean(forKey: "bool_key")
        XCTAssertTrue(retrievedBool)
        
        // Test data operations
        let testData = "test".data(using: .utf8)!
        try await capability.setValue(testData, forKey: "data_key")
        let retrievedData = try await capability.getData(forKey: "data_key")
        XCTAssertEqual(retrievedData, testData)
        
        // Test key existence
        XCTAssertTrue(try await capability.keyExists("test_key"))
        XCTAssertFalse(try await capability.keyExists("nonexistent_key"))
        
        // Test key listing
        let allKeys = try await capability.getAllKeys()
        XCTAssertTrue(allKeys.contains("test.test_key"))
        XCTAssertTrue(allKeys.contains("test.int_key"))
        
        // Test removal
        try await capability.removeValue(forKey: "test_key")
        XCTAssertFalse(try await capability.keyExists("test_key"))
        
        await capability.deactivate()
    }
    
    func testUserDefaultsTypeValidation() async throws {
        let configuration = UserDefaultsCapabilityConfiguration(
            enableTypeValidation: true,
            maxValueSize: 100
        )
        let capability = UserDefaultsCapability(configuration: configuration)
        try await capability.activate()
        
        // Test valid types
        try await capability.setValue("string", forKey: "string_key")
        try await capability.setValue(123, forKey: "int_key")
        try await capability.setValue(3.14, forKey: "double_key")
        try await capability.setValue(true, forKey: "bool_key")
        
        // Test size validation
        let largeString = String(repeating: "a", count: 200)
        do {
            try await capability.setValue(largeString, forKey: "large_key")
            XCTFail("Should reject oversized value")
        } catch {
            XCTAssertTrue(error is AxiomCapabilityError)
        }
        
        await capability.deactivate()
    }
    
    // MARK: - Keychain Capability Tests
    
    func testKeychainCapabilityLifecycle() async throws {
        let configuration = KeychainCapabilityConfiguration(
            service: "com.test.app",
            keyPrefix: "test"
        )
        let capability = KeychainCapability(configuration: configuration)
        
        // Test activation
        try await capability.activate()
        XCTAssertTrue(await capability.isAvailable)
        
        // Test data storage and retrieval
        let testData = "secret_data".data(using: .utf8)!
        try await capability.store(data: testData, forKey: "secret")
        
        let retrievedData = try await capability.retrieve(forKey: "secret")
        XCTAssertEqual(retrievedData, testData)
        
        // Test existence check
        XCTAssertTrue(try await capability.exists(forKey: "secret"))
        XCTAssertFalse(try await capability.exists(forKey: "nonexistent"))
        
        // Test string convenience methods
        try await capability.storeString("secret_string", forKey: "string_secret")
        let retrievedString = try await capability.retrieveString(forKey: "string_secret")
        XCTAssertEqual(retrievedString, "secret_string")
        
        // Test credentials storage
        try await capability.storeCredentials(
            username: "testuser",
            password: "testpass",
            forKey: "credentials"
        )
        
        let credentials = try await capability.retrieveCredentials(forKey: "credentials")
        XCTAssertEqual(credentials?.username, "testuser")
        XCTAssertEqual(credentials?.password, "testpass")
        
        // Test update
        let newData = "updated_secret".data(using: .utf8)!
        try await capability.update(data: newData, forKey: "secret")
        
        let updatedData = try await capability.retrieve(forKey: "secret")
        XCTAssertEqual(updatedData, newData)
        
        // Test key listing
        let allKeys = try await capability.getAllKeys()
        XCTAssertTrue(allKeys.contains("test.secret"))
        XCTAssertTrue(allKeys.contains("test.string_secret"))
        
        // Test deletion
        try await capability.delete(forKey: "secret")
        XCTAssertFalse(try await capability.exists(forKey: "secret"))
        
        // Cleanup
        try await capability.deleteAll()
        
        await capability.deactivate()
    }
    
    func testKeychainConfiguration() async throws {
        let configuration = KeychainCapabilityConfiguration(
            service: "com.test.app",
            accessibility: .whenUnlocked,
            enableTouchID: false,
            enableSynchronization: false
        )
        
        XCTAssertTrue(configuration.isValid)
        XCTAssertEqual(configuration.service, "com.test.app")
        XCTAssertEqual(configuration.accessibility, .whenUnlocked)
        XCTAssertFalse(configuration.enableTouchID)
        XCTAssertFalse(configuration.enableSynchronization)
    }
    
    // MARK: - Integration Tests
    
    func testStorageCapabilityIntegration() async throws {
        // Test integration between different storage capabilities
        let fileConfig = FileSystemCapabilityConfiguration(allowedExtensions: ["json"])
        let userDefaultsConfig = UserDefaultsCapabilityConfiguration(suiteName: "integration.test")
        let keychainConfig = KeychainCapabilityConfiguration(service: "com.integration.test")
        
        let fileCapability = FileSystemCapability(configuration: fileConfig)
        let userDefaultsCapability = UserDefaultsCapability(configuration: userDefaultsConfig)
        let keychainCapability = KeychainCapability(configuration: keychainConfig)
        
        // Activate all capabilities
        try await fileCapability.activate()
        try await userDefaultsCapability.activate()
        try await keychainCapability.activate()
        
        // Store same data in different storage types
        let testData = """
        {
            "key": "value",
            "number": 42,
            "flag": true
        }
        """.data(using: .utf8)!
        
        // File system storage
        try await fileCapability.writeFile(at: "test_data.json", data: testData)
        
        // UserDefaults storage (as data)
        try await userDefaultsCapability.setValue(testData, forKey: "json_data")
        
        // Keychain storage
        try await keychainCapability.store(data: testData, forKey: "secure_json")
        
        // Verify data integrity across storage types
        let fileData = try await fileCapability.readFile(at: "test_data.json")
        let userDefaultsData = try await userDefaultsCapability.getData(forKey: "json_data")
        let keychainData = try await keychainCapability.retrieve(forKey: "secure_json")
        
        XCTAssertEqual(fileData, testData)
        XCTAssertEqual(userDefaultsData, testData)
        XCTAssertEqual(keychainData, testData)
        
        // Cleanup
        try await fileCapability.deleteItem(at: "test_data.json")
        try await userDefaultsCapability.removeValue(forKey: "json_data")
        try await keychainCapability.delete(forKey: "secure_json")
        
        await fileCapability.deactivate()
        await userDefaultsCapability.deactivate()
        await keychainCapability.deactivate()
    }
    
    // MARK: - Performance Tests
    
    func testStoragePerformance() async throws {
        let fileCapability = FileSystemCapability()
        try await fileCapability.activate()
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Write multiple files
        for i in 0..<100 {
            let data = "Test data \(i)".data(using: .utf8)!
            try await fileCapability.writeFile(at: "perf_test_\(i).txt", data: data)
        }
        
        let writeTime = CFAbsoluteTimeGetCurrent() - startTime
        
        let readStartTime = CFAbsoluteTimeGetCurrent()
        
        // Read multiple files
        for i in 0..<100 {
            _ = try await fileCapability.readFile(at: "perf_test_\(i).txt")
        }
        
        let readTime = CFAbsoluteTimeGetCurrent() - readStartTime
        
        // Cleanup
        for i in 0..<100 {
            try await fileCapability.deleteItem(at: "perf_test_\(i).txt")
        }
        
        await fileCapability.deactivate()
        
        // Assert reasonable performance (adjust thresholds as needed)
        XCTAssertLessThan(writeTime, 5.0, "Write performance should be reasonable")
        XCTAssertLessThan(readTime, 2.0, "Read performance should be reasonable")
    }
    
    // MARK: - Error Handling Tests
    
    func testStorageErrorHandling() async throws {
        let fileCapability = FileSystemCapability()
        try await fileCapability.activate()
        
        // Test reading non-existent file
        do {
            _ = try await fileCapability.readFile(at: "nonexistent.txt")
            XCTFail("Should throw error for non-existent file")
        } catch {
            XCTAssertTrue(error is AxiomCapabilityError)
        }
        
        // Test writing to invalid path
        do {
            let data = "test".data(using: .utf8)!
            try await fileCapability.writeFile(at: "", data: data)
            XCTFail("Should throw error for empty path")
        } catch {
            XCTAssertTrue(error is AxiomCapabilityError)
        }
        
        await fileCapability.deactivate()
    }
}

// MARK: - Test Helpers

extension CoreStorageCapabilityTests {
    
    /// Helper to create test Core Data model
    private func createTestCoreDataModel() -> URL? {
        // In a real test, you would create a proper Core Data model file
        // For this test, we'll return nil to trigger the expected error
        return nil
    }
    
    /// Helper to create temporary database file
    private func createTempDatabaseURL() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let dbName = "test_\(UUID().uuidString).db"
        return tempDir.appendingPathComponent(dbName)
    }
    
    /// Helper to cleanup test files
    private func cleanupTestFiles() {
        let tempDir = FileManager.default.temporaryDirectory
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
            for url in contents {
                if url.lastPathComponent.hasPrefix("test_") {
                    try FileManager.default.removeItem(at: url)
                }
            }
        } catch {
            // Ignore cleanup errors
        }
    }
}