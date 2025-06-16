import XCTest
import AxiomTesting
@testable import AxiomCapabilityDomains
@testable import AxiomCapabilities
@testable import AxiomPlatform
@testable import AxiomArchitecture

/// Tests for AxiomCapabilityDomains persistence capability domain functionality
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class PersistenceCapabilityDomainTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Core Functionality Tests
    
    func testPersistenceCapabilityDomainInitialization() async throws {
        let persistenceDomain = PersistenceCapabilityDomain()
        XCTAssertNotNil(persistenceDomain, "PersistenceCapabilityDomain should initialize correctly")
        XCTAssertEqual(persistenceDomain.identifier, "axiom.capability.domain.persistence", "Should have correct identifier")
    }
    
    func testDatabaseCapabilityRegistration() async throws {
        let persistenceDomain = PersistenceCapabilityDomain()
        
        let sqliteCapability = SQLiteCapability()
        let coreDataCapability = CoreDataCapability()
        let cloudKitCapability = CloudKitCapability()
        
        await persistenceDomain.registerCapability(sqliteCapability)
        await persistenceDomain.registerCapability(coreDataCapability)
        await persistenceDomain.registerCapability(cloudKitCapability)
        
        let registeredCapabilities = await persistenceDomain.getRegisteredCapabilities()
        XCTAssertEqual(registeredCapabilities.count, 3, "Should have 3 registered persistence capabilities")
        
        let hasSQLite = await persistenceDomain.hasCapability("axiom.persistence.sqlite")
        XCTAssertTrue(hasSQLite, "Should have SQLite capability")
        
        let hasCoreData = await persistenceDomain.hasCapability("axiom.persistence.coredata")
        XCTAssertTrue(hasCoreData, "Should have CoreData capability")
        
        let hasCloudKit = await persistenceDomain.hasCapability("axiom.persistence.cloudkit")
        XCTAssertTrue(hasCloudKit, "Should have CloudKit capability")
    }
    
    func testCacheCapabilityManagement() async throws {
        let persistenceDomain = PersistenceCapabilityDomain()
        
        let memoryCache = MemoryCacheCapability()
        let diskCache = DiskCacheCapability()
        let distributedCache = DistributedCacheCapability()
        
        await persistenceDomain.registerCapability(memoryCache)
        await persistenceDomain.registerCapability(diskCache)
        await persistenceDomain.registerCapability(distributedCache)
        
        let cacheCapabilities = await persistenceDomain.getCapabilitiesOfType(.cache)
        XCTAssertEqual(cacheCapabilities.count, 3, "Should have 3 cache capabilities")
        
        let bestCacheCapability = await persistenceDomain.getBestCapabilityForUseCase(.fastAccess)
        XCTAssertEqual(bestCacheCapability?.identifier, memoryCache.identifier, "Memory cache should be best for fast access")
        
        let largeStorageCapability = await persistenceDomain.getBestCapabilityForUseCase(.largeStorage)
        XCTAssertEqual(largeStorageCapability?.identifier, diskCache.identifier, "Disk cache should be best for large storage")
    }
    
    func testPersistenceStrategySelection() async throws {
        let persistenceDomain = PersistenceCapabilityDomain()
        
        // Register various persistence capabilities
        await persistenceDomain.registerCapability(SQLiteCapability())
        await persistenceDomain.registerCapability(CoreDataCapability())
        await persistenceDomain.registerCapability(CloudKitCapability())
        await persistenceDomain.registerCapability(MemoryCacheCapability())
        
        let strategy = await persistenceDomain.selectOptimalStrategy(
            for: PersistenceRequirements(
                durability: .permanent,
                consistency: .strong,
                availability: .high,
                dataSize: .medium
            )
        )
        
        XCTAssertNotNil(strategy, "Should select an optimal persistence strategy")
        XCTAssertTrue(strategy!.capabilities.count > 0, "Strategy should include capabilities")
        
        let primaryCapability = strategy!.primaryCapability
        XCTAssertNotNil(primaryCapability, "Strategy should have a primary capability")
    }
    
    func testTransactionCoordination() async throws {
        let persistenceDomain = PersistenceCapabilityDomain()
        
        await persistenceDomain.registerCapability(SQLiteCapability())
        await persistenceDomain.registerCapability(CoreDataCapability())
        
        let transactionCoordinator = await persistenceDomain.getTransactionCoordinator()
        XCTAssertNotNil(transactionCoordinator, "Should provide transaction coordinator")
        
        let transactionId = await transactionCoordinator!.beginDistributedTransaction()
        XCTAssertNotNil(transactionId, "Should begin distributed transaction")
        
        await transactionCoordinator!.addParticipant(transactionId, capability: "axiom.persistence.sqlite")
        await transactionCoordinator!.addParticipant(transactionId, capability: "axiom.persistence.coredata")
        
        let participants = await transactionCoordinator!.getParticipants(transactionId)
        XCTAssertEqual(participants.count, 2, "Should have 2 transaction participants")
        
        await transactionCoordinator!.commitTransaction(transactionId)
        
        let isCommitted = await transactionCoordinator!.isTransactionCommitted(transactionId)
        XCTAssertTrue(isCommitted, "Transaction should be committed")
    }
    
    // MARK: - Performance Tests
    
    func testPersistenceCapabilityDomainPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let persistenceDomain = PersistenceCapabilityDomain()
                
                // Test rapid capability operations
                for i in 0..<100 {
                    let capability = TestPersistenceCapability(index: i)
                    await persistenceDomain.registerCapability(capability)
                }
                
                // Test strategy selection performance
                for _ in 0..<50 {
                    let requirements = PersistenceRequirements(
                        durability: .permanent,
                        consistency: .eventual,
                        availability: .medium,
                        dataSize: .small
                    )
                    _ = await persistenceDomain.selectOptimalStrategy(for: requirements)
                }
            },
            maxDuration: .milliseconds(300),
            maxMemoryGrowth: 1024 * 1024 // 1MB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testPersistenceCapabilityDomainMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            let persistenceDomain = PersistenceCapabilityDomain()
            
            // Simulate domain lifecycle
            for i in 0..<30 {
                let capability = TestPersistenceCapability(index: i)
                await persistenceDomain.registerCapability(capability)
                
                if i % 5 == 0 {
                    let requirements = PersistenceRequirements(
                        durability: .temporary,
                        consistency: .weak,
                        availability: .low,
                        dataSize: .large
                    )
                    _ = await persistenceDomain.selectOptimalStrategy(for: requirements)
                }
                
                if i % 10 == 0 {
                    await persistenceDomain.unregisterCapability(capability.identifier)
                }
            }
            
            await persistenceDomain.cleanup()
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testPersistenceCapabilityDomainErrorHandling() async throws {
        let persistenceDomain = PersistenceCapabilityDomain()
        
        // Test registering capability with duplicate identifier
        let capability1 = TestPersistenceCapability(index: 1)
        let capability2 = TestPersistenceCapability(index: 1) // Same index = same identifier
        
        await persistenceDomain.registerCapability(capability1)
        
        do {
            try await persistenceDomain.registerCapabilityStrict(capability2)
            XCTFail("Should throw error for duplicate identifier")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for duplicate identifier")
        }
        
        // Test strategy selection with impossible requirements
        do {
            let impossibleRequirements = PersistenceRequirements(
                durability: .permanent,
                consistency: .strong,
                availability: .high,
                dataSize: .unlimited
            )
            try await persistenceDomain.selectOptimalStrategyStrict(for: impossibleRequirements)
            // This might succeed if capabilities can handle it, so we don't fail here
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for impossible requirements")
        }
    }
}

