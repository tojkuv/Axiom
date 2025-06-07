# PROTOCOLS_GENERATOR.md

Protocol generator specification for architectural development cycles.

## Protocol Generation Commands

### Individual Protocol Generation
```text
@PROTOCOLS_GENERATOR generate framework-plan      → Generate Framework PLAN protocol
@PROTOCOLS_GENERATOR generate framework-develop   → Generate Framework DEVELOP protocol  
@PROTOCOLS_GENERATOR generate framework-document  → Generate Framework DOCUMENT protocol
@PROTOCOLS_GENERATOR generate framework-analyze   → Generate Framework ANALYZE protocol
@PROTOCOLS_GENERATOR generate application-plan    → Generate Application PLAN protocol
@PROTOCOLS_GENERATOR generate application-develop → Generate Application DEVELOP protocol
@PROTOCOLS_GENERATOR generate application-analyze → Generate Application ANALYZE protocol
```

### Batch Protocol Generation
```text
@PROTOCOLS_GENERATOR generate all-framework   → Generate all Framework protocols
@PROTOCOLS_GENERATOR generate all-application → Generate all Application protocols
@PROTOCOLS_GENERATOR generate all             → Generate all protocols (Framework + Application)
```

### Protocol Specifications
- **framework-plan**: Creates Framework PLAN protocol for requirements gathering and cycle initiation
- **framework-develop**: Creates Framework DEVELOP protocol for TDD implementation with session tracking
- **framework-document**: Creates Framework DOCUMENT protocol for comprehensive architectural documentation
- **framework-analyze**: Creates Framework ANALYZE protocol for framework improvement insights
- **application-plan**: Creates Application PLAN protocol for Task Manager requirements
- **application-develop**: Creates Application DEVELOP protocol for Task Manager TDD implementation with framework documentation reference
- **application-analyze**: Creates Application ANALYZE protocol for framework validation through Task Manager

## Generation Principles
- **Deterministic**: Each protocol type generates consistent output from the same specifications
- **Hierarchical**: Maintains clear separation between workspace artifacts and codebase implementations
- **Cyclic**: Protocols follow the development cycle flow with proper input/output dependencies
- **Template-Driven**: All paths and patterns use resolvable template variables for portability

This generator is the single source of truth for Axiom protocol generation. All template variables are resolved using the Path Resolution Reference below.

## Path Resolution Reference

### Template Variable Resolutions
- `{{FRAMEWORK}}` → Framework
- `{{APPLICATION}}` → Application
- `{{FRAMEWORK_CODEBASE}}` → `/Users/tojkuv/Documents/GitHub/axiom-apple/workspace-framework/AxiomFramework`
- `{{APPLICATION_CODEBASE}}` → `/Users/tojkuv/Documents/GitHub/axiom-apple/workspace-application/AxiomApplications`
- `{{FRAMEWORK_WORKSPACE}}` → `/Users/tojkuv/Documents/GitHub/axiom-apple/workspace-meta-workspace/workspaces/FrameworkWorkspace`
- `{{APPLICATION_WORKSPACE}}` → `/Users/tojkuv/Documents/GitHub/axiom-apple/workspace-meta-workspace/workspaces/ApplicationWorkspace`

## File System Structure

### Workflow Artifacts Structure
```text
{{FRAMEWORK_WORKSPACE}}/
└── CYCLE-XXX-[TITLE]/
    ├── REQUIREMENTS-XXX-[TITLE].md
    ├── DOCUMENTATION-XXX.md
    ├── ANALYSIS-XXX.md
    └── SESSIONS/
        └── FW-SESSION-XXX.md

{{APPLICATION_WORKSPACE}}/
└── CYCLE-XXX-[TITLE]/
    ├── REQUIREMENTS-XXX-[TITLE].md
    ├── ANALYSIS-XXX.md
    └── SESSIONS/
        └── APP-SESSION-XXX.md
```

### Implementation Codebase Structure
```text
{{FRAMEWORK_CODEBASE}}/
└── [Framework implementation files]

{{APPLICATION_CODEBASE}}/
└── TaskManager-XXX-[TITLE]/
    └── [Task Manager implementation files]
```

## Development Cycle and Protocol Specifications

### Architecture Development Flow

The development cycle follows a continuous loop of framework improvement validated through Task Manager application development:

