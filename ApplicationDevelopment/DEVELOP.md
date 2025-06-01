# @DEVELOP.md - Axiom Application Development Command

Application development command with methodology, requirements, and execution procedures

## Automated Mode Trigger

**When human sends**: `@DEVELOP [optional-args]`
**Action**: Enter ultrathink mode and execute application development workflow

### Usage Modes
- **`@DEVELOP`** → Auto-detect current context and execute application development workflow
- **`@DEVELOP plan`** → Plan application development tasks and priorities
- **`@DEVELOP build`** → Execute application build and testing cycle
- **`@DEVELOP test`** → Run application testing suite
- **`@DEVELOP validate`** → Application validation and integration testing

### Application Development Scope
**Application Focus**: Test application development, framework integration validation, user experience implementation
**Quality Standards**: High test coverage with comprehensive success rates
**Integration**: Integration with @PLAN, @CHECKPOINT, and application development workflows

### 🔄 **Test-Driven Development Git Workflow**
All ApplicationDevelopment commands follow this TDD-enforced workflow:
1. **Branch Setup**: Switch to `application` branch (create if doesn't exist)
2. **Update**: Pull latest changes from remote `application` branch
3. **Test-First Development**: Write failing tests before any implementation work
4. **Implementation**: Execute implementation to make tests pass
5. **Test Validation**: MANDATORY - All tests must pass before any commits
6. **Commit**: Commit changes to `application` branch with descriptive messages
7. **Pre-Merge Validation**: MANDATORY - Run complete test suite before merge
8. **Integration**: Merge `application` branch into `main` branch ONLY if all tests pass
9. **Deployment**: Push `main` branch to remote repository
10. **Cycle Reset**: Delete old `application` branch and create fresh one for next cycle

## Application Development Philosophy

**Core Principle**: Application development focuses on building test applications that demonstrate framework capabilities through practical implementation and user experience validation.

**Test-Driven Development Philosophy**: ALL application development MUST follow TDD methodology - tests written first, implementation follows, refactoring with passing tests.

**Quality Standards**: Application components maintain framework integration patterns, provide good user experience, and validate framework capabilities through real-world usage.

**Testing Requirements**: Application development targets 100% test success rate with comprehensive test coverage. See `AxiomTestApp/Documentation/Testing/TESTING_STRATEGY.md` for testing requirements and standards.

**Development Focus**: Application development implements features that demonstrate framework capabilities through user interfaces, business logic implementation, and integration validation.

**Code Integrity**: ZERO TOLERANCE for broken tests in main branch - development process designed to prevent test failures from reaching production.

## Application Development Principles

### Framework Integration
- **Architectural Patterns**: Implement applications using framework architectural constraints
- **Integration Consistency**: Ensure consistent framework usage patterns across application components
- **API Usage**: Demonstrate framework APIs through practical application implementation
- **Performance Validation**: Achieve application performance targets while demonstrating framework capabilities
- **Component Integration**: Implement framework components through application-level integration

### User Experience Implementation
- **Interface Design**: Build user interfaces that demonstrate framework capabilities effectively
- **Interaction Patterns**: Implement user interaction patterns that validate framework responsiveness
- **User Flow Implementation**: Create user workflows that exercise framework features comprehensively
- **Accessibility Implementation**: Ensure application accessibility while demonstrating framework capabilities
- **Performance Optimization**: Optimize application performance through framework pattern usage

### Application Testing
- **Integration Testing**: Test application integration with framework components and capabilities
- **User Experience Testing**: Validate user experience and interface functionality
- **Performance Testing**: Test application performance and framework performance validation
- **Framework Validation**: Validate framework capabilities through application usage patterns
- **Documentation Validation**: Ensure application implementation matches framework documentation

### Testing Standards
**Requirements**: High test coverage, comprehensive test success rates, multiple test categories
**Standards**: See `AxiomTestApp/Documentation/Testing/TESTING_STRATEGY.md` for detailed testing methodology and requirements

## Application Development Methodology

### Phase 1: Application Design and Planning
1. **Requirement Analysis** → Understand application development needs and framework validation goals
2. **Design Planning** → Design application features that demonstrate framework capabilities
3. **Integration Design** → Create application architecture that validates framework patterns
4. **User Experience Planning** → Establish user experience targets and validation strategies
5. **Testing Planning** → Plan comprehensive application testing and framework validation

### Phase 2: Implementation and Development
1. **Core Implementation** → Build application features using framework patterns and principles
2. **Framework Integration** → Implement framework components through application-level usage
3. **User Interface Implementation** → Create user interfaces that demonstrate framework capabilities
4. **Business Logic Implementation** → Build application logic that validates framework patterns
5. **Performance Implementation** → Implement application features with performance validation

### Phase 3: Test-Driven Development and Validation
**TDD Requirements**: ALL application development must follow test-driven development methodology
**Testing Standards**: 100% test success rate - NO EXCEPTIONS for commits to main branch
**Testing Strategy**: Multi-layered validation including unit, integration, user experience, performance, and framework validation testing
**Standards**: Detailed testing requirements in `AxiomTestApp/Documentation/Testing/TESTING_STRATEGY.md`
**CRITICAL RULE**: Test failures COMPLETELY BLOCK all application development progress until resolved
**TDD Process**: Write failing tests → Implement minimal code → Make tests pass → Refactor → Repeat

### Phase 4: Documentation and Integration
1. **Usage Documentation** → Document application implementation patterns and framework usage
2. **Integration Documentation** → Update framework integration guides with application examples
3. **Performance Documentation** → Document application performance characteristics and framework validation
4. **User Experience Documentation** → Create user experience guides and validation examples
5. **Quality Review** → Final review to ensure application meets framework validation standards

## Application Development Categories

### Framework Integration Components
- **AxiomClient Usage** → Application-level actor-based state management implementation
- **AxiomContext Implementation** → Context orchestration and SwiftUI integration demonstration
- **AxiomView Integration** → View-context relationships with reactive binding validation
- **Capability System Usage** → Runtime validation demonstration with application-level examples
- **Domain Model Implementation** → Application domain models with framework pattern validation
- **Intelligence System Integration** → AI-powered features demonstrated through application usage

### User Experience Components
- **Interface Implementation** → User interface components that demonstrate framework capabilities
- **Interaction Validation** → User interaction patterns that validate framework responsiveness
- **Navigation Implementation** → Application navigation demonstrating framework integration patterns
- **Data Presentation** → Data display components that validate framework state management
- **User Input Handling** → Input components that demonstrate framework validation capabilities
- **Error Handling Implementation** → User-facing error handling that validates framework error management

### Application Validation Systems
- **Performance Monitoring** → Application-level performance measurement and framework validation
- **Integration Testing** → Application testing that validates framework integration patterns
- **User Experience Validation** → Application usability testing and framework capability demonstration
- **Framework Pattern Validation** → Application implementation that validates framework architectural patterns
- **Documentation Validation** → Application examples that validate framework documentation accuracy

## Testing Integration

**Testing Framework**: Multi-layered testing strategy covering application components and framework integration
**Testing Categories**: Unit, integration, user experience, performance, framework validation, and regression testing
**Testing Standards**: Testing specifications available in `AxiomTestApp/Documentation/Testing/TESTING_STRATEGY.md`
**Integration**: Testing requirements integrated into application development workflow

## 🚨 MANDATORY Test Requirements

**ABSOLUTE REQUIREMENT**: 100% test success rate for ANY commit to main branch - NO EXCEPTIONS
**TDD ENFORCEMENT**: All application development MUST follow test-driven development methodology
**BLOCKING BEHAVIOR**: Test failures IMMEDIATELY halt ALL application development work until resolved
**Quality Gate**: NO code reaches main branch without passing ALL tests
**Resolution Process**: STOP EVERYTHING → identify cause → fix failure → verify ALL tests pass → continue
**Pre-Commit Validation**: Every commit MUST run complete test suite
**Pre-Merge Validation**: Every merge to main MUST pass complete test suite
**Standards**: Testing requirements in `AxiomTestApp/Documentation/Testing/TESTING_STRATEGY.md`

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
- **ALL tests must pass before ANY commit to application branch**
- **ALL tests must pass before ANY merge to main branch**

**Quality Gate Automation**:
```bash
# Pre-commit hook (automatically enforced)
if ! xcodebuild test -scheme ExampleApp -destination 'platform=iOS Simulator,name=iPhone 15' -quiet; then
    echo "❌ COMMIT BLOCKED: Tests must pass before commit"
    exit 1
fi

# Pre-merge validation (automatically enforced)
if ! xcodebuild test -scheme ExampleApp -destination 'platform=iOS Simulator,name=iPhone 15' -quiet; then
    echo "❌ MERGE BLOCKED: Tests must pass before merge to main"
    exit 1
fi
```

## Application Development Success Criteria

**Framework Integration**: Proper framework pattern usage, functional API demonstration, framework capability validation
**User Experience**: Intuitive application interfaces, effective framework capability demonstration, user experience validation
**Application Implementation**: Robust application features, framework integration validation, performance demonstration
**Testing Standards**: High test coverage, comprehensive test success rates, testing across all categories
**Standards**: Success criteria in `AxiomTestApp/Documentation/Development/DEVELOPMENT_STANDARDS.md`

## Application Development Execution Loop

**Command**: `@DEVELOP [plan|build|test|validate]`
**Action**: Execute comprehensive application development workflow with methodology enforcement

### 🔄 **Branch Verification and Setup**

**Before executing any development work, execute this branch verification:**

```bash
# 1. MANDATORY: Verify all tests pass on current branch before any work
echo "🧪 MANDATORY: Running complete test suite validation..."
cd AxiomExampleApp
if ! xcodebuild test -scheme ExampleApp -destination 'platform=iOS Simulator,name=iPhone 15' -quiet; then
    echo "❌ CRITICAL: Tests are failing on current branch"
    echo "🚨 BLOCKING: All development work MUST stop until tests pass"
    echo "🔧 Required action: Fix failing tests before proceeding"
    exit 1
fi
echo "✅ Test suite passed - safe to proceed"
cd ..

# 2. Check current branch and switch to application branch if needed
CURRENT_BRANCH=$(git branch --show-current)
echo "🎯 Current branch: $CURRENT_BRANCH"

if [ "$CURRENT_BRANCH" != "application" ]; then
    echo "🔄 Switching from $CURRENT_BRANCH to application branch..."
    
    # Check if application branch exists
    if git show-ref --verify --quiet refs/heads/application; then
        echo "📍 Application branch exists locally, switching..."
        git checkout application
    elif git show-ref --verify --quiet refs/remotes/origin/application; then
        echo "📍 Application branch exists remotely, checking out..."
        git checkout -b application origin/application
    else
        echo "🌱 Creating new application branch..."
        git checkout -b application
        git push origin application -u
    fi
    
    echo "✅ Now on application branch"
else
    echo "✅ Already on application branch"
fi

# 3. Update application branch with latest changes
echo "🔄 Updating application branch..."
git fetch origin application 2>/dev/null || true
git pull origin application 2>/dev/null || echo "📍 No remote updates available"

# 4. MANDATORY: Verify all tests pass after branch update
echo "🧪 MANDATORY: Re-validating test suite after branch update..."
cd AxiomExampleApp
if ! xcodebuild test -scheme ExampleApp -destination 'platform=iOS Simulator,name=iPhone 15' -quiet; then
    echo "❌ CRITICAL: Tests failing after branch update"
    echo "🚨 BLOCKING: Development cannot proceed with failing tests"
    echo "🔧 Required action: Fix failing tests before any development work"
    exit 1
fi
echo "✅ All tests passing - application development ready"
cd ..

echo "🎯 Branch verification and test validation complete - ready for TDD application development"
```

**Test-Driven Automated Execution Process**:
1. **Branch Verification** → Switch to `application` branch and update with latest changes
2. **Environment Validation** → Verify clean working tree, application dependencies
3. **Test Suite Validation** → MANDATORY - Run complete test suite and verify 100% pass rate
4. **Planning Integration** → Reference current TRACKING application priorities and @PLAN outputs
5. **TDD Methodology Enforcement** → Apply test-driven development principles and framework integration patterns
6. **Test-First Development** → Write failing tests before any implementation work
7. **Implementation Cycle** → Implement minimal code to make tests pass
8. **Test Validation** → MANDATORY - All tests must pass before any commits
9. **Build and Test Cycle** → Execute application build, test with coverage requirements
10. **Quality Gate Validation** → ABSOLUTE REQUIREMENT - 100% test success rate before any progression
11. **Documentation Updates** → Update application documentation and integration guides
12. **TRACKING.md Progress Update** → Update implementation progress in ApplicationDevelopment/TRACKING.md
13. **Pre-Merge Test Validation** → MANDATORY - Complete test suite must pass before merge to main
14. **Coordination Updates** → Provide progress updates and framework validation results

**Test-Driven Application Development Execution Examples**:
- `@DEVELOP plan` → Plan application development priorities with test-first approach
- `@DEVELOP build` → Execute TDD cycle: write tests → implement → validate
- `@DEVELOP test` → Run comprehensive application testing with 100% pass requirement
- `@DEVELOP validate` → Application validation and framework integration with test-driven verification

## Application Development Workflow Integration

**Planning**: Integrates with @PLAN for application development task planning and priority coordination
**TDD Execution**: Test-first development → implementation → validation → framework integration → documentation cycle
**ABSOLUTE RULE**: ANY test failure IMMEDIATELY blocks ALL application development work until resolved
**Quality Gate**: NO code progression without 100% test success rate
**Pre-Commit Requirement**: ALL commits must pass complete test suite
**Pre-Merge Requirement**: ALL merges to main must pass complete test suite
**Documentation**: Work details tracked in `/AxiomTestApp/Documentation/` only
**Coordination**: Integration with @CHECKPOINT for application development cycle completion

## Application Development Resources

**Application Architecture**: Framework integration patterns, user experience guidelines, performance targets, validation principles
**Development Infrastructure**: Application testing framework, performance monitoring, documentation systems, validation tools
**Resources**: Complete application development resources in `AxiomTestApp/Documentation/Development/`

## Application Development Coordination

**Branch Focus**: Application development and framework integration validation in application branch
**Work Storage**: Application development work tracked in `/AxiomTestApp/Documentation/` only
**Planning Integration**: @PLAN command provides contextual application development planning
**Coordination**: Application development operation with framework validation and progress coordination

---

**APPLICATION DEVELOPMENT COMMAND STATUS**: Application development command with methodology, requirements, and execution procedures
**CORE FOCUS**: Application development with framework integration validation and automated workflow implementation  
**AUTOMATION**: Supports `@DEVELOP [plan|build|test|validate]` with execution procedures  
**TESTING REQUIREMENTS**: 100% test success rate and comprehensive test coverage required - NO EXCEPTIONS  
**TDD ENFORCEMENT**: Test-driven development methodology mandatory for all application development  
**QUALITY GATES**: Automated test validation prevents broken code from reaching main branch  
**INTEGRATION**: Workflow integration with @PLAN, @CHECKPOINT, and application development coordination

**Use @DEVELOP for test-driven application development with framework integration validation and automated methodology implementation.**