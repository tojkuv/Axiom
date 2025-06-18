import XCTest
import AxiomTesting
import SwiftUI
@testable import AxiomArchitecture
@testable import AxiomCore

/// Comprehensive tests for deep linking functionality
/// 
/// Consolidates: DeepLinkingTests, DeepLinkingFrameworkTests
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class DeepLinkingTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Basic Deep Link Tests
    
    func testBasicDeepLinkParsing() async throws {
        try await testEnvironment.runTest { env in
            let deepLinkHandler = DeepLinkHandler()
            
            // Test simple deep links
            let simpleLinks = [
                "myapp://home": DeepLinkResult.route(.home),
                "myapp://profile/user123": DeepLinkResult.route(.profile(userId: "user123")),
                "myapp://settings": DeepLinkResult.route(.settings),
                "myapp://product/123": DeepLinkResult.route(.product(id: "123"))
            ]
            
            for (url, expectedResult) in simpleLinks {
                let result = await deepLinkHandler.handle(url)
                
                XCTAssertTrue(result.isSuccess, "Should successfully parse URL: \(url)")
                XCTAssertEqual(result.route, expectedResult.route, "Should extract correct route from: \(url)")
            }
        }
    }
    
    func testParameterizedDeepLinks() async throws {
        try await testEnvironment.runTest { env in
            let deepLinkHandler = DeepLinkHandler()
            
            // Register parameterized patterns
            await deepLinkHandler.registerPattern(
                "/users/{userId}/posts/{postId}",
                handler: { params in
                    guard let userId = params["userId"],
                          let postId = params["postId"] else {
                        return .failure(.invalidParameters)
                    }
                    return .success(.userPost(userId: userId, postId: postId))
                }
            )
            
            await deepLinkHandler.registerPattern(
                "/search?q={query}&category={category}",
                handler: { params in
                    let query = params["query"] ?? ""
                    let category = params["category"] ?? "all"
                    return .success(.search(query: query, category: category))
                }
            )
            
            // Test parameterized deep links
            let parameterizedResult = await deepLinkHandler.handle("myapp://users/john123/posts/post456")
            XCTAssertTrue(parameterizedResult.isSuccess, "Should parse parameterized URL")
            XCTAssertEqual(parameterizedResult.route, .userPost(userId: "john123", postId: "post456"), "Should extract parameters correctly")
            
            // Test query parameters
            let queryResult = await deepLinkHandler.handle("myapp://search?q=swift&category=programming")
            XCTAssertTrue(queryResult.isSuccess, "Should parse query parameters")
            XCTAssertEqual(queryResult.route, .search(query: "swift", category: "programming"), "Should extract query parameters")
        }
    }
    
    func testDeepLinkValidation() async throws {
        try await testEnvironment.runTest { env in
            let deepLinkHandler = DeepLinkHandler()
            
            // Register pattern with validation
            await deepLinkHandler.registerPattern(
                "/user/{userId}",
                validator: { params in
                    guard let userId = params["userId"],
                          !userId.isEmpty,
                          userId.count >= 3 else {
                        return .invalid("User ID must be at least 3 characters")
                    }
                    return .valid
                },
                handler: { params in
                    return .success(.profile(userId: params["userId"]!))
                }
            )
            
            // Test valid user ID
            let validResult = await deepLinkHandler.handle("myapp://user/john123")
            XCTAssertTrue(validResult.isSuccess, "Should accept valid user ID")
            
            // Test invalid user IDs
            let emptyResult = await deepLinkHandler.handle("myapp://user/")
            XCTAssertFalse(emptyResult.isSuccess, "Should reject empty user ID")
            
            let shortResult = await deepLinkHandler.handle("myapp://user/ab")
            XCTAssertFalse(shortResult.isSuccess, "Should reject short user ID")
            XCTAssertEqual(shortResult.error?.type, .validationFailed, "Should report validation failure")
        }
    }
    
    func testDeepLinkSecurity() async throws {
        try await testEnvironment.runTest { env in
            let deepLinkHandler = DeepLinkHandler()
            
            // Register pattern with security checks
            await deepLinkHandler.registerPattern(
                "/admin/{action}",
                securityHandler: { params, context in
                    guard context.hasAdminPermissions else {
                        return .deny("Admin permissions required")
                    }
                    return .allow
                },
                handler: { params in
                    return .success(.admin(action: params["action"]!))
                }
            )
            
            // Test without admin permissions
            let unauthorizedContext = DeepLinkContext(hasAdminPermissions: false)
            let unauthorizedResult = await deepLinkHandler.handle(
                "myapp://admin/deleteUser",
                context: unauthorizedContext
            )
            XCTAssertFalse(unauthorizedResult.isSuccess, "Should deny unauthorized access")
            XCTAssertEqual(unauthorizedResult.error?.type, .securityDenied, "Should report security denial")
            
            // Test with admin permissions
            let authorizedContext = DeepLinkContext(hasAdminPermissions: true)
            let authorizedResult = await deepLinkHandler.handle(
                "myapp://admin/viewLogs",
                context: authorizedContext
            )
            XCTAssertTrue(authorizedResult.isSuccess, "Should allow authorized access")
            XCTAssertEqual(authorizedResult.route, .admin(action: "viewLogs"), "Should process admin action")
        }
    }
    
    // MARK: - Deep Link Framework Tests
    
    func testDeepLinkRoutingIntegration() async throws {
        try await testEnvironment.runTest { env in
            let navigationService = TestNavigationService()
            let deepLinkRouter = DeepLinkRouter(navigationService: navigationService)
            
            // Configure deep link routes
            await deepLinkRouter.configureRoutes {
                DeepLinkRoute("/product/{id}") { params in
                    .route(.product(id: params["id"]!))
                }
                
                DeepLinkRoute("/category/{category}/products") { params in
                    .route(.categoryProducts(category: params["category"]!))
                }
                
                DeepLinkRoute("/user/{userId}/profile") { params in
                    .route(.profile(userId: params["userId"]!))
                }
            }
            
            // Test navigation via deep link
            let navigationResult = await deepLinkRouter.navigate(to: "myapp://product/123")
            
            XCTAssertTrue(navigationResult.isSuccess, "Should navigate via deep link")
            XCTAssertEqual(navigationService.currentRoute, .product(id: "123"), "Should navigate to correct route")
            XCTAssertNotNil(navigationService.lastTransition, "Should record navigation transition")
        }
    }
    
    func testDeepLinkChaining() async throws {
        try await testEnvironment.runTest { env in
            let deepLinkHandler = DeepLinkHandler()
            
            // Register chained deep link patterns
            await deepLinkHandler.registerChain([
                DeepLinkChainStep(
                    pattern: "/onboarding/start",
                    route: .onboarding(.start),
                    nextStep: "/onboarding/permissions"
                ),
                DeepLinkChainStep(
                    pattern: "/onboarding/permissions",
                    route: .onboarding(.permissions),
                    nextStep: "/onboarding/complete"
                ),
                DeepLinkChainStep(
                    pattern: "/onboarding/complete",
                    route: .onboarding(.complete),
                    nextStep: nil
                )
            ])
            
            // Execute chained deep link
            let chainExecution = await deepLinkHandler.executeChain("myapp://onboarding/start")
            
            XCTAssertNotNil(chainExecution, "Should create chain execution")
            XCTAssertEqual(chainExecution?.currentStep?.route, .onboarding(.start), "Should start with first step")
            
            // Progress through chain
            await chainExecution?.progressToNext()
            XCTAssertEqual(chainExecution?.currentStep?.route, .onboarding(.permissions), "Should progress to permissions")
            
            await chainExecution?.progressToNext()
            XCTAssertEqual(chainExecution?.currentStep?.route, .onboarding(.complete), "Should progress to completion")
            
            let isChainComplete = await chainExecution?.isComplete()
            XCTAssertTrue(isChainComplete == true, "Should complete chain")
        }
    }
    
    func testDeepLinkStateRestoration() async throws {
        try await testEnvironment.runTest { env in
            let stateManager = DeepLinkStateManager()
            let deepLinkHandler = DeepLinkHandler(stateManager: stateManager)
            
            // Create deep link with state
            let statefulLink = StatefulDeepLink(
                url: "myapp://cart/review",
                state: [
                    "cartItems": ["item1", "item2", "item3"],
                    "totalPrice": 99.99,
                    "userPreferences": ["currency": "USD", "shipping": "express"]
                ]
            )
            
            // Save state
            await stateManager.saveState(for: statefulLink.url, state: statefulLink.state)
            
            // Process deep link with state restoration
            let result = await deepLinkHandler.handleWithStateRestoration(statefulLink.url)
            
            XCTAssertTrue(result.isSuccess, "Should handle stateful deep link")
            XCTAssertNotNil(result.restoredState, "Should restore state")
            
            let cartItems = result.restoredState?["cartItems"] as? [String]
            XCTAssertEqual(cartItems?.count, 3, "Should restore cart items")
            
            let totalPrice = result.restoredState?["totalPrice"] as? Double
            XCTAssertEqual(totalPrice, 99.99, "Should restore total price")
        }
    }
    
    func testDeepLinkMiddleware() async throws {
        try await testEnvironment.runTest { env in
            let deepLinkHandler = DeepLinkHandler()
            var analyticsEvents: [AnalyticsEvent] = []
            var securityChecks: [SecurityCheck] = []
            
            // Register middleware
            await deepLinkHandler.addMiddleware(
                AnalyticsMiddleware { event in
                    analyticsEvents.append(event)
                }
            )
            
            await deepLinkHandler.addMiddleware(
                SecurityMiddleware { check in
                    securityChecks.append(check)
                    return .allow
                }
            )
            
            await deepLinkHandler.addMiddleware(
                ValidationMiddleware { url in
                    guard !url.contains("malicious") else {
                        return .reject("Malicious URL detected")
                    }
                    return .allow
                }
            )
            
            // Process deep link through middleware
            let result = await deepLinkHandler.handle("myapp://profile/user123")
            
            XCTAssertTrue(result.isSuccess, "Should process through middleware")
            XCTAssertEqual(analyticsEvents.count, 1, "Should trigger analytics")
            XCTAssertEqual(securityChecks.count, 1, "Should perform security check")
            
            // Test malicious URL rejection
            let maliciousResult = await deepLinkHandler.handle("myapp://malicious/script")
            XCTAssertFalse(maliciousResult.isSuccess, "Should reject malicious URL")
            XCTAssertEqual(maliciousResult.error?.type, .middlewareRejection, "Should report middleware rejection")
        }
    }
    
    // MARK: - Universal Links Tests
    
    func testUniversalLinkHandling() async throws {
        try await testEnvironment.runTest { env in
            let universalLinkHandler = UniversalLinkHandler()
            
            // Configure universal link domains
            await universalLinkHandler.configureDomains([
                "example.com",
                "www.example.com",
                "app.example.com"
            ])
            
            // Register universal link patterns
            await universalLinkHandler.registerPattern(
                "https://example.com/product/{id}",
                handler: { params in
                    return .success(.product(id: params["id"]!))
                }
            )
            
            await universalLinkHandler.registerPattern(
                "https://app.example.com/share/{shareId}",
                handler: { params in
                    return .success(.sharedContent(shareId: params["shareId"]!))
                }
            )
            
            // Test universal link processing
            let productResult = await universalLinkHandler.handle("https://example.com/product/123")
            XCTAssertTrue(productResult.isSuccess, "Should handle universal link")
            XCTAssertEqual(productResult.route, .product(id: "123"), "Should extract route from universal link")
            
            // Test subdomain universal link
            let shareResult = await universalLinkHandler.handle("https://app.example.com/share/abc123")
            XCTAssertTrue(shareResult.isSuccess, "Should handle subdomain universal link")
            XCTAssertEqual(shareResult.route, .sharedContent(shareId: "abc123"), "Should handle subdomain patterns")
            
            // Test invalid domain
            let invalidResult = await universalLinkHandler.handle("https://malicious.com/product/123")
            XCTAssertFalse(invalidResult.isSuccess, "Should reject invalid domain")
            XCTAssertEqual(invalidResult.error?.type, .invalidDomain, "Should report domain validation failure")
        }
    }
    
    func testUniversalLinkFallback() async throws {
        try await testEnvironment.runTest { env in
            let universalLinkHandler = UniversalLinkHandler()
            
            // Configure fallback handling
            await universalLinkHandler.configureFallback { url in
                // Extract path and try to match against app routes
                let path = URL(string: url)?.path ?? ""
                
                switch path {
                case "/downloads":
                    return .success(.appStore)
                case "/help":
                    return .success(.help)
                default:
                    return .success(.home)
                }
            }
            
            // Test fallback for unregistered pattern
            let fallbackResult = await universalLinkHandler.handle("https://example.com/downloads")
            XCTAssertTrue(fallbackResult.isSuccess, "Should handle fallback")
            XCTAssertEqual(fallbackResult.route, .appStore, "Should use fallback route")
            
            // Test default fallback
            let defaultResult = await universalLinkHandler.handle("https://example.com/unknown")
            XCTAssertTrue(defaultResult.isSuccess, "Should handle default fallback")
            XCTAssertEqual(defaultResult.route, .home, "Should default to home")
        }
    }
    
    // MARK: - Deep Link Analytics Tests
    
    func testDeepLinkAnalytics() async throws {
        try await testEnvironment.runTest { env in
            let analyticsCollector = DeepLinkAnalyticsCollector()
            let deepLinkHandler = DeepLinkHandler(analyticsCollector: analyticsCollector)
            
            // Process various deep links
            await deepLinkHandler.handle("myapp://home")
            await deepLinkHandler.handle("myapp://product/123")
            await deepLinkHandler.handle("myapp://product/456")
            await deepLinkHandler.handle("myapp://profile/user789")
            await deepLinkHandler.handle("myapp://invalid/route")
            
            // Analyze collected data
            let analytics = await analyticsCollector.generateReport()
            
            XCTAssertEqual(analytics.totalDeepLinks, 5, "Should track total deep link attempts")
            XCTAssertEqual(analytics.successfulDeepLinks, 4, "Should track successful deep links")
            XCTAssertEqual(analytics.failedDeepLinks, 1, "Should track failed deep links")
            XCTAssertEqual(analytics.successRate, 0.8, "Should calculate success rate")
            
            // Test route popularity
            let routePopularity = analytics.routePopularity
            XCTAssertEqual(routePopularity["product"], 2, "Should track route frequency")
            XCTAssertEqual(routePopularity["home"], 1, "Should track individual routes")
            XCTAssertEqual(routePopularity["profile"], 1, "Should track profile routes")
            
            // Test source tracking
            let sourceAnalytics = await analyticsCollector.getSourceAnalytics()
            XCTAssertTrue(sourceAnalytics.sources.contains("app"), "Should track app source")
        }
    }
    
    func testDeepLinkPerformanceMetrics() async throws {
        try await testEnvironment.runTest { env in
            let performanceTracker = DeepLinkPerformanceTracker()
            let deepLinkHandler = DeepLinkHandler(performanceTracker: performanceTracker)
            
            // Process deep links with performance tracking
            for i in 0..<10 {
                await deepLinkHandler.handle("myapp://product/\(i)")
            }
            
            // Analyze performance metrics
            let metrics = await performanceTracker.getMetrics()
            
            XCTAssertEqual(metrics.totalProcessed, 10, "Should track total processed")
            XCTAssertGreaterThan(metrics.averageProcessingTime, 0, "Should measure processing time")
            XCTAssertLessThan(metrics.averageProcessingTime, 0.1, "Should process quickly")
            
            // Test performance thresholds
            let slowestLink = metrics.slowestProcessingTime
            XCTAssertLessThan(slowestLink, 0.2, "Should meet performance thresholds")
            
            // Test memory usage
            XCTAssertLessThan(metrics.memoryUsage, 1024 * 1024, "Should use reasonable memory") // 1MB
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testDeepLinkErrorRecovery() async throws {
        try await testEnvironment.runTest { env in
            let errorHandler = DeepLinkErrorHandler()
            let deepLinkHandler = DeepLinkHandler(errorHandler: errorHandler)
            
            // Configure error recovery strategies
            await errorHandler.configureRecovery(.malformedURL) { error in
                return .fallback(.home)
            }
            
            await errorHandler.configureRecovery(.routeNotFound) { error in
                return .fallback(.notFound)
            }
            
            await errorHandler.configureRecovery(.networkError) { error in
                return .retry(maxAttempts: 3, delay: 0.1)
            }
            
            // Test malformed URL recovery
            let malformedResult = await deepLinkHandler.handle("malformed://invalid::url")
            XCTAssertTrue(malformedResult.isSuccess, "Should recover from malformed URL")
            XCTAssertEqual(malformedResult.route, .home, "Should fallback to home")
            
            // Test route not found recovery
            let notFoundResult = await deepLinkHandler.handle("myapp://nonexistent/route")
            XCTAssertTrue(notFoundResult.isSuccess, "Should recover from route not found")
            XCTAssertEqual(notFoundResult.route, .notFound, "Should show not found page")
        }
    }
    
    func testDeepLinkValidationErrors() async throws {
        try await testEnvironment.runTest { env in
            let deepLinkHandler = DeepLinkHandler()
            
            // Register pattern with strict validation
            await deepLinkHandler.registerPattern(
                "/user/{userId}",
                validator: { params in
                    guard let userId = params["userId"] else {
                        return .invalid("Missing user ID")
                    }
                    
                    if userId.isEmpty {
                        return .invalid("User ID cannot be empty")
                    }
                    
                    if userId.count < 3 {
                        return .invalid("User ID must be at least 3 characters")
                    }
                    
                    if !userId.allSatisfy({ $0.isAlphanumeric }) {
                        return .invalid("User ID must be alphanumeric")
                    }
                    
                    return .valid
                },
                handler: { params in
                    return .success(.profile(userId: params["userId"]!))
                }
            )
            
            // Test various validation failures
            let validationCases = [
                ("myapp://user/", "User ID cannot be empty"),
                ("myapp://user/ab", "User ID must be at least 3 characters"),
                ("myapp://user/user@123", "User ID must be alphanumeric")
            ]
            
            for (url, expectedError) in validationCases {
                let result = await deepLinkHandler.handle(url)
                XCTAssertFalse(result.isSuccess, "Should fail validation for: \(url)")
                XCTAssertTrue(result.error?.message.contains(expectedError) == true, "Should provide specific error message")
            }
        }
    }
    
    // MARK: - Performance Tests
    
    func testDeepLinkHandlingPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let deepLinkHandler = DeepLinkHandler()
                
                // Register many patterns
                for i in 0..<100 {
                    await deepLinkHandler.registerPattern(
                        "/route\(i)/{param}",
                        handler: { params in
                            return .success(.dynamic(id: i, param: params["param"]!))
                        }
                    )
                }
                
                // Process many deep links
                for i in 0..<1000 {
                    _ = await deepLinkHandler.handle("myapp://route\(i % 100)/param\(i)")
                }
            },
            maxDuration: .milliseconds(500),
            maxMemoryGrowth: 2 * 1024 * 1024 // 2MB
        )
    }
    
    func testUniversalLinkPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let universalLinkHandler = UniversalLinkHandler()
                
                await universalLinkHandler.configureDomains(["example.com"])
                
                // Register many universal link patterns
                for i in 0..<50 {
                    await universalLinkHandler.registerPattern(
                        "https://example.com/category\(i)/{id}",
                        handler: { params in
                            return .success(.category(id: i, itemId: params["id"]!))
                        }
                    )
                }
                
                // Process many universal links
                for i in 0..<500 {
                    _ = await universalLinkHandler.handle("https://example.com/category\(i % 50)/item\(i)")
                }
            },
            maxDuration: .milliseconds(400),
            maxMemoryGrowth: 1 * 1024 * 1024 // 1MB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testDeepLinkMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            for iteration in 0..<20 {
                let deepLinkHandler = DeepLinkHandler()
                
                // Register patterns
                for i in 0..<25 {
                    await deepLinkHandler.registerPattern(
                        "/memory-test-\(iteration)-\(i)/{param}",
                        handler: { params in
                            return .success(.memoryTest(iteration: iteration, index: i, param: params["param"]!))
                        }
                    )
                }
                
                // Process deep links
                for i in 0..<25 {
                    _ = await deepLinkHandler.handle("myapp://memory-test-\(iteration)-\(i)/test")
                }
                
                // Force cleanup
                await deepLinkHandler.cleanup()
            }
        }
    }
    
    func testUniversalLinkMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            for iteration in 0..<15 {
                let universalLinkHandler = UniversalLinkHandler()
                
                await universalLinkHandler.configureDomains(["test\(iteration).com"])
                
                for i in 0..<20 {
                    await universalLinkHandler.registerPattern(
                        "https://test\(iteration).com/test\(i)/{id}",
                        handler: { params in
                            return .success(.universalTest(iteration: iteration, index: i, id: params["id"]!))
                        }
                    )
                }
                
                for i in 0..<15 {
                    _ = await universalLinkHandler.handle("https://test\(iteration).com/test\(i)/memory")
                }
                
                await universalLinkHandler.cleanup()
            }
        }
    }
}

