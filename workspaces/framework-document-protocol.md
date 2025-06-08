# FRAMEWORK_DOCUMENT_PROTOCOL.md

Generate framework documentation that emphasizes test-driven development support and addresses validated pain points from application development.

## Protocol Activation

```text
@FRAMEWORK_DOCUMENT [command] [arguments]
```

## Commands

```text
generate              → Generate documentation emphasizing TDD support and pain point resolution
preview [section]     → Preview specific documentation section
validate              → Validate examples and ensure pain points are addressed
publish              → Prepare documentation for distribution
diff [version]       → Show what pain points were addressed between versions
```

## Process Flow

```text
1. Extract APIs with emphasis on testability features
2. Document pain point resolutions with examples
3. Include comprehensive testing guides
4. Validate documentation against real usage patterns
5. Ensure developers understand improvements
```

## Command Details

### Generate Command

Create documentation focused on developer needs:

```bash
@FRAMEWORK_DOCUMENT generate
```

The documentation generation now prioritizes content that helps developers use the framework effectively in test-driven development. This includes prominent placement of test utilities and helpers, examples showing test-first development patterns, clear guidance on mocking and stubbing framework components, and explicit callouts of improvements addressing previous pain points.

Output:
```
Scanning AxiomFramework v002...

Documentation Focus Areas:
  - Test utilities and helpers (12 new)
  - Pain points addressed (8 resolved)
  - TDD patterns and examples
  - Performance improvements
  - Migration from workarounds

Generating developer-focused documentation...
  ✓ Quick Start with TDD approach
  ✓ Testing guide with utilities
  ✓ Pain point resolution guide
  ✓ API reference with testing notes
  ✓ Examples from real applications

Generated: DOCUMENTATION-002.md
Validates against application usage patterns
```

### Preview Command

Preview sections with context:

```bash
@FRAMEWORK_DOCUMENT preview "Batch Operations"
```

The preview now shows how new features address specific pain points:

```
## Batch Operations (New in v002)

**Pain Point Addressed**: Single-item saves taking 3+ seconds for lists
**Application Context**: CYCLE-001-TASK-MANAGER Sessions 3, 5
**Time Savings**: ~95% for bulk operations

### Quick Example
```swift
// Before (v001) - Required 3+ seconds
for item in items {
    try await store.save(item)
}

// After (v002) - Takes <100ms
let saved = try await store.saveMany(items)
```

### Testing Batch Operations
```swift
func testBatchSave() async throws {
    // Arrange
    let items = (0..<100).map { Item(name: "Item \($0)") }
    
    // Act
    let saved = try await store.saveMany(items)
    
    // Assert
    XCTAssertEqual(saved.count, 100)
    XCTAssertTrue(saved.allSatisfy { $0.id != nil })
    // Performance assertion
    XCTAssertLessThan(executionTime, 0.1)
}
```

### Why This Improvement Matters
Based on developer feedback, batch operations reduce test setup time by 80% and eliminate complex transaction workarounds...
```

### Validate Command

Ensure documentation addresses real needs:

```bash
@FRAMEWORK_DOCUMENT validate
```

Validation now checks that pain points are addressed with clear examples, test utilities are documented with use cases, migration paths exist for all workarounds, and examples match real application patterns.

### Diff Command

Show pain point resolution between versions:

```bash
@FRAMEWORK_DOCUMENT diff v001
```

The diff command now emphasizes what problems were solved:

```
Framework Improvements v001 → v002

PAIN POINTS RESOLVED:
✓ Batch operations - Save 100 items in <100ms (was 3+ seconds)
✓ Transaction complexity - Single-line API (was 50+ lines)
✓ Async test utilities - XCTAssertAsync helper added
✓ Mock complexity - Auto-mocking for framework protocols

NEW TEST UTILITIES:
+ XCTAssertAsync - Simplifies async testing
+ MockClient - Pre-built test double
+ TestDataBuilder - Reduces test setup

DEVELOPER EXPERIENCE:
- Test setup: 65% less boilerplate
- TDD velocity: 40% faster RED→GREEN
- Documentation lookups: 50% reduction

MIGRATION GUIDE:
- 8 common workarounds now unnecessary
- Automated migration for 6 patterns
- Manual migration needed for 2 edge cases
```

## Documentation Structure Optimization

### TDD-First Organization
Documentation is now organized to support test-driven development workflow, with testing guides appearing early in documentation, every API example including its test, clear sections on mocking and stubbing, and performance characteristics for test planning.

### Pain Point Callouts
Throughout the documentation, callout boxes highlight when features address specific pain points, including the original problem description, the solution provided, example migration from workaround, and measured improvement in developer experience.

### Progressive Disclosure
Documentation provides quick wins first for developers wanting immediate productivity, then deeper content for those needing advanced usage. This includes quick start focused on TDD basics, testing utilities for common scenarios, advanced patterns for complex cases, and performance tuning for optimization.

## Example Enhancement

### Real-World Examples
Examples are now derived from actual application code that exhibited pain points, showing before/after improvements. This helps developers recognize their own patterns and understand how to migrate effectively.

### Test-First Examples
Every code example shows the test first, reinforcing TDD practices:

```swift
// 1. Write the test (RED)
func testTaskCreation() async throws {
    let task = Task(title: "Test Task")
    let saved = try await store.save(task)
    XCTAssertNotNil(saved.id)
}

// 2. Implement the feature (GREEN)
struct Task: Model {
    var id: UUID?
    let title: String
}

// 3. Refactor if needed (REFACTOR)
// In this case, the simple implementation is sufficient
```

### Performance Context
Examples include performance characteristics so developers can plan their tests effectively, showing typical execution times, memory usage patterns, and scaling characteristics.

## Testing Guide Prominence

### Dedicated Testing Section
A comprehensive testing guide appears early in documentation, covering framework-specific test utilities, patterns for testing each component type, strategies for async testing, and performance testing approaches.

### Component Testing Guides
Each framework component documentation includes a dedicated testing subsection explaining how to test components in isolation, what mocks or stubs are needed, common testing patterns, and potential testing pitfalls.

### Test Utility Reference
All test utilities are documented with clear use cases, before/after examples showing improvement, integration with standard XCTest, and performance characteristics.

## Success Metrics

The documentation protocol tracks whether developers can find what they need quickly (search analytics), understand how to test framework components (support ticket reduction), migrate from workarounds successfully (adoption metrics), and feel the framework supports TDD (developer surveys).

## Best Practices

1. **Lead with Testing**
   - Show test examples before implementation
   - Emphasize test utilities and helpers
   - Make TDD the obvious path

2. **Address Pain Points Explicitly**
   - Call out what problems are solved
   - Show migration from workarounds
   - Quantify improvements

3. **Use Real Examples**
   - Base examples on actual usage
   - Show problematic patterns and solutions
   - Include performance characteristics

4. **Progressive Learning**
   - Quick wins for immediate productivity
   - Deeper content for advanced usage
   - Clear learning path

5. **Validate Continuously**
   - Test examples actually work
   - Documentation matches implementation
   - Addresses real developer needs