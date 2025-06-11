import XCTest
@testable import Axiom

final class DeepLinkingTests: XCTestCase {
    
    // MARK: - RED: Deep Linking Tests
    
    func testInvalidURLHandlingProducesStructuredErrors() async throws {
        // Requirement: URL to route resolution with type-safe parameter extraction
        // Acceptance: Invalid URLs produce structured errors, not crashes, with parser handling all registered URL patterns
        // Boundary: URL parsing isolated from navigation execution
        
        // RED Test: Invalid URLs should produce structured errors, not crashes
        
        // Test 1: Invalid URL scheme should produce structured error
        let invalidSchemeURL = URL(string: "http://example.com/invalid")!
        let parser = URLToRouteParser()
        
        do {
            let _ = try parser.parse(url: invalidSchemeURL)
            XCTFail("Invalid URL scheme should produce error")
        } catch DeepLinkingError.invalidURLScheme(let scheme) {
            XCTAssertEqual(scheme, "http", "Should capture invalid scheme")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
        
        // Test 2: Malformed URL path should produce structured error
        let malformedPathURL = URL(string: "axiom://detail/")! // Empty detail ID
        
        do {
            let _ = try parser.parse(url: malformedPathURL)
            XCTFail("Malformed URL path should produce error")
        } catch DeepLinkingError.patternNotFound(let pattern) {
            XCTAssertEqual(pattern, "/detail", "Should capture invalid pattern")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
        
        // Test 3: Unregistered URL pattern should produce structured error
        let unregisteredURL = URL(string: "axiom://unknown/path")!
        
        do {
            let _ = try parser.parse(url: unregisteredURL)
            XCTFail("Unregistered URL pattern should produce error")
        } catch DeepLinkingError.patternNotFound(let pattern) {
            XCTAssertEqual(pattern, "/unknown/path", "Should capture unregistered pattern")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
        
        // Test 4: Invalid parameter extraction should produce structured error
        let invalidParamURL = URL(string: "axiom://detail/")! // Missing required ID parameter
        
        do {
            let _ = try parser.parse(url: invalidParamURL)
            XCTFail("Invalid parameters should produce error")
        } catch DeepLinkingError.patternNotFound(let pattern) {
            XCTAssertEqual(pattern, "/detail", "Should capture failed pattern")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testURLParsingIsolatedFromNavigationExecution() async throws {
        // Test that URL parsing is isolated from navigation execution
        
        let validURL = URL(string: "axiom://home")!
        let parser = URLToRouteParser()
        
        // URL parsing should work without navigation system
        let route = try parser.parse(url: validURL)
        XCTAssertEqual(route, .home, "URL parsing should work independently")
        
        // Parsing should not trigger navigation
        var navigationCalled = false
        let mockNavigator = MockNavigator { _ in
            navigationCalled = true
        }
        
        // Parse URL - should not trigger navigation
        let parsedRoute = try parser.parse(url: validURL)
        XCTAssertFalse(navigationCalled, "URL parsing should not trigger navigation")
        XCTAssertEqual(parsedRoute, .home, "Parsed route should be correct")
        
        // Only explicit navigation should trigger navigation
        await mockNavigator.navigate(to: parsedRoute)
        XCTAssertTrue(navigationCalled, "Explicit navigation should trigger navigator")
    }
    
    func testAllRegisteredURLPatternsHandled() async throws {
        // Test that parser can handle all registered URL patterns
        
        let parser = URLToRouteParser()
        
        // Test all standard patterns
        let patterns: [(URL, Route)] = [
            (URL(string: "axiom://home")!, .home),
            (URL(string: "axiom://detail/test-id")!, .detail(id: "test-id")),
            (URL(string: "axiom://settings")!, .settings),
            (URL(string: "axiom://custom/test-path")!, .custom(path: "test-path"))
        ]
        
        for (url, expectedRoute) in patterns {
            do {
                let parsedRoute = try parser.parse(url: url)
                XCTAssertEqual(parsedRoute, expectedRoute, "Pattern \(url) should parse to \(expectedRoute)")
            } catch {
                XCTFail("Pattern \(url) should be handled but got error: \(error)")
            }
        }
    }
    
    func testTypeSafeParameterExtraction() async throws {
        // Test that parameter extraction is type-safe
        
        let parser = URLToRouteParser()
        
        // Test string parameter extraction
        let detailURL = URL(string: "axiom://detail/item-123")!
        let detailRoute = try parser.parse(url: detailURL)
        
        if case .detail(let id) = detailRoute {
            XCTAssertEqual(id, "item-123", "ID parameter should be extracted correctly")
        } else {
            XCTFail("Expected detail route with ID parameter")
        }
        
        // Test custom path parameter extraction
        let customURL = URL(string: "axiom://custom/nested/path/structure")!
        let customRoute = try parser.parse(url: customURL)
        
        if case .custom(let path) = customRoute {
            XCTAssertEqual(path, "nested/path/structure", "Custom path should be extracted correctly")
        } else {
            XCTFail("Expected custom route with path parameter")
        }
    }
    
    func testURLValidationBeforeParsing() async throws {
        // Test that URLs are validated before parsing
        
        let parser = URLToRouteParser()
        
        // Test valid URLs pass validation
        let validURLs = [
            URL(string: "axiom://home")!,
            URL(string: "axiom://detail/valid-id")!,
            URL(string: "axiom://settings")!
        ]
        
        for url in validURLs {
            XCTAssertNoThrow(try parser.validate(url: url), "Valid URL \(url) should pass validation")
        }
        
        // Test invalid URLs fail validation
        let invalidURLs = [
            URL(string: "http://invalid.com")!, // Wrong scheme
            URL(string: "axiom://")!           // No host or path
        ]
        
        for url in invalidURLs {
            XCTAssertThrowsError(try parser.validate(url: url), "Invalid URL \(url) should fail validation")
        }
        
        // Note: axiom://detail/ is actually valid according to our URL structure
        // It has host="detail" and path="/", which our parser can handle
    }
    
    // MARK: - REFACTOR: Regex Pattern Matching Tests
    
    func testRegexBasedPatternMatching() async throws {
        // Test enhanced parser with regex patterns
        
        let regexPatterns = try [
            RegexURLPattern(pattern: "/home", routeType: .home),
            RegexURLPattern(pattern: "/detail/{id}", routeType: .detail),
            RegexURLPattern(pattern: "/user/{userId}/detail/{id}", routeType: .detail),
            RegexURLPattern(pattern: "/category/{category}/item/{id}", routeType: .detail),
            RegexURLPattern(pattern: "/settings", routeType: .settings),
            RegexURLPattern(pattern: "/custom/{path}", routeType: .custom)
        ]
        
        let enhancedParser = EnhancedURLToRouteParser(
            scheme: "axiom",
            regexPatterns: regexPatterns
        )
        
        // Test simple patterns
        let homeURL = URL(string: "axiom://home")!
        let homeRoute = try enhancedParser.parse(url: homeURL)
        XCTAssertEqual(homeRoute, .home)
        
        let detailURL = URL(string: "axiom://detail/test-123")!
        let detailRoute = try enhancedParser.parse(url: detailURL)
        XCTAssertEqual(detailRoute, .detail(id: "test-123"))
        
        // Test complex patterns with multiple parameters
        let userDetailURL = URL(string: "axiom://user/user-456/detail/item-789")!
        let userDetailRoute = try enhancedParser.parse(url: userDetailURL)
        // Should extract the "id" parameter from the detail part
        if case .detail(let id) = userDetailRoute {
            XCTAssertEqual(id, "item-789", "Should extract detail ID from complex pattern")
        } else {
            XCTFail("Expected detail route with extracted ID")
        }
        
        let categoryURL = URL(string: "axiom://category/electronics/item/phone-123")!
        let categoryRoute = try enhancedParser.parse(url: categoryURL)
        if case .detail(let id) = categoryRoute {
            XCTAssertEqual(id, "phone-123", "Should extract item ID from category pattern")
        } else {
            XCTFail("Expected detail route with extracted item ID")
        }
    }
    
    func testRegexPatternBuilder() async throws {
        // Test pattern builder for creating complex patterns
        
        var builder = RegexPatternBuilder()
        
        try builder.addPattern("/api/v1/users/{userId}", type: .custom)
        try builder.addPattern("/api/v1/products/{productId}/reviews/{reviewId}", type: .detail)
        try builder.addPatterns([
            ("/admin/settings", .settings),
            ("/admin/users/{userId}/profile", .custom)
        ])
        
        let patterns = builder.build()
        XCTAssertEqual(patterns.count, 4, "Builder should create all patterns")
        
        // Test one of the complex patterns
        let apiPattern = patterns.first { $0.pattern == "/api/v1/users/{userId}" }
        XCTAssertNotNil(apiPattern, "API pattern should be created")
        
        let testPath = "/api/v1/users/123"
        XCTAssertTrue(apiPattern!.matches(path: testPath), "Pattern should match test path")
    }
    
    func testRegexPatternParameterExtraction() async throws {
        // Test parameter extraction from regex patterns
        
        let pattern = try RegexURLPattern(pattern: "/user/{userId}/posts/{postId}/comments/{commentId}", routeType: .custom)
        
        let testPath = "/user/john-doe/posts/blog-post-123/comments/comment-456"
        XCTAssertTrue(pattern.matches(path: testPath), "Pattern should match complex path")
        
        // Create a mock URL for extraction test
        let url = URL(string: "axiom://user/john-doe/posts/blog-post-123/comments/comment-456")!
        let route = try pattern.extractRoute(from: url, matchedPath: testPath)
        
        // Should extract the comment ID (last parameter for custom routes)
        if case .custom(let path) = route {
            XCTAssertEqual(path, "comment-456", "Should extract the comment ID as path parameter")
        } else {
            XCTFail("Expected custom route with extracted comment ID")
        }
    }
    
    func testRegexPatternErrorHandling() async throws {
        // Test error handling in regex patterns
        
        // Test pattern that doesn't match
        let pattern = try RegexURLPattern(pattern: "/specific/pattern/{id}", routeType: .detail)
        let nonMatchingPath = "/different/path/123"
        
        XCTAssertFalse(pattern.matches(path: nonMatchingPath), "Pattern should not match different path")
        
        // Test parameter extraction failure
        let url = URL(string: "axiom://different/path/123")!
        XCTAssertThrowsError(try pattern.extractRoute(from: url, matchedPath: nonMatchingPath)) { error in
            XCTAssertTrue(error is DeepLinkingError, "Should throw DeepLinkingError")
            if let deepLinkingError = error as? DeepLinkingError {
                switch deepLinkingError {
                case .patternNotFound(let path):
                    XCTAssertEqual(path, nonMatchingPath, "Should report the non-matching path")
                default:
                    XCTFail("Expected patternNotFound error")
                }
            }
        }
    }
    
    func testEnhancedParserFallback() async throws {
        // Test fallback behavior when regex patterns don't match
        
        let limitedRegexPatterns = try [
            RegexURLPattern(pattern: "/special/{id}", routeType: .detail)
        ]
        
        let enhancedParser = EnhancedURLToRouteParser(
            scheme: "axiom",
            regexPatterns: limitedRegexPatterns,
            fallbackPatterns: URLPattern.defaultPatterns
        )
        
        // Test URL that matches fallback pattern but not regex pattern
        let homeURL = URL(string: "axiom://home")!
        let homeRoute = try enhancedParser.parse(url: homeURL)
        XCTAssertEqual(homeRoute, .home, "Should fall back to default patterns")
        
        // Test URL that matches regex pattern
        let specialURL = URL(string: "axiom://special/test-id")!
        let specialRoute = try enhancedParser.parse(url: specialURL)
        XCTAssertEqual(specialRoute, .detail(id: "test-id"), "Should use regex pattern")
    }
    
    func testConcurrentURLParsing() async throws {
        // Test that URL parsing is thread-safe
        
        let parser = URLToRouteParser()
        let urls = [
            URL(string: "axiom://home")!,
            URL(string: "axiom://detail/item-1")!,
            URL(string: "axiom://detail/item-2")!,
            URL(string: "axiom://settings")!,
            URL(string: "axiom://custom/path-1")!
        ]
        
        // Parse URLs concurrently
        let results = await withTaskGroup(of: (URL, Result<Route, Error>).self) { group in
            for url in urls {
                group.addTask {
                    do {
                        let route = try parser.parse(url: url)
                        return (url, .success(route))
                    } catch {
                        return (url, .failure(error))
                    }
                }
            }
            
            var results: [(URL, Result<Route, Error>)] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
        
        // All parsing should succeed
        XCTAssertEqual(results.count, urls.count, "All URLs should be processed")
        
        for (url, result) in results {
            switch result {
            case .success(let route):
                // Verify correct parsing based on the actual URL structure
                if url.host == "home" {
                    XCTAssertEqual(route, .home)
                } else if url.host == "detail" {
                    if url.path == "/item-1" {
                        XCTAssertEqual(route, .detail(id: "item-1"))
                    } else if url.path == "/item-2" {
                        XCTAssertEqual(route, .detail(id: "item-2"))
                    } else {
                        XCTFail("Unexpected detail URL path: \(url.path)")
                    }
                } else if url.host == "settings" {
                    XCTAssertEqual(route, .settings)
                } else if url.host == "custom" {
                    if url.path == "/path-1" {
                        XCTAssertEqual(route, .custom(path: "path-1"))
                    } else {
                        XCTFail("Unexpected custom URL path: \(url.path)")
                    }
                } else {
                    XCTFail("Unexpected URL host: \(url.host ?? "nil")")
                }
            case .failure(let error):
                XCTFail("URL parsing failed for \(url): \(error)")
            }
        }
    }
}

// MARK: - Test Support Types

/// Mock navigator for testing isolation
actor MockNavigator {
    private let navigationHandler: (Route) -> Void
    
    init(navigationHandler: @escaping (Route) -> Void) {
        self.navigationHandler = navigationHandler
    }
    
    func navigate(to route: Route) {
        navigationHandler(route)
    }
}