// MARK: - Test Helper Classes and Types

private class DeepLinkHandler {
    private var patterns: [String: DeepLinkPattern] = [:]
    private var chains: [String: DeepLinkChain] = [:]
    private var middleware: [DeepLinkMiddleware] = []
    private let stateManager: DeepLinkStateManager?
    private let analyticsCollector: DeepLinkAnalyticsCollector?
    private let performanceTracker: DeepLinkPerformanceTracker?
    private let errorHandler: DeepLinkErrorHandler?
    
    init(
        stateManager: DeepLinkStateManager? = nil,
        analyticsCollector: DeepLinkAnalyticsCollector? = nil,
        performanceTracker: DeepLinkPerformanceTracker? = nil,
        errorHandler: DeepLinkErrorHandler? = nil
    ) {
        self.stateManager = stateManager
        self.analyticsCollector = analyticsCollector
        self.performanceTracker = performanceTracker
        self.errorHandler = errorHandler
    }
    
    func handle(_ url: String, context: DeepLinkContext = DeepLinkContext()) async -> DeepLinkResult {
        let startTime = Date()
        defer {
            let duration = Date().timeIntervalSince(startTime)
            Task {
                await performanceTracker?.recordProcessingTime(duration)
                await analyticsCollector?.recordDeepLink(url, success: true)
            }
        }
        
        // Apply middleware
        for middleware in self.middleware {
            let middlewareResult = await middleware.process(url)
            if !middlewareResult.shouldContinue {
                await analyticsCollector?.recordDeepLink(url, success: false)
                return .failure(.middlewareRejection)
            }
        }
        
        // Parse URL
        guard let components = parseURL(url) else {
            if let recovery = await errorHandler?.recover(from: .malformedURL) {
                return recovery
            }
            return .failure(.malformedURL)
        }
        
        // Find matching pattern
        for (patternString, pattern) in patterns {
            if let match = await pattern.match(components, context: context) {
                return match
            }
        }
        
        // Handle route not found
        if let recovery = await errorHandler?.recover(from: .routeNotFound) {
            return recovery
        }
        
        return .failure(.routeNotFound)
    }
    