1. **Framework PLAN**
   - **Type**: Artifact-generating protocol (creates cycle folder)
   - **Input**: Optional Framework ANALYSIS from previous cycle
   - **Output**: `{{FRAMEWORK_WORKSPACE}}/CYCLE-XXX-[TITLE]/REQUIREMENTS-XXX-[TITLE].md`
   - **Features**: Interactive exploration and final revision phases

2. **Framework DEVELOP**
   - **Type**: Code-generating protocol (produces implementation + metrics)
   - **Input**: Framework REQUIREMENTS from cycle folder
   - **Output**: Updated implementation in `{{FRAMEWORK_CODEBASE}}/`
   - **Metrics**: `FW-SESSION-*.md` in SESSIONS folder
   - **Features**: Multi-session support, TDD approach, progress tracking

3. **Framework DOCUMENT**
   - **Type**: Artifact-generating protocol (one per cycle)
   - **Input**: Current framework implementation
   - **Output**: `DOCUMENTATION-XXX.md` in cycle folder
   - **Features**: Complete architectural specification

4. **Application PLAN**
   - **Type**: Artifact-generating protocol (creates cycle folder)
   - **Input**: Framework DOCUMENTATION from cycle folder
   - **Output**: `{{APPLICATION_WORKSPACE}}/CYCLE-XXX-[TITLE]/REQUIREMENTS-XXX-[TITLE].md`
   - **Features**: Task Manager requirements with framework integration focus

5. **Application DEVELOP**
   - **Type**: Code-generating protocol (produces implementation + metrics)
   - **Input**: Application REQUIREMENTS from cycle folder + Framework DOCUMENTATION from cycle folder
   - **Output**: Task Manager in `{{APPLICATION_CODEBASE}}/TaskManager-XXX-[TITLE]/`
   - **Metrics**: `APP-SESSION-*.md` in SESSIONS folder
   - **Features**: Multi-session support, TDD approach, progress tracking

6. **Application ANALYZE**
   - **Type**: Artifact-generating protocol
   - **Input**: Task Manager implementation + REQUIREMENTS + Documentation + session metrics
   - **Output**: `ANALYSIS-XXX.md` in Application cycle folder
   - **Features**: Aggregates session insights, identifies friction points

7. **Framework ANALYZE**
   - **Type**: Artifact-generating protocol
   - **Input**: Application ANALYSIS + current framework + session metrics
   - **Output**: `ANALYSIS-XXX.md` in Framework cycle folder
   - **Features**: Aggregates insights for next cycle

The cycle returns to step 1 with analysis insights driving continuous improvement.

## Protocol Structure Requirements

### Required Sections (All Protocols)

1. **Header**: Protocol name and trigger pattern
2. **Commands**: All available commands with syntax and outputs
3. **Core Process**: Linear flow with philosophy and workflow rule
4. **Format Specifications**: Complete templates (artifact protocols only)
5. **Workflow**: Detailed procedures and state management
6. **Technical Details**: Paths, validation, persistence requirements
7. **Error Handling**: Error types and recovery procedures

## Command Pattern Specifications

### Basic Command Pattern
```text
{{COMMAND}} {{ARGUMENTS}} → {{ACTION_DESCRIPTION}}
```

### Artifact-Generating Command Pattern
```text
{{COMMAND}} {{ARGUMENTS}} → {{ACTION}} + Generates {{ARTIFACT_TYPE}}
  - Uses: {{FORMAT_SPECIFICATION}}
  - Output: {{OUTPUT_PATH_PATTERN}}
```

### State-Tracking Command Pattern
```text
{{COMMAND}} {{IDENTIFIER}} → {{CONTINUATION_ACTION}}
  - Tracks: {{PROGRESS_LOCATION}}
  - Updates: {{STATE_REFERENCE}}
```

## Protocol Command Specifications

### Framework PLAN Protocol Commands (@framework-plan)

```text
create {{TITLE}} → Create framework requirements draft + Generates REQUIREMENTS-XXX-[TITLE].md
  - Creates: New cycle folder {{FRAMEWORK_WORKSPACE}}/CYCLE-XXX-[TITLE]/
  - Output: Framework requirements document with Draft status

explore {{DOCUMENT_ID}} → Interactive framework requirement exploration
  - Updates: Iterative refinement of framework requirements

accept {{DOCUMENT_ID}} {{SELECTIONS}} → Accept explored framework requirements
  - Updates: Framework requirement status to Accepted

finalize {{DOCUMENT_ID}} → Complete framework requirements + Updates REQUIREMENTS
  - Updates: Status to Approved with final revision
```

