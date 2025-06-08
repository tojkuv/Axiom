# FRAMEWORK_DEVELOP_PROTOCOL.md

Implement framework improvements through test-driven development with session tracking.

## Protocol Activation

```text
@FRAMEWORK_DEVELOP [command] [arguments]
```

## Commands

```text
start [requirements-id]    → Begin implementing framework requirements
resume [requirements-id]   → Continue implementation in new session
test [requirements-id]     → Run framework test suite
benchmark [requirements-id] → Run performance benchmarks
status [requirements-id]   → Show implementation progress
finalize [requirements-id] → Complete implementation and prepare release
```

## Process Flow

```text
1. Start from approved requirements
2. Implement via TDD cycles
3. Track progress in sessions
4. Validate with benchmarks
5. Finalize for documentation
```

## Command Details

### Start Command

Begin new framework implementation:

```bash
@FRAMEWORK_DEVELOP start 002
```

Actions:
1. Load REQUIREMENTS-002-BATCH-OPERATIONS.md
2. Create FW-SESSION-001.md
3. Set up test files
4. Create initial failing tests

Output:
```
Starting REQUIREMENTS-002-BATCH-OPERATIONS implementation

Framework v001 → v002 development
Requirements: 3 (Batch save, Batch delete, Performance)

Created tests:
  ✗ DataStoreTests.testBatchSave (RED)
  ✗ DataStoreTests.testBatchDelete (RED)
  ✗ DataStoreTests.testBatchPerformance (RED)

Session: FW-SESSION-001.md
Next: Implement DataStore.saveMany() to pass first test
```

### Resume Command

Continue in new session:

```bash
@FRAMEWORK_DEVELOP resume 002
```

Output:
```
Resuming REQUIREMENTS-002-BATCH-OPERATIONS
Previous: FW-SESSION-003.md (2.5 hours)

Progress:
  [x] REQ-001: Batch save operations (100%)
  [x] REQ-002: Batch delete operations (100%)
  [ ] REQ-003: Performance optimization (40%)

Current tests:
  ✓ DataStoreTests.testBatchSave (GREEN)
  ✓ DataStoreTests.testBatchDelete (GREEN)
  ✗ DataStoreTests.testBatchPerformance (RED)
    Expected: <100ms for 1000 items
    Actual: 342ms

Session: FW-SESSION-004.md
Next: Optimize batch implementation for performance target
```

### Test Command

Run framework tests:

```bash
@FRAMEWORK_DEVELOP test 002
```

Output:
```
Running framework tests for v002 development...

Core Tests:
  ✓ DataStoreTests: 45/45 passed
  ✓ UIBindingTests: 32/32 passed
  ✓ NetworkTests: 28/28 passed

New Feature Tests:
  ✓ BatchOperationTests: 12/12 passed
  ✓ TransactionTests: 8/8 passed
  ✗ PerformanceTests: 4/5 passed (1 slow)

Compatibility Tests:
  ✓ v001 API compatibility: 100%
  ✓ Migration tests: 3/3 passed

Summary: 136/137 tests passed (99.3%)
Failed: PerformanceTests.testLargeBatchSave (342ms > 100ms limit)
```

### Benchmark Command

Run performance benchmarks:

```bash
@FRAMEWORK_DEVELOP benchmark 002
```

Output:
```
Framework Performance Benchmarks - v002

Batch Operations (NEW):
  saveMany(10 items):      12ms  (83% faster than loop)
  saveMany(100 items):     45ms  (91% faster than loop)
  saveMany(1000 items):   342ms  (89% faster than loop)
  deleteMany(100 items):   23ms  (94% faster than loop)

Existing Operations (regression check):
  save(single):            3ms   (no change)
  fetch(single):           2ms   (no change)
  delete(single):          3ms   (no change)

Memory Impact:
  Batch buffer overhead:   ~2MB for 1000 items
  Peak memory:            48MB (acceptable)

Recommendation: Optimize chunking for 1000+ items
```

### Status Command

Show implementation progress:

```bash
@FRAMEWORK_DEVELOP status 002
```

Output:
```
Implementation Status - REQUIREMENTS-002-BATCH-OPERATIONS

Requirements:
  [x] REQ-001: Batch save API (100%)
      - saveMany() implemented
      - Transaction support added
      - Tests passing
  
  [x] REQ-002: Batch delete API (100%)
      - deleteMany() implemented
      - Cascade handling added
      - Tests passing
  
  [ ] REQ-003: Performance targets (80%)
      - [x] <50ms for 100 items
      - [ ] <100ms for 1000 items (currently 342ms)
      - [x] Memory efficient

Sessions: 4 (8.5 hours)
Code Changes: +847 lines, -123 lines
Test Coverage: 96.2%

Next: Implement chunked processing for large batches
```

