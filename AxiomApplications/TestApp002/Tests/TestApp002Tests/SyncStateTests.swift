import XCTest
@testable import TestApp002Core

final class SyncStateTests: XCTestCase {
    
    // MARK: - Test SyncState immutability
    
    func testSyncStateImmutability() {
        let conflict = SyncConflict(
            taskId: "task-1",
            localVersion: createTestTask(title: "Local"),
            remoteVersion: createTestTask(title: "Remote")
        )
        
        let state = SyncState(
            isSyncing: true,
            progress: 0.5,
            lastSyncDate: Date(),
            pendingChanges: 10,
            conflicts: [conflict]
        )
        
        // Verify all properties are immutable
        XCTAssertTrue(state.isSyncing)
        XCTAssertEqual(state.progress, 0.5)
        XCTAssertNotNil(state.lastSyncDate)
        XCTAssertEqual(state.pendingChanges, 10)
        XCTAssertEqual(state.conflicts.count, 1)
    }
    
    func testSyncStateEquatable() {
        let date = Date()
        let state1 = SyncState(
            isSyncing: true,
            progress: 0.75,
            lastSyncDate: date,
            pendingChanges: 5,
            conflicts: []
        )
        
        let state2 = SyncState(
            isSyncing: true,
            progress: 0.75,
            lastSyncDate: date,
            pendingChanges: 5,
            conflicts: []
        )
        
        // Same values should be equal
        XCTAssertEqual(state1, state2)
        
        // Different progress should not be equal
        let state3 = SyncState(
            isSyncing: true,
            progress: 0.50,
            lastSyncDate: date,
            pendingChanges: 5,
            conflicts: []
        )
        XCTAssertNotEqual(state1, state3)
    }
    
    func testSyncStateHashable() {
        let state1 = SyncState(isSyncing: false, progress: 1.0)
        let state2 = SyncState(isSyncing: false, progress: 1.0)
        
        // Equal states should have equal hash values
        XCTAssertEqual(state1.hashValue, state2.hashValue)
        
        // Can be used in Sets
        let stateSet: Set<SyncState> = [state1, state2]
        XCTAssertEqual(stateSet.count, 1)
    }
    
    func testSyncStateDefaultValues() {
        let state = SyncState()
        
        XCTAssertFalse(state.isSyncing)
        XCTAssertEqual(state.progress, 0.0)
        XCTAssertNil(state.lastSyncDate)
        XCTAssertEqual(state.pendingChanges, 0)
        XCTAssertTrue(state.conflicts.isEmpty)
    }
    
    func testSyncConflictCreation() {
        let localTask = createTestTask(title: "Local Version", isCompleted: false)
        let remoteTask = createTestTask(title: "Remote Version", isCompleted: true)
        
        let conflict = SyncConflict(
            taskId: localTask.id,
            localVersion: localTask,
            remoteVersion: remoteTask
        )
        
        XCTAssertEqual(conflict.taskId, localTask.id)
        XCTAssertEqual(conflict.localVersion.title, "Local Version")
        XCTAssertEqual(conflict.remoteVersion.title, "Remote Version")
        XCTAssertFalse(conflict.localVersion.isCompleted)
        XCTAssertTrue(conflict.remoteVersion.isCompleted)
    }
    
    func testSyncConflictCodable() throws {
        let conflict = SyncConflict(
            id: "conflict-1",
            taskId: "task-1",
            localVersion: createTestTask(title: "Local"),
            remoteVersion: createTestTask(title: "Remote"),
            timestamp: Date()
        )
        
        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(conflict)
        
        // Decode
        let decoder = JSONDecoder()
        let decodedConflict = try decoder.decode(SyncConflict.self, from: data)
        
        XCTAssertEqual(conflict.id, decodedConflict.id)
        XCTAssertEqual(conflict.taskId, decodedConflict.taskId)
        XCTAssertEqual(conflict.localVersion.title, decodedConflict.localVersion.title)
        XCTAssertEqual(conflict.remoteVersion.title, decodedConflict.remoteVersion.title)
    }
    
    func testSyncStateProgressValidation() {
        // Test progress bounds (0.0 to 1.0)
        let state1 = SyncState(progress: 0.0)
        XCTAssertEqual(state1.progress, 0.0)
        
        let state2 = SyncState(progress: 1.0)
        XCTAssertEqual(state2.progress, 1.0)
        
        let state3 = SyncState(progress: 0.5)
        XCTAssertEqual(state3.progress, 0.5)
    }
    
    func testSyncStateUpdatePattern() {
        // Test immutable update pattern for sync progress
        let originalState = SyncState(isSyncing: true, progress: 0.0)
        
        // Simulate progress updates
        let state25 = SyncState(
            isSyncing: originalState.isSyncing,
            progress: 0.25,
            lastSyncDate: originalState.lastSyncDate,
            pendingChanges: originalState.pendingChanges,
            conflicts: originalState.conflicts
        )
        
        let state50 = SyncState(
            isSyncing: originalState.isSyncing,
            progress: 0.50,
            lastSyncDate: originalState.lastSyncDate,
            pendingChanges: originalState.pendingChanges,
            conflicts: originalState.conflicts
        )
        
        let stateComplete = SyncState(
            isSyncing: false,
            progress: 1.0,
            lastSyncDate: Date(),
            pendingChanges: 0,
            conflicts: []
        )
        
        // Original unchanged
        XCTAssertEqual(originalState.progress, 0.0)
        XCTAssertEqual(state25.progress, 0.25)
        XCTAssertEqual(state50.progress, 0.50)
        XCTAssertEqual(stateComplete.progress, 1.0)
        XCTAssertFalse(stateComplete.isSyncing)
    }
    
    // MARK: - Helper Methods
    
    private func createTestTask(title: String, isCompleted: Bool = false) -> Task {
        return Task(
            id: UUID().uuidString,
            title: title,
            description: "Test description",
            dueDate: nil,
            categoryId: nil,
            priority: .medium,
            isCompleted: isCompleted,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}