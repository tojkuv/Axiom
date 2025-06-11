import XCTest
@testable import Axiom

class RouteCompilationValidationTests: XCTestCase {
    
    var routeValidator: RouteValidator!
    var graphValidator: NavigationGraphValidator!
    var paramValidator: RouteParameterValidator!
    
    override func setUp() async throws {
        try await super.setUp()
        routeValidator = RouteValidator()
        graphValidator = NavigationGraphValidator()
        paramValidator = RouteParameterValidator()
    }
    
    override func tearDown() async throws {
        routeValidator = nil
        graphValidator = nil
        paramValidator = nil
        try await super.tearDown()
    }
    
    // MARK: - Route Definition Validation Tests
    
    func testRouteValidationFramework() throws {
        // This test should fail initially as validation system doesn't exist
        
        // Test route definition validation
        routeValidator.addRoute(RouteDefinition(
            identifier: "profile",
            path: "/profile/:userId",
            parameters: [.required("userId", String.self)],
            presentation: .push
        ))
        
        routeValidator.addRoute(RouteDefinition(
            identifier: "settings", 
            path: "/settings",
            parameters: [],
            presentation: .present(.sheet)
        ))
        
        // Verify route compilation
        let compilationResult = routeValidator.compile()
        XCTAssertTrue(compilationResult.isSuccess)
        XCTAssertEqual(routeValidator.routeCount, 2)
        
        // Test route manifest generation
        let manifest = routeValidator.generateManifest()
        XCTAssertNotNil(manifest)
        XCTAssertEqual(manifest.routes.count, 2)
    }
    
    func testUniqueRouteIdentifiers() throws {
        // Test that duplicate route identifiers are rejected
        let route1 = RouteDefinition(
            identifier: "profile",
            path: "/profile/:id",
            parameters: [.required("id", String.self)],
            presentation: .push
        )
        
        let route2 = RouteDefinition(
            identifier: "profile", // Duplicate identifier
            path: "/user/:id",
            parameters: [.required("id", String.self)],
            presentation: .push
        )
        
        routeValidator.addRoute(route1)
        XCTAssertThrowsError(try routeValidator.addRoute(route2)) { error in
            XCTAssertTrue(error is RouteValidationError)
            if let validationError = error as? RouteValidationError {
                XCTAssertEqual(validationError, .duplicateIdentifier("profile"))
            }
        }
    }
    
    func testRoutePathSyntaxValidation() throws {
        // Test valid path syntax
        let validRoute = RouteDefinition(
            identifier: "validRoute",
            path: "/user/:id/settings/:section?",
            parameters: [
                .required("id", String.self),
                .optional("section", String.self)
            ],
            presentation: .push
        )
        
        XCTAssertNoThrow(try routeValidator.addRoute(validRoute))
        
        // Test invalid path syntax
        let invalidRoute = RouteDefinition(
            identifier: "invalidRoute",
            path: "/user/[invalid]/path",
            parameters: [],
            presentation: .push
        )
        
        XCTAssertThrowsError(try routeValidator.addRoute(invalidRoute)) { error in
            if let validationError = error as? RouteValidationError {
                XCTAssertEqual(validationError, .invalidPathSyntax("/user/[invalid]/path"))
            }
        }
    }
    
    func testConflictingRoutePatterns() throws {
        // Test detection of conflicting route patterns
        let route1 = RouteDefinition(
            identifier: "userProfile",
            path: "/user/:id",
            parameters: [.required("id", String.self)],
            presentation: .push
        )
        
        let route2 = RouteDefinition(
            identifier: "userDetails",
            path: "/user/:userId", // Conflicting pattern
            parameters: [.required("userId", String.self)],
            presentation: .push
        )
        
        routeValidator.addRoute(route1)
        XCTAssertThrowsError(try routeValidator.addRoute(route2)) { error in
            if let validationError = error as? RouteValidationError {
                XCTAssertEqual(validationError, .conflictingPattern("/user/:userId"))
            }
        }
    }
    
