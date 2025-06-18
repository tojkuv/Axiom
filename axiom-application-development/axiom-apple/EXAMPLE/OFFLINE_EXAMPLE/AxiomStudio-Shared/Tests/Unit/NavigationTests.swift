import XCTest
@testable import AxiomStudio_Shared

final class NavigationTests: XCTestCase {
    
    var navigationService: StudioNavigationService!
    
    override func setUp() async throws {
        try await super.setUp()
        navigationService = StudioNavigationService()
    }
    
    override func tearDown() async throws {
        navigationService = nil
        try await super.tearDown()
    }
    
    // MARK: - Basic Navigation Tests
    
    func testInitialState() {
        XCTAssertEqual(navigationService.currentRoute, .personalInfo)
        XCTAssertTrue(navigationService.navigationStack.isEmpty)
        XCTAssertNil(navigationService.deepLinkingContext)
    }
    
    func testBasicNavigation() {
        navigationService.navigate(to: .taskList)
        
        XCTAssertEqual(navigationService.currentRoute, .taskList)
        XCTAssertEqual(navigationService.navigationStack.count, 1)
        XCTAssertEqual(navigationService.navigationStack.first, .personalInfo)
    }
    
    func testNavigationBetweenRootRoutes() {
        navigationService.navigate(to: .healthLocation)
        
        XCTAssertEqual(navigationService.currentRoute, .healthLocation)
        XCTAssertTrue(navigationService.navigationStack.isEmpty)
    }
    
    func testNavigationWithinCategory() {
        navigationService.navigate(to: .taskList)
        navigationService.navigate(to: .taskDetail)
        
        XCTAssertEqual(navigationService.currentRoute, .taskDetail)
        XCTAssertEqual(navigationService.navigationStack.count, 2)
        XCTAssertEqual(navigationService.navigationStack[0], .personalInfo)
        XCTAssertEqual(navigationService.navigationStack[1], .taskList)
    }
    
    func testGoBack() {
        navigationService.navigate(to: .taskList)
        navigationService.navigate(to: .taskDetail)
        
        let canGoBack = navigationService.goBack()
        
        XCTAssertTrue(canGoBack)
        XCTAssertEqual(navigationService.currentRoute, .taskList)
        XCTAssertEqual(navigationService.navigationStack.count, 1)
        XCTAssertEqual(navigationService.navigationStack.first, .personalInfo)
    }
    
    func testGoBackWhenStackEmpty() {
        let canGoBack = navigationService.goBack()
        
        XCTAssertFalse(canGoBack)
        XCTAssertEqual(navigationService.currentRoute, .personalInfo)
        XCTAssertTrue(navigationService.navigationStack.isEmpty)
    }
    
    func testPopToRoot() {
        navigationService.navigate(to: .taskList)
        navigationService.navigate(to: .taskDetail)
        navigationService.navigate(to: .editTask)
        
        navigationService.popToRoot()
        
        XCTAssertEqual(navigationService.currentRoute, .personalInfo)
        XCTAssertTrue(navigationService.navigationStack.isEmpty)
    }
    
    func testReplace() {
        navigationService.navigate(to: .taskList)
        let stackSizeBefore = navigationService.navigationStack.count
        
        navigationService.replace(with: .contactList)
        
        XCTAssertEqual(navigationService.currentRoute, .contactList)
        XCTAssertEqual(navigationService.navigationStack.count, stackSizeBefore)
    }
    
    // MARK: - Deep Linking Tests
    
    func testDeepLinkParsing() {
        let url = URL(string: "axiomstudio://navigate/taskDetail?id=123&mode=edit")!
        
        let success = navigationService.handleDeepLink(url: url)
        
        XCTAssertTrue(success)
        XCTAssertEqual(navigationService.currentRoute, .taskDetail)
        XCTAssertNotNil(navigationService.deepLinkingContext)
        XCTAssertEqual(navigationService.deepLinkingContext?.sourceURL, url)
        XCTAssertEqual(navigationService.deepLinkingContext?.parameters["id"], "123")
        XCTAssertEqual(navigationService.deepLinkingContext?.parameters["mode"], "edit")
    }
    
    func testInvalidDeepLink() {
        let url = URL(string: "axiomstudio://navigate/invalidRoute")!
        
        let success = navigationService.handleDeepLink(url: url)
        
        XCTAssertFalse(success)
        XCTAssertEqual(navigationService.currentRoute, .personalInfo) // Should not change
        XCTAssertNil(navigationService.deepLinkingContext)
    }
    
    func testDeepLinkGeneration() {
        let url = navigationService.generateDeepLink(for: .taskDetail, parameters: ["id": "456", "mode": "view"])
        
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "axiomstudio")
        XCTAssertEqual(url?.host, "navigate")
        XCTAssertEqual(url?.path, "/taskDetail")
        
