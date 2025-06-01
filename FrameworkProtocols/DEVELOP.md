# @DEVELOP.md - Axiom Framework Development Command

Framework development command with methodology, requirements, and execution procedures

## Automated Mode Trigger

**When human sends**: `@DEVELOP [optional-args]`
**Action**: Enter ultrathink mode and execute framework development workflow

### Usage Modes
- **`@DEVELOP`** → Auto-detect current context and execute development workflow
- **`@DEVELOP plan`** → Plan development tasks and priorities
- **`@DEVELOP build`** → Execute development build and testing cycle
- **`@DEVELOP test`** → Run testing suite
- **`@DEVELOP optimize`** → Performance optimization and analysis

### Development Command Scope
**Framework Focus**: Core framework development, architecture enhancement, capability implementation
**Quality Standards**: High test coverage with comprehensive success rates
**Integration**: Integration with @PLAN, @CHECKPOINT, and @REFACTOR workflows

### 🔄 **Test-Driven Development Workflow Architecture**
**IMPORTANT**: DEVELOP commands NEVER perform git operations (commit/push/merge)
**Version Control**: Only @CHECKPOINT commands handle all git operations
**Work Philosophy**: DEVELOP implements code → Multiple DEVELOP/REFACTOR cycles → @CHECKPOINT commits and merges

TDD-enforced development workflow (NO git operations):
1. **Test-First Development**: Write failing tests before any implementation work
2. **Implementation**: Execute implementation to make tests pass
3. **Test Validation**: MANDATORY - All tests must pass before any work completion
4. **Quality Gate Validation**: ABSOLUTE REQUIREMENT - 100% test success rate
5. **Documentation Updates**: Update technical documentation and API references
6. **TRACKING.md Progress Update**: Update implementation progress tracking
**No Git Operations**: DEVELOP commands never commit, push, or merge

## Framework Development Philosophy

**Core Principle**: Framework development focuses on building iOS development capabilities that integrate architectural analysis with intelligent system features.

**Test-Driven Development Philosophy**: ALL framework development MUST follow TDD methodology - tests written first, implementation follows, refactoring with passing tests.

**Quality Standards**: Framework components maintain architectural integrity, meet performance targets, provide good developer experience, and integrate with framework capabilities.

**Testing Requirements**: Framework development targets 100% test success rate with comprehensive test coverage. See `AxiomFramework/Documentation/Testing/TESTING_STRATEGY.md` for testing requirements and standards.

**Development Focus**: Framework development implements capabilities that enhance iOS development through AI integration, predictive analysis, and intelligent automation features.

**Code Integrity**: ZERO TOLERANCE for broken tests in main branch - development process designed to prevent test failures from reaching production.

## Framework Development Principles

### Architectural Integrity
- **Architectural Constraints**: Maintain adherence to foundational architectural patterns
- **Design Consistency**: Ensure consistent patterns and approaches across framework components
- **API Design**: Design intuitive and type-safe interfaces for framework consumers
- **Performance Focus**: Achieve performance targets while maintaining feature functionality
- **Thread Safety**: Implement actor-based isolation and concurrency patterns

### Intelligence Capability Development
- **AI Integration**: Build artificial intelligence capabilities into framework core
- **Predictive Analysis**: Develop features that identify and prevent issues
- **Optimization Systems**: Create analysis-driven optimization and improvement systems
- **Natural Language Processing**: Enable architectural queries and analysis through text interface
- **Pattern Detection**: Implement pattern recognition and standardization capabilities

### Developer Experience
- **API Design**: Design framework interfaces that are intuitive and functional
- **Code Generation**: Minimize repetitive code through automation
- **Type Safety**: Provide compile-time guarantees and runtime safety
- **Error Handling**: Implement graceful degradation and error management
- **Documentation**: Ensure framework capabilities are documented and accessible

### Testing Standards
**Requirements**: High test coverage, comprehensive test success rates, multiple test categories
**Standards**: See `AxiomFramework/Documentation/Testing/TESTING_STRATEGY.md` for detailed testing methodology and requirements

## Framework Development Methodology

### Phase 1: Architecture and Design
1. **Requirement Analysis** → Understand framework enhancement needs and architectural goals
2. **Design Planning** → Design new capabilities that align with architectural constraints
3. **API Design** → Create intuitive interfaces for framework consumers
4. **Performance Planning** → Establish performance targets and optimization strategies
5. **Integration Planning** → Ensure new capabilities integrate with existing framework

### Phase 2: Implementation and Development
1. **Core Implementation** → Build framework capabilities using established patterns and principles
2. **Actor Integration** → Implement thread-safe patterns using actor-based isolation
3. **Protocol Design** → Create protocol hierarchies that support framework goals
4. **Capability Development** → Build runtime capability validation and management systems
5. **Intelligence Integration** → Integrate AI and ML capabilities into framework operations

