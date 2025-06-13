import XCTest
@testable import Axiom

class DeepLinkingFrameworkTests: XCTestCase {
    
    var deepLinkHandler: DeepLinkPatternHandler!
    var universalLinkHandler: UniversalLinkHandler!
    
    override func setUp() async throws {
        try await super.setUp()
        deepLinkHandler = DeepLinkPatternHandler()
        universalLinkHandler = UniversalLinkHandler()
    }
    
    override func tearDown() async throws {
        deepLinkHandler = nil
        universalLinkHandler = nil
        try await super.tearDown()
    }
    
    // MARK: - Pattern Registration Tests
    
    func testDeepLinkPatternRegistration() throws {
        // This test should fail initially as pattern system doesn't exist
        
        // Test pattern registration with required parameters
        deepLinkHandler.register(pattern: "/profile/:userId") { params in
            guard let userId = params["userId"] else { return nil }
            return StandardRoute.detail(id: userId)
        }
        
        // Test pattern registration with optional parameters
        deepLinkHandler.register(pattern: "/post/:postId/comment/:commentId?") { params in
            guard let postId = params["postId"] else { return nil }
            let commentId = params["commentId"]
            return StandardRoute.custom(path: "post-\(postId)-\(commentId ?? "none")")
        }
        
        // Verify pattern compilation
        XCTAssertEqual(deepLinkHandler.registeredPatterns.count, 2)
        XCTAssertTrue(deepLinkHandler.canHandle(URL(string: "axiom://profile/123")!))
        XCTAssertTrue(deepLinkHandler.canHandle(URL(string: "axiom://post/456/comment/789")!))
        XCTAssertTrue(deepLinkHandler.canHandle(URL(string: "axiom://post/456")!)) // Optional parameter
    }
    
    func testPatternPriorityOrdering() throws {
        // More specific patterns should have higher priority
        deepLinkHandler.register(pattern: "/user/:id") { params in
            return StandardRoute.custom(path: "general-user")
        }
        
        deepLinkHandler.register(pattern: "/user/:id/settings") { params in
            return StandardRoute.custom(path: "user-settings")
        }
        
        deepLinkHandler.register(pattern: "/user/admin") { params in
            return StandardRoute.custom(path: "admin-user")
        }
        
        // Static patterns should have highest priority
        let adminResult = deepLinkHandler.resolve(URL(string: "axiom://user/admin")!)
        if case .resolved(let route) = adminResult {
            XCTAssertEqual(route.identifier, "custom-admin-user")
        } else {
            XCTFail("Expected admin route resolution")
        }
        
        // More specific patterns should match before general ones
        let settingsResult = deepLinkHandler.resolve(URL(string: "axiom://user/123/settings")!)
        if case .resolved(let route) = settingsResult {
            XCTAssertEqual(route.identifier, "custom-user-settings")
        } else {
            XCTFail("Expected settings route resolution")
        }
    }
    
    // MARK: - Parameter Extraction Tests
    
    func testDeepLinkParameterExtraction() throws {
        deepLinkHandler.register(pattern: "/user/:id/settings/:section?") { params in
            let parameters = DeepLinkParameters(
                pathParameters: params,
                queryParameters: [:],
                fragments: nil
            )
            
            guard let userId = parameters.get("id", as: String.self) else { return nil }
            let section = parameters.get("section", as: String.self) ?? "general"
            
            return StandardRoute.custom(path: "user-\(userId)-\(section)")
        }
        
        // Test with all parameters
        let fullURL = URL(string: "axiom://user/123/settings/privacy")!
        let fullResult = deepLinkHandler.resolve(fullURL)
        
        if case .resolved(let route) = fullResult {
            XCTAssertEqual(route.identifier, "custom-user-123-privacy")
        } else {
            XCTFail("Expected resolved route")
        }
        
        // Test with optional parameter missing
        let partialURL = URL(string: "axiom://user/456/settings")!
        let partialResult = deepLinkHandler.resolve(partialURL)
        
        if case .resolved(let route) = partialResult {
            XCTAssertEqual(route.identifier, "custom-user-456-general")
        } else {
            XCTFail("Expected resolved route with default")
        }
    }
    
