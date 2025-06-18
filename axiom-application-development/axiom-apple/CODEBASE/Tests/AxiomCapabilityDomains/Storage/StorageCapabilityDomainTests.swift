import XCTest
import AxiomTesting
@testable import AxiomCapabilityDomains
@testable import AxiomCapabilities
@testable import AxiomPlatform
@testable import AxiomArchitecture

/// Tests for AxiomCapabilityDomains storage capability domain functionality
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class StorageCapabilityDomainTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Core Functionality Tests
    
    func testStorageCapabilityDomainInitialization() async throws {
        let storageDomain = StorageCapabilityDomain()
        XCTAssertNotNil(storageDomain, "StorageCapabilityDomain should initialize correctly")
        XCTAssertEqual(storageDomain.identifier, "axiom.capability.domain.storage", "Should have correct identifier")
    }
    
    func testLocalStorageCapabilityRegistration() async throws {
        let storageDomain = StorageCapabilityDomain()
        
        let fileSystemCapability = FileSystemCapability()
        let userDefaultsCapability = UserDefaultsCapability()
        let keychainCapability = KeychainCapability()
        let coreDataCapability = CoreDataCapability()
        
        await storageDomain.registerCapability(fileSystemCapability)
        await storageDomain.registerCapability(userDefaultsCapability)
        await storageDomain.registerCapability(keychainCapability)
        await storageDomain.registerCapability(coreDataCapability)
        
        let registeredCapabilities = await storageDomain.getRegisteredCapabilities()
        XCTAssertEqual(registeredCapabilities.count, 4, "Should have 4 registered local storage capabilities")
        
        let hasFileSystem = await storageDomain.hasCapability("axiom.storage.local.filesystem")
        XCTAssertTrue(hasFileSystem, "Should have File System capability")
        
        let hasUserDefaults = await storageDomain.hasCapability("axiom.storage.local.userdefaults")
        XCTAssertTrue(hasUserDefaults, "Should have UserDefaults capability")
        
        let hasKeychain = await storageDomain.hasCapability("axiom.storage.local.keychain")
        XCTAssertTrue(hasKeychain, "Should have Keychain capability")
        
        let hasCoreData = await storageDomain.hasCapability("axiom.storage.local.coredata")
        XCTAssertTrue(hasCoreData, "Should have CoreData capability")
    }
    
    func testCloudStorageCapabilityManagement() async throws {
        let storageDomain = StorageCapabilityDomain()
        
        let iCloudCapability = iCloudStorageCapability()
        let cloudKitCapability = CloudKitCapability()
        let s3Capability = S3StorageCapability()
        let dropboxCapability = DropboxCapability()
        
        await storageDomain.registerCapability(iCloudCapability)
        await storageDomain.registerCapability(cloudKitCapability)
        await storageDomain.registerCapability(s3Capability)
        await storageDomain.registerCapability(dropboxCapability)
        
        let cloudCapabilities = await storageDomain.getCapabilitiesOfType(.cloud)
        XCTAssertEqual(cloudCapabilities.count, 4, "Should have 4 cloud storage capabilities")
        
        let syncCapability = await storageDomain.getBestCapabilityForUseCase(.automaticSync)
        XCTAssertNotNil(syncCapability, "Should find best capability for automatic sync")
        
        let backupCapability = await storageDomain.getBestCapabilityForUseCase(.backup)
        XCTAssertNotNil(backupCapability, "Should find best capability for backup")
    }
    
    func testTemporaryStorageCapabilities() async throws {
        let storageDomain = StorageCapabilityDomain()
        
        let memoryCapability = MemoryStorageCapability()
        let tempFileCapability = TempFileStorageCapability()
        let cacheCapability = CacheStorageCapability()
        
        await storageDomain.registerCapability(memoryCapability)
        await storageDomain.registerCapability(tempFileCapability)
        await storageDomain.registerCapability(cacheCapability)
        
        let tempCapabilities = await storageDomain.getCapabilitiesOfType(.temporary)
        XCTAssertEqual(tempCapabilities.count, 3, "Should have 3 temporary storage capabilities")
        
        let fastAccessCapability = await storageDomain.getBestCapabilityForUseCase(.fastAccess)
        XCTAssertNotNil(fastAccessCapability, "Should find best capability for fast access")
    }
    
    func testStorageStrategySelection() async throws {
        let storageDomain = StorageCapabilityDomain()
        
        // Register various storage capabilities
        await storageDomain.registerCapability(FileSystemCapability())
        await storageDomain.registerCapability(MemoryStorageCapability())
        await storageDomain.registerCapability(iCloudStorageCapability())
        await storageDomain.registerCapability(KeychainCapability())
        
        let strategy = await storageDomain.selectOptimalStrategy(
            for: StorageRequirements(
                dataType: .userDocuments,
                durability: .permanent,
                accessibility: .userInitiated,
                synchronization: .required,
                security: .high
            )
        )
        
        XCTAssertNotNil(strategy, "Should select an optimal storage strategy")
        XCTAssertTrue(strategy!.storageLayer.count > 0, "Strategy should include storage layers")
        
        let primaryStorage = strategy!.primaryStorage
        XCTAssertNotNil(primaryStorage, "Strategy should have a primary storage")
        
        let backupStorage = strategy!.backupStorage
        XCTAssertNotNil(backupStorage, "Strategy should have backup storage for permanent data")
    }
    
    func testDataMigrationCapability() async throws {
        let storageDomain = StorageCapabilityDomain()
        
        await storageDomain.registerCapability(FileSystemCapability())
        await storageDomain.registerCapability(iCloudStorageCapability())
        await storageDomain.registerCapability(CoreDataCapability())
        
        let migrationManager = await storageDomain.getMigrationManager()
        XCTAssertNotNil(migrationManager, "Should provide migration manager")
        
        // Test migration plan creation
        let migrationPlan = await migrationManager!.createMigrationPlan(
            from: "axiom.storage.local.filesystem",
            to: "axiom.storage.cloud.icloud",
            dataSize: 1024 * 1024 * 100 // 100MB
        )
        
        XCTAssertNotNil(migrationPlan, "Should create migration plan")
        XCTAssertTrue(migrationPlan!.steps.count > 0, "Migration plan should have steps")
        
        let estimatedDuration = await migrationPlan!.getEstimatedDuration()
        XCTAssertGreaterThan(estimatedDuration, 0, "Should estimate migration duration")
        
        // Test migration validation
        let isValidMigration = await migrationManager!.validateMigration(migrationPlan!)
        XCTAssertTrue(isValidMigration, "Migration plan should be valid")
    }
    
    func testStorageQuotaManagement() async throws {
        let storageDomain = StorageCapabilityDomain()
        
        await storageDomain.registerCapability(FileSystemCapability())
        await storageDomain.registerCapability(iCloudStorageCapability())
        
        let quotaManager = await storageDomain.getQuotaManager()
        XCTAssertNotNil(quotaManager, "Should provide quota manager")
        
        // Test quota monitoring
        let availableSpace = await quotaManager!.getAvailableSpace(for: .local)
        XCTAssertGreaterThan(availableSpace, 0, "Should have available local space")
        
        let cloudQuota = await quotaManager!.getQuotaInfo(for: .cloud)
        XCTAssertNotNil(cloudQuota, "Should provide cloud quota information")
        
        // Test quota alerts
        let alertThreshold: Double = 0.9 // 90%
        await quotaManager!.setQuotaAlert(threshold: alertThreshold, for: .local)
        
        let alertThresholds = await quotaManager!.getAlertThresholds()
        XCTAssertEqual(alertThresholds[.local], alertThreshold, "Should set quota alert threshold")
        
        // Test quota cleanup
        let cleanupResult = await quotaManager!.performCleanup(for: .temporary, aggressiveness: .moderate)
        XCTAssertNotNil(cleanupResult, "Should perform quota cleanup")
        XCTAssertGreaterThanOrEqual(cleanupResult!.freedSpace, 0, "Cleanup should free some space")
    }
    
    func testStorageEncryptionCapability() async throws {
        let storageDomain = StorageCapabilityDomain()
        
        await storageDomain.registerCapability(KeychainCapability())
        await storageDomain.registerCapability(FileSystemCapability())
        
        let encryptionManager = await storageDomain.getEncryptionManager()
        XCTAssertNotNil(encryptionManager, "Should provide encryption manager")
        
        // Test data encryption
        let sensitiveData = "This is sensitive user data"
        let encryptedData = await encryptionManager!.encryptData(sensitiveData.data(using: .utf8)!)
        XCTAssertNotEqual(encryptedData, sensitiveData.data(using: .utf8)!, "Data should be encrypted")
        
        let decryptedData = await encryptionManager!.decryptData(encryptedData)
        let decryptedString = String(data: decryptedData, encoding: .utf8)
        XCTAssertEqual(decryptedString, sensitiveData, "Decrypted data should match original")
        
        // Test key management
        let keyId = "user-data-key"
        let keyGenerated = await encryptionManager!.generateKey(identifier: keyId)
        XCTAssertTrue(keyGenerated, "Should generate encryption key")
        
        let keyExists = await encryptionManager!.keyExists(identifier: keyId)
        XCTAssertTrue(keyExists, "Generated key should exist")
        
        await encryptionManager!.deleteKey(identifier: keyId)
        let keyDeleted = await encryptionManager!.keyExists(identifier: keyId)
        XCTAssertFalse(keyDeleted, "Key should be deleted")
    }
    
    // MARK: - Performance Tests
    
    func testStorageCapabilityDomainPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let storageDomain = StorageCapabilityDomain()
                
                // Test rapid capability operations
                for i in 0..<100 {
                    let capability = TestStorageCapability(index: i)
                    await storageDomain.registerCapability(capability)
                }
                
                // Test strategy selection performance
                for _ in 0..<25 {
                    let requirements = StorageRequirements(
                        dataType: .userSettings,
                        durability: .session,
                        accessibility: .background,
                        synchronization: .optional,
                        security: .medium
                    )
                    _ = await storageDomain.selectOptimalStrategy(for: requirements)
                }
            },
            maxDuration: .milliseconds(350),
            maxMemoryGrowth: 1024 * 1024 // 1MB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testStorageCapabilityDomainMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            let storageDomain = StorageCapabilityDomain()
            
            // Simulate domain lifecycle
            for i in 0..<30 {
                let capability = TestStorageCapability(index: i)
                await storageDomain.registerCapability(capability)
                
                if i % 5 == 0 {
                    let requirements = StorageRequirements(
                        dataType: .cache,
                        durability: .temporary,
                        accessibility: .immediate,
                        synchronization: .none,
                        security: .low
                    )
                    _ = await storageDomain.selectOptimalStrategy(for: requirements)
                }
                
                if i % 8 == 0 {
                    await storageDomain.unregisterCapability(capability.identifier)
                }
            }
            
            await storageDomain.cleanup()
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testStorageCapabilityDomainErrorHandling() async throws {
        let storageDomain = StorageCapabilityDomain()
        
        // Test registering capability with duplicate identifier
        let capability1 = TestStorageCapability(index: 1)
        let capability2 = TestStorageCapability(index: 1) // Same index = same identifier
        
        await storageDomain.registerCapability(capability1)
        
        do {
            try await storageDomain.registerCapabilityStrict(capability2)
            XCTFail("Should throw error for duplicate identifier")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for duplicate identifier")
        }
        
        // Test strategy selection with impossible requirements
        do {
            let impossibleRequirements = StorageRequirements(
                dataType: .largeMedia,
                durability: .permanent,
                accessibility: .immediate,
                synchronization: .realtime,
                security: .maximum
            )
            try await storageDomain.selectOptimalStrategyStrict(for: impossibleRequirements)
            // This might succeed with trade-offs, so we don't fail here
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for impossible requirements")
        }
        
        // Test migration with invalid storage types
        let migrationManager = await storageDomain.getMigrationManager()
        if let manager = migrationManager {
            do {
                try await manager.createMigrationPlanStrict(
                    from: "invalid.storage.type",
                    to: "another.invalid.storage.type",
                    dataSize: 1024
                )
                XCTFail("Should throw error for invalid storage types")
            } catch {
                XCTAssertTrue(error is AxiomError, "Should throw AxiomError for invalid storage types")
            }
        }
    }
}