    // MARK: - Parameter Type Validation Tests
    
    func testRouteParameterValidation() throws {
        // Test required parameter validation
        let validRoute = RouteDefinition(
            identifier: "userProfile",
            path: "/user/:id",
            parameters: [.required("id", String.self)],
            presentation: .push
        )
        XCTAssertTrue(paramValidator.validate(validRoute))
        
        // Test optional parameter validation  
        let optionalRoute = RouteDefinition(
            identifier: "postDetail",
            path: "/post/:id/comment/:commentId?",
            parameters: [
                .required("id", String.self),
                .optional("commentId", String.self)
            ],
            presentation: .push
        )
        XCTAssertTrue(paramValidator.validate(optionalRoute))
    }
    
    func testRequiredParametersMustNotBeOptional() throws {
        // Test that required parameters cannot be optional types
        let invalidRoute = RouteDefinition(
            identifier: "invalidRoute",
            path: "/user/:id",
            parameters: [.required("id", String?.self)], // Invalid: required parameter with optional type
            presentation: .push
        )
        
        XCTAssertFalse(paramValidator.validate(invalidRoute))
        
        let validationErrors = paramValidator.getValidationErrors(for: invalidRoute)
        XCTAssertTrue(validationErrors.contains(.requiredParameterCannotBeOptional("id")))
    }
    
    func testParameterPathMismatch() throws {
        // Test detection of parameter/path mismatches
        let mismatchedRoute = RouteDefinition(
            identifier: "mismatchedRoute",
            path: "/user/:userId",
            parameters: [.required("id", String.self)], // Mismatch: path has "userId" but parameter is "id"
            presentation: .push
        )
        
        XCTAssertFalse(paramValidator.validate(mismatchedRoute))
        
        let validationErrors = paramValidator.getValidationErrors(for: mismatchedRoute)
        XCTAssertTrue(validationErrors.contains(.parameterPathMismatch("id", "userId")))
    }
    
    func testOptionalParameterSyntax() throws {
        // Test that optional parameters must use ? syntax in path
        let correctOptionalRoute = RouteDefinition(
            identifier: "correctOptional",
            path: "/post/:id/comment/:commentId?",
            parameters: [
                .required("id", String.self),
                .optional("commentId", String.self)
            ],
            presentation: .push
        )
        XCTAssertTrue(paramValidator.validate(correctOptionalRoute))
        
        let incorrectOptionalRoute = RouteDefinition(
            identifier: "incorrectOptional",
            path: "/post/:id/comment/:commentId", // Missing ? for optional parameter
            parameters: [
                .required("id", String.self),
                .optional("commentId", String.self)
            ],
            presentation: .push
        )
        XCTAssertFalse(paramValidator.validate(incorrectOptionalRoute))
    }
    
    // MARK: - Navigation Graph Validation Tests
    
    func testNavigationGraphValidation() throws {
        // Add navigation edges
        graphValidator.addEdge(from: "home", to: "profile")
        graphValidator.addEdge(from: "profile", to: "settings")
        graphValidator.addEdge(from: "settings", to: "home")
        
        // Test cycle detection
        let cycles = graphValidator.detectCycles()
        XCTAssertTrue(cycles.contains(["home", "profile", "settings", "home"]))
        
        // Test reachability analysis
        let unreachable = graphValidator.findUnreachable(from: "home")
        XCTAssertTrue(unreachable.isEmpty)
    }
    
    func testCycleDetection() throws {
        // Create a navigation graph with cycles
        graphValidator.addEdge(from: "A", to: "B")
        graphValidator.addEdge(from: "B", to: "C")
        graphValidator.addEdge(from: "C", to: "A") // Creates cycle A -> B -> C -> A
        graphValidator.addEdge(from: "D", to: "E") // Separate component
        
        let cycles = graphValidator.detectCycles()
        XCTAssertEqual(cycles.count, 1)
        XCTAssertTrue(cycles.first?.contains("A") == true)
        XCTAssertTrue(cycles.first?.contains("B") == true)
        XCTAssertTrue(cycles.first?.contains("C") == true)
    }
    