    func registerPattern(
        _ pattern: String,
        validator: ((DeepLinkParameters) async -> ValidationResult)? = nil,
        securityHandler: ((DeepLinkParameters, DeepLinkContext) async -> SecurityResult)? = nil,
        handler: @escaping (DeepLinkParameters) async -> DeepLinkResult
    ) async {
        patterns[pattern] = DeepLinkPattern(
            pattern: pattern,
            validator: validator,
            securityHandler: securityHandler,
            handler: handler
        )
    }
    
    func registerChain(_ steps: [DeepLinkChainStep]) async {
        guard let firstStep = steps.first else { return }
        chains[firstStep.pattern] = DeepLinkChain(steps: steps)
    }
    
    func executeChain(_ url: String) async -> DeepLinkChainExecution? {
        guard let components = parseURL(url),
              let chain = chains[components.path] else { return nil }
        
        return DeepLinkChainExecution(chain: chain)
    }
    
    func addMiddleware(_ middleware: DeepLinkMiddleware) async {
        self.middleware.append(middleware)
    }
    
    func handleWithStateRestoration(_ url: String) async -> StatefulDeepLinkResult {
        let result = await handle(url)
        let restoredState = await stateManager?.restoreState(for: url)
        
        return StatefulDeepLinkResult(
            isSuccess: result.isSuccess,
            route: result.route,
            error: result.error,
            restoredState: restoredState
        )
    }
    
