# Axiom Framework: Agent Quick Reference

## 🎯 Essential Commands & Locations

### Key File Locations
```
/Users/tojkuv/Documents/GitHub/Axiom/
├── STATUS.md                          # Current state & issues
├── Examples/FoundationExample/        # Task manager app
├── Sources/Axiom/                     # Core framework
├── Tests/AxiomTests/                  # Test suite
└── Documentation/
    ├── REFINEMENT_PHASE_GUIDE.md      # Current phase guide
    ├── IMPLEMENTATION_ROADMAP.md      # Progress tracking
    └── Technical/                     # API specifications
```

### Daily Workflow Commands
```bash
# Check current issues
cat STATUS.md

# Run example app
cd ExampleApp && open ExampleApp.xcodeproj

# Run tests
swift test

# Check git status
git status

# Performance profiling
instruments -t "Time Profiler" ExampleApp.app
```

## 🔍 Debugging Common Issues

### SwiftUI Integration Problems
**Symptoms**: Views not updating, binding issues, memory leaks
**Check**: 
- `Sources/Axiom/SwiftUI/ContextBinding.swift`
- `Sources/Axiom/SwiftUI/ViewIntegration.swift`
- Example app view files

**Debug Steps**:
1. Add logging to `AxiomContext.objectWillChange`
2. Check actor isolation in context updates
3. Verify view lifecycle matches context lifecycle

### State Management Issues
**Symptoms**: Concurrent update conflicts, transaction failures
**Check**:
- `Sources/Axiom/State/StateSnapshot.swift`
- `Sources/Axiom/State/StateTransaction.swift`
- Client actor state management

**Debug Steps**:
1. Enable state transaction logging
2. Check for actor isolation violations
3. Verify copy-on-write behavior

### Error Propagation Problems
**Symptoms**: Errors not reaching UI, unclear error messages
**Check**:
- `Sources/Axiom/Errors/ErrorHandling.swift`
- Context error handling chains
- SwiftUI error view modifiers

**Debug Steps**:
1. Trace error through context layers
2. Check error type conformance
3. Verify recovery action triggers

### Performance Issues
**Symptoms**: Slow startup, high memory usage, laggy UI
**Check**:
- `Sources/Axiom/Performance/PerformanceMonitor.swift`
- State access hot paths
- Intelligence system overhead

**Debug Steps**:
1. Profile with Instruments
2. Check capability validation caching
3. Analyze state snapshot efficiency

## 🛠️ Common Framework Fixes

### Adding Convenience Methods
```swift
// Location: Sources/Axiom/Core/AxiomContext.swift
extension AxiomContext {
    public func register<T: AxiomClient>(_ clientType: T.Type) {
        // Simplified registration
    }
}
```

### Improving Error Messages
```swift
// Location: Sources/Axiom/Errors/AxiomError.swift
extension AxiomError {
    public var helpfulMessage: String {
        // Add guidance for common errors
    }
}
```

### Performance Optimizations
```swift
// Location: Hot paths identified by profiler
// Add caching, reduce allocations, optimize actor access
```

## 📊 Testing & Validation

### Run Specific Test Categories
```bash
# Core functionality
swift test --filter AxiomTests

# Integration tests
swift test --filter IntegrationTests

# Intelligence tests
swift test --filter IntelligenceTests

# Performance tests
swift test --filter PerformanceTests
```

### Example App Testing
```bash
# Build example
cd Examples/FoundationExample
swift build

# Run with debugging
swift run --configuration debug

# Profile performance
swift run --configuration release
```

### Performance Validation
```bash
# Memory usage
leaks ExampleApp.app

# CPU profiling
instruments -t "Time Profiler" ExampleApp.app

# State access benchmarks
swift test --filter "StateAccessPerformance"
```

## 🔧 API Improvement Patterns

### Before/After API Comparisons

#### Client Registration
```swift
// BEFORE (verbose)
let context = AxiomContext()
context.registerClient(UserClient.self, withDomain: UserDomain())

// AFTER (simplified)
let context = AxiomContext()
context.register(UserClient.self)
```

#### Capability Checking
```swift
// BEFORE (verbose)
guard case .available = capabilities.validate(.networking) else { return }

// AFTER (simplified)
guard capabilities.has(.networking) else { return }
```

#### Error Handling
```swift
// BEFORE (verbose)
.catch { error in
    switch error {
    case let axiomError as AxiomError:
        // handle
    default:
        // handle
    }
}

// AFTER (simplified)
.catchAxiomError { axiomError in
    // handle
}
```

## 📝 Documentation Update Process

### After Fixing Issues
1. Update `STATUS.md` with resolution
2. Add learnings to `REFINEMENT_PHASE_GUIDE.md`
3. Update test cases to prevent regression
4. Document any API changes

### After API Improvements
1. Update relevant Technical/ specifications
2. Add examples to `AGENT_QUICK_REFERENCE.md`
3. Update example apps to use new APIs
4. Test migration paths from old APIs

## 🎯 Current Focus Areas

### Priority 1: Example App Stability
- Task manager must run without errors
- All core workflows must work smoothly
- Performance must meet basic expectations

### Priority 2: Developer Experience
- Error messages must guide to solutions
- Common patterns must have ergonomic APIs
- Debugging must be straightforward

### Priority 3: Release Preparation
- API must be stable and well-tested
- Documentation must reflect real usage
- Migration guides must be complete

## 🚀 Quick Actions

### When Issues Are Discovered
```bash
# 1. Reproduce issue
cd Examples/FoundationExample && swift run

# 2. Create minimal test case
# Edit Tests/AxiomTests/IssueReproduction/

# 3. Identify root cause
# Use debugging steps above

# 4. Implement fix
# Edit relevant Sources/Axiom/ files

# 5. Validate fix
swift test && cd Examples/FoundationExample && swift run

# 6. Update documentation
# Update STATUS.md and relevant docs
```

### When Adding New Features
```bash
# 1. Check Technical/ specs for design
# 2. Implement in Sources/Axiom/
# 3. Add comprehensive tests
# 4. Update example apps to use feature
# 5. Document in appropriate guides
```

---

**REMEMBER**: Focus on fixing real issues discovered through example apps. Perfect is the enemy of good in the refinement phase.