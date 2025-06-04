# @DEVELOP.md - Axiom Framework Development Command

Implementation command that transforms RFC requirements into working code through disciplined TDD

## Automated Mode Trigger

**When human sends**: `@DEVELOP [optional-args]`
**Action**: Enter ultrathink mode and execute framework development workflow

### Usage Modes
- **`@DEVELOP build [RFC-XXX]`** → Execute TDD implementation with mandatory refactoring for RFC requirements
- **`@DEVELOP test [RFC-XXX]`** → Run tests for RFC implementation
- **`@DEVELOP`** → Show current RFC implementation status in Proposed/ directory

### Implementation Command Scope
**Single Responsibility**: Transform RFC requirements into tested, refactored code
**Input Source**: RFCs in Proposed/ directory with acceptance criteria
**Core Process**: Red-Green-Refactor cycles (mandatory refactoring)
**Success Criteria**: All acceptance tests pass, zero code smells
**Progress Tracking**: Check off TDD checklist items in RFC
**Quality Gate**: 100% test success before and after refactoring
**Strict Boundary**: Read requirements only, never modify them
**Integration**: Works with @PLAN for RFC lifecycle and @CHECKPOINT for version control

### TDD Implementation Workflow

**Workflow Rules**:
- No git operations (handled by @CHECKPOINT)
- Mandatory refactoring after every green test
- Update RFC checklist after each cycle

**Work Philosophy**: DEVELOP implements code → Refactor for quality → Multiple cycles → @CHECKPOINT commits and merges

**Red-Green-Refactor Cycle**:
1. **RED**: Write test from RFC acceptance criteria → Verify it fails
2. **GREEN**: Write minimal code to pass → All tests green
3. **REFACTOR**: Apply patterns to improve → Tests stay green
4. **CHECKLIST**: Mark RFC item complete → Move to next requirement

**Refactoring Targets**:
- Extract methods/classes
- Remove duplication
- Improve naming
- Simplify logic
- Optimize structure

## Implementation Philosophy

**Core Discipline**: Transform requirements into reality through rigorous TDD and refactoring

**Test-Driven Development Philosophy**: Following Kent Beck's TDD methodology - "Test-Driven Development by Example"
- Write tests first, implementation follows, refactor with confidence
- Small steps, rapid feedback, emergent design
- Tests as specification, documentation, and safety net

**Refactoring Philosophy**: Following Martin Fowler's disciplined approach - "Refactoring: Improving the Design of Existing Code"
- Refactoring is changing internal structure without changing external behavior
- Apply catalog of proven refactoring patterns
- Identify and eliminate code smells systematically
- Boy Scout Rule: Always leave code cleaner than you found it

**Quality Standards**: Framework components maintain architectural integrity, meet performance targets, provide good developer experience, exhibit structural excellence, and integrate with framework capabilities.

**TDD Methodology** (Kent Beck):
- Red: Write failing test from acceptance criteria
- Green: Minimal code to pass
- Refactor: Improve without changing behavior
- Small steps, continuous validation

**Refactoring Discipline** (Martin Fowler):
- Catalog of 70+ proven patterns
- Eliminate code smells systematically
- Maintain green tests throughout
- Boy Scout Rule always applies

**Quality Gates**:
- 100% acceptance criteria satisfaction
- Zero failing tests ever
- No code smells remaining
- Performance targets met

**Structural Excellence**: Optimal code organization, minimal complexity, zero duplication, clear naming conventions, and architectural consistency.

**Code Integrity**: ZERO TOLERANCE for broken tests in main branch - development process designed to prevent test failures from reaching production.

**Implementation Focus**:
- Read requirements, write tests
- Implement to pass tests
- Refactor to excellence
- Never modify requirements

## Implementation Principles

**From Requirements to Code**:
- Read acceptance criteria → Write test
- Test fails → Implement minimal solution
- Test passes → Refactor to excellence
- Never guess intent → Follow RFC exactly

**Technical Excellence**:
- Type safety through Swift's type system
- Concurrency safety through actors
- Performance through measurement
- Maintainability through refactoring

