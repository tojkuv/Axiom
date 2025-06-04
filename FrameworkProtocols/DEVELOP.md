# @DEVELOP.md - Axiom Framework Development Command

Framework development command with methodology, requirements, and execution procedures

## Automated Mode Trigger

**When human sends**: `@DEVELOP [optional-args]`
**Action**: Enter ultrathink mode and execute framework development workflow

### Usage Modes
- **`@DEVELOP build [RFC-XXX]`** → Execute TDD implementation with mandatory refactoring for RFC requirements
- **`@DEVELOP test [RFC-XXX]`** → Run tests for RFC implementation
- **`@DEVELOP`** → Show current RFC implementation status in Proposed/ directory

### Development Command Scope
**RFC Implementation**: Implement RFCs from Proposed/ directory with TDD methodology
**Build Command Mandate**: MANDATORY refactoring after every implementation cycle
**Progress Tracking**: Update RFC implementation checklists as tasks complete
**Quality Standards**: High test coverage with comprehensive success rates and code organization excellence
**Refactoring Requirement**: Build command MUST include refactoring - it's not complete without it
**Integration**: Works with @PLAN for RFC lifecycle and @CHECKPOINT for version control

### 🔄 **Test-Driven Development & Refactoring Workflow Architecture**
**IMPORTANT**: DEVELOP commands NEVER perform git operations (commit/push/merge)
**Version Control**: Only @CHECKPOINT commands handle all git operations
**Work Philosophy**: DEVELOP implements code → Refactor for quality → Multiple cycles → @CHECKPOINT commits and merges

TDD-enforced development workflow with MANDATORY refactoring (NO git operations):
1. **RFC Analysis**: Review RFC requirements and implementation checklist
2. **Test-First Development**: Write failing tests for RFC requirements (RED phase)
3. **Minimal Implementation**: Execute implementation to make tests pass (GREEN phase)
4. **Test Validation**: MANDATORY - All tests must pass before proceeding
5. **MANDATORY Refactoring Phase**: REQUIRED - Improve code structure (REFACTOR phase)
   - Eliminate code duplication through abstraction
   - Simplify complex logic while preserving behavior
   - Improve naming for clarity and consistency
   - Optimize file and module organization
   - Remove technical debt and dead code
6. **Quality Gate Validation**: ABSOLUTE REQUIREMENT - 100% test success after refactoring
7. **Structural Excellence**: Verify optimal organization and maintainability
8. **Final Validation**: Ensure functionality preservation and test success
9. **RFC Checklist Update**: Check off completed implementation items in RFC
**No Git Operations**: DEVELOP commands never commit, push, or merge

## Framework Development Philosophy

**Core Principle**: Framework development focuses on building type-safe, concurrency-safe, performant, deterministic iOS development framework with actor-based isolation, minimal boilerplate, and capabilities permissions for AI agent coding.

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

**Testing Requirements**: Framework development targets 100% test success rate with comprehensive test coverage. See `AxiomFramework/Documentation/Testing/TESTING_STRATEGY.md` for testing requirements and standards.

**Development Focus**: Framework development implements type-safe architecture, actor-based concurrency, performance optimization, deterministic behavior, code generation for minimal boilerplate, and capabilities permissions enforcement with consistent patterns.

**Structural Excellence**: Optimal code organization, minimal complexity, zero duplication, clear naming conventions, and architectural consistency.

**Code Integrity**: ZERO TOLERANCE for broken tests in main branch - development process designed to prevent test failures from reaching production.

## Framework Development Principles

### Architectural Integrity
- **Architectural Constraints**: Maintain adherence to foundational architectural patterns
- **Design Consistency**: Ensure consistent patterns and approaches across framework components
- **API Design**: Design intuitive and type-safe interfaces for framework consumers
- **Performance Focus**: Achieve performance targets while maintaining feature functionality
- **Thread Safety**: Implement actor-based isolation and concurrency patterns

### Core Technical Capabilities
- **Type Safety**: Build compile-time type validation and runtime safety guarantees
- **Concurrency Safety**: Develop actor-based isolation preventing data races
- **Performance Optimization**: Create measurable performance improvements and profiling
- **Deterministic Behavior**: Enable predictable, reproducible operations
- **Boilerplate Reduction**: Implement code generation through macros and builders

