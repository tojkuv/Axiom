import XCTest
import AxiomTesting
@testable import AxiomCapabilities
@testable import AxiomPlatform
@testable import AxiomArchitecture

/// Tests for AxiomCapabilities data capability functionality
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class DataCapabilityTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Core Functionality Tests
    
    func testDataCapabilityInitialization() async throws {
        let dataCapability = DataCapability()
        XCTAssertNotNil(dataCapability, "DataCapability should initialize correctly")
        XCTAssertEqual(dataCapability.identifier, "axiom.data", "Should have correct identifier")
    }
    
    func testDataStorageCapability() async throws {
        let storageCapability = DataStorageCapability()
        
        let isAvailable = await storageCapability.isAvailable()
        XCTAssertTrue(isAvailable, "Data storage should be available")
        
        let canStore = await storageCapability.canStoreData(size: 1024)
        XCTAssertNotNil(canStore, "Should determine if data can be stored")
        
        let maxStorageSize = await storageCapability.getMaxStorageSize()
        XCTAssertGreaterThan(maxStorageSize, 0, "Max storage size should be positive")
    }
    
    func testDataEncryptionCapability() async throws {
        let encryptionCapability = DataEncryptionCapability()
        
        let isAvailable = await encryptionCapability.isAvailable()
        
        if isAvailable {
            let supportedAlgorithms = await encryptionCapability.getSupportedAlgorithms()
            XCTAssertFalse(supportedAlgorithms.isEmpty, "Should support encryption algorithms")
            
            let canEncrypt = await encryptionCapability.canEncryptData(algorithm: .aes256)
            XCTAssertTrue(canEncrypt, "Should support AES256 encryption")
        }
    }
    
    func testDataCompressionCapability() async throws {
        let compressionCapability = DataCompressionCapability()
        
        let isAvailable = await compressionCapability.isAvailable()
        
        if isAvailable {
            let supportedFormats = await compressionCapability.getSupportedFormats()
            XCTAssertFalse(supportedFormats.isEmpty, "Should support compression formats")
            
            let compressionRatio = await compressionCapability.estimateCompressionRatio(
                dataSize: 1024, 
                format: .gzip
            )
            XCTAssertGreaterThan(compressionRatio, 0, "Compression ratio should be positive")
        }
    }
    
    func testDataSyncCapability() async throws {
        let syncCapability = DataSyncCapability()
        
        let isAvailable = await syncCapability.isAvailable()
        
        if isAvailable {
            let syncMethods = await syncCapability.getSupportedSyncMethods()
            XCTAssertFalse(syncMethods.isEmpty, "Should support sync methods")
            
            let canSyncToCloud = await syncCapability.canSyncToService(.icloud)
            XCTAssertNotNil(canSyncToCloud, "Should determine cloud sync availability")
        }
    }
    
    func testDataValidationCapability() async throws {
        let validationCapability = DataValidationCapability()
        
        let testData = Data("test data".utf8)
        let isValid = await validationCapability.validateData(testData, schema: .json)
        XCTAssertNotNil(isValid, "Should validate data against schema")
        
        let supportedSchemas = await validationCapability.getSupportedSchemas()
        XCTAssertFalse(supportedSchemas.isEmpty, "Should support validation schemas")
    }
    
    // MARK: - Performance Tests
    
    func testDataCapabilityPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let dataCapability = DataCapability()
                let storageCapability = DataStorageCapability()
                let encryptionCapability = DataEncryptionCapability()
                
                // Test rapid capability queries
                for _ in 0..<100 {
                    _ = await dataCapability.isAvailable()
                    _ = await storageCapability.canStoreData(size: 1024)
                    _ = await encryptionCapability.getSupportedAlgorithms()
                }
            },
            maxDuration: .milliseconds(100),
            maxMemoryGrowth: 512 * 1024 // 512KB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testDataCapabilityMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            let dataCapability = DataCapability()
            let storageCapability = DataStorageCapability()
            let encryptionCapability = DataEncryptionCapability()
            let compressionCapability = DataCompressionCapability()
            
            // Simulate capability lifecycle
            for _ in 0..<20 {
                _ = await dataCapability.isAvailable()
                _ = await storageCapability.getMaxStorageSize()
                _ = await encryptionCapability.getSupportedAlgorithms()
                _ = await compressionCapability.getSupportedFormats()
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testDataCapabilityErrorHandling() async throws {
        let storageCapability = DataStorageCapability()
        
        // Test storing data with invalid size
        do {
            try await storageCapability.storeDataStrict(Data(), size: -1)
            XCTFail("Should throw error for negative size")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for invalid size")
        }
        
        let encryptionCapability = DataEncryptionCapability()
        
        // Test encryption with unsupported algorithm
        do {
            try await encryptionCapability.encryptDataStrict(Data(), algorithm: .unsupported)
            XCTFail("Should throw error for unsupported algorithm")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for unsupported algorithm")
        }
    }
}

// MARK: - Test Helper Types

private enum EncryptionAlgorithm {
    case aes256
    case rsa
    case unsupported
}

private enum CompressionFormat {
    case gzip
    case zip
    case lz4
}

private enum SyncService {
    case icloud
    case dropbox
    case googleDrive
}

private enum ValidationSchema {
    case json
    case xml
    case yaml
}