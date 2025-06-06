import XCTest
@testable import TestApp002Core

final class UserClientTests: XCTestCase {
    
    // MARK: - Red Phase: Test UserClient authentication fails
    
    func testUserClientInitialization() async throws {
        let userClient = UserClient()
        
        // Verify it conforms to Client protocol
        XCTAssertNotNil(userClient)
        
        // Verify initial state is logged out
        var iterator = await userClient.stateStream.makeAsyncIterator()
        let initialState = await iterator.next()
        XCTAssertNotNil(initialState)
        XCTAssertNil(initialState?.userId)
        XCTAssertNil(initialState?.profile)
    }
    
    func testUserLogin() async throws {
        let userClient = UserClient()
        let expectation = XCTestExpectation(description: "User logged in")
        
        SwiftTask<Void, Never> {
            var iterator = await userClient.stateStream.makeAsyncIterator()
            // Skip initial state
            _ = await iterator.next()
            
            // Wait for logged in state
            if let state = await iterator.next() {
                if state.userId != nil && state.profile != nil {
                    expectation.fulfill()
                }
            }
        }
        
        // Give time for observer to start
        try await SwiftTask.sleep(nanoseconds: 10_000_000)
        
        // Test login
        let startTime = CFAbsoluteTimeGetCurrent()
        try await userClient.process(.login(email: "test@example.com", password: "password123"))
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Login should complete within 500ms as per RFC
        XCTAssertLessThan(duration, 0.5, "Login took too long: \(duration)s")
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testUserLogout() async throws {
        let userClient = UserClient()
        
        // First login
        try await userClient.process(.login(email: "test@example.com", password: "password123"))
        
        let expectation = XCTestExpectation(description: "User logged out")
        
        SwiftTask<Void, Never> {
            var iterator = await userClient.stateStream.makeAsyncIterator()
            
            // Skip states until we find logged out state
            while let state = await iterator.next() {
                if state.userId == nil && state.profile == nil {
                    expectation.fulfill()
                    break
                }
            }
        }
        
        // Test logout
        try await userClient.process(.logout)
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Verify state was properly cleaned up
        var iterator = await userClient.stateStream.makeAsyncIterator()
        while let state = await iterator.next() {
            if state.userId == nil {
                XCTAssertNil(state.profile, "Profile should be nil after logout")
                break
            }
        }
    }
    
    func testUpdateUserProfile() async throws {
        let userClient = UserClient()
        
        // First login
        try await userClient.process(.login(email: "test@example.com", password: "password123"))
        
        let newProfile = UserProfile(
            id: "user-123",
            email: "test@example.com",
            displayName: "Updated Name",
            avatarURL: "https://example.com/avatar.jpg"
        )
        
        let expectation = XCTestExpectation(description: "Profile updated")
        
        SwiftTask<Void, Never> {
            var iterator = await userClient.stateStream.makeAsyncIterator()
            
            while let state = await iterator.next() {
                if state.profile?.displayName == "Updated Name" {
                    expectation.fulfill()
                    break
                }
            }
        }
        
        // Update profile
        try await userClient.process(.updateProfile(newProfile))
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
}