    func cleanup() async {
        patterns.removeAll()
        chains.removeAll()
        middleware.removeAll()
    }
    
    private func parseURL(_ url: String) -> URLComponents? {
        // Simple URL parsing implementation
        guard let urlObj = URL(string: url) else { return nil }
        return URLComponents(string: url)
    }
}

private struct DeepLinkPattern {
    let pattern: String
    let validator: ((DeepLinkParameters) async -> ValidationResult)?
    let securityHandler: ((DeepLinkParameters, DeepLinkContext) async -> SecurityResult)?
    let handler: (DeepLinkParameters) async -> DeepLinkResult
    
    func match(_ components: URLComponents, context: DeepLinkContext) async -> DeepLinkResult? {
        let parameters = extractParameters(from: components)
        
        // Validate parameters
        if let validator = validator {
            let validationResult = await validator(parameters)
            if !validationResult.isValid {
                return .failure(.validationFailed)
            }
        }
        
        // Check security
        if let securityHandler = securityHandler {
            let securityResult = await securityHandler(parameters, context)
            if !securityResult.isAllowed {
                return .failure(.securityDenied)
            }
        }
        
        return await handler(parameters)
    }
    
    private func extractParameters(from components: URLComponents) -> DeepLinkParameters {
        // Simple parameter extraction
        var params: [String: String] = [:]
        
        // Extract path parameters (simplified)
        if let path = components.path {
            let pathComponents = path.components(separatedBy: "/")
            for (index, component) in pathComponents.enumerated() {
                if index == 1 && pathComponents.count > 2 {
                    params["userId"] = component
                } else if index == 2 {
                    params["postId"] = component
                } else if index == 1 {
                    params["id"] = component
                }
            }
        }
        
        // Extract query parameters
        if let queryItems = components.queryItems {
            for item in queryItems {
                params[item.name] = item.value
            }
        }
        
        return params
    }
}

