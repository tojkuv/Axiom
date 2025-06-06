import XCTest
import Axiom
@testable import TestApp002Core

final class SyncStatusUITests: XCTestCase {
    
    // MARK: - RED Phase: Sync UI update tests that will fail
    
    func testProgressUpdatesThrottledTo200ms() async throws {
        // RFC Requirement: Progress bar updates throttled to 5Hz (200ms intervals) during sync
        let syncClient = SyncClient()
        var updateTimestamps: [Date] = []
        let expectation = XCTestExpectation(description: "Progress throttled to 200ms")
        
        SwiftTask<Void, Never> {
            var iterator = await syncClient.stateStream.makeAsyncIterator()
            var previousProgress: Double = -1
            
            while let state = await iterator.next() {
                // Only track progress updates (not initial state or final completion)
                if state.isSyncing && state.progress != previousProgress && state.progress > 0 {
                    updateTimestamps.append(Date())
                    previousProgress = state.progress
                    
                    // Check intervals after we have at least 2 updates
                    if updateTimestamps.count >= 2 {
                        let lastTwoUpdates = Array(updateTimestamps.suffix(2))
                        let interval = lastTwoUpdates[1].timeIntervalSince(lastTwoUpdates[0])
                        
                        // Should be at least 200ms apart (with 50ms tolerance for timing)
                        XCTAssertGreaterThanOrEqual(interval, 0.15, 
                            "Progress updates too frequent: \(interval * 1000)ms, expected ≥200ms")
                    }
                }
                
                // Complete test after sync finishes
                if !state.isSyncing && updateTimestamps.count >= 3 {
                    expectation.fulfill()
                    break
                }
            }
        }
        
        try await syncClient.process(.startSync)
        await fulfillment(of: [expectation], timeout: 3.0)
        
        // This test will FAIL because current implementation updates every 50ms
        XCTAssertGreaterThan(updateTimestamps.count, 0, "Should have received progress updates")
    }
    