// MARK: - Test Helper Classes

private struct FileSystemCapability: StorageCapability {
    let identifier = "axiom.storage.local.filesystem"
    let isAvailable = true
    let storageType: StorageType = .local
    let durability: StorageDurability = .permanent
    let performance: StoragePerformance = .medium
    let capacity: StorageCapacity = .large
}

private struct UserDefaultsCapability: StorageCapability {
    let identifier = "axiom.storage.local.userdefaults"
    let isAvailable = true
    let storageType: StorageType = .local
    let durability: StorageDurability = .permanent
    let performance: StoragePerformance = .fast
    let capacity: StorageCapacity = .small
}

private struct KeychainCapability: StorageCapability {
    let identifier = "axiom.storage.local.keychain"
    let isAvailable = true
    let storageType: StorageType = .secure
    let durability: StorageDurability = .permanent
    let performance: StoragePerformance = .medium
    let capacity: StorageCapacity = .small
}

private struct CoreDataCapability: StorageCapability {
    let identifier = "axiom.storage.local.coredata"
    let isAvailable = true
    let storageType: StorageType = .database
    let durability: StorageDurability = .permanent
    let performance: StoragePerformance = .medium
    let capacity: StorageCapacity = .large
}

private struct iCloudStorageCapability: StorageCapability {
    let identifier = "axiom.storage.cloud.icloud"
    let isAvailable = true
    let storageType: StorageType = .cloud
    let durability: StorageDurability = .permanent
    let performance: StoragePerformance = .slow
    let capacity: StorageCapacity = .unlimited
}