### Phase 3: Test-Driven Development and Validation
**TDD Requirements**: ALL development must follow test-driven development methodology
**Testing Standards**: 100% test success rate - NO EXCEPTIONS for commits to main branch
**Testing Strategy**: Multi-layered validation including unit, integration, performance, AI/ML, security, and concurrency testing
**Standards**: Detailed testing requirements in `AxiomFramework/Documentation/Testing/TESTING_STRATEGY.md`
**CRITICAL RULE**: Test failures COMPLETELY BLOCK all development progress until resolved
**TDD Process**: Write failing tests → Implement minimal code → Make tests pass → Refactor → Repeat

### **Phase 4: Documentation and Polish**
1. **API Documentation** → Document all public interfaces with comprehensive examples
2. **Architecture Documentation** → Update technical specifications with new capabilities
3. **Performance Documentation** → Document performance characteristics and optimization strategies
4. **Integration Guides** → Create guidance for framework consumers using new capabilities
5. **Quality Review** → Final review to ensure framework meets excellence standards

## 📊 Framework Development Categories

### **Core Framework Components**
- **AxiomClient** → Actor-based state management with single ownership patterns
- **AxiomContext** → Client orchestration and SwiftUI integration layer
- **AxiomView** → 1:1 view-context relationships with reactive binding
- **Capability System** → Runtime validation with compile-time optimization
- **Domain Models** → Immutable value objects with business logic integration
- **Intelligence System** → AI-powered architectural analysis and optimization

### Intelligence Capability Areas
- **Component Introspection** → Component analysis and documentation generation systems
- **Predictive Analysis** → Issue identification and architectural analysis
- **Natural Language Queries** → Text-based architectural exploration interface
- **Performance Optimization** → Analysis-driven optimization recommendations
- **Pattern Detection** → Pattern recognition and standardization capabilities
- **Architecture Evolution** → Requirements-based architecture adaptation

### **Performance and Quality Systems**
- **Memory Management** → Efficient memory usage patterns and optimization
- **Concurrency Patterns** → Actor-based isolation and async/await integration
- **Error Handling** → Comprehensive error management and recovery
- **Type Safety** → Compile-time and runtime type validation
- **API Consistency** → Uniform interface design across framework components

## Testing Integration

**Testing Framework**: Multi-layered testing strategy covering framework components
**Testing Categories**: Unit, integration, performance, AI/ML, security, concurrency, and regression testing
**Testing Standards**: Testing specifications available in `AxiomFramework/Documentation/Testing/TESTING_STRATEGY.md`
**Integration**: Testing requirements integrated into development workflow

## 🚨 MANDATORY Test Requirements

**ABSOLUTE REQUIREMENT**: 100% test success rate for ANY commit to main branch - NO EXCEPTIONS
**TDD ENFORCEMENT**: All development MUST follow test-driven development methodology
**BLOCKING BEHAVIOR**: Test failures IMMEDIATELY halt ALL development work until resolved
**Quality Gate**: NO code reaches main branch without passing ALL tests
**Resolution Process**: STOP EVERYTHING → identify cause → fix failure → verify ALL tests pass → continue
**Pre-Commit Validation**: Every commit MUST run complete test suite
**Pre-Merge Validation**: Every merge to main MUST pass complete test suite
**Standards**: Testing requirements in `AxiomFramework/Documentation/Testing/TESTING_STRATEGY.md`

## 🔬 Test-Driven Development Methodology

**TDD Cycle (RED-GREEN-REFACTOR)**:
1. **RED**: Write a failing test that describes the desired functionality
2. **GREEN**: Write the minimal code necessary to make the test pass
3. **REFACTOR**: Improve the code while keeping all tests passing
4. **REPEAT**: Continue cycle for each new feature or change

**TDD Enforcement Rules**:
- **NEVER write production code without a failing test first**
- **NEVER write more test code than sufficient to make a test fail**
- **NEVER write more production code than sufficient to make the test pass**
- **ALL tests must pass before ANY commit to framework branch**
- **ALL tests must pass before ANY merge to main branch**

**Quality Gate Automation**:
```bash
# Pre-commit hook (automatically enforced)
if ! swift test; then
    echo "❌ COMMIT BLOCKED: Tests must pass before commit"
    exit 1
fi

# Pre-merge validation (automatically enforced)
if ! swift test; then
    echo "❌ MERGE BLOCKED: Tests must pass before merge to main"
    exit 1
fi
```

## Development Success Criteria

**Architectural Compliance**: Adherence to 8 architectural constraints, consistent design patterns, functional API design, performance targets achieved
**Intelligence Capabilities**: AI features providing analysis value, predictive issue identification, optimization recommendations
**Developer Experience**: Intuitive APIs, boilerplate reduction through code generation, type safety, clear error handling
**Testing Standards**: High test coverage, comprehensive test success rates, testing across all categories
**Standards**: Success criteria in `AxiomFramework/Documentation/DEVELOPMENT_STANDARDS.md`

## 🤖 Development Execution Loop

**Command**: `@DEVELOP [plan|build|test|optimize]`
**Action**: Execute comprehensive development workflow with methodology enforcement

### 🔄 **Test-Driven Development Execution Process**

