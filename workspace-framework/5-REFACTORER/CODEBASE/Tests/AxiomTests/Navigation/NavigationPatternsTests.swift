import XCTest
@testable import Axiom

final class NavigationPatternsTests: XCTestCase {
    
    // MARK: - RED: Navigation Pattern Tests
    
    func testPatternConflictsDetectedAndReported() async throws {
        // Requirement: Framework supports stack, modal, and tab navigation patterns
        // Acceptance: Each pattern maintains independent navigation state with proper hierarchy preservation
        // Boundary: Navigation patterns composable without conflicts
        
        // RED Test: Pattern conflicts should be detected when incompatible patterns are combined
        
        // Test 1: Modal over modal conflict
        let modalPattern = ModalNavigationPattern()
        let currentRoute = Route.settings
        await modalPattern.setCurrentModal(currentRoute)
        
        // Attempting to present another modal should fail
        let conflictingRoute = Route.detail(id: "conflict")
        do {
            try await modalPattern.validateNavigation(to: conflictingRoute, from: currentRoute)
            XCTFail("Modal over modal should produce conflict")
        } catch NavigationPatternError.patternConflict(let message) {
            XCTAssertTrue(message.contains("modal"), "Error should indicate modal conflict")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Test 2: Tab navigation within modal conflict
        let tabPattern = TabNavigationPattern()
        let modalContext = await MainActor.run {
            NavigationPatternContext(pattern: .modal, parent: nil)
        }
        
        do {
            try await tabPattern.validateInContext(modalContext)
            XCTFail("Tab navigation within modal should produce conflict")
        } catch NavigationPatternError.invalidContext(let message) {
            XCTAssertTrue(message.contains("tab"), "Error should indicate tab context issue")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Test 3: Stack navigation cycle detection
        let stackPattern = StackNavigationPattern()
        let routeA = Route.home
        let routeB = Route.detail(id: "B")
        let routeC = Route.custom(path: "C")
        
        try await stackPattern.push(routeA)
        try await stackPattern.push(routeB)
        try await stackPattern.push(routeC)
        
        // Attempting to push routeA again should detect cycle
        do {
            try await stackPattern.push(routeA)
            XCTFail("Circular navigation should be detected")
        } catch NavigationPatternError.circularNavigation(let routes) {
            XCTAssertTrue(routes.contains(where: { $0 == routeA }), "Cycle should include routeA")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testStackPatternMaintainsIndependentState() async throws {
        // Test that stack navigation maintains its own state
        
        let stackPattern = StackNavigationPattern()
        
        // Test push operations
        try await stackPattern.push(Route.home)
        try await stackPattern.push(Route.detail(id: "item-1"))
        try await stackPattern.push(Route.settings)
        
        let currentRoute = await stackPattern.currentRoute
        XCTAssertEqual(currentRoute, Route.settings)
        let state = await stackPattern.currentState
        XCTAssertEqual(state.history.count, 3)
        
        // Test pop operations
        let poppedRoute = try await stackPattern.pop()
        XCTAssertEqual(poppedRoute, Route.settings)
        let currentRoute2 = await stackPattern.currentRoute
        XCTAssertEqual(currentRoute2, Route.detail(id: "item-1"))
        let newState = await stackPattern.currentState
        XCTAssertEqual(newState.history.count, 2)
        
        // Test pop to root
        try await stackPattern.popToRoot()
        let homeRoute = await stackPattern.currentRoute
        XCTAssertEqual(homeRoute, Route.home)
        let rootState = await stackPattern.currentState
        XCTAssertEqual(rootState.history.count, 1)
        
        // Test empty stack pop
        _ = try await stackPattern.pop() // Remove home
        await XCTAssertThrowsAsyncError(try await stackPattern.pop()) { error in
            XCTAssertTrue(error is NavigationPatternError)
        }
    }
    
    func testModalPatternMaintainsIndependentState() async throws {
        // Test that modal navigation maintains its own state
        
        let modalPattern = ModalNavigationPattern()
        
        // Test modal presentation
        let baseRoute = Route.home
        let modalRoute = Route.settings
        
        try await modalPattern.present(modalRoute, over: baseRoute)
        let state = await modalPattern.currentState
        XCTAssertEqual(state.currentRoute, modalRoute)
        XCTAssertTrue(state.metadata.isPresented)
        let isPresented = await modalPattern.isModalPresented
        XCTAssertTrue(isPresented)
        
        // Test modal dismissal
        let dismissedRoute = try await modalPattern.dismiss()
        XCTAssertEqual(dismissedRoute, modalRoute)
        let dismissedState = await modalPattern.currentState
        XCTAssertNil(dismissedState.currentRoute)
        let notPresented = await modalPattern.isModalPresented
        XCTAssertFalse(notPresented)
        
        // Test dismissal when no modal
        await XCTAssertThrowsAsyncError(try await modalPattern.dismiss()) { error in
            XCTAssertTrue(error is NavigationPatternError)
        }
        
        // Test nested modal prevention
        try await modalPattern.present(modalRoute, over: baseRoute)
        await XCTAssertThrowsAsyncError(try await modalPattern.present(Route.detail(id: "nested"), over: modalRoute)) { error in
            guard case NavigationPatternError.patternConflict = error else {
                XCTFail("Expected pattern conflict error")
                return
            }
        }
    }
    
    func testTabPatternMaintainsIndependentState() async throws {
        // Test that tab navigation maintains its own state
        
        let tabPattern = TabNavigationPattern()
        
        // Configure tabs
        let tabs: [(String, Route)] = [
            ("home", Route.home),
            ("search", Route.custom(path: "search")),
            ("profile", Route.custom(path: "profile"))
        ]
        
        try await tabPattern.configureTabs(tabs)
        let state = await tabPattern.currentState
        XCTAssertEqual(state.metadata.tabCount, 3)
        XCTAssertEqual(state.metadata.selectedTab, "home")
        
        // Test tab selection
        try await tabPattern.selectTab("search")
        let searchState = await tabPattern.currentState
        XCTAssertEqual(searchState.metadata.selectedTab, "search")
        let tabRoute = await tabPattern.currentRoute
        XCTAssertEqual(tabRoute, Route.custom(path: "search"))
        
        // Test invalid tab selection
        await XCTAssertThrowsAsyncError(try await tabPattern.selectTab("invalid")) { error in
            guard case NavigationPatternError.tabNotFound = error else {
                XCTFail("Expected tab not found error")
                return
            }
        }
        
        // Test tab-specific navigation stacks
        try await tabPattern.pushInCurrentTab(Route.detail(id: "search-result"))
        let searchStack = await tabPattern.getStackForTab("search")
        XCTAssertEqual(searchStack.count, 2)
        
        // Switch tabs and verify independent stacks
        try await tabPattern.selectTab("home")
        let homeStack = await tabPattern.getStackForTab("home")
        XCTAssertEqual(homeStack.count, 1)
        
        // Return to search tab and verify stack preserved
        try await tabPattern.selectTab("search")
        let preservedStack = await tabPattern.getStackForTab("search")
        XCTAssertEqual(preservedStack.count, 2)
    }
    
    func testNavigationPatternComposition() async throws {
        // Test that patterns can be composed without conflicts
        
        let coordinator = NavigationPatternCoordinator()
        
        // Test 1: Tab root with stack navigation per tab
        try await coordinator.setRootPattern(.tab)
        try await coordinator.configureTabPattern(tabs: [
            ("home", Route.home),
            ("browse", Route.custom(path: "browse")),
            ("settings", Route.settings)
        ])
        
        // Navigate within tab using stack pattern
        try await coordinator.navigate(to: Route.detail(id: "item-1"), pattern: .stack)
        let coordRoute = await coordinator.currentRoute
        XCTAssertEqual(coordRoute, Route.detail(id: "item-1"))
        
        // Switch tabs
        try await coordinator.selectTab("browse")
        let browseRoute = await coordinator.currentRoute
        XCTAssertEqual(browseRoute, Route.custom(path: "browse"))
        
        // Present modal over tab
        try await coordinator.navigate(to: Route.settings, pattern: .modal)
        let modalPresented = await coordinator.isModalPresented
        XCTAssertTrue(modalPresented)
        
        // Test 2: Stack root with modal presentation
        let stackCoordinator = NavigationPatternCoordinator()
        try await stackCoordinator.setRootPattern(.stack)
        
        try await stackCoordinator.navigate(to: Route.home, pattern: .stack)
        try await stackCoordinator.navigate(to: Route.detail(id: "1"), pattern: .stack)
        try await stackCoordinator.navigate(to: Route.settings, pattern: .modal)
        
        let stackModalPresented = await stackCoordinator.isModalPresented
        let presentingRoute = await stackCoordinator.modalPresentingRoute
        XCTAssertTrue(stackModalPresented)
        XCTAssertEqual(presentingRoute, Route.detail(id: "1"))
        
        // Dismiss modal
        try await stackCoordinator.dismissModal()
        let modalDismissed = await stackCoordinator.isModalPresented
        let finalRoute = await stackCoordinator.currentRoute
        XCTAssertFalse(modalDismissed)
        XCTAssertEqual(finalRoute, Route.detail(id: "1"))
    }
    
    @MainActor
    func testHierarchyPreservation() async throws {
        // Test that navigation hierarchy is properly preserved
        
        let hierarchy = NavigationHierarchy()
        
        // Build a complex hierarchy
        let rootContext = NavigationPatternContext(pattern: .tab, parent: nil)
        try hierarchy.setRoot(rootContext)
        
        // Add tab contexts
        let homeTabContext = NavigationPatternContext(pattern: .stack, parent: rootContext)
        try hierarchy.addChild(homeTabContext, to: rootContext)
        
        let browseTabContext = NavigationPatternContext(pattern: .stack, parent: rootContext)
        try hierarchy.addChild(browseTabContext, to: rootContext)
        
        // Add stack items to home tab
        let detailContext = NavigationPatternContext(pattern: .navigation, parent: homeTabContext)
        try hierarchy.addChild(detailContext, to: homeTabContext)
        
        // Add modal over everything
        let modalContext = NavigationPatternContext(pattern: .modal, parent: rootContext)
        try hierarchy.addChild(modalContext, to: rootContext)
        
        // Validate hierarchy
        XCTAssertEqual(hierarchy.depth, 3)
        XCTAssertEqual(hierarchy.activeLeaf?.pattern, .modal)
        
        // Test path to root
        let pathToRoot = hierarchy.pathToRoot(from: detailContext)
        XCTAssertEqual(pathToRoot.count, 3) // detail -> homeTab -> root
        XCTAssertEqual(pathToRoot[0].pattern, .navigation)
        XCTAssertEqual(pathToRoot[1].pattern, .stack)
        XCTAssertEqual(pathToRoot[2].pattern, .tab)
        
        // Test hierarchy validation
        do {
            // Try to add a tab as child of modal (invalid)
            let invalidTab = NavigationPatternContext(pattern: .tab, parent: modalContext)
            try hierarchy.addChild(invalidTab, to: modalContext)
            XCTFail("Tab under modal should be invalid")
        } catch NavigationPatternError.invalidHierarchy {
            // Expected
        }
    }
    
    func testPatternSpecificConstraints() async throws {
        // Test pattern-specific constraints and rules
        
        // Test 1: Stack depth limits
        let stackPattern = StackNavigationPattern(maxDepth: 5)
        
        // Push up to limit
        for i in 1...5 {
            try await stackPattern.push(Route.detail(id: "item-\(i)"))
        }
        
        // Exceeding limit should fail
        await XCTAssertThrowsAsyncError(try await stackPattern.push(Route.settings)) { error in
            guard case NavigationPatternError.depthLimitExceeded = error else {
                XCTFail("Expected depth limit error")
                return
            }
        }
        
        // Test 2: Modal presentation constraints
        let modalPattern = ModalNavigationPattern()
        
        // Can't present modal without base route
        await XCTAssertThrowsAsyncError(try await modalPattern.present(Route.settings, over: nil)) { error in
            guard case NavigationPatternError.missingPresentingRoute = error else {
                XCTFail("Expected missing presenting route error")
                return
            }
        }
        
        // Test 3: Tab constraints
        let tabPattern = TabNavigationPattern()
        
        // Must configure tabs before use
        await XCTAssertThrowsAsyncError(try await tabPattern.selectTab("home")) { error in
            guard case NavigationPatternError.tabNotFound = error else {
                XCTFail("Expected tabs not configured error")
                return
            }
        }
        
        // Minimum tabs requirement
        await XCTAssertThrowsAsyncError(try await tabPattern.configureTabs([("single", Route.home)])) { error in
            guard case NavigationPatternError.insufficientTabs = error else {
                XCTFail("Expected insufficient tabs error")
                return
            }
        }
    }
}

// MARK: - Test Helpers

extension XCTest {
    func XCTAssertThrowsAsyncError<T>(
        _ expression: @autoclosure () async throws -> T,
        _ errorHandler: (Error) -> Void = { _ in },
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await expression()
            XCTFail("Expected error to be thrown", file: file, line: line)
        } catch {
            errorHandler(error)
        }
    }
}