### Framework DEVELOP Protocol Commands (@framework-develop)

```text
start {{REQUIREMENTS_ID}} → Begin test-driven framework implementation
  - Creates: First framework session metrics file FW-SESSION-XXX.md
  - Tracks: Framework requirement checklist initialization

resume {{REQUIREMENTS_ID}} → Continue framework implementation
  - Creates: New framework session metrics file
  - Updates: Framework progress tracking

finalize {{REQUIREMENTS_ID}} → Optimize and complete framework
  - Updates: Final framework cleanup and optimization

test {{REQUIREMENTS_ID}} → Run complete framework test suite
  - Validates: All framework requirements met
```

### Framework DOCUMENT Protocol Commands (@framework-document)

```text
generate → Create comprehensive framework documentation
  - Scans: Entire framework codebase at {{FRAMEWORK_CODEBASE}}
  - Output: {{FRAMEWORK_WORKSPACE}}/CYCLE-XXX/DOCUMENTATION-XXX.md
  - Rule: One documentation artifact per framework cycle
```

### Framework ANALYZE Protocol Commands (@framework-analyze)

```text
generate → Create framework improvement analysis
  - Aggregates: Application analysis + framework session metrics
  - Output: {{FRAMEWORK_WORKSPACE}}/CYCLE-XXX/ANALYSIS-XXX.md

compare {{ID1}} {{ID2}} → Compare framework analysis reports
  - Output: Framework evolution between cycles
```

### Application PLAN Protocol Commands (@application-plan)

```text
create {{TITLE}} → Create Task Manager requirements + Generates REQUIREMENTS-XXX-[TITLE].md
  - Creates: New cycle folder {{APPLICATION_WORKSPACE}}/CYCLE-XXX-[TITLE]/
  - Input: Framework documentation from current cycle
  - Output: Task Manager requirements document with Draft status

explore {{DOCUMENT_ID}} → Interactive Task Manager requirement exploration
  - Updates: Iterative refinement of Task Manager features

accept {{DOCUMENT_ID}} {{SELECTIONS}} → Accept explored Task Manager requirements
  - Updates: Task Manager requirement status to Accepted

finalize {{DOCUMENT_ID}} → Complete Task Manager requirements
  - Updates: Status to Approved with final revision
```

### Application DEVELOP Protocol Commands (@application-develop)

```text
start {{REQUIREMENTS_ID}} → Begin test-driven Task Manager implementation
  - Creates: First application session metrics file APP-SESSION-XXX.md
  - Tracks: Task Manager requirement checklist initialization
  - References: Framework documentation from current cycle

resume {{REQUIREMENTS_ID}} → Continue Task Manager implementation
  - Creates: New application session metrics file
  - Updates: Task Manager progress tracking
  - References: Framework documentation for API usage

finalize {{REQUIREMENTS_ID}} → Optimize and complete Task Manager
  - Updates: Final Task Manager cleanup and optimization

test {{REQUIREMENTS_ID}} → Run complete Task Manager test suite
  - Validates: All Task Manager requirements met
```

### Application ANALYZE Protocol Commands (@application-analyze)

```text
generate {{TASK_MANAGER_PATH}} → Create Task Manager analysis report
  - Aggregates: Implementation + requirements + session metrics
  - Output: {{APPLICATION_WORKSPACE}}/CYCLE-XXX/ANALYSIS-XXX.md

compare {{ID1}} {{ID2}} → Compare Task Manager analysis reports
  - Output: Task Manager evolution between cycles
```

## Artifact Format Templates

### Framework Requirements Format (Framework PLAN Protocol)