    func testQueryParameterExtraction() throws {
        deepLinkHandler.register(pattern: "/profile/:userId") { params in
            // This handler should receive query parameters as well
            return StandardRoute.detail(id: params["userId"] ?? "unknown")
        }
        
        let url = URL(string: "axiom://profile/123?source=email&campaign=summer2024")!
        let result = deepLinkHandler.resolve(url)
        
        // Should extract query parameters for context
        XCTAssertNotNil(result)
        if case .resolved(let route) = result {
            XCTAssertEqual(route.identifier, "detail-123")
        }
        
        // Query parameters should be accessible through context
        let context = deepLinkHandler.lastResolutionContext
        XCTAssertEqual(context?.queryParameters["source"], "email")
        XCTAssertEqual(context?.queryParameters["campaign"], "summer2024")
    }
    
    func testTypeSafeParameterConversion() throws {
        deepLinkHandler.register(pattern: "/item/:itemId") { params in
            let parameters = DeepLinkParameters(
                pathParameters: params,
                queryParameters: [:],
                fragments: nil
            )
            
            // Test type-safe conversion
            guard let itemId = parameters.get("itemId", as: Int.self) else { return nil }
            return StandardRoute.custom(path: "item-\(itemId)")
        }
        
        // Valid integer parameter
        let validURL = URL(string: "axiom://item/42")!
        let validResult = deepLinkHandler.resolve(validURL)
        
        if case .resolved(let route) = validResult {
            XCTAssertEqual(route.identifier, "custom-item-42")
        } else {
            XCTFail("Expected resolved route")
        }
        
        // Invalid integer parameter should fail
        let invalidURL = URL(string: "axiom://item/notanumber")!
        let invalidResult = deepLinkHandler.resolve(invalidURL)
        
        XCTAssertEqual(invalidResult, .invalid(reason: "Invalid parameter type"))
    }
    
    // MARK: - Universal Link Tests
    
    func testUniversalLinkSupport() async throws {
        // Test universal link validation
        let universalURL = URL(string: "https://myapp.com/profile/123")!
        let result = await universalLinkHandler.handleUniversalLink(universalURL)
        
        XCTAssertTrue(result.isSuccess)
    }
    
    func testUniversalLinkDomainValidation() async throws {
        // Valid domain
        let validURL = URL(string: "https://myapp.com/profile/123")!
        let validResult = await universalLinkHandler.handleUniversalLink(validURL)
        XCTAssertTrue(validResult.isSuccess)
        
        // Invalid domain should be rejected
        let invalidURL = URL(string: "https://malicious.com/profile/123")!
        let invalidResult = await universalLinkHandler.handleUniversalLink(invalidURL)
        XCTAssertTrue(invalidResult.isFailed)
    }
    
    func testUniversalLinkPathPrefixHandling() async throws {
        // Universal links should support path prefixes
        let prefixURL = URL(string: "https://myapp.com/app/profile/123")!
        let result = await universalLinkHandler.handleUniversalLink(prefixURL)
        
        XCTAssertTrue(result.isSuccess)
        
        // The '/app/' prefix should be stripped before processing
        // Result should be equivalent to 'axiom://profile/123'
    }
    
    // MARK: - Custom Scheme Tests
    
    func testCustomSchemeRegistration() throws {
        let customSchemeHandler = CustomSchemeHandler()
        
        customSchemeHandler.registerScheme("myapp") { url in
            return .resolved(StandardRoute.home)
        }
        
        let customURL = URL(string: "myapp://open")!
        let result = customSchemeHandler.handle(customURL)
        
        if case .resolved(let route) = result {
            XCTAssertEqual(route, StandardRoute.home)
        } else {
            XCTFail("Expected resolved route")
        }
    }
    
