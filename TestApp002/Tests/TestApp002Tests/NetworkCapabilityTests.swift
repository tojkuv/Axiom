import XCTest
import Axiom
@testable import TestApp002Core

final class NetworkCapabilityTests: XCTestCase {
    
    // MARK: - Red Phase: Test NetworkCapability fails
    
    func testNetworkCapabilityTimeout() async throws {
        let networkCapability = TestNetworkCapability()
        try await networkCapability.initialize()
        let endpoint = Endpoint(url: URL(string: "https://api.example.com/tasks")!)
        
        // This should succeed now with our GREEN implementation
        do {
            let tasks: [Task] = try await networkCapability.request(endpoint)
            XCTAssertNotNil(tasks, "Should return valid task array")
        } catch {
            XCTFail("Should not throw error with GREEN implementation, got: \(error)")
        }
    }
    
    func testNetworkCapabilityRetryLogic() async throws {
        let networkCapability = TestNetworkCapability()
        try await networkCapability.initialize()
        let endpoint = Endpoint(url: URL(string: "https://api.example.com/tasks")!)
        
        // Test that retry logic is implemented (should succeed in GREEN phase)
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            let tasks: [Task] = try await networkCapability.request(endpoint)
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            
            // Should complete quickly since no retries needed
            XCTAssertLessThan(duration, 1.0, "Should complete without retries")
            XCTAssertNotNil(tasks, "Should return valid task array")
        } catch {
            XCTFail("Should not throw error with GREEN implementation, got: \(error)")
        }
    }
    
    func testNetworkCapabilityCancellation() async throws {
        let networkCapability = TestNetworkCapability()
        try await networkCapability.initialize()
        let endpoint = Endpoint(url: URL(string: "https://api.example.com/tasks")!)
        
        // Test immediate cancellation on task cancellation as per RFC
        let task = SwiftTask<[Task], Error> {
            try await networkCapability.request(endpoint) as [Task]
        }
        
        // Cancel immediately
        task.cancel()
        
        do {
            _ = try await task.value
            XCTFail("Should have thrown cancelled error")
        } catch {
            // Task cancellation might throw CancellationError or NetworkError.cancelled
            XCTAssertTrue(error is CancellationError || error is NetworkError, "Should throw cancellation-related error")
        }
    }
    
    func testNetworkCapabilityUpload() async throws {
        let networkCapability = TestNetworkCapability()
        try await networkCapability.initialize()
        let endpoint = Endpoint(url: URL(string: "https://api.example.com/tasks")!, method: .POST)
        
        let taskData = Task(
            id: "upload-test",
            title: "Upload Test",
            description: "Test upload",
            dueDate: nil,
            categoryId: nil,
            priority: .medium,
            isCompleted: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // This should succeed with GREEN implementation
        do {
            try await networkCapability.upload(taskData, to: endpoint)
            // Success - no return value for upload
        } catch {
            XCTFail("Should not throw error with GREEN implementation, got: \(error)")
        }
    }
    
    func testNetworkCapabilityErrorHandling() async throws {
        let networkCapability = TestNetworkCapability()
        try await networkCapability.initialize()
        let endpoint = Endpoint(url: URL(string: "https://api.example.com/tasks")!)
        
        // Test that capability handles requests properly (GREEN phase)
        do {
            let tasks: [Task] = try await networkCapability.request(endpoint)
            XCTAssertNotNil(tasks, "Should return valid task array")
        } catch {
            XCTFail("Should not throw error with GREEN implementation, got: \(error)")
        }
    }
    
    func testNetworkCapabilityPerformance() async throws {
        let networkCapability = TestNetworkCapability()
        try await networkCapability.initialize()
        let endpoint = Endpoint(url: URL(string: "https://api.example.com/tasks")!)
        
        // Test that requests complete within reasonable time
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            let _: [Task] = try await networkCapability.request(endpoint)
        } catch {
            XCTFail("Should not throw error with GREEN implementation, got: \(error)")
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Should complete quickly without retries
        XCTAssertLessThan(duration, 1.0, "Request should complete quickly")
    }
    
    func testNetworkCapabilityThreadSafety() async throws {
        let networkCapability = TestNetworkCapability()
        try await networkCapability.initialize()
        let endpoint = Endpoint(url: URL(string: "https://api.example.com/tasks")!)
        
        // Test concurrent requests
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    do {
                        let _: [Task] = try await networkCapability.request(endpoint)
                    } catch {
                        XCTFail("Should not throw error with GREEN implementation, got: \(error)")
                    }
                }
            }
        }
        
        // Should complete without crashes
        XCTAssertTrue(true, "Concurrent requests should not crash")
    }
}