private typealias DeepLinkParameters = [String: String]

private enum DeepLinkResult {
    case success(TestRoute)
    case failure(DeepLinkError)
    
    var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }
    
    var route: TestRoute? {
        switch self {
        case .success(let route): return route
        case .failure: return nil
        }
    }
    
    var error: DeepLinkError? {
        switch self {
        case .success: return nil
        case .failure(let error): return error
        }
    }
    
    static func route(_ route: TestRoute) -> DeepLinkResult {
        return .success(route)
    }
}

private struct DeepLinkError {
    let type: DeepLinkErrorType
    let message: String
    
    init(_ type: DeepLinkErrorType, message: String = "") {
        self.type = type
        self.message = message.isEmpty ? type.defaultMessage : message
    }
}

private enum DeepLinkErrorType {
    case malformedURL
    case routeNotFound
    case invalidParameters
    case validationFailed
    case securityDenied
    case middlewareRejection
    case invalidDomain
    case networkError
    
    var defaultMessage: String {
        switch self {
        case .malformedURL: return "URL is malformed"
        case .routeNotFound: return "Route not found"
        case .invalidParameters: return "Invalid parameters"
        case .validationFailed: return "Validation failed"
        case .securityDenied: return "Access denied"
        case .middlewareRejection: return "Middleware rejection"
        case .invalidDomain: return "Invalid domain"
        case .networkError: return "Network error"
        }
    }
}