    func testReachabilityAnalysis() throws {
        // Create graph with unreachable nodes
        graphValidator.addEdge(from: "home", to: "profile")
        graphValidator.addEdge(from: "profile", to: "settings")
        graphValidator.addEdge(from: "orphan1", to: "orphan2") // Unreachable from home
        
        let unreachable = graphValidator.findUnreachable(from: "home")
        XCTAssertEqual(unreachable.count, 2)
        XCTAssertTrue(unreachable.contains("orphan1"))
        XCTAssertTrue(unreachable.contains("orphan2"))
        
        let reachable = graphValidator.findReachable(from: "home")
        XCTAssertEqual(reachable.count, 3) // home, profile, settings
        XCTAssertTrue(reachable.contains("home"))
        XCTAssertTrue(reachable.contains("profile"))
        XCTAssertTrue(reachable.contains("settings"))
    }
    
    func testValidTransitions() throws {
        // Test valid transition definitions
        graphValidator.defineValidTransition(from: "onboarding", to: "home")
        graphValidator.defineInvalidTransition(from: "login", to: "profile") // Must go through home
        
        XCTAssertTrue(graphValidator.isValidTransition(from: "onboarding", to: "home"))
        XCTAssertFalse(graphValidator.isValidTransition(from: "login", to: "profile"))
        
        // Test transitivity: login -> home -> profile should be valid
        graphValidator.defineValidTransition(from: "login", to: "home")
        graphValidator.defineValidTransition(from: "home", to: "profile")
        
        let path = graphValidator.findValidPath(from: "login", to: "profile")
        XCTAssertNotNil(path)
        XCTAssertEqual(path, ["login", "home", "profile"])
    }
    
    func testGraphExhaustiveness() throws {
        // Test that all defined routes have handlers
        routeValidator.addRoute(RouteDefinition(
            identifier: "home",
            path: "/home",
            parameters: [],
            presentation: .replace
        ))
        
        routeValidator.addRoute(RouteDefinition(
            identifier: "profile",
            path: "/profile/:id",
            parameters: [.required("id", String.self)],
            presentation: .push
        ))
        
        // Register handlers for routes
        routeValidator.registerHandler(for: "home") { _ in }
        // Intentionally don't register handler for "profile"
        
        let exhaustivenessResult = routeValidator.checkExhaustiveness()
        XCTAssertFalse(exhaustivenessResult.isComplete)
        XCTAssertTrue(exhaustivenessResult.missingHandlers.contains("profile"))
    }
    
    // MARK: - Route Manifest Generation Tests
    
    func testRouteManifestGeneration() throws {
        // Add routes to validator
        routeValidator.addRoute(RouteDefinition(
            identifier: "profile",
            path: "/profile/:userId",
            parameters: [.required("userId", String.self)],
            presentation: .push
        ))
        
        routeValidator.addRoute(RouteDefinition(
            identifier: "settings",
            path: "/settings",
            parameters: [],
            presentation: .present(.sheet)
        ))
        
        // Generate manifest
        let manifest = routeValidator.generateManifest()
        XCTAssertNotNil(manifest)
        XCTAssertEqual(manifest.routes.count, 2)
        
        // Verify manifest content
        let profileRoute = manifest.routes["profile"]
        XCTAssertNotNil(profileRoute)
        XCTAssertEqual(profileRoute?.path, "/profile/:userId")
        XCTAssertEqual(profileRoute?.parameters.count, 1)
        XCTAssertEqual(profileRoute?.presentation, .push)
        
        let settingsRoute = manifest.routes["settings"]
        XCTAssertNotNil(settingsRoute)
        XCTAssertEqual(settingsRoute?.path, "/settings")
        XCTAssertEqual(settingsRoute?.parameters.count, 0)
        XCTAssertEqual(settingsRoute?.presentation, .present(.sheet))
    }
    
