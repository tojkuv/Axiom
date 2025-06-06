import XCTest
@testable import TestApp002Core

final class SyncClientTests: XCTestCase {
    
    // MARK: - Red Phase: Test SyncClient coordination fails
    
    func testSyncClientInitialization() async throws {
        let syncClient = SyncClient()
        
        // Verify it conforms to Client protocol
        XCTAssertNotNil(syncClient)
        
        // Verify initial state shows not syncing
        var iterator = await syncClient.stateStream.makeAsyncIterator()
        let initialState = await iterator.next()
        XCTAssertNotNil(initialState)
        XCTAssertFalse(initialState?.isSyncing ?? true)
        XCTAssertEqual(initialState?.progress, 0.0)
        XCTAssertEqual(initialState?.pendingChanges, 0)
    }
    
    func testStartSyncProcess() async throws {
        let syncClient = SyncClient()
        let expectation = XCTestExpectation(description: "Sync started")
        
        SwiftTask<Void, Never> {
            var iterator = await syncClient.stateStream.makeAsyncIterator()
            // Skip initial state
            _ = await iterator.next()
            
            // Wait for syncing state
            if let state = await iterator.next() {
                if state.isSyncing {
                    expectation.fulfill()
                }
            }
        }
        
        // Give time for observer to start
        try await SwiftTask.sleep(nanoseconds: 10_000_000)
        
        // Start sync
        try await syncClient.process(.startSync)
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testSyncProgressUpdates() async throws {
        let syncClient = SyncClient()
        let expectation = XCTestExpectation(description: "Progress updated")
        
        SwiftTask<Void, Never> {
            var iterator = await syncClient.stateStream.makeAsyncIterator()
            var progressSeen = Set<Double>()
            
            while let state = await iterator.next() {
                progressSeen.insert(state.progress)
                
                // Check if we've seen progress updates (0.0, some progress, 1.0)
                if progressSeen.count >= 2 && progressSeen.contains(1.0) {
                    expectation.fulfill()
                    break
                }
            }
        }
        
        // Start sync and wait for completion
        try await syncClient.process(.startSync)
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testSyncCancellation() async throws {
        let syncClient = SyncClient()
        
        // Start sync
        try await syncClient.process(.startSync)
        
        let expectation = XCTestExpectation(description: "Sync cancelled")
        
        SwiftTask<Void, Never> {
            var iterator = await syncClient.stateStream.makeAsyncIterator()
            
            while let state = await iterator.next() {
                if !state.isSyncing && state.progress == 0.0 {
                    expectation.fulfill()
                    break
                }
            }
        }
        
        // Cancel sync
        try await syncClient.process(.cancelSync)
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testConflictResolution() async throws {
        let syncClient = SyncClient()
        
        // Create a test conflict
        let localTask = Task(
            id: "conflict-task",
            title: "Local Title",
            description: "Local Description",
            dueDate: nil,
            categoryId: nil,
            priority: .high,
            isCompleted: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let remoteTask = Task(
            id: "conflict-task",
            title: "Remote Title", 
            description: "Remote Description",
            dueDate: nil,
            categoryId: nil,
            priority: .medium,
            isCompleted: true,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let conflict = SyncConflict(
            taskId: "conflict-task",
            localVersion: localTask,
            remoteVersion: remoteTask
        )
        
        let expectation = XCTestExpectation(description: "Conflict resolved")
        
        SwiftTask<Void, Never> {
            var iterator = await syncClient.stateStream.makeAsyncIterator()
            
            while let state = await iterator.next() {
                if state.conflicts.isEmpty {
                    expectation.fulfill()
                    break
                }
            }
        }
        
        // This should fail until we implement conflict handling
        try await syncClient.process(.resolveConflict(conflictId: conflict.id, resolution: .useRemote))
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testMassiveSyncPerformance() async throws {
        let syncClient = SyncClient()
        
        // Test processing 1000 sync operations as per RFC requirement
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Simulate 1000 sync operations
        for _ in 0..<1000 {
            try await syncClient.process(.startSync)
            try await syncClient.process(.cancelSync)
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Should process 1000 operations without blocking (excluding network time)
        // Allow reasonable time for 1000 operations - 1 second max
        XCTAssertLessThan(duration, 1.0, "1000 sync operations took too long: \(duration)s")
    }
}