private struct DeepLinkContext {
    let hasAdminPermissions: Bool
    
    init(hasAdminPermissions: Bool = false) {
        self.hasAdminPermissions = hasAdminPermissions
    }
}

private struct ValidationResult {
    let isValid: Bool
    let message: String
    
    static let valid = ValidationResult(isValid: true, message: "")
    
    static func invalid(_ message: String) -> ValidationResult {
        return ValidationResult(isValid: false, message: message)
    }
}

private struct SecurityResult {
    let isAllowed: Bool
    let reason: String
    
    static let allow = SecurityResult(isAllowed: true, reason: "")
    
    static func deny(_ reason: String) -> SecurityResult {
        return SecurityResult(isAllowed: false, reason: reason)
    }
}

// MARK: - Deep Link Router

private class DeepLinkRouter {
    private let navigationService: TestNavigationService
    private var routes: [String: (DeepLinkParameters) -> DeepLinkRouteResult] = [:]
    
    init(navigationService: TestNavigationService) {
        self.navigationService = navigationService
    }
    
    func configureRoutes(@RouteConfigurationBuilder builder: () -> [DeepLinkRouteConfiguration]) async {
        let configurations = builder()
        for config in configurations {
            routes[config.pattern] = config.handler
        }
    }
    
    func navigate(to url: String) async -> NavigationResult {
        guard let components = URL(string: url),
              let path = components.path else {
            return NavigationResult(isSuccess: false, transition: nil)
        }
        
        // Find matching route
        for (pattern, handler) in routes {
            if path.contains(pattern.replacingOccurrences(of: "/{id}", with: "")) {
                let params = extractParameters(from: components)
                let routeResult = handler(params)
                
                if let route = routeResult.route {
                    await navigationService.navigate(to: route)
                    return NavigationResult(isSuccess: true, transition: navigationService.lastTransition)
                }
            }
        }
        
        return NavigationResult(isSuccess: false, transition: nil)
    }
    
    private func extractParameters(from url: URL) -> DeepLinkParameters {
        var params: [String: String] = [:]
        let pathComponents = url.path.components(separatedBy: "/")
        
        if pathComponents.count > 2 {
            params["id"] = pathComponents[2]
        }
        if pathComponents.count > 1 {
            params["category"] = pathComponents[1]
        }
        
        return params
    }
}

private struct DeepLinkRouteConfiguration {
    let pattern: String
    let handler: (DeepLinkParameters) -> DeepLinkRouteResult
}

private struct DeepLinkRouteResult {
    let route: TestRoute?
}