    func testCustomSchemeSecurityValidation() throws {
        let customSchemeHandler = CustomSchemeHandler()
        
        // Should reject unregistered schemes
        let unauthorizedURL = URL(string: "malicious://attack")!
        let result = customSchemeHandler.handle(unauthorizedURL)
        
        XCTAssertEqual(result, .invalid(reason: "Unauthorized scheme"))
    }
    
    // MARK: - Security Validation Tests
    
    func testURLSecurityValidation() throws {
        let securityValidator = DeepLinkSecurity()
        
        // Valid URLs should pass
        let validURL = URL(string: "axiom://profile/123")!
        let validResult = securityValidator.validateURL(validURL)
        XCTAssertEqual(validResult, .success)
        
        // URLs with dangerous parameters should be rejected
        let dangerousURL = URL(string: "axiom://profile/123?script=<script>alert('xss')</script>")!
        let dangerousResult = securityValidator.validateURL(dangerousURL)
        if case .failure(let reason) = dangerousResult {
            XCTAssertTrue(reason.contains("Invalid parameter"))
        } else {
            XCTFail("Expected security failure")
        }
    }
    
    func testHostWhitelistValidation() throws {
        let securityValidator = DeepLinkSecurity()
        
        // Whitelisted hosts should pass
        let whitelistedURL = URL(string: "https://myapp.com/profile/123")!
        let validResult = securityValidator.validateURL(whitelistedURL)
        XCTAssertEqual(validResult, .success)
        
        // Non-whitelisted hosts should fail
        let blockedURL = URL(string: "https://blocked.com/profile/123")!
        let blockedResult = securityValidator.validateURL(blockedURL)
        if case .failure(let reason) = blockedResult {
            XCTAssertTrue(reason.contains("Unauthorized host"))
        } else {
            XCTFail("Expected host validation failure")
        }
    }
    
    // MARK: - Pattern Compilation Tests
    
    func testURLPatternCompiler() throws {
        let compiler = URLPatternCompiler()
        
        // Test static pattern compilation
        let staticPattern = compiler.compile("/profile/settings")
        XCTAssertEqual(staticPattern.segments.count, 2)
        
        // Test parameter pattern compilation
        let paramPattern = compiler.compile("/user/:id/posts/:postId?")
        XCTAssertEqual(paramPattern.segments.count, 4)
        
        // Verify parameter segments
        let userSegment = paramPattern.segments[1]
        XCTAssertTrue(userSegment.isParameter)
        XCTAssertEqual(userSegment.parameterName, "id")
        XCTAssertFalse(userSegment.isOptional)
        
        let postSegment = paramPattern.segments[3]
        XCTAssertTrue(postSegment.isParameter)
        XCTAssertEqual(postSegment.parameterName, "postId")
        XCTAssertTrue(postSegment.isOptional)
    }
    
    func testWildcardPatternCompilation() throws {
        let compiler = URLPatternCompiler()
        
        // Test single wildcard
        let singleWildcard = compiler.compile("/docs/*")
        XCTAssertTrue(singleWildcard.segments.last?.isWildcard == true)
        XCTAssertFalse(singleWildcard.segments.last?.isGreedy == true)
        
        // Test greedy wildcard
        let greedyWildcard = compiler.compile("/api/**")
        XCTAssertTrue(greedyWildcard.segments.last?.isWildcard == true)
        XCTAssertTrue(greedyWildcard.segments.last?.isGreedy == true)
    }
    
    // MARK: - Performance Tests
    