    func testTypeSafeBuilderGeneration() throws {
        // Test generation of type-safe route builders
        routeValidator.addRoute(RouteDefinition(
            identifier: "userProfile",
            path: "/user/:userId",
            parameters: [.required("userId", String.self)],
            presentation: .push
        ))
        
        let builders = routeValidator.generateTypeSafeBuilders()
        XCTAssertNotNil(builders)
        
        // Verify builder functions are generated
        XCTAssertTrue(builders.contains("func toUserProfile(userId: String) -> Route"))
    }
    
    // MARK: - Build-Time Integration Tests
    
    func testBuildTimeValidation() throws {
        // Test build-time validation pipeline
        let buildValidator = BuildTimeValidator()
        
        buildValidator.addSourcePath("Sources/")
        buildValidator.setOutputPath(".build/route-validation.json")
        
        let validationResult = buildValidator.validate()
        XCTAssertTrue(validationResult.isSuccess)
        
        // Verify validation report format
        let report = validationResult.report
        XCTAssertNotNil(report.timestamp)
        XCTAssertGreaterThan(report.routes.total, 0)
        XCTAssertEqual(report.routes.valid + report.routes.warnings + report.routes.errors, report.routes.total)
    }
    
    func testSwiftLintRuleIntegration() throws {
        // Test SwiftLint custom rules for route validation
        let lintValidator = SwiftLintRouteValidator()
        
        // Test invalid route parameter rule
        let invalidCode = """
        @Route(path: "/user/:id")
        case userProfile(id: String?) // Should be error: required parameter cannot be optional
        """
        
        let lintResult = lintValidator.validate(code: invalidCode)
        XCTAssertTrue(lintResult.hasErrors)
        XCTAssertTrue(lintResult.errors.contains { $0.rule == "invalid_route_parameter" })
        
        // Test unused route rule
        let unusedRouteCode = """
        enum AppRoute {
            case unusedRoute(id: String)
            case usedRoute(id: String)
        }
        // usedRoute is referenced somewhere, unusedRoute is not
        """
        
        let unusedResult = lintValidator.validate(code: unusedRouteCode)
        XCTAssertTrue(unusedResult.hasWarnings)
        XCTAssertTrue(unusedResult.warnings.contains { $0.rule == "unused_route" })
    }
    
    // MARK: - Performance Validation Tests
    
    func testRouteValidationPerformance() throws {
        // Test validation performance with large number of routes
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Add 1000 routes
        for i in 0..<1000 {
            routeValidator.addRoute(RouteDefinition(
                identifier: "route\(i)",
                path: "/route\(i)/:id",
                parameters: [.required("id", String.self)],
                presentation: .push
            ))
        }
        
        // Compile all routes
        let compilationResult = routeValidator.compile()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Validation should complete in < 5s for 1000 routes
        XCTAssertLessThan(duration, 5.0, "Route validation too slow: \(duration)s")
        XCTAssertTrue(compilationResult.isSuccess)
        XCTAssertEqual(routeValidator.routeCount, 1000)
    }
    
    func testGraphAnalysisPerformance() throws {
        // Test graph analysis performance
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Create complex graph with many edges
        for i in 0..<500 {
            for j in 0..<5 {
                let target = (i * 5 + j + 1) % 1000
                graphValidator.addEdge(from: "node\(i)", to: "node\(target)")
            }
        }
        
        // Perform cycle detection
        let cycles = graphValidator.detectCycles()
        let cycleDuration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Cycle detection should complete in < 1s
        XCTAssertLessThan(cycleDuration, 1.0, "Cycle detection too slow: \(cycleDuration)s")
        
        // Perform reachability analysis
        let reachabilityStart = CFAbsoluteTimeGetCurrent()
        let unreachable = graphValidator.findUnreachable(from: "node0")
        let reachabilityDuration = CFAbsoluteTimeGetCurrent() - reachabilityStart
        
        // Reachability should complete in < 1s
        XCTAssertLessThan(reachabilityDuration, 1.0, "Reachability analysis too slow: \(reachabilityDuration)s")
    }
    
    // MARK: - Integration Tests
    