        let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems
        XCTAssertTrue(queryItems?.contains { $0.name == "id" && $0.value == "456" } ?? false)
        XCTAssertTrue(queryItems?.contains { $0.name == "mode" && $0.value == "view" } ?? false)
    }
    
    func testClearDeepLinkingContext() {
        let url = URL(string: "axiomstudio://navigate/taskDetail")!
        _ = navigationService.handleDeepLink(url: url)
        
        XCTAssertNotNil(navigationService.deepLinkingContext)
        
        navigationService.clearDeepLinkingContext()
        
        XCTAssertNil(navigationService.deepLinkingContext)
    }
    
    // MARK: - Route Validation Tests
    
    func testCanNavigate() {
        XCTAssertTrue(navigationService.canNavigate(to: .taskList))
        XCTAssertTrue(navigationService.canNavigate(to: .healthDashboard))
        XCTAssertTrue(navigationService.canNavigate(to: .settings))
    }
    
    func testValidateRoute() {
        let validResult = navigationService.validateRoute(.taskList)
        let invalidResult = navigationService.validateRoute(.taskList) // All routes are currently valid
        
        switch validResult {
        case .valid:
            XCTAssertTrue(true)
        case .invalid:
            XCTFail("Route should be valid")
        }
    }
    
    // MARK: - Navigation Analytics Tests
    
    func testNavigationHistory() {
        navigationService.navigate(to: .taskList)
        navigationService.navigate(to: .taskDetail)
        navigationService.navigate(to: .contactList)
        
        let history = navigationService.getNavigationHistory()
        
        XCTAssertEqual(history.count, 3)
        XCTAssertEqual(history[0].toRoute, .taskList)
        XCTAssertEqual(history[1].toRoute, .taskDetail)
        XCTAssertEqual(history[2].toRoute, .contactList)
    }
    
    func testRecentTransitions() {
        // Create more transitions than the limit
        for i in 0..<15 {
            let route: StudioRoute = i % 2 == 0 ? .taskList : .contactList
            navigationService.navigate(to: route)
        }
        
        let recent = navigationService.getRecentTransitions(limit: 5)
        
        XCTAssertEqual(recent.count, 5)
    }
    
    func testNavigationAnalytics() {
        navigationService.navigate(to: .taskList)
        navigationService.navigate(to: .taskList)
        navigationService.navigate(to: .contactList)
        navigationService.navigate(to: .taskList)
        
        let analytics = navigationService.getNavigationAnalytics()
        
        XCTAssertEqual(analytics.totalTransitions, 4)
        XCTAssertEqual(analytics.routeCounts[.taskList], 3)
        XCTAssertEqual(analytics.routeCounts[.contactList], 1)
        XCTAssertEqual(analytics.mostVisitedRoute, .taskList)
    }
    
    // MARK: - State Restoration Tests
    
    func testSaveNavigationState() {
        navigationService.navigate(to: .taskList)
        navigationService.navigate(to: .taskDetail)
        
        let state = navigationService.saveNavigationState()
        
        XCTAssertEqual(state.currentRoute, .taskDetail)
        XCTAssertEqual(state.navigationStack.count, 2)
        XCTAssertEqual(state.navigationStack[0], .personalInfo)
        XCTAssertEqual(state.navigationStack[1], .taskList)
    }
    
    func testRestoreNavigationState() {
        let state = NavigationState(
            currentRoute: .contactDetail,
            navigationStack: [.personalInfo, .contactList],
            deepLinkingContext: nil
        )
        
        navigationService.restoreNavigationState(state)
        
        XCTAssertEqual(navigationService.currentRoute, .contactDetail)
        XCTAssertEqual(navigationService.navigationStack.count, 2)
        XCTAssertEqual(navigationService.navigationStack[0], .personalInfo)
        XCTAssertEqual(navigationService.navigationStack[1], .contactList)
    }
    
    // MARK: - Route Category Tests
    
    func testRouteCategorization() {
        XCTAssertEqual(StudioRoute.taskList.category, .personalInfo)
        XCTAssertEqual(StudioRoute.healthDashboard.category, .healthLocation)
        XCTAssertEqual(StudioRoute.mlModels.category, .contentProcessor)
        XCTAssertEqual(StudioRoute.documentBrowser.category, .mediaHub)
        XCTAssertEqual(StudioRoute.memoryMonitor.category, .performance)
    }
    
    func testRootRouteIdentification() {
        XCTAssertTrue(StudioRoute.personalInfo.isRootRoute)
        XCTAssertTrue(StudioRoute.healthLocation.isRootRoute)
        XCTAssertTrue(StudioRoute.contentProcessor.isRootRoute)
        XCTAssertTrue(StudioRoute.mediaHub.isRootRoute)
        XCTAssertTrue(StudioRoute.performance.isRootRoute)
        XCTAssertTrue(StudioRoute.settings.isRootRoute)
        
        XCTAssertFalse(StudioRoute.taskList.isRootRoute)
        XCTAssertFalse(StudioRoute.taskDetail.isRootRoute)
        XCTAssertFalse(StudioRoute.healthDashboard.isRootRoute)
    }
    
    func testCategoryRootRoutes() {
        XCTAssertEqual(RouteCategory.personalInfo.rootRoute, .personalInfo)
        XCTAssertEqual(RouteCategory.healthLocation.rootRoute, .healthLocation)
        XCTAssertEqual(RouteCategory.contentProcessor.rootRoute, .contentProcessor)
        XCTAssertEqual(RouteCategory.mediaHub.rootRoute, .mediaHub)
        XCTAssertEqual(RouteCategory.performance.rootRoute, .performance)
        XCTAssertEqual(RouteCategory.settings.rootRoute, .settings)
    }
    
    // MARK: - Performance Tests
    
    func testNavigationPerformance() {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Perform many navigation operations
        for i in 0..<1000 {
            let route: StudioRoute = i % 2 == 0 ? .taskList : .contactList
            navigationService.navigate(to: route)
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // Navigation should be fast (less than 1 second for 1000 operations)
        XCTAssertLessThan(duration, 1.0)
    }
    
    func testMemoryUsage() {
        // Create many navigation transitions
        for i in 0..<1000 {
            let route: StudioRoute = i % 6 == 0 ? .personalInfo :
                                   i % 6 == 1 ? .healthLocation :
                                   i % 6 == 2 ? .contentProcessor :
                                   i % 6 == 3 ? .mediaHub :
                                   i % 6 == 4 ? .performance : .settings
            navigationService.navigate(to: route)
        }
        
        let history = navigationService.getNavigationHistory()
        
        // History should be limited to prevent memory growth
        XCTAssertLessThanOrEqual(history.count, 100)
    }
}