    func testPatternMatchingPerformance() throws {
        // Register many patterns to test performance
        for i in 0..<1000 {
            deepLinkHandler.register(pattern: "/item/\(i)/:id") { params in
                return StandardRoute.custom(path: "item-\(i)")
            }
        }
        
        // Measure pattern matching performance
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<100 {
            let url = URL(string: "axiom://item/500/12345")!
            _ = deepLinkHandler.resolve(url)
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        let averageTime = (duration / 100) * 1000 // Convert to milliseconds
        
        // Should be under 5ms per resolution as per requirements
        XCTAssertLessThan(averageTime, 5.0, "Pattern matching too slow: \(averageTime)ms")
    }
    
    // MARK: - Integration Tests
    
    func testNavigationServiceIntegration() async throws {
        let navigationService = ModularNavigationService()
        let deepLinkHandler = navigationService.deepLinkHandler
        
        // Register pattern
        deepLinkHandler.register(pattern: "/profile/:userId") { params in
            guard let userId = params["userId"] else { return nil }
            return StandardRoute.detail(id: userId)
        }
        
        // Test deep link navigation
        let url = URL(string: "axiom://profile/123")!
        let result = await navigationService.handleDeepLink(url)
        
        XCTAssertTrue(result)
        
        // Verify navigation occurred
        let currentRoute = await navigationService.stateStore.currentRoute
        XCTAssertNotNil(currentRoute)
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidPatternHandling() throws {
        // Invalid patterns should throw during registration
        XCTAssertThrowsError(try deepLinkHandler.registerUnsafe(pattern: "/invalid/[")) { error in
            XCTAssertTrue(error is DeepLinkError)
        }
        
        // Empty patterns should be rejected
        XCTAssertThrowsError(try deepLinkHandler.registerUnsafe(pattern: "")) { error in
            if let deepLinkError = error as? DeepLinkError {
                XCTAssertEqual(deepLinkError, .invalidPattern("Empty pattern"))
            }
        }
    }
    
    func testConflictingPatternDetection() throws {
        // Register initial pattern
        deepLinkHandler.register(pattern: "/user/:id") { params in
            return StandardRoute.custom(path: "user-1")
        }
        
        // Conflicting pattern should be detected
        XCTAssertThrowsError(try deepLinkHandler.registerUnsafe(pattern: "/user/:userId")) { error in
            if let deepLinkError = error as? DeepLinkError {
                XCTAssertEqual(deepLinkError, .conflictingPattern("Pattern conflicts with existing"))
            }
        }
    }
    
    // MARK: - Context and Analytics Tests
    
    func testDeepLinkContextCapture() throws {
        deepLinkHandler.register(pattern: "/profile/:userId") { params in
            return StandardRoute.detail(id: params["userId"] ?? "unknown")
        }
        
        let url = URL(string: "axiom://profile/123?source=push&campaign=retention")!
        _ = deepLinkHandler.resolve(url)
        
        let context = deepLinkHandler.lastResolutionContext
        XCTAssertNotNil(context)
        XCTAssertEqual(context?.source, .pushNotification)
        XCTAssertEqual(context?.campaign, "retention")
        XCTAssertNotNil(context?.timestamp)
    }
    
    func testDeferredDeepLinkHandling() async throws {
        let deferredHandler = DeferredDeepLinkHandler()
        
        // Store pending link
        let url = URL(string: "axiom://profile/123")!
        deferredHandler.storePendingLink(url)
        
        XCTAssertEqual(deferredHandler.pendingLinksCount, 1)
        
        // Process pending links
        let routes = await deferredHandler.processPendingLinks()
        XCTAssertEqual(routes.count, 1)
        XCTAssertEqual(deferredHandler.pendingLinksCount, 0)
    }
}

// MARK: - Deep Link Testing DSL

extension DeepLinkingFrameworkTests {
    
    func testDeepLinkTestingDSL() async throws {
        let tester = DeepLinkTester(handler: deepLinkHandler)
        
        // Register test patterns
        deepLinkHandler.register(pattern: "/profile/:userId") { params in
            guard let userId = params["userId"] else { return nil }
            return StandardRoute.detail(id: userId)
        }
        
        // Test valid deep link
        await tester.test("axiom://profile/123") { route in
            XCTAssertEqual(route.identifier, "detail-123")
        }
        
        // Test invalid deep link
        await tester.testInvalid("axiom://unknown/path") { error in
            XCTAssertEqual(error, .routeNotFound)
        }
        
        // Test with query parameters
        await tester.test("axiom://profile/456?source=email") { route in
            XCTAssertEqual(route.identifier, "detail-456")
        }
    }
}