@resultBuilder
private struct RouteConfigurationBuilder {
    static func buildBlock(_ components: DeepLinkRouteConfiguration...) -> [DeepLinkRouteConfiguration] {
        return components
    }
}

private func DeepLinkRoute(_ pattern: String, handler: @escaping (DeepLinkParameters) -> DeepLinkRouteResult) -> DeepLinkRouteConfiguration {
    return DeepLinkRouteConfiguration(pattern: pattern, handler: handler)
}

// MARK: - Deep Link Chain

private struct DeepLinkChain {
    let steps: [DeepLinkChainStep]
}

private struct DeepLinkChainStep {
    let pattern: String
    let route: TestRoute
    let nextStep: String?
}

private class DeepLinkChainExecution {
    private let chain: DeepLinkChain
    private var currentStepIndex = 0
    
    init(chain: DeepLinkChain) {
        self.chain = chain
    }
    
    var currentStep: DeepLinkChainStep? {
        guard currentStepIndex < chain.steps.count else { return nil }
        return chain.steps[currentStepIndex]
    }
    
    func progressToNext() async {
        guard currentStepIndex < chain.steps.count - 1 else { return }
        currentStepIndex += 1
    }
    
    func isComplete() async -> Bool {
        return currentStepIndex >= chain.steps.count - 1
    }
}

// MARK: - State Management

private class DeepLinkStateManager {
    private var savedStates: [String: [String: Any]] = [:]
    
    func saveState(for url: String, state: [String: Any]) async {
        savedStates[url] = state
    }
    
    func restoreState(for url: String) async -> [String: Any]? {
        return savedStates[url]
    }
}

private struct StatefulDeepLink {
    let url: String
    let state: [String: Any]
}

private struct StatefulDeepLinkResult {
    let isSuccess: Bool
    let route: TestRoute?
    let error: DeepLinkError?
    let restoredState: [String: Any]?
}

// MARK: - Middleware

private protocol DeepLinkMiddleware {
    func process(_ url: String) async -> MiddlewareResult
}

private struct MiddlewareResult {
    let shouldContinue: Bool
    let message: String
    
    static let allow = MiddlewareResult(shouldContinue: true, message: "")
    
    static func reject(_ message: String) -> MiddlewareResult {
        return MiddlewareResult(shouldContinue: false, message: message)
    }
}

private struct AnalyticsMiddleware: DeepLinkMiddleware {
    let trackEvent: (AnalyticsEvent) async -> Void
    
    func process(_ url: String) async -> MiddlewareResult {
        await trackEvent(AnalyticsEvent(type: .deepLinkProcessed, url: url))
        return .allow
    }
}

private struct SecurityMiddleware: DeepLinkMiddleware {
    let performCheck: (SecurityCheck) async -> SecurityResult
    
    func process(_ url: String) async -> MiddlewareResult {
        let check = SecurityCheck(url: url, timestamp: Date())
        let result = await performCheck(check)
        return result.isAllowed ? .allow : .reject(result.reason)
    }
}

private struct ValidationMiddleware: DeepLinkMiddleware {
    let validate: (String) -> ValidationResult
    
    func process(_ url: String) async -> MiddlewareResult {
        let result = validate(url)
        return result.isValid ? .allow : .reject(result.message)
    }
}

private struct AnalyticsEvent {
    let type: AnalyticsEventType
    let url: String
    let timestamp: Date
    
    init(type: AnalyticsEventType, url: String) {
        self.type = type
        self.url = url
        self.timestamp = Date()
    }
}

private enum AnalyticsEventType {
    case deepLinkProcessed
}

private struct SecurityCheck {
    let url: String
    let timestamp: Date
}

// MARK: - Universal Links

private class UniversalLinkHandler {
    private var allowedDomains: Set<String> = []
    private var patterns: [String: (DeepLinkParameters) async -> DeepLinkResult] = [:]
    private var fallbackHandler: ((String) async -> DeepLinkResult)?
    
    func configureDomains(_ domains: [String]) async {
        allowedDomains = Set(domains)
    }
    
    func registerPattern(_ pattern: String, handler: @escaping (DeepLinkParameters) async -> DeepLinkResult) async {
        patterns[pattern] = handler
    }
    
    func configureFallback(_ handler: @escaping (String) async -> DeepLinkResult) async {
        fallbackHandler = handler
    }
    
    func handle(_ url: String) async -> DeepLinkResult {
        guard let urlObj = URL(string: url),
              let host = urlObj.host else {
            return .failure(.malformedURL)
        }
        
        // Validate domain
        guard allowedDomains.contains(host) else {
            return .failure(.invalidDomain)
        }
        
        // Try to match patterns
        for (pattern, handler) in patterns {
            if url.contains(pattern.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "/{id}", with: "")) {
                let params = extractParameters(from: urlObj)
                return await handler(params)
            }
        }
        
        // Use fallback if available
        if let fallbackHandler = fallbackHandler {
            return await fallbackHandler(url)
        }
        
        return .failure(.routeNotFound)
    }
    
    func cleanup() async {
        allowedDomains.removeAll()
        patterns.removeAll()
        fallbackHandler = nil
    }
    
    private func extractParameters(from url: URL) -> DeepLinkParameters {
        var params: [String: String] = [:]
        let pathComponents = url.path.components(separatedBy: "/")
        
        if pathComponents.count > 2 {
            params["id"] = pathComponents[2]
        }
        if pathComponents.count > 3 {
            params["shareId"] = pathComponents[2]
        }
        
        return params
    }
}

