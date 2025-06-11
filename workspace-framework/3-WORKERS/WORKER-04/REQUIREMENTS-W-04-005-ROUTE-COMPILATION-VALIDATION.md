# REQUIREMENTS-W-04-005: Route Compilation and Validation System

## Overview
Implement a compile-time route validation system that ensures route integrity, prevents navigation errors, and provides build-time guarantees for route consistency, parameter matching, and navigation graph validity.

## Core Requirements

### 1. Compile-Time Route Validation
- **Route Definition Validation**:
  - Verify all routes have unique identifiers
  - Ensure required parameters are non-optional
  - Validate route path syntax
  - Check for conflicting route patterns

- **Parameter Type Checking**:
  ```swift
  @RouteBuilder
  enum AppRoute {
      @Route(path: "/profile/:userId")
      case profile(userId: String)  // Compile error if userId is optional
      
      @Route(path: "/post/:id/comment/:commentId?")
      case post(id: String, commentId: String? = nil)  // Optional allowed with ?
  }
  ```

- **Route Exhaustiveness**:
  - Ensure all defined routes have handlers
  - Verify all route references exist
  - Check for unreachable routes

### 2. Navigation Graph Validation
- **Cycle Detection**:
  ```swift
  @NavigationGraph
  struct AppNavigation {
      @Edge(from: .home, to: .profile)
      @Edge(from: .profile, to: .settings)
      @Edge(from: .settings, to: .home)
      // Build warning: Potential navigation cycle detected
  }
  ```

- **Reachability Analysis**:
  - Identify orphaned routes
  - Detect dead-end navigation paths
  - Validate root route accessibility

- **Transition Validation**:
  ```swift
  @ValidTransition(from: .onboarding, to: .home)
  @InvalidTransition(from: .login, to: .profile) // Must go through home
  ```

### 3. Build-Time Code Generation
- **Route Manifest Generation**:
  ```swift
  // Generated at build time
  extension AppRoute {
      static let manifest = RouteManifest(
          routes: [
              .profile: RouteInfo(
                  path: "/profile/:userId",
                  parameters: [.required("userId", String.self)],
                  presentation: .push
              ),
              // ... all routes
          ]
      )
  }
  ```

- **Type-Safe Builders**:
  ```swift
  // Generated route builders
  extension Navigation {
      func toProfile(userId: String) -> Route {
          return AppRoute.profile(userId: userId)
      }
  }
  ```

### 4. Static Analysis Integration
- **SwiftLint Rules**:
  ```yaml
  custom_rules:
    invalid_route_parameter:
      regex: '@Route\(path:.*:\w+[^?]\)'
      message: "Required route parameters must not be optional types"
      severity: error
    
    unused_route:
      regex: 'case\s+(\w+)\s*\([^)]*\)'
      message: "Route defined but never used"
      severity: warning
  ```

- **Build Phase Validation**:
  ```bash
  # Run route validator during build
  swift run route-validator validate \
    --source Sources/ \
    --output .build/route-validation.json
  ```

### 5. Macro-Based Validation
- **Route Validation Macro**:
  ```swift
  @RouteValidator
  @attached(peer, names: arbitrary)
  public macro RouteValidator() = #externalMacro(
      module: "AxiomMacros",
      type: "RouteValidatorMacro"
  )
  ```

- **Compile-Time Checks**:
  ```swift
  public struct RouteValidatorMacro: PeerMacro {
      public static func expansion(
          of node: AttributeSyntax,
          providingPeersOf declaration: some DeclSyntaxProtocol,
          in context: some MacroExpansionContext
      ) throws -> [DeclSyntax] {
          // Validate route definitions
          // Generate compile errors for invalid routes
          // Create validation report
      }
  }
  ```

## Advanced Features

### 1. Route Dependency Graph
```swift
struct RouteDependencyGraph {
    let nodes: [Route: Set<Route>]
    
    func findCycles() -> [[Route]] {
        // Tarjan's algorithm for cycle detection
    }
    
    func findUnreachable(from root: Route) -> Set<Route> {
        // BFS to find unreachable routes
    }
    
    func validateTransitions() -> [ValidationError] {
        // Check all transitions are valid
    }
}
```

### 2. Performance Validation
```swift
@PerformanceRoute(maxDepth: 5, maxParameters: 3)
enum OptimizedRoute {
    // Compile error if route depth exceeds limit
    // Warning if too many parameters
}
```

### 3. Migration Validation
```swift
@DeprecatedRoute(since: "2.0", replacement: .profileV2)
case profile(userId: String)

// Build warning: Using deprecated route
let route = AppRoute.profile(userId: "123")
```

## Testing Integration

### 1. Route Test Generation
```swift
// Automatically generated tests
final class AppRouteTests: XCTestCase {
    func testAllRoutesHaveUniqueIdentifiers() {
        let identifiers = AppRoute.allCases.map(\.identifier)
        XCTAssertEqual(identifiers.count, Set(identifiers).count)
    }
    
    func testAllRoutesAreReachable() {
        let graph = NavigationGraph.current
        let unreachable = graph.findUnreachable(from: .home)
        XCTAssertTrue(unreachable.isEmpty)
    }
}
```

### 2. Compile-Time Test Validation
```swift
@TestRoute
func testInvalidRoute() {
    // This test will fail to compile if route is invalid
    let route = AppRoute.profile(userId: "123")
    XCTAssertNotNil(route)
}
```

## Implementation Strategy

### 1. Build Pipeline Integration
```yaml
# Package.swift plugin
.plugin(
    name: "RouteValidation",
    capability: .buildTool(),
    dependencies: ["AxiomMacros"]
)
```

### 2. Validation Report Format
```json
{
  "timestamp": "2024-01-10T10:00:00Z",
  "routes": {
    "total": 25,
    "valid": 23,
    "warnings": 2,
    "errors": 0
  },
  "graph": {
    "cycles": [],
    "unreachable": ["debug_route"],
    "maxDepth": 4
  },
  "performance": {
    "validationTime": "1.2s",
    "routeCount": 25,
    "patternComplexity": "medium"
  }
}
```

## Dependencies
- **PROVISIONER**: Macro system infrastructure
- **Type-Safe Routing**: Route type definitions
- **Navigation Service**: Runtime validation hooks

## Validation Criteria
1. All route compilation errors must be caught at build time
2. Navigation cycles must be detected and reported
3. Unused routes must generate warnings
4. Route validation must complete in < 5s for 1000 routes
5. Zero false positives in validation reports

## Benefits
1. **Developer Experience**: Immediate feedback on route errors
2. **Code Quality**: Enforced route consistency
3. **Performance**: Optimized route structures
4. **Maintainability**: Clear route dependency visualization
5. **Safety**: Compile-time guarantees for navigation