```text
# {{DOCUMENT_ID}}: {{TITLE}}

{{METADATA_SECTION}}
- Identifier
- Title
- Status lifecycle
- Type classification
- Timestamps
- Dependencies

{{ABSTRACT_SECTION}}
- Purpose summary
- Scope definition
- Success criteria

{{MOTIVATION_SECTION}}
- Problem statement
- Solution rationale
- Expected outcomes

{{REQUIREMENT_SPECIFICATIONS_SECTION}}
For each requirement:
- Requirement definition
- Acceptance criteria
- Integration dependencies
- Performance targets

{{TDD_DEVELOPMENT_CHECKLIST_SECTION}}
For each requirement - implement through atomic TDD cycles:

### TDD Cycle 1: Core Functionality
- [ ] RED: Write failing test for basic functionality
- [ ] GREEN: Implement minimal code to pass test
- [ ] REFACTOR: Clean up if needed

### TDD Cycle 2: Input Validation
- [ ] RED: Write failing test for validation rules
- [ ] GREEN: Implement validation logic
- [ ] REFACTOR: Extract validation methods if needed

### TDD Cycle 3: Edge Cases
- [ ] RED: Write failing test for edge case
- [ ] GREEN: Handle edge case
- [ ] REFACTOR: Simplify conditional logic if needed

### TDD Cycle 4: Error Handling
- [ ] RED: Write failing test for error scenario
- [ ] GREEN: Implement error handling
- [ ] REFACTOR: Consolidate error handling patterns

### TDD Cycle 5: Integration Points
- [ ] RED: Write failing integration test
- [ ] GREEN: Implement integration
- [ ] REFACTOR: Optimize integration code if needed

### TDD Cycle 6: Performance
- [ ] RED: Write failing performance test
- [ ] GREEN: Meet performance requirements
- [ ] REFACTOR: Optimize further if possible

### Continuous Throughout Development
- [ ] Run all tests after each cycle
- [ ] Maintain test coverage > 90%
- [ ] Keep cycles small (< 10 minutes)
- [ ] Commit after each GREEN phase

{{TDD_IMPLEMENTATION_PLANNING_SECTION}}
- Atomic RED-GREEN-REFACTOR cycles (target: < 10 minutes each)
- One test at a time, one implementation at a time
- Commit after each GREEN phase
- Integration tests after feature cycles complete
- Continuous test execution with immediate feedback
- Test coverage monitored after each cycle

{{TEST_STRATEGY_SECTION}}
- Unit test requirements and patterns
- Integration test requirements
- Performance test requirements
- Acceptance test scenarios
- Continuous integration test runs

{{TRANSITION_SECTION}}
- Test migration strategy
- Backward compatibility testing
- Regression test planning

{{ALTERNATIVES_SECTION}}
- Evaluated options with test implications
- Testing complexity analysis
- Selection rationale based on testability

{{OPEN_ITEMS_SECTION}}
- Pending test definitions
- Unclear test scenarios
- Future test considerations

{{REFERENCES_SECTION}}
- Related test specifications
- Testing framework documentation
- External testing resources
```

### Application Requirements Format (Application PLAN Protocol)

