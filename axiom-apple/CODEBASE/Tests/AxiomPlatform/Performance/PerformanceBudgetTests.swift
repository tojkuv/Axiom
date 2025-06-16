import XCTest
import AxiomTesting
@testable import AxiomPlatform
@testable import AxiomArchitecture

/// Tests for AxiomPlatform performance budget functionality
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class PerformanceBudgetTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Core Functionality Tests
    
    func testPerformanceBudgetInitialization() async throws {
        let budget = PerformanceBudget()
        XCTAssertNotNil(budget, "PerformanceBudget should initialize correctly")
    }
    
    func testBudgetConfiguration() async throws {
        let budget = PerformanceBudget()
        
        budget.maxMemoryUsage = 100 * 1024 * 1024 // 100MB
        budget.maxCPUUsage = 0.8 // 80%
        budget.maxNetworkBandwidth = 1000 // 1000 KB/s
        budget.maxDiskIO = 500 // 500 KB/s
        
        XCTAssertEqual(budget.maxMemoryUsage, 100 * 1024 * 1024, "Should set max memory usage")
        XCTAssertEqual(budget.maxCPUUsage, 0.8, "Should set max CPU usage")
        XCTAssertEqual(budget.maxNetworkBandwidth, 1000, "Should set max network bandwidth")
        XCTAssertEqual(budget.maxDiskIO, 500, "Should set max disk IO")
    }
    
    func testBudgetValidation() async throws {
        let budget = PerformanceBudget()
        let validator = PerformanceBudgetValidator()
        
        // Test valid budget
        budget.maxMemoryUsage = 50 * 1024 * 1024 // 50MB
        budget.maxCPUUsage = 0.7 // 70%
        
        let isValid = await validator.validateBudget(budget)
        XCTAssertTrue(isValid, "Valid budget should pass validation")
        
        // Test budget violation
        budget.maxMemoryUsage = 1 * 1024 // 1KB (too low)
        let isInvalid = await validator.validateBudget(budget)
        XCTAssertFalse(isInvalid, "Unrealistic budget should fail validation")
    }
    
    func testBudgetEnforcement() async throws {
        let budget = PerformanceBudget()
        let enforcer = PerformanceBudgetEnforcer()
        
        budget.maxMemoryUsage = 10 * 1024 * 1024 // 10MB
        budget.maxCPUUsage = 0.5 // 50%
        
        await enforcer.setBudget(budget)
        
        // Simulate operation within budget
        await enforcer.reportUsage(memory: 5 * 1024 * 1024, cpu: 0.3)
        let isWithinBudget = await enforcer.isWithinBudget()
        XCTAssertTrue(isWithinBudget, "Should be within budget")
        
        // Simulate operation exceeding budget
        await enforcer.reportUsage(memory: 15 * 1024 * 1024, cpu: 0.8)
        let isOverBudget = await enforcer.isWithinBudget()
        XCTAssertFalse(isOverBudget, "Should be over budget")
    }
    
    func testAdaptiveBudgetAdjustment() async throws {
        let budget = PerformanceBudget()
        let adapter = AdaptiveBudgetManager()
        
        budget.maxMemoryUsage = 20 * 1024 * 1024 // 20MB
        await adapter.setBaseBudget(budget)
        
        // Test adaptation based on device capabilities
        let deviceInfo = DeviceInfo()
        let totalMemory = await deviceInfo.getTotalMemory()
        
        await adapter.adaptBudgetForDevice()
        let adaptedBudget = await adapter.getCurrentBudget()
        
        // Adapted budget should be reasonable for device
        XCTAssertLessThanOrEqual(adaptedBudget.maxMemoryUsage, totalMemory / 4, 
                                "Adapted budget should not exceed 25% of total memory")
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceBudgetOverhead() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let budget = PerformanceBudget()
                let enforcer = PerformanceBudgetEnforcer()
                
                budget.maxMemoryUsage = 50 * 1024 * 1024
                budget.maxCPUUsage = 0.8
                
                await enforcer.setBudget(budget)
                
                // Test rapid budget checking
                for i in 0..<1000 {
                    let memory = (i % 100) * 1024 * 1024
                    let cpu = Double(i % 100) / 100.0
                    await enforcer.reportUsage(memory: memory, cpu: cpu)
                    _ = await enforcer.isWithinBudget()
                }
            },
            maxDuration: .milliseconds(100),
            maxMemoryGrowth: 1024 * 1024 // 1MB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testPerformanceBudgetMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            let budget = PerformanceBudget()
            let enforcer = PerformanceBudgetEnforcer()
            let adapter = AdaptiveBudgetManager()
            
            // Simulate budget lifecycle
            budget.maxMemoryUsage = 30 * 1024 * 1024
            await enforcer.setBudget(budget)
            await adapter.setBaseBudget(budget)
            
            for i in 0..<100 {
                await enforcer.reportUsage(memory: i * 1024 * 1024, cpu: 0.5)
                await adapter.adaptBudgetForCurrentConditions()
            }
            
            await enforcer.reset()
            await adapter.reset()
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testPerformanceBudgetErrorHandling() async throws {
        let budget = PerformanceBudget()
        let validator = PerformanceBudgetValidator()
        
        // Test invalid memory budget
        budget.maxMemoryUsage = -1
        
        do {
            try await validator.validateBudgetStrict(budget)
            XCTFail("Should throw error for negative memory budget")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for invalid budget")
        }
        
        // Test invalid CPU budget
        budget.maxMemoryUsage = 1024 * 1024
        budget.maxCPUUsage = 1.5 // > 100%
        
        do {
            try await validator.validateBudgetStrict(budget)
            XCTFail("Should throw error for CPU budget > 100%")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for invalid CPU budget")
        }
    }
}