### Finalize Command

Complete and prepare for release:

```bash
@FRAMEWORK_DEVELOP finalize 002
```

Actions:
1. Run all tests
2. Verify requirements met
3. Update version number
4. Generate migration guide
5. Create final session

Output:
```
Finalizing v002 - Batch Operations...

✓ All requirements satisfied
✓ Tests passing: 142/142
✓ Performance acceptable (with documented limits)
✓ No breaking changes detected
✓ Migration guide generated

Version bumped: 1.0.0 → 1.1.0

API Additions:
  + DataStore.saveMany<T>(_: [T]) async throws
  + DataStore.deleteMany<T>(type: T.Type, ids: [UUID]) async throws
  + DataStore.transaction<T>(_: () async throws -> T) async rethrows -> T

Final session: FW-SESSION-005.md
Ready for documentation: @FRAMEWORK_DOCUMENT generate
```

## TDD Implementation

### Test First (RED)

```swift
// Write test for new API
func testBatchSave() async throws {
    let items = (0..<100).map { Task(title: "Task \($0)") }
    
    let saved = try await store.saveMany(items)
    
    XCTAssertEqual(saved.count, 100)
    XCTAssertTrue(saved.allSatisfy { $0.id != nil })
}
// FAILS: saveMany() doesn't exist
```

### Implement (GREEN)

```swift
// Add minimum implementation
extension DataStore {
    func saveMany<T: Model>(_ items: [T]) async throws -> [T] {
        try await transaction {
            try await items.asyncMap { try await save($0) }
        }
    }
}
// Test passes but naive implementation
```

### Optimize (REFACTOR)

```swift
// Optimize for performance
extension DataStore {
    func saveMany<T: Model>(_ items: [T]) async throws -> [T] {
        try await transaction {
            let chunks = items.chunked(into: 50)
            return try await chunks.asyncFlatMap { chunk in
                try await batchInsert(chunk)
            }
        }
    }
}
// Tests still pass, much faster
```

## Session Tracking

### Session Structure

Each FW-SESSION-XXX.md tracks:
- Requirements progress
- TDD cycles completed
- API design decisions
- Performance measurements
- Compatibility concerns
- Next session planning

### Progress Tracking

Sessions maintain:
```markdown
## Requirements Checklist
- [x] REQ-001: Batch save operations
  - [x] Basic API design
  - [x] Transaction support
  - [x] Error handling
  - [x] Tests complete
```

## Technical Details

### Paths

```text
FrameworkCodebase: /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-framework/AxiomFramework
FrameworkWorkspace: /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-meta-workspace/workspaces/FrameworkWorkspace
```

### Framework Structure

```text
AxiomFramework/
├── Sources/
│   ├── AxiomCore/
│   ├── AxiomData/
│   ├── AxiomUI/
│   └── AxiomTest/
├── Tests/
│   ├── AxiomCoreTests/
│   ├── AxiomDataTests/
│   └── AxiomUITests/
└── Benchmarks/
```

### Version Management

- Semantic versioning (MAJOR.MINOR.PATCH)
- Breaking changes require major version
- New APIs are minor versions
- Bug fixes are patch versions

## Integration Points

### Inputs
- REQUIREMENTS-XXX.md (from PLAN)
- Previous framework version
- Application feedback

### Outputs
- Updated framework code
- FW-SESSION-XXX.md files
- Ready for DOCUMENT protocol

### Tools
- Swift Package Manager
- XCTest framework
- Performance benchmarking
- API compatibility checker

## Error Handling

### Test Failures
```
Error: 3 tests failing after changes
Recovery: 
1. Review test failures
2. Check for unintended breaking changes
3. Update tests if behavior change intended
```

### Performance Regression
```
Error: Existing operations 20% slower
Recovery:
1. Profile to identify bottleneck
2. Optimize without changing API
3. Document if tradeoff necessary
```

### API Compatibility Break
```
Error: Public API change detected
Options:
1. Add compatibility shim
2. Deprecate old API gracefully
3. Bump major version if necessary
```

## Best Practices

1. **Always write tests first** - No implementation without failing test

2. **Maintain compatibility** - Existing apps must not break

3. **Benchmark everything** - Performance is a feature

4. **Document decisions** - Session files capture "why" not just "what"

5. **Iterate quickly** - Small changes, frequent validation