```text
# {{DOCUMENT_ID}}: Task Manager Requirements

{{METADATA_SECTION}}
- Identifier
- Title  
- Status lifecycle
- Type classification
- Timestamps
- Framework documentation reference

{{ABSTRACT_SECTION}}
- Task Manager application purpose
- Framework validation through task management features
- Success criteria for framework integration

{{MOTIVATION_SECTION}}
- Framework capabilities validated through task management
- Consistent application type for cycle comparison
- Expected framework validation outcomes

{{CORE_TASK_FEATURES_SECTION}}
- Task creation and editing
- Task status management (pending/in-progress/completed)
- Task prioritization (high/medium/low)
- Task categorization and tagging
- Due date and reminder functionality
- Task search and filtering

{{TDD_DEVELOPMENT_CHECKLIST_SECTION}}
Each feature implemented through atomic TDD cycles:

### Feature: Task Creation
TDD Cycle 1: Basic task creation
- [ ] RED: Test creating task with title
- [ ] GREEN: Implement task creation
- [ ] REFACTOR: Extract task factory if needed

TDD Cycle 2: Task validation
- [ ] RED: Test validation rules
- [ ] GREEN: Add validation logic
- [ ] REFACTOR: Consolidate validation

TDD Cycle 3: Framework integration
- [ ] RED: Test task creation through framework
- [ ] GREEN: Integrate with framework state
- [ ] REFACTOR: Optimize state updates

### Feature: Task Status Management
TDD Cycle 1: Status transitions
- [ ] RED: Test pending → in-progress
- [ ] GREEN: Implement transition
- [ ] REFACTOR: Extract state machine if complex

TDD Cycle 2: Status constraints
- [ ] RED: Test invalid transitions
- [ ] GREEN: Add transition rules
- [ ] REFACTOR: Simplify rule engine

### Feature: Task List Display
TDD Cycle 1: Empty state
- [ ] RED: Test empty list display
- [ ] GREEN: Show empty state message
- [ ] REFACTOR: Extract empty state component

TDD Cycle 2: Basic list rendering
- [ ] RED: Test displaying tasks
- [ ] GREEN: Render task list
- [ ] REFACTOR: Optimize rendering

TDD Cycle 3: Sorting
- [ ] RED: Test sort by priority
- [ ] GREEN: Implement sorting
- [ ] REFACTOR: Extract sort logic

### Feature: Task Filtering
TDD Cycle 1: Filter by status
- [ ] RED: Test status filtering
- [ ] GREEN: Implement filter
- [ ] REFACTOR: Create reusable filter

TDD Cycle 2: Combined filters
- [ ] RED: Test multiple filters
- [ ] GREEN: Implement filter combination
- [ ] REFACTOR: Optimize filter performance

### Performance & Scale
TDD Cycle: Large task lists
- [ ] RED: Test with 1000 tasks
- [ ] GREEN: Optimize for performance
- [ ] REFACTOR: Implement virtualization if needed

{{FRAMEWORK_INTEGRATION_SECTION}}
For each framework component:
- Component integration in task management context
- State management for tasks
- UI component usage for task display
- Service integration for task persistence
- Navigation between task views

{{USER_INTERFACE_REQUIREMENTS_SECTION}}
- Task list view
- Task detail view
- Task creation/edit form
- Filter and search interface
- Statistics dashboard
- Settings screen

{{DATA_MODEL_SECTION}}
- Task entity structure
- Category/tag models
- User preferences model
- Task state transitions
- Data persistence requirements

{{FRAMEWORK_VALIDATION_SCENARIOS_SECTION}}
- CRUD operations through framework
- State management validation
- UI responsiveness testing
- Data flow verification
- Error handling scenarios
- Performance under task load

{{TDD_IMPLEMENTATION_PHASES_SECTION}}
Phase 1: Core Task Management
- Complete Task Creation feature (3-4 TDD cycles)
- Complete Task Status Management (2-3 TDD cycles)
- Complete Task List Display (3-4 TDD cycles)
- Integration test all core features

Phase 2: Task Organization
- Complete Task Categories feature (2-3 TDD cycles)
- Complete Task Filtering feature (3-4 TDD cycles)
- Complete Task Search feature (2-3 TDD cycles)
- Integration test organization features

Phase 3: Advanced Features
- Complete Due Dates feature (2-3 TDD cycles)
- Complete Reminders feature (3-4 TDD cycles)
- Complete Statistics Dashboard (4-5 TDD cycles)
- Performance test all features

Phase 4: UI Enhancements
- Complete Gesture Support (2-3 TDD cycles)
- Complete Keyboard Navigation (2-3 TDD cycles)
- Complete Accessibility Features (3-4 TDD cycles)
- Cross-platform testing

Phase 5: Production Readiness
- Complete Performance Optimization (2-3 TDD cycles)
- Complete Error Recovery (2-3 TDD cycles)
- Complete Offline Support (3-4 TDD cycles)
- Final test coverage verification

{{SUCCESS_METRICS_SECTION}}
- Framework API coverage in task features
- Task operation performance benchmarks
- UI responsiveness metrics
- Memory usage with large task lists
- Developer experience implementing tasks

{{OPEN_ITEMS_SECTION}}
- Framework limitations for task features
- Integration challenges specific to task management
- Future task management enhancements

{{REFERENCES_SECTION}}
- Framework documentation
- Previous Task Manager implementations
- Task management best practices
```

### Framework Analysis Format (Framework ANALYZE Protocol)

