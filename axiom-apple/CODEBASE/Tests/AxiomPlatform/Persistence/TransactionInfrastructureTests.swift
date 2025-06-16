import XCTest
import AxiomTesting
@testable import AxiomPlatform
@testable import AxiomArchitecture

/// Tests for AxiomPlatform transaction infrastructure functionality
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class TransactionInfrastructureTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Core Functionality Tests
    
    func testTransactionInfrastructureInitialization() async throws {
        let infrastructure = TransactionInfrastructure()
        XCTAssertNotNil(infrastructure, "TransactionInfrastructure should initialize correctly")
    }
    
    func testBasicTransactionLifecycle() async throws {
        let infrastructure = TransactionInfrastructure()
        
        // Begin transaction
        let transactionId = await infrastructure.beginTransaction()
        XCTAssertNotNil(transactionId, "Should create transaction ID")
        
        let isActive = await infrastructure.isTransactionActive(transactionId)
        XCTAssertTrue(isActive, "Transaction should be active after begin")
        
        // Commit transaction
        await infrastructure.commitTransaction(transactionId)
        
        let isCommitted = await infrastructure.isTransactionCommitted(transactionId)
        XCTAssertTrue(isCommitted, "Transaction should be committed")
        
        let isStillActive = await infrastructure.isTransactionActive(transactionId)
        XCTAssertFalse(isStillActive, "Transaction should not be active after commit")
    }
    
    func testTransactionRollback() async throws {
        let infrastructure = TransactionInfrastructure()
        
        let transactionId = await infrastructure.beginTransaction()
        
        // Perform some operations within transaction
        await infrastructure.addOperation(transactionId, operation: "create_user", data: ["name": "test"])
        await infrastructure.addOperation(transactionId, operation: "update_profile", data: ["age": 25])
        
        let operationCount = await infrastructure.getOperationCount(transactionId)
        XCTAssertEqual(operationCount, 2, "Should have 2 operations in transaction")
        
        // Rollback transaction
        await infrastructure.rollbackTransaction(transactionId)
        
        let isRolledBack = await infrastructure.isTransactionRolledBack(transactionId)
        XCTAssertTrue(isRolledBack, "Transaction should be rolled back")
        
        let isActive = await infrastructure.isTransactionActive(transactionId)
        XCTAssertFalse(isActive, "Transaction should not be active after rollback")
    }
    
    func testNestedTransactions() async throws {
        let infrastructure = TransactionInfrastructure()
        
        // Begin parent transaction
        let parentId = await infrastructure.beginTransaction()
        
        // Begin nested transaction
        let nestedId = await infrastructure.beginNestedTransaction(parent: parentId)
        XCTAssertNotEqual(parentId, nestedId, "Nested transaction should have different ID")
        
        let isNested = await infrastructure.isNestedTransaction(nestedId)
        XCTAssertTrue(isNested, "Should identify as nested transaction")
        
        let parentOfNested = await infrastructure.getParentTransaction(nestedId)
        XCTAssertEqual(parentOfNested, parentId, "Should reference correct parent")
        
        // Commit nested first
        await infrastructure.commitTransaction(nestedId)
        
        let isParentStillActive = await infrastructure.isTransactionActive(parentId)
        XCTAssertTrue(isParentStillActive, "Parent should remain active after nested commit")
        
        // Commit parent
        await infrastructure.commitTransaction(parentId)
        
        let areAllCommitted = await infrastructure.areAllTransactionsCommitted([parentId, nestedId])
        XCTAssertTrue(areAllCommitted, "Both transactions should be committed")
    }
    
    func testTransactionIsolation() async throws {
        let infrastructure = TransactionInfrastructure()
        
        let transaction1 = await infrastructure.beginTransaction()
        let transaction2 = await infrastructure.beginTransaction()
        
        // Add operations to each transaction
        await infrastructure.addOperation(transaction1, operation: "update_counter", data: ["value": 1])
        await infrastructure.addOperation(transaction2, operation: "update_counter", data: ["value": 2])
        
        // Operations should be isolated
        let ops1 = await infrastructure.getOperations(transaction1)
        let ops2 = await infrastructure.getOperations(transaction2)
        
        XCTAssertEqual(ops1.count, 1, "Transaction 1 should have 1 operation")
        XCTAssertEqual(ops2.count, 1, "Transaction 2 should have 1 operation")
        
        if let op1 = ops1.first, let op2 = ops2.first {
            XCTAssertNotEqual(op1.data["value"] as? Int, op2.data["value"] as? Int, 
                             "Operations should have different values")
        }
        
        // Clean up
        await infrastructure.commitTransaction(transaction1)
        await infrastructure.commitTransaction(transaction2)
    }
    
    func testTransactionTimeouts() async throws {
        let infrastructure = TransactionInfrastructure()
        
        // Begin transaction with short timeout
        let transactionId = await infrastructure.beginTransaction(timeout: .milliseconds(100))
        
        // Wait longer than timeout
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        let isTimedOut = await infrastructure.isTransactionTimedOut(transactionId)
        XCTAssertTrue(isTimedOut, "Transaction should have timed out")
        
        let isActive = await infrastructure.isTransactionActive(transactionId)
        XCTAssertFalse(isActive, "Timed out transaction should not be active")
    }
    
    // MARK: - Performance Tests
    
    func testTransactionInfrastructurePerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let infrastructure = TransactionInfrastructure()
                
                // Test rapid transaction creation and commit
                var transactionIds: [String] = []
                
                for i in 0..<100 {
                    let transactionId = await infrastructure.beginTransaction()
                    transactionIds.append(transactionId)
                    
                    await infrastructure.addOperation(transactionId, 
                                                    operation: "test_op_\(i)", 
                                                    data: ["index": i])
                }
                
                // Commit all transactions
                for transactionId in transactionIds {
                    await infrastructure.commitTransaction(transactionId)
                }
            },
            maxDuration: .milliseconds(500),
            maxMemoryGrowth: 2 * 1024 * 1024 // 2MB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testTransactionInfrastructureMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            let infrastructure = TransactionInfrastructure()
            
            // Simulate transaction lifecycle
            for i in 0..<50 {
                let transactionId = await infrastructure.beginTransaction()
                
                // Add multiple operations
                for j in 0..<5 {
                    await infrastructure.addOperation(transactionId, 
                                                    operation: "op_\(i)_\(j)", 
                                                    data: ["data": "value_\(j)"])
                }
                
                // Randomly commit or rollback
                if i % 2 == 0 {
                    await infrastructure.commitTransaction(transactionId)
                } else {
                    await infrastructure.rollbackTransaction(transactionId)
                }
            }
            
            await infrastructure.cleanup()
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testTransactionInfrastructureErrorHandling() async throws {
        let infrastructure = TransactionInfrastructure()
        
        // Test operations on non-existent transaction
        do {
            try await infrastructure.addOperationStrict("non-existent-id", 
                                                       operation: "test", 
                                                       data: [:])
            XCTFail("Should throw error for non-existent transaction")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for invalid transaction")
        }
        
        // Test double commit
        let transactionId = await infrastructure.beginTransaction()
        await infrastructure.commitTransaction(transactionId)
        
        do {
            try await infrastructure.commitTransactionStrict(transactionId)
            XCTFail("Should throw error for double commit")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for double commit")
        }
        
        // Test rollback after commit
        do {
            try await infrastructure.rollbackTransactionStrict(transactionId)
            XCTFail("Should throw error for rollback after commit")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for rollback after commit")
        }
    }
}