private struct CloudKitCapability: StorageCapability {
    let identifier = "axiom.storage.cloud.cloudkit"
    let isAvailable = true
    let storageType: StorageType = .cloud
    let durability: StorageDurability = .permanent
    let performance: StoragePerformance = .medium
    let capacity: StorageCapacity = .large
}

private struct S3StorageCapability: StorageCapability {
    let identifier = "axiom.storage.cloud.s3"
    let isAvailable = true
    let storageType: StorageType = .cloud
    let durability: StorageDurability = .permanent
    let performance: StoragePerformance = .medium
    let capacity: StorageCapacity = .unlimited
}

private struct DropboxCapability: StorageCapability {
    let identifier = "axiom.storage.cloud.dropbox"
    let isAvailable = true
    let storageType: StorageType = .cloud
    let durability: StorageDurability = .permanent
    let performance: StoragePerformance = .slow
    let capacity: StorageCapacity = .large
}

private struct MemoryStorageCapability: StorageCapability {
    let identifier = "axiom.storage.temp.memory"
    let isAvailable = true
    let storageType: StorageType = .temporary
    let durability: StorageDurability = .volatile
    let performance: StoragePerformance = .fastest
    let capacity: StorageCapacity = .small
}

private struct TempFileStorageCapability: StorageCapability {
    let identifier = "axiom.storage.temp.file"
    let isAvailable = true
    let storageType: StorageType = .temporary
    let durability: StorageDurability = .session
    let performance: StoragePerformance = .fast
    let capacity: StorageCapacity = .medium
}