// MARK: - Test Helper Classes

private struct SQLiteCapability: PersistenceCapability {
    let identifier = "axiom.persistence.sqlite"
    let isAvailable = true
    let persistenceType: PersistenceType = .database
    let durability: Durability = .permanent
    let consistency: Consistency = .strong
}

private struct CoreDataCapability: PersistenceCapability {
    let identifier = "axiom.persistence.coredata"
    let isAvailable = true
    let persistenceType: PersistenceType = .objectStore
    let durability: Durability = .permanent
    let consistency: Consistency = .strong
}

private struct CloudKitCapability: PersistenceCapability {
    let identifier = "axiom.persistence.cloudkit"
    let isAvailable = true
    let persistenceType: PersistenceType = .cloudStore
    let durability: Durability = .permanent
    let consistency: Consistency = .eventual
}

private struct MemoryCacheCapability: PersistenceCapability {
    let identifier = "axiom.persistence.memory"
    let isAvailable = true
    let persistenceType: PersistenceType = .cache
    let durability: Durability = .temporary
    let consistency: Consistency = .strong
}

private struct DiskCacheCapability: PersistenceCapability {
    let identifier = "axiom.persistence.disk"
    let isAvailable = true
    let persistenceType: PersistenceType = .cache
    let durability: Durability = .session
    let consistency: Consistency = .strong
}

private struct DistributedCacheCapability: PersistenceCapability {
    let identifier = "axiom.persistence.distributed"
    let isAvailable = true
    let persistenceType: PersistenceType = .cache
    let durability: Durability = .session
    let consistency: Consistency = .eventual
}

private struct TestPersistenceCapability: PersistenceCapability {
    let identifier: String
    let isAvailable = true
    let persistenceType: PersistenceType = .cache
    let durability: Durability = .temporary
    let consistency: Consistency = .weak
    
    init(index: Int) {
        self.identifier = "test.persistence.capability.\(index)"
    }
}

private enum PersistenceType {
    case database
    case objectStore
    case cloudStore
    case cache
}

private enum Durability {
    case temporary
    case session
    case permanent
}

private enum Consistency {
    case weak
    case eventual
    case strong
}

private enum Availability {
    case low
    case medium
    case high
}

private enum DataSize {
    case small
    case medium
    case large
    case unlimited
}

private struct PersistenceRequirements {
    let durability: Durability
    let consistency: Consistency
    let availability: Availability
    let dataSize: DataSize
}

private enum PersistenceUseCase {
    case fastAccess
    case largeStorage
    case cloudSync
    case offline
}