```text
# Analysis: {{ANALYSIS_SUBJECT}}

{{METADATA_SECTION}}
- Analysis identifier
- Analysis type classification
- Timestamp
- Cycle reference
- Duration metrics
- Test execution time

{{EXECUTIVE_SUMMARY}}
- Analysis overview
- Test coverage summary
- Quality metrics summary
- Key findings list
- Action priorities

{{TEST_METRICS_SECTIONS}}

### Test Coverage Metrics
- Unit test coverage percentage
- Integration test coverage
- Test case count by category
- Test execution time analysis
- Test failure rate trends

### Test Quality Metrics
- Test-to-code ratio
- Test complexity analysis
- Test maintainability score
- Test duplication analysis
- Test assertion density

### TDD Compliance Metrics
- Test-first development adherence
- Red-green-refactor cycle tracking
- Test commit patterns
- Pre-implementation test coverage

{{IMPLEMENTATION_METRICS_SECTIONS}}

### Code Quality Metrics
- Cyclomatic complexity
- Code coverage by tests
- Defect density
- Technical debt measurements

### Architecture Metrics
- Component testability score
- Dependency injection usage
- Mock/stub utilization
- Integration point analysis

### Performance Metrics
- Test suite execution time
- Performance test results
- Resource usage during tests
- Regression detection rate

{{FINDINGS_SECTIONS}}

### Testing Practice Analysis
- TDD adoption patterns
- Test antipattern identification
- Missing test scenarios
- Test improvement opportunities

### Implementation Quality Analysis
- Code maintainability issues
- Architecture testability concerns
- Integration complexity findings
- Performance bottlenecks

### Development Process Analysis
- Test-first compliance gaps
- Development velocity impact
- Quality gate effectiveness
- Continuous integration metrics

{{SESSION_AGGREGATION}}
- TDD session patterns
- Test creation velocity
- Test failure resolution time
- Common testing friction points
- Test refactoring frequency

{{RECOMMENDATIONS}}
- Test coverage improvements
- Testing practice enhancements
- Architecture testability changes
- Process optimization suggestions

{{APPENDICES}}
- Detailed test execution logs
- Coverage reports by component
- Test performance profiles
- Session-by-session test metrics
```

### Application Analysis Format (Application ANALYZE Protocol)

```text
# Analysis: Task Manager Implementation

{{METADATA_SECTION}}
- Analysis identifier
- Analysis type classification
- Timestamp
- Cycle reference
- Task Manager version reference
- Framework version tested

{{EXECUTIVE_SUMMARY}}
- Task Manager implementation overview
- Framework adoption success in task management context
- Integration challenges summary
- Key recommendations for framework improvement

{{FRAMEWORK_INTEGRATION_METRICS}}

### API Usage Analysis
- Framework APIs utilized
- API coverage percentage
- Usage patterns identified
- Missing API scenarios

### Integration Quality
- Setup complexity score
- Boilerplate code ratio
- Error handling coverage
- Framework idiom adoption

### Developer Experience
- Learning curve assessment
- Documentation gaps found
- API discoverability score
- Error message clarity

{{IMPLEMENTATION_METRICS}}

### Application Architecture
- Framework pattern compliance
- Component structure analysis
- State management approach
- Dependency injection usage

### Code Quality
- Test coverage metrics
- Code maintainability index
- Technical debt assessment
- Performance bottlenecks

### Feature Completeness
- Requirements coverage
- Feature implementation status
- Edge case handling
- User scenario coverage

{{FRICTION_ANALYSIS}}

### Development Friction Points
- Framework limitations encountered
- Workarounds implemented
- API gaps identified
- Integration pain points

### Testing Challenges
- Framework testability issues
- Mock/stub difficulties
- Test setup complexity
- CI/CD integration problems

### Performance Issues
- Framework overhead analysis
- Resource usage patterns
- Responsiveness metrics
- Scalability concerns

{{FRAMEWORK_FEEDBACK}}

### API Improvements
- Missing functionality
- Confusing interfaces
- Inconsistent patterns
- Enhancement suggestions

### Documentation Needs
- Unclear concepts
- Missing examples
- Tutorial requirements
- API reference gaps

### Tooling Requirements
- Developer tool needs
- Debugging capabilities
- Testing utilities
- Build system integration

{{RECOMMENDATIONS}}
- Priority framework improvements
- API enhancement proposals
- Documentation priorities
- Tooling investments

{{APPENDICES}}
- Detailed friction logs
- Performance profiles
- Code quality reports
- Session insights compilation
```

### Documentation Format (Framework DOCUMENT Protocol)