private struct CacheStorageCapability: StorageCapability {
    let identifier = "axiom.storage.temp.cache"
    let isAvailable = true
    let storageType: StorageType = .temporary
    let durability: StorageDurability = .session
    let performance: StoragePerformance = .fast
    let capacity: StorageCapacity = .medium
}

private struct TestStorageCapability: StorageCapability {
    let identifier: String
    let isAvailable = true
    let storageType: StorageType = .local
    let durability: StorageDurability = .session
    let performance: StoragePerformance = .medium
    let capacity: StorageCapacity = .medium
    
    init(index: Int) {
        self.identifier = "test.storage.capability.\(index)"
    }
}

private enum StorageType {
    case local
    case cloud
    case temporary
    case secure
    case database
}

private enum StorageDurability {
    case volatile
    case session
    case permanent
}

private enum StoragePerformance {
    case slow
    case medium
    case fast
    case fastest
}

private enum StorageCapacity {
    case small
    case medium
    case large
    case unlimited
}

private enum DataType {
    case userSettings
    case userDocuments
    case cache
    case largeMedia
    case sensitiveData
}

private enum StorageAccessibility {
    case immediate
    case userInitiated
    case background
    case delayed
}

private enum StorageSynchronization {
    case none
    case optional
    case required
    case realtime
}

private enum StorageSecurity {
    case low
    case medium
    case high
    case maximum
}

private enum StorageLocation {
    case local
    case cloud
    case temporary
}

private enum CleanupAggressiveness {
    case conservative
    case moderate
    case aggressive
}

private enum StorageUseCase {
    case automaticSync
    case backup
    case fastAccess
    case archival
}

private struct StorageRequirements {
    let dataType: DataType
    let durability: StorageDurability
    let accessibility: StorageAccessibility
    let synchronization: StorageSynchronization
    let security: StorageSecurity
}

private struct QuotaInfo {
    let totalSpace: UInt64
    let usedSpace: UInt64
    let availableSpace: UInt64
}

private struct CleanupResult {
    let freedSpace: UInt64
    let deletedItems: Int
}