**Code Quality Standards**:
- Zero tolerance for failing tests
- No code smells after refactoring
- Clear naming from RFC terminology
- Modular structure for testability

### Industry Standard Refactoring Principles (Martin Fowler's Approach)

**Core Refactoring Definition**: 
"A change made to the internal structure of software to make it easier to understand and cheaper to modify without changing its observable behavior" - Martin Fowler

**When to Refactor (The Three Strikes Rule)**:
1. **First time**: Just do it
2. **Second time**: Wince at duplication, but do it anyway
3. **Third time**: Refactor before proceeding

**Types of Refactoring**:
- **Preparatory Refactoring**: Making it easier to add a feature
- **Comprehension Refactoring**: Making code easier to understand
- **Litter-Pickup Refactoring**: Small cleanups as you go
- **Planned Refactoring**: Dedicated time for larger improvements
- **Long-Term Refactoring**: Gradual architectural improvements

**Refactoring Process**:
1. **Identify Code Smell**: Recognize what needs improvement
2. **Choose Refactoring**: Select appropriate technique from catalog
3. **Apply in Small Steps**: Each step maintains working code
4. **Run Tests**: After EVERY micro-change
5. **Verify**: Ensure all tests pass (commits handled by @CHECKPOINT)

**Common Refactorings to Apply**:
- Extract Method/Function (most used refactoring)
- Rename Variable/Method/Class
- Extract Variable
- Inline Variable/Method
- Move Method/Field
- Extract Class
- Replace Conditional with Polymorphism
- Introduce Parameter Object

### Industry Standard Refactoring Principles (Martin Fowler's Approach)

**Core Refactoring Definition**: 
"A change made to the internal structure of software to make it easier to understand and cheaper to modify without changing its observable behavior" - Martin Fowler

**When to Refactor (The Three Strikes Rule)**:
1. **First time**: Just do it
2. **Second time**: Wince at duplication, but do it anyway
3. **Third time**: Refactor before proceeding

**Types of Refactoring**:
- **Preparatory Refactoring**: Making it easier to add a feature
- **Comprehension Refactoring**: Making code easier to understand
- **Litter-Pickup Refactoring**: Small cleanups as you go
- **Planned Refactoring**: Dedicated time for larger improvements
- **Long-Term Refactoring**: Gradual architectural improvements

**Refactoring Process**:
1. **Identify Code Smell**: Recognize what needs improvement
2. **Choose Refactoring**: Select appropriate technique from catalog
3. **Apply in Small Steps**: Each step maintains working code
4. **Run Tests**: After EVERY micro-change
5. **Verify**: Ensure all tests pass (commits handled by @CHECKPOINT)

**Common Refactorings to Apply**:
- Extract Method/Function (most used refactoring)
- Rename Variable/Method/Class
- Extract Variable
- Inline Variable/Method
- Move Method/Field
- Extract Class
- Replace Conditional with Polymorphism
- Introduce Parameter Object

### Testing Standards
**Requirements**: High test coverage, comprehensive test success rates, multiple test categories
**Standards**: See `AxiomFramework/Documentation/Testing/TESTING_STRATEGY.md` for detailed testing methodology and requirements

## Implementation Methodology

### Phase 1: RFC Analysis
1. **Extract Acceptance Criteria** → One test per criterion
2. **Identify Test Boundaries** → Know what to mock
3. **Note Performance Targets** → Prepare benchmarks
4. **Follow TDD Checklist** → Work in order
5. **API Design Validation** → Ensure APIs match RFC interface specifications

### Phase 2: Writing the Code
1. **Test First** → From acceptance criteria
2. **Code Minimal** → Just enough to pass
3. **Refactor Always** → After each green
4. **Measure Performance** → Against RFC targets
5. **Update Checklist** → Track progress

### Phase 3: Professional Test-Driven Development

**Industry TDD Standards**:
- **Kent Beck's TDD**: Small steps, fast feedback, emergent design
- **Test Pyramid (Mike Cohn)**: Many unit tests, fewer integration, few E2E
- **FIRST Principles**: Fast, Independent, Repeatable, Self-validating, Timely
- **AAA Pattern**: Arrange-Act-Assert for test structure