```text
# {{FRAMEWORK_NAME}} Documentation

{{METADATA_SECTION}}
- Generation timestamp
- Documentation version
- Status indicator
- Technology versions
- Platform targets
- Cycle reference
- Previous documentation reference

{{OVERVIEW_SECTION}}
- Executive summary
- Architecture overview
- Core design principles
- Technology stack summary
- Key capabilities

{{REQUIREMENTS_SECTION}}
- Technology requirements
- Platform requirements
- Development environment
- Dependencies

{{ARCHITECTURE_SECTIONS}}

### Core Architecture
- Architectural principles
- Component hierarchy diagram
- Layer responsibilities
- Communication patterns

### Component Specifications
For each core component:
- Component name and purpose
- Responsibilities
- Interface specification
- Dependencies
- Threading model
- Lifecycle management

### Data Flow Patterns
- State flow documentation
- Action flow documentation
- Error propagation patterns
- Timing requirements

### Concurrency Model
- Threading architecture
- Isolation boundaries
- Synchronization patterns
- Async operation handling

{{API_REFERENCE_SECTIONS}}

### Public APIs
For each public API:
- Interface definition
- Method signatures
- Parameter specifications
- Return value specifications
- Error conditions
- Usage examples

### Integration Points
- External service interfaces
- Extension points
- Plugin architecture
- Configuration APIs

{{IMPLEMENTATION_SECTIONS}}

### Implementation Guidelines
- Coding standards
- Architecture patterns
- Best practices
- Anti-patterns to avoid

### Performance Considerations
- Performance requirements
- Optimization strategies
- Profiling guidelines
- Resource management

### Testing Strategy
- Test architecture
- Test patterns
- Coverage requirements
- Integration test approach

{{APPENDICES}}

### Migration Guide
- Breaking changes
- Migration strategies
- Compatibility notes

### Glossary
- Term definitions
- Acronym expansions

### References
- Related specifications
- External dependencies
- Further reading
```

### Session Metrics Formats (DEVELOP Protocols)

#### Framework Session Format (Framework DEVELOP Protocol)
```text
## Framework Development Session: {{TIMESTAMP}}
- Duration tracking
- Requirement reference
- TDD cycle count
- Test-first compliance

### Test-Driven Development
- Tests written before implementation
- Red-green-refactor cycles completed
- Test coverage delta
- Failed test resolution time
- Test execution time trends

### Implementation Progress
- Requirements addressed via tests
- Test-guided refactoring
- Coverage improvement areas
- Test suite health metrics

### Technical Decisions
- Test design decisions
- Mock/stub strategy choices
- Test framework selections
- Coverage tool configurations

### Testing Challenges
- Difficult test scenarios
- Test flakiness issues
- Performance test challenges
- Integration test complexity

### Quality Evolution
- Test suite improvements
- Coverage trend analysis
- Test maintenance performed
- Test performance optimizations

### Session Metrics
- Tests added/modified/deleted
- Coverage before/after
- Test execution time
- Test failure rate
- TDD compliance percentage

### Next Steps
- Pending test scenarios
- Coverage gaps to address
- Test refactoring needs
- Performance test requirements
```

#### Application Session Format (Application DEVELOP Protocol)
```text
## Application Development Session: {{TIMESTAMP}}
- Duration tracking
- Feature reference
- TDD cycle count
- Test-first compliance

### Test-Driven Implementation
- Feature tests written first
- Acceptance test coverage
- Integration test development
- UI test automation progress
- Test pyramid adherence

### Framework Testing
- Framework API test coverage
- Mock/stub usage patterns
- Test helper utilization
- Framework-specific test challenges

### Testing Friction Points
- Framework testability issues
- Missing test utilities
- Complex setup requirements
- Test data management challenges

### Test Performance
- Test suite execution time
- Slow test identification
- Test parallelization success
- CI/CD test time impact

### Integration Test Metrics
- End-to-end test coverage
- Integration point testing
- External dependency mocking
- Test environment stability

### Session Quality Metrics
- Tests added/modified/deleted
- Feature coverage percentage
- Test execution statistics
- Defects found by tests
- TDD cycle efficiency

### Next Steps
- Missing test scenarios
- Test debt to address
- Test optimization opportunities
- Framework testing feedback
```