    func testOfflineModeIndication() async throws {
        // RFC Boundary: Clear indication of offline mode
        let syncClient = SyncClient()
        let expectation = XCTestExpectation(description: "Offline mode set")
        
        SwiftTask<Void, Never> {
            var iterator = await syncClient.stateStream.makeAsyncIterator()
            
            // Skip initial state and sync start state
            _ = await iterator.next() // initial
            _ = await iterator.next() // start sync
            
            // Wait for offline state
            while let state = await iterator.next() {
                if state.isOffline && !state.isSyncing {
                    expectation.fulfill()
                    break
                }
            }
        }
        
        // Start sync then go offline
        try await syncClient.process(.startSync)
        try await syncClient.process(.setOfflineMode(true))
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testSmoothVisualFeedback() async throws {
        // RFC Acceptance: Smooth visual feedback without rapid updates
        let syncClient = SyncClient()
        var rapidUpdates = 0
        let expectation = XCTestExpectation(description: "Smooth progress updates")
        
        SwiftTask<Void, Never> {
            var iterator = await syncClient.stateStream.makeAsyncIterator()
            var lastUpdateTime = Date()
            
            while let state = await iterator.next() {
                let now = Date()
                let timeSinceLastUpdate = now.timeIntervalSince(lastUpdateTime)
                
                // Count updates that are too rapid (< 150ms apart)
                if timeSinceLastUpdate < 0.15 && state.isSyncing && state.progress > 0 {
                    rapidUpdates += 1
                }
                
                lastUpdateTime = now
                
                if !state.isSyncing && state.progress >= 1.0 {
                    expectation.fulfill()
                    break
                }
            }
        }
        
        try await syncClient.process(.startSync)
        await fulfillment(of: [expectation], timeout: 3.0)
        
        // This will FAIL because current implementation has rapid updates every 50ms
        XCTAssertLessThanOrEqual(rapidUpdates, 1, 
            "Too many rapid updates (\(rapidUpdates)), expected smooth 200ms intervals")
    }
    
    func testProgressUpdateConsistency() async throws {
        // Test that progress updates are monotonic and consistent
        let syncClient = SyncClient()
        var progressValues: [Double] = []
        let expectation = XCTestExpectation(description: "Consistent progress")
        
        SwiftTask<Void, Never> {
            var iterator = await syncClient.stateStream.makeAsyncIterator()
            
            while let state = await iterator.next() {
                if state.isSyncing || state.progress > 0 {
                    progressValues.append(state.progress)
                }
                
                if !state.isSyncing && state.progress >= 1.0 {
                    expectation.fulfill()
                    break
                }
            }
        }
        
        try await syncClient.process(.startSync)
        await fulfillment(of: [expectation], timeout: 3.0)
        
        // Verify progress is monotonic (always increasing)
        for i in 1..<progressValues.count {
            XCTAssertGreaterThanOrEqual(progressValues[i], progressValues[i-1], 
                "Progress should be monotonic: \(progressValues)")
        }
        
        // This will pass but validates the requirement for smooth progress
        XCTAssertGreaterThan(progressValues.count, 0, "Should have progress updates")
        XCTAssertEqual(progressValues.last, 1.0, "Should complete with 100% progress")
    }
    
    func testManualSyncTrigger() async throws {
        // RFC Refactoring: Add manual sync trigger
        let syncClient = SyncClient()
        let expectation = XCTestExpectation(description: "Manual sync started")
        
        SwiftTask<Void, Never> {
            var iterator = await syncClient.stateStream.makeAsyncIterator()
            
            // Skip initial state
            _ = await iterator.next()
            
            // Wait for sync to start
            if let state = await iterator.next() {
                if state.isSyncing {
                    expectation.fulfill()
                }
            }
        }
        
        // Start manual sync
        try await syncClient.process(.manualSync(force: true))
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testUIUpdatePerformance() async throws {
        // Measure UI update performance at 5Hz (200ms intervals)
        let syncClient = SyncClient()
        var uiUpdateTimes: [Double] = []
        let expectation = XCTestExpectation(description: "UI performance")
        
        SwiftTask<Void, Never> {
            var iterator = await syncClient.stateStream.makeAsyncIterator()
            
            while let state = await iterator.next() {
                // Simulate UI update time
                let startTime = CFAbsoluteTimeGetCurrent()
                
                // Simulate basic UI updates that would happen in real app
                let _ = state.progress * 100 // Progress percentage
                let _ = state.isSyncing ? "Syncing..." : "Complete"
                let _ = "\(state.pendingChanges) pending"
                
                let updateTime = CFAbsoluteTimeGetCurrent() - startTime
                uiUpdateTimes.append(updateTime)
                
                if !state.isSyncing && state.progress >= 1.0 {
                    expectation.fulfill()
                    break
                }
            }
        }
        
        try await syncClient.process(.startSync)
        await fulfillment(of: [expectation], timeout: 3.0)
        
        // Each UI update should be fast (< 16ms for 60fps)
        let maxUpdateTime = uiUpdateTimes.max() ?? 0
        XCTAssertLessThan(maxUpdateTime, 0.016, 
            "UI updates too slow: \(maxUpdateTime * 1000)ms, expected < 16ms")
    }
    
    // REFACTOR: Test for enhanced logging functionality
    func testSyncLogging() async throws {
        let syncClient = SyncClient()
        let expectation = XCTestExpectation(description: "Sync logging complete")
        var capturedLogs: [SyncLogEntry] = []
        
        SwiftTask<Void, Never> {
            var iterator = await syncClient.stateStream.makeAsyncIterator()
            
            while let state = await iterator.next() {
                capturedLogs = state.syncLogs
                
                if !state.isSyncing && state.progress >= 1.0 {
                    expectation.fulfill()
                    break
                }
            }
        }
        
        try await syncClient.process(.startSync)
        await fulfillment(of: [expectation], timeout: 3.0)
        
        // Verify logs were captured
        XCTAssertGreaterThan(capturedLogs.count, 0, "Should have sync logs")
        
        // Verify we have start and completion logs
        let startLog = capturedLogs.first { $0.message.contains("Sync started") }
        let completeLog = capturedLogs.first { $0.message.contains("Sync completed successfully") }
        
        XCTAssertNotNil(startLog, "Should have sync start log")
        XCTAssertNotNil(completeLog, "Should have sync completion log")
        
        // Verify log timestamps are reasonable
        for log in capturedLogs {
            XCTAssertLessThan(Date().timeIntervalSince(log.timestamp), 5.0, 
                "Log timestamp should be recent")
        }
    }
    
    // REFACTOR: Test for enhanced UI feedback
    func testEnhancedUIFeedback() async throws {
        let syncClient = SyncClient()
        let expectation = XCTestExpectation(description: "UI feedback captured")
        var statusMessages: [String] = []
        
        SwiftTask<Void, Never> {
            var iterator = await syncClient.stateStream.makeAsyncIterator()
            
            while let state = await iterator.next() {
                statusMessages.append(state.statusMessage)
                
                if !state.isSyncing && state.progress >= 1.0 {
                    expectation.fulfill()
                    break
                }
            }
        }
        
        try await syncClient.process(.startSync)
        await fulfillment(of: [expectation], timeout: 3.0)
        
        // Verify we captured meaningful status messages
        XCTAssertGreaterThan(statusMessages.count, 0, "Should have status messages")
        
        // Check for expected status patterns
        let hasSyncingMessage = statusMessages.contains { $0.contains("Syncing") }
        let hasCompletionMessage = statusMessages.contains { $0.contains("Last sync") }
        
        XCTAssertTrue(hasSyncingMessage, "Should have syncing status message")
        XCTAssertTrue(hasCompletionMessage, "Should have completion status message")
    }
    
    // REFACTOR: Test offline mode status feedback
    func testOfflineStatusFeedback() async throws {
        let syncClient = SyncClient()
        let expectation = XCTestExpectation(description: "Offline status captured")
        
        SwiftTask<Void, Never> {
            var iterator = await syncClient.stateStream.makeAsyncIterator()
            
            while let state = await iterator.next() {
                if state.isOffline && state.statusMessage.contains("Offline") {
                    expectation.fulfill()
                    break
                }
            }
        }
        
        try await syncClient.process(.setOfflineMode(true))
        await fulfillment(of: [expectation], timeout: 1.0)
    }
}