### Developer Experience
- **API Design**: Design framework interfaces that are intuitive and functional
- **Code Generation**: Minimize repetitive code through automation
- **Type Safety**: Provide compile-time guarantees and runtime safety
- **Error Handling**: Implement graceful degradation and error management
- **Documentation**: Ensure framework capabilities are documented and accessible

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

## Framework Development Methodology

### Phase 1: RFC Analysis (for build command)
1. **RFC Requirements Review** → Analyze RFC specifications and implementation checklist
2. **API Design Validation** → Ensure APIs match RFC interface specifications
3. **Performance Target Review** → Verify RFC performance requirements

### Phase 2: Implementation and Development
1. **Core Implementation** → Build framework capabilities using established patterns and principles
2. **Actor Integration** → Implement thread-safe patterns using actor-based isolation
3. **Protocol Design** → Create protocol hierarchies that support framework goals
4. **Capability Development** → Build runtime capability validation and management systems
5. **Capabilities Integration** → Integrate runtime permissions validation with compile-time hints

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

## 📊 Framework Development Categories

### **Core Framework Components**
- **AxiomClient** → Actor-based state management with single ownership patterns
- **AxiomContext** → Client orchestration and SwiftUI integration layer
- **AxiomView** → 1:1 view-context relationships with reactive binding
- **Capability System** → Runtime validation with compile-time optimization
- **Domain Models** → Immutable value objects with business logic integration
- **Capabilities System** → Runtime permissions validation with graceful degradation

### Technical Implementation Areas
- **Type System Design** → Compile-time validation and type-safe interfaces
- **Actor Isolation** → Thread-safe state management and concurrency patterns
- **Performance Profiling** → Measurement and optimization of framework performance
- **Code Generation** → Macro system reducing boilerplate and ensuring consistency
- **Permissions Validation** → Capability checking with compile-time optimization
- **Pattern Consistency** → Uniform patterns enabling reliable AI agent coding

### Refactoring Focus Areas
- **Code Organization** → Optimal file structure, module boundaries, and dependency management
- **Technical Debt Elimination** → Remove duplication, dead code, and complexity
- **Naming Consistency** → Standardize naming conventions across framework
- **Structural Improvements** → Enhance maintainability and readability
- **Interface Alignment** → Ensure APIs match architectural intentions
- **Functionality Preservation** → 100% behavioral compatibility during refactoring

### **Performance and Quality Systems**
- **Memory Management** → Efficient memory usage patterns and optimization
- **Concurrency Patterns** → Actor-based isolation and async/await integration
- **Error Handling** → Comprehensive error management and recovery
- **Type Safety** → Compile-time and runtime type validation
- **API Consistency** → Uniform interface design across framework components

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

## 🔬 Test-Driven Development Methodology

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
# Test validation (enforced by @DEVELOP)
if ! swift test; then
    echo "❌ DEVELOPMENT BLOCKED: Tests must pass before proceeding"
    exit 1
fi

# Integration readiness check
if ! swift test; then
    echo "❌ NOT READY: Tests must pass for @CHECKPOINT integration"
    exit 1
fi
```

## Development Success Criteria

**Architectural Compliance**: Type safety, concurrency safety through actors, performance targets, deterministic behavior, minimal boilerplate, capabilities permissions
**Technical Capabilities**: Type safety guarantees, actor-based concurrency, performance targets, deterministic behavior, minimal boilerplate
**Developer Experience**: Intuitive APIs, boilerplate reduction through code generation, type safety, clear error handling
**Structural Excellence**: Optimal code organization, minimal complexity, zero duplication, consistent patterns, clear module boundaries
**Testing Standards**: High test coverage, comprehensive test success rates, testing across all categories
**Refactoring Quality**: 100% functionality preservation, improved maintainability, reduced technical debt, enhanced readability
**Standards**: Success criteria in `AxiomFramework/Documentation/DEVELOPMENT_STANDARDS.md`

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

## 📚 Development Resources

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

## 🤖 Development Coordination

**RFC Implementation**: Implements RFCs from Proposed/ directory with TDD methodology
**RFC Selection**: @PLAN propose moves RFCs to Proposed/ for implementation
**Progress Tracking**: RFC implementation checklists track development progress
**Completion Criteria**: All RFC checklist items must be completed
**Activation Ready**: Completed RFCs can be activated via @PLAN activate

---

---

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