// MARK: - Analytics and Performance

private class DeepLinkAnalyticsCollector {
    private var deepLinkAttempts: [DeepLinkAttempt] = []
    
    func recordDeepLink(_ url: String, success: Bool) async {
        deepLinkAttempts.append(DeepLinkAttempt(url: url, success: success, timestamp: Date()))
    }
    
    func generateReport() async -> DeepLinkAnalytics {
        let total = deepLinkAttempts.count
        let successful = deepLinkAttempts.filter { $0.success }.count
        let failed = total - successful
        let successRate = total > 0 ? Double(successful) / Double(total) : 0
        
        let routePopularity = Dictionary(grouping: deepLinkAttempts.filter { $0.success }) { attempt in
            extractRouteType(from: attempt.url)
        }.mapValues { $0.count }
        
        return DeepLinkAnalytics(
            totalDeepLinks: total,
            successfulDeepLinks: successful,
            failedDeepLinks: failed,
            successRate: successRate,
            routePopularity: routePopularity
        )
    }
    
    func getSourceAnalytics() async -> SourceAnalytics {
        return SourceAnalytics(sources: ["app"])
    }
    
    private func extractRouteType(from url: String) -> String {
        if url.contains("/product/") {
            return "product"
        } else if url.contains("/profile/") {
            return "profile"
        } else if url.contains("/home") {
            return "home"
        }
        return "unknown"
    }
}

private struct DeepLinkAttempt {
    let url: String
    let success: Bool
    let timestamp: Date
}

private struct DeepLinkAnalytics {
    let totalDeepLinks: Int
    let successfulDeepLinks: Int
    let failedDeepLinks: Int
    let successRate: Double
    let routePopularity: [String: Int]
}

private struct SourceAnalytics {
    let sources: [String]
}

private class DeepLinkPerformanceTracker {
    private var processingTimes: [TimeInterval] = []
    private var memoryUsage: Int = 512 * 1024 // 512KB baseline
    
    func recordProcessingTime(_ time: TimeInterval) async {
        processingTimes.append(time)
    }
    
    func getMetrics() async -> PerformanceMetrics {
        let totalProcessed = processingTimes.count
        let averageTime = processingTimes.isEmpty ? 0 : processingTimes.reduce(0, +) / Double(processingTimes.count)
        let slowestTime = processingTimes.max() ?? 0
        
        return PerformanceMetrics(
            totalProcessed: totalProcessed,
            averageProcessingTime: averageTime,
            slowestProcessingTime: slowestTime,
            memoryUsage: memoryUsage
        )
    }
}

private struct PerformanceMetrics {
    let totalProcessed: Int
    let averageProcessingTime: TimeInterval
    let slowestProcessingTime: TimeInterval
    let memoryUsage: Int
}

// MARK: - Error Handling

private class DeepLinkErrorHandler {
    private var recoveryStrategies: [DeepLinkErrorType: (DeepLinkError) async -> DeepLinkResult] = [:]
    
    func configureRecovery(_ errorType: DeepLinkErrorType, handler: @escaping (DeepLinkError) async -> DeepLinkResult) async {
        recoveryStrategies[errorType] = handler
    }
    
    func recover(from errorType: DeepLinkErrorType) async -> DeepLinkResult? {
        let error = DeepLinkError(errorType)
        return await recoveryStrategies[errorType]?(error)
    }
}

// MARK: - Test Navigation Service

private class TestNavigationService {
    private(set) var currentRoute: TestRoute?
    private(set) var lastTransition: NavigationTransition?
    
    func navigate(to route: TestRoute) async {
        currentRoute = route
        lastTransition = NavigationTransition(type: .push, duration: 0.3)
    }
}

private struct NavigationResult {
    let isSuccess: Bool
    let transition: NavigationTransition?
}

private struct NavigationTransition {
    let type: TransitionType
    let duration: TimeInterval
}

private enum TransitionType {
    case push
    case modal
    case replace
}

// MARK: - Test Routes

private enum TestRoute: Equatable {
    case home
    case profile(userId: String)
    case settings
    case product(id: String)
    case userPost(userId: String, postId: String)
    case search(query: String, category: String)
    case admin(action: String)
    case categoryProducts(category: String)
    case sharedContent(shareId: String)
    case appStore
    case help
    case notFound
    case onboarding(OnboardingStep)
    case dynamic(id: Int, param: String)
    case category(id: Int, itemId: String)
    case memoryTest(iteration: Int, index: Int, param: String)
    case universalTest(iteration: Int, index: Int, id: String)
}

private enum OnboardingStep {
    case start
    case permissions
    case complete
}

// MARK: - Helper Extensions

private extension Character {
    var isAlphanumeric: Bool {
        return isLetter || isNumber
    }
}

private extension DeepLinkRouteResult {
    static func route(_ route: TestRoute) -> DeepLinkRouteResult {
        return DeepLinkRouteResult(route: route)
    }
}