**CRITICAL**: DEVELOP commands work on current branch state - NO git operations

```bash
# Branch switching - Create fresh framework branch before starting work
echo "🔄 Creating fresh framework branch..."
ORIGINAL_BRANCH=$(git branch --show-current)
echo "📍 Current branch: $ORIGINAL_BRANCH"

# Delete existing framework branch if it exists
if git show-ref --verify --quiet refs/heads/framework; then
    echo "🗑️ Deleting existing framework branch..."
    if [ "$ORIGINAL_BRANCH" = "framework" ]; then
        git checkout main
    fi
    git branch -D framework 2>/dev/null || true
    git push origin --delete framework 2>/dev/null || true
fi

# Create fresh framework branch
echo "🌱 Creating fresh framework branch..."
git checkout -b framework
echo "✅ Fresh framework branch created and active"

# Test-driven development workflow (NO git operations)
echo "🧪 MANDATORY: Running complete test suite validation..."
cd AxiomFramework
if ! swift test; then
    echo "❌ CRITICAL: Tests are failing on current branch"
    echo "🚨 BLOCKING: All development work MUST stop until tests pass"
    echo "🔧 Required action: Fix failing tests before proceeding"
    # Stay on framework branch even on failure for debugging
    cd ..
    echo "❗ Staying on framework branch for debugging"
    exit 1
fi
echo "✅ Test suite passed - safe to proceed with TDD framework development"
echo "📍 Working on current branch: $(git branch --show-current)"
echo "⚠️ Version control managed by @CHECKPOINT only"
cd ..
```

**Test-Driven Automated Execution Process**:
1. **Test Suite Validation** → MANDATORY - Run complete test suite and verify 100% pass rate
2. **Planning Integration** → Reference current TRACKING development priorities and @PLAN outputs
3. **TDD Methodology Enforcement** → Apply test-driven development principles and architectural constraints
4. **Test-First Development** → Write failing tests before any implementation work
5. **Implementation Cycle** → Implement minimal code to make tests pass
6. **Test Validation** → MANDATORY - All tests must pass before work completion
7. **Build and Test Cycle** → Execute swift build, swift test with coverage requirements
8. **Quality Gate Validation** → ABSOLUTE REQUIREMENT - 100% test success rate before any progression
9. **Documentation Updates** → Update technical documentation and API references
10. **TRACKING.md Progress Update** → Update implementation progress in FrameworkProtocols/TRACKING.md
11. **Coordination Updates** → Provide progress updates and next steps
**No Git Operations**: All version control handled by @CHECKPOINT commands only
**Branch Management**: Work remains on framework branch for @CHECKPOINT integration

**Test-Driven Development Execution Examples**:
- `@DEVELOP plan` → Plan development priorities with test-first approach
- `@DEVELOP build` → Execute TDD cycle: write tests → implement → validate
- `@DEVELOP test` → Run comprehensive testing with 100% pass requirement
- `@DEVELOP optimize` → Performance optimization with test-driven validation

## 🔄 Development Workflow Integration

**Planning**: Integrates with @PLAN for development task planning and priority coordination
**TDD Execution**: Test-first development → implementation → validation → optimization → documentation cycle
**ABSOLUTE RULE**: ANY test failure IMMEDIATELY blocks ALL development work until resolved
**Quality Gate**: NO code progression without 100% test success rate
**Pre-Commit Requirement**: ALL commits must pass complete test suite
**Pre-Merge Requirement**: ALL merges to main must pass complete test suite
**Documentation**: Work details tracked in `/AxiomFramework/Documentation/` only
**Coordination**: Seamless integration with @CHECKPOINT for development cycle completion

## 📚 Development Resources

**Framework Architecture**: 8 architectural constraints, 8 intelligence systems, performance targets, API design principles
**Development Infrastructure**: Testing framework, performance monitoring, documentation systems, quality tools
**Resources**: Complete development resources in `AxiomFramework/Documentation/Development/`

## 🤖 Development Coordination

**Branch Focus**: Dedicated framework core development and enhancement in development branch
**Work Storage**: Development work tracked in `/AxiomFramework/Documentation/` only
**Planning Integration**: @PLAN command provides contextual development planning
**Coordination**: Independent development operation with cross-branch progress sharing

---

---

**DEVELOPMENT COMMAND STATUS**: Development command with methodology, requirements, and execution procedures
**CORE FOCUS**: Framework development with automated workflow implementation  
**AUTOMATION**: Supports `@DEVELOP [plan|build|test|optimize]` with execution procedures  
**TESTING REQUIREMENTS**: 100% test success rate and comprehensive test coverage required - NO EXCEPTIONS  
**TDD ENFORCEMENT**: Test-driven development methodology mandatory for all framework development  
**QUALITY GATES**: Automated test validation prevents broken code from reaching main branch  
**INTEGRATION**: Workflow integration with @PLAN, @CHECKPOINT, and development coordination

**Use @DEVELOP for test-driven framework development with automated methodology implementation and execution.**