    func testTypeSystemIntegration() throws {
        // Test integration with existing TypeSafeRoute system
        let validator = RouteValidator()
        
        // Add route that integrates with existing system
        validator.addRoute(RouteDefinition(
            identifier: "profile",
            path: "/profile/:userId",
            parameters: [.required("userId", String.self)],
            presentation: .push
        ))
        
        // Verify it generates compatible route types
        let compatibilityResult = validator.checkTypeSystemCompatibility()
        XCTAssertTrue(compatibilityResult.isCompatible)
        XCTAssertEqual(compatibilityResult.incompatibleRoutes.count, 0)
    }
    
    func testNavigationServiceIntegration() throws {
        // Test integration with ModularNavigationService
        let navigationService = ModularNavigationService()
        let validator = RouteValidator()
        
        // Register validation with navigation service
        navigationService.setRouteValidator(validator)
        
        // Add route to validator
        validator.addRoute(RouteDefinition(
            identifier: "testRoute",
            path: "/test/:id",
            parameters: [.required("id", String.self)],
            presentation: .push
        ))
        
        // Test that navigation service can validate routes
        let isValid = navigationService.validateRoute(identifier: "testRoute")
        XCTAssertTrue(isValid)
        
        let isInvalid = navigationService.validateRoute(identifier: "nonexistentRoute")
        XCTAssertFalse(isInvalid)
    }
    
    // MARK: - Error Handling Tests
    
    func testRouteValidationErrors() throws {
        // Test comprehensive error handling
        let validator = RouteValidator()
        
        // Test empty identifier error
        XCTAssertThrowsError(try validator.addRoute(RouteDefinition(
            identifier: "",
            path: "/test",
            parameters: [],
            presentation: .push
        ))) { error in
            XCTAssertEqual(error as? RouteValidationError, .emptyIdentifier)
        }
        
        // Test empty path error
        XCTAssertThrowsError(try validator.addRoute(RouteDefinition(
            identifier: "testRoute",
            path: "",
            parameters: [],
            presentation: .push
        ))) { error in
            XCTAssertEqual(error as? RouteValidationError, .emptyPath)
        }
        
        // Test missing parameter definition error
        XCTAssertThrowsError(try validator.addRoute(RouteDefinition(
            identifier: "testRoute",
            path: "/test/:id",
            parameters: [], // Missing parameter definition
            presentation: .push
        ))) { error in
            XCTAssertEqual(error as? RouteValidationError, .missingParameterDefinition("id"))
        }
    }
    
    func testValidationReportGeneration() throws {
        // Test comprehensive validation report
        let validator = RouteValidator()
        
        // Add valid and invalid routes
        validator.addRoute(RouteDefinition(
            identifier: "validRoute",
            path: "/valid/:id",
            parameters: [.required("id", String.self)],
            presentation: .push
        ))
        
        try? validator.addRoute(RouteDefinition(
            identifier: "",
            path: "/invalid",
            parameters: [],
            presentation: .push
        )) // This will fail but should be tracked
        
        let report = validator.generateValidationReport()
        XCTAssertNotNil(report.timestamp)
        XCTAssertEqual(report.routes.valid, 1)
        XCTAssertEqual(report.routes.errors, 1)
        XCTAssertEqual(report.routes.total, 2)
    }
}

// MARK: - Route Validation Testing DSL

extension RouteCompilationValidationTests {
    
    func testRouteValidationDSL() throws {
        let tester = RouteValidationTester(validator: routeValidator)
        
        // Test valid route
        tester.testValid(
            identifier: "profile",
            path: "/profile/:userId",
            parameters: [.required("userId", String.self)],
            presentation: .push
        ) { result in
            XCTAssertTrue(result.isValid)
            XCTAssertEqual(result.warnings.count, 0)
        }
        
        // Test invalid route
        tester.testInvalid(
            identifier: "",
            path: "/invalid",
            parameters: [],
            presentation: .push
        ) { errors in
            XCTAssertTrue(errors.contains(.emptyIdentifier))
        }
    }
}