**Test Categories by Speed**:
- **Unit Tests**: Milliseconds (thousands per second)
- **Integration Tests**: Seconds (external dependencies mocked)
- **End-to-End Tests**: Minutes (real system interactions)

**TDD Best Practices**:
1. **One behavior per test**: Single assertion preferred
2. **Descriptive names**: `test_should_X_when_Y`
3. **No test interdependence**: Random order execution
4. **Fast feedback**: Entire suite under 10 minutes
5. **Living documentation**: Tests explain system behavior

**Red-Green-Refactor Discipline**:
- **Red**: Test must fail for the right reason
- **Green**: Simplest thing that could possibly work
- **Refactor**: Clean up without changing behavior
- **Verify**: All tests pass (version control via @CHECKPOINT)

### Phase 4: Professional Refactoring Practice

**Martin Fowler's Refactoring Workflow**:

1. **Identify Code Smells**
   Common smells to address:
   - **Bloaters**: Long methods, large classes, long parameter lists
   - **Object-Orientation Abusers**: Switch statements, refused bequest
   - **Change Preventers**: Divergent change, shotgun surgery
   - **Dispensables**: Dead code, duplicate code, speculative generality
   - **Couplers**: Feature envy, inappropriate intimacy

2. **Apply Refactoring Patterns**
   Most common refactorings (in order of frequency):
   - **Extract Method**: When method is too long or needs explanation
   - **Rename**: When name doesn't reveal intention
   - **Extract Variable**: When expression is complex
   - **Move Method**: When method uses more features of another class
   - **Extract Class**: When class is doing too much
   - **Replace Temp with Query**: To eliminate temporary variables
   - **Replace Conditional with Polymorphism**: For type-based switching

3. **Refactoring Rhythm**
   - Make change easy (might be hard)
   - Then make the easy change
   - Refactor in tiny steps (minutes, not hours)
   - Run tests after each micro-refactoring
   - Maintain working state (commits via @CHECKPOINT)

4. **Safety Checks**
   - All tests green before starting
   - All tests green after each step
   - Behavior unchanged (only structure improved)
   - Performance characteristics maintained
   - Architectural constraints respected

## Implementation Components

**What Gets Built** (from RFC requirements):
- Protocols matching RFC interfaces
- Actors for thread-safe components  
- Value types for immutable state
- Error types with recovery strategies
- Performance benchmarks from targets

**How It Gets Built** (TDD process):
- Test-first from acceptance criteria
- Minimal implementation to green
- Refactor to remove all smells
- Measure against RFC targets
- Update checklist on completion
>>>>>>> framework

## Testing Integration

**Testing Framework**: Multi-layered testing strategy covering framework components
**Testing Categories**: Unit, integration, performance, security, concurrency, and regression testing
**Testing Standards**: Testing specifications available in `AxiomFramework/Documentation/Testing/TESTING_STRATEGY.md`
**Integration**: Testing requirements integrated into development workflow

## 🚨 MANDATORY Test Requirements

**ABSOLUTE REQUIREMENT**: 100% test success rate required - NO EXCEPTIONS
**TDD ENFORCEMENT**: All development MUST follow test-driven development methodology
**BLOCKING BEHAVIOR**: Test failures IMMEDIATELY halt ALL development work until resolved
**Quality Gate**: Code must pass ALL tests before @CHECKPOINT integration
**Resolution Process**: STOP EVERYTHING → identify cause → fix failure → verify ALL tests pass → continue
**Test Suite Validation**: Complete test suite must pass before development completion
**Integration Requirement**: Tests must pass for @CHECKPOINT to integrate changes
**Standards**: Testing requirements in `AxiomFramework/Documentation/Testing/TESTING_STRATEGY.md`

## TDD Execution Details

<<<<<<< HEAD
**Industry Standard TDD Cycle (Kent Beck's RED-GREEN-REFACTOR)**:

1. **RED Phase - Write a Failing Test**
   - Write the simplest test that fails for the right reason
   - Test describes ONE specific behavior
   - Follow AAA pattern: Arrange, Act, Assert
   - Ensure test fails with clear, informative message

2. **GREEN Phase - Make it Pass**
   - Write MINIMAL code to pass - even if it's "stupid" code
   - Resist urge to write more than needed
   - Focus only on making the red test green
   - No optimization, no clever solutions yet

3. **REFACTOR Phase - Make it Right**
   Apply Martin Fowler's refactoring catalog:
   - **Extract Method**: Pull out code into well-named methods
   - **Rename**: Use intention-revealing names
   - **Remove Duplication**: Apply DRY principle
   - **Simplify Conditionals**: Replace nested ifs with guard clauses
   - **Extract Class**: When a class does too much
   - **Move Method**: Put behavior where it belongs
   
   Code Smells to eliminate:
   - Long methods, large classes, long parameter lists
   - Duplicate code, dead code, speculative generality
   - Feature envy, inappropriate intimacy
   - Primitive obsession, data clumps

4. **VALIDATE - Ensure All Tests Pass**
   - Run entire test suite after each refactoring
   - If any test fails, undo refactoring immediately
   - Keep code in working state for @CHECKPOINT

5. **REPEAT - Next Test**

**Robert C. Martin's Three Laws of TDD**:
1. **First Law**: You are not allowed to write any production code unless it is to make a failing unit test pass
2. **Second Law**: You are not allowed to write any more of a unit test than is sufficient to fail; and compilation failures are failures
3. **Third Law**: You are not allowed to write any more production code than is sufficient to pass the one failing unit test

**Additional TDD Principles**:
- **One Test at a Time**: Focus on single behavior per test
- **Test First, Not Test Later**: Tests drive the design
- **YAGNI (You Aren't Gonna Need It)**: Don't add functionality until needed
- **Fake it Till You Make it**: Start with hardcoded values, then generalize
- **Triangulation**: Use multiple tests to drive generic solutions

**Refactoring Discipline (Martin Fowler)**:
- **Definition**: Refactoring is a disciplined technique for restructuring existing code, altering its internal structure without changing its external behavior
- **When to Refactor**: 
  - Rule of Three: Refactor when you see duplication the third time
  - Preparatory Refactoring: Make change easy, then make easy change
  - Comprehension Refactoring: Refactor to understand
  - Litter-Pickup Refactoring: Clean as you go
- **When NOT to Refactor**: When tests are failing or during debugging

**Quality Gate Validation**:
```bash
swift test || exit 1  # No broken tests ever
```

## Success Criteria

<<<<<<< HEAD
**Architectural Compliance**: Type safety, concurrency safety through actors, performance targets, deterministic behavior, minimal boilerplate, capabilities permissions
**Technical Capabilities**: Type safety guarantees, actor-based concurrency, performance targets, deterministic behavior, minimal boilerplate
**Developer Experience**: Intuitive APIs, boilerplate reduction through code generation, type safety, clear error handling
**Structural Excellence**: Optimal code organization, minimal complexity, zero duplication, consistent patterns, clear module boundaries
**Testing Standards**: High test coverage, comprehensive test success rates, testing across all categories
**Refactoring Quality**: 100% functionality preservation, improved maintainability, reduced technical debt, enhanced readability
**Standards**: Success criteria in `AxiomFramework/Documentation/DEVELOPMENT_STANDARDS.md`
=======
**Implementation Complete When**:
- All RFC acceptance criteria have passing tests
- Zero code smells after refactoring
- Performance meets RFC targets
- TDD checklist fully checked
- No failing tests anywhere
- Code structure optimal
>>>>>>> framework

## 🤖 Development Execution Loop

**Command**: `@DEVELOP [build|test] [RFC-XXX]`
**Action**: Execute RFC implementation or testing with TDD methodology enforcement

### 🔄 **RFC-Driven Development Execution Process**

**CRITICAL**: DEVELOP commands work on current branch state - NO git operations

```bash
# RFC implementation workflow
echo "📋 RFC Implementation Workflow"
RFC_NUMBER=$1

# Validate RFC exists in Proposed/ directory
if [ -z "$RFC_NUMBER" ]; then
    echo "📊 Current RFC Implementation Status:"
    ls -la AxiomFramework/RFCs/Proposed/RFC-*.md 2>/dev/null || echo "No RFCs in Proposed/ directory"
    exit 0
fi

# Navigate to framework workspace
echo "🔄 Entering framework development workspace..."
cd framework-workspace/ || {
    echo "❌ Framework workspace not found"
    echo "💡 Run '@WORKSPACE setup' to initialize worktrees"
    exit 1
}

# Verify RFC exists and is ready for implementation
RFC_PATH="AxiomFramework/RFCs/Proposed/${RFC_NUMBER}*.md"
if ! ls $RFC_PATH 1> /dev/null 2>&1; then
    echo "❌ RFC ${RFC_NUMBER} not found in Proposed/ directory"
    echo "💡 Use '@PLAN propose ${RFC_NUMBER}' to move RFC to Proposed status"
    exit 1
fi

# Test-driven development workflow (NO git operations)
echo "🧪 MANDATORY: Running complete test suite validation..."
cd AxiomFramework
if ! swift test; then
    echo "❌ CRITICAL: Tests are failing on current branch"
    echo "🚨 BLOCKING: All development work MUST stop until tests pass"
    echo "🔧 Required action: Fix failing tests before proceeding"
    cd ..
    exit 1
fi
echo "✅ Test suite passed - safe to proceed with RFC ${RFC_NUMBER} implementation"
echo "📍 Workspace: $(pwd)"
echo "🌿 Branch: $(git branch --show-current)"
echo "📋 Implementing: ${RFC_NUMBER}"
echo "⚠️ Version control managed by @CHECKPOINT only"
cd ..
```

<<<<<<< HEAD
**Build Command - Professional TDD Implementation**:

1. **Pre-Implementation Setup**
   - Verify RFC exists in Proposed/ directory
   - Run full test suite - must be 100% green
   - Review RFC requirements and acceptance criteria

2. **TDD Implementation Loop (Kent Beck Style)**
   For each RFC requirement:
   
   **RED Phase**:
   - Write ONE failing test for smallest piece of functionality
   - Use descriptive test names: `test_should_[expected behavior]_when_[condition]`
   - Follow AAA: Arrange preconditions, Act on system, Assert expectations
   - Verify test fails for the RIGHT reason
   
   **GREEN Phase**:
   - Write SIMPLEST code that passes - even hardcoded values
   - Resist temptation to generalize prematurely
   - "Fake it till you make it" is acceptable
   - Goal: See green bar as quickly as possible
   
   **REFACTOR Phase (Martin Fowler's Approach)**:
   - Identify code smells in new code
   - Apply specific refactorings:
     * Extract Method for any code needing explanation
     * Remove Duplication using DRY principle
     * Rename for clarity (variables, methods, classes)
     * Simplify Conditionals (guard clauses, polymorphism)
     * Extract Constants for magic numbers/strings
   - Run tests after EACH micro-refactoring
   - Maintain working code (version control via @CHECKPOINT)

3. **Comprehensive Refactoring Review**
   After all requirements implemented:
   - Look for cross-cutting concerns
   - Apply architectural refactorings
   - Ensure SOLID principles compliance
   - Update documentation to match code

4. **Final Quality Gates**
   - 100% test coverage for new code
   - All tests passing
   - No code smells remaining
   - RFC checklist complete

**Test Command Execution (`@DEVELOP test [RFC-XXX]`)**:
1. **Test Scope** → Determine full suite or RFC-specific tests
2. **Test Execution** → Run swift test with coverage
3. **Results Validation** → Verify 100% pass rate
4. **Coverage Report** → Display test coverage metrics
=======
**Build Command Execution**:

1. **Setup**: Verify RFC in Proposed/, run tests (must be green)

2. **For Each Requirement**:
   - **RED**: Write test from acceptance criteria
   - **GREEN**: Minimal code to pass
   - **REFACTOR**: Apply patterns, eliminate smells
   - **CHECK**: Mark item complete in RFC

3. **Final Validation**:
   - All acceptance criteria satisfied
   - Performance targets met
   - Zero code smells
   - Checklist complete

**Test Command Execution**:
1. **Scope**: Full suite or RFC-specific
2. **Run**: `swift test` with coverage
3. **Validate**: All acceptance criteria pass
4. **Measure**: Performance vs RFC targets
5. **Report**: Coverage and results
>>>>>>> framework

**CRITICAL - No Git Operations**: The @DEVELOP protocol performs NO git operations whatsoever. ALL version control (commits, pushes, merges) is handled exclusively by @CHECKPOINT protocol.


**RFC Implementation Execution Examples**:
- `@DEVELOP build RFC-001` → Execute TDD cycle for RFC-001 requirements
- `@DEVELOP test RFC-001` → Run tests for RFC-001 implementation
- `@DEVELOP test` → Run complete framework test suite
- `@DEVELOP` → Show implementation status of all RFCs in Proposed/

## 🔄 Development Workflow Integration

**Build Command**: Implements RFCs using Kent Beck's TDD with Martin Fowler's refactoring
**Test Command**: Validates implementation following test pyramid principles
**RFC Workflow**: @PLAN propose → @DEVELOP build (TDD+refactoring) → @DEVELOP test → @PLAN activate
<<<<<<< HEAD
**Progress Tracking**: RFC checklist items checked off as test-driven cycles complete

**TDD Discipline (Robert C. Martin's Three Laws)**:
1. Write production code only to pass a failing test
2. Write only enough test code to fail
3. Write only enough production code to pass

**Refactoring Discipline (Martin Fowler)**:
- Refactor when you add function (preparatory)
- Refactor when you need to understand (comprehension)
- Refactor when you see mess (litter-pickup)
- Never refactor when tests are red

**Quality Standards**:
- **Test Coverage**: 100% coverage for new code
- **Test Speed**: Unit tests run in milliseconds
- **Test Independence**: Each test runs in isolation
- **Refactoring Safety**: All tests green before and after

**Professional Practices**:
- **Boy Scout Rule**: Leave code cleaner than found
- **Continuous Integration**: Tests run on every change
- **Collective Code Ownership**: Anyone can refactor anything
- **Merciless Refactoring**: Never tolerate code smells
=======
**Progress Tracking**: RFC TDD checklist items checked off as Red-Green-Refactor cycles complete
**Acceptance Driven**: Each RFC requirement has testable acceptance criteria that drive implementation
**Test Boundaries**: RFCs define clear test boundaries and mock requirements for each protocol
>>>>>>> framework

**TDD Discipline (Robert C. Martin's Three Laws)**:
1. Write production code only to pass a failing test
2. Write only enough test code to fail
3. Write only enough production code to pass

<<<<<<< HEAD
**Industry Standard References**:
- **TDD**: "Test-Driven Development by Example" - Kent Beck
- **Refactoring**: "Refactoring: Improving the Design of Existing Code" - Martin Fowler
- **Clean Code**: "Clean Code: A Handbook of Agile Software Craftsmanship" - Robert C. Martin
- **Working Effectively**: "Working Effectively with Legacy Code" - Michael Feathers

**Key Methodologies Applied**:
- **Kent Beck's TDD**: Red-Green-Refactor cycle with small steps
- **Martin Fowler's Refactoring Catalog**: 70+ proven refactoring patterns
- **Robert C. Martin's SOLID Principles**: Design principles for maintainable code
- **Michael Feathers' Legacy Code Techniques**: Safe refactoring strategies

**Framework-Specific Resources**:
- **Architecture Documentation**: `AxiomFramework/Documentation/Architecture/`
- **TDD Examples**: `AxiomFramework/Documentation/TDD/`
- **Refactoring Guides**: `AxiomFramework/Documentation/Refactoring/`
- **Testing Strategy**: `AxiomFramework/Documentation/Testing/TESTING_STRATEGY.md`
=======
**Refactoring Discipline (Martin Fowler)**:
- Refactor when you add function (preparatory)
- Refactor when you need to understand (comprehension)
- Refactor when you see mess (litter-pickup)
- Never refactor when tests are red
>>>>>>> framework

**Quality Standards**:
- **Test Coverage**: 100% coverage for new code
- **Test Speed**: Unit tests run in milliseconds
- **Test Independence**: Each test runs in isolation
- **Refactoring Safety**: All tests green before and after

<<<<<<< HEAD
**RFC Implementation**: Implements RFCs from Proposed/ directory with TDD methodology
**RFC Selection**: @PLAN propose moves RFCs to Proposed/ for implementation
**Progress Tracking**: RFC implementation checklists track development progress
**Completion Criteria**: All RFC checklist items must be completed
**Activation Ready**: Completed RFCs can be activated via @PLAN activate
=======
**Professional Practices**:
- **Boy Scout Rule**: Leave code cleaner than found
- **Continuous Integration**: Tests run on every change
- **Collective Code Ownership**: Anyone can refactor anything
- **Merciless Refactoring**: Never tolerate code smells

## References

**Core Methodologies**:
- Kent Beck's TDD: Red-Green-Refactor
- Martin Fowler's Refactoring: 70+ patterns
- Robert Martin's SOLID principles

**Documentation**:
- RFC format: [RFC_FORMAT.md](./RFC_FORMAT.md)
- Testing: `AxiomFramework/Documentation/Testing/`
- Examples: `AxiomFramework/Documentation/TDD/`
>>>>>>> framework

---

**DEVELOP Command Summary**:
- **Purpose**: Transform RFC requirements into tested code
- **Commands**: `build RFC-XXX` | `test [RFC-XXX]` | status
- **Process**: Red-Green-Refactor with mandatory refactoring
- **Input**: RFCs from Proposed/ with acceptance criteria
- **Output**: Working code passing all tests
- **Quality**: Zero broken tests, zero code smells
- **Boundaries**: Never modify requirements, no git operations

<<<<<<< HEAD
**DEVELOPMENT COMMAND STATUS**: RFC implementation with build and test commands
**CORE FOCUS**: Implement RFCs from Proposed/ directory using TDD methodology  
**COMMANDS**: `@DEVELOP build RFC-XXX` for implementation, `@DEVELOP test [RFC-XXX]` for testing  
**PROGRESS TRACKING**: RFC implementation checklists track completed tasks  
**TESTING REQUIREMENTS**: 100% test success rate required - NO EXCEPTIONS  
**TDD METHODOLOGY**: Kent Beck's Test-Driven Development by Example  
**REFACTORING APPROACH**: Martin Fowler's Refactoring catalog and principles  
**BUILD PROCESS**: Write failing test → Make it pass minimally → Refactor with confidence → Validate  
**TEST COMMAND**: Run framework tests or RFC-specific tests  
**QUALITY GATES**: All tests must pass before and after implementation  
**INTEGRATION**: Works with @PLAN for RFC lifecycle and @CHECKPOINT for ALL version control
**NO GIT OPERATIONS**: @DEVELOP only builds and tests - no commits, pushes, or merges

**Use @DEVELOP build RFC-XXX to implement RFCs with TDD, or @DEVELOP test to validate implementation.**
=======
### Expected RFC Format

DEVELOP protocol expects RFCs following the standard format defined in [RFC_FORMAT.md](./RFC_FORMAT.md).

**Key RFC Requirements for Implementation**:
- **Testable Acceptance Criteria**: Each requirement includes specific acceptance criteria
- **Test Boundaries**: Protocol definitions specify test boundaries and mock requirements  
- **TDD Implementation Checklist**: Red-Green-Refactor format for each component
- **Performance Targets**: Specific percentile requirements with test scenarios
- **Refactoring Opportunities**: Documented optimization and improvement strategies

**See [RFC_FORMAT.md](./RFC_FORMAT.md)** for complete RFC structure and format requirements.

This standardized format enables DEVELOP to extract acceptance criteria, test boundaries, and refactoring guidance directly from RFCs for implementation.
>>>>>>> framework
