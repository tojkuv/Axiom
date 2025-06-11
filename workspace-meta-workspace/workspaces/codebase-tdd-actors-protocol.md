# CODEBASE-TDD-ACTORS-PROTOCOL

Execute rapid test-driven development cycles for parallel-worker codebase development after provisioner completes foundational requirements. Produces session artifacts optimized for MVP delivery with worker-isolated quality validation. Supports 2-8 parallel TDD actors operating on isolated requirement folders, ensuring quality within worker scope while documenting integration points for stabilizer.

## Protocol Activation

```text
@CODEBASE_TDD_ACTORS execute <codebase_directory> <worker_directory> <session_template>
```

**Parameters:**
- `<codebase_directory>`: Path to directory containing source code to develop
- `<worker_directory>`: Path to worker's isolated directory containing requirements and for storing session artifacts
- `<session_template>`: Path to TDD actor session template

**Prerequisites**: Provisioner requirements must be completed before actors begin

**EXPLICITLY EXCLUDED FROM PARALLEL DEVELOPMENT (MVP FOCUS):**
- Version control integration (development focuses on current codebase state)
- Database versioning considerations (work with current schema)
- Migration pathway development (no migration concerns for MVP)
- Deprecation management (we fix problems, don't deprecate)
- Legacy code preservation (transform code, don't preserve obsolete patterns)
- Backward compatibility constraints (no compatibility limitations)
- Breaking change mitigation (breaking changes welcomed for MVP clarity)
- Semantic versioning enforcement (MVP operates on current iteration)
- API stability preservation across versions (APIs evolve for MVP optimization)
- Configuration migration support (use current configuration)
- Deployment versioning concerns (deploy current state)
- Release management integration (continuous MVP iteration)
- Rollback procedures (no rollback concerns for MVP)
- Multi-version support (single current version)

**Parallel-Worker Isolated Development Philosophy:**
- Zero compatibility constraints - breaking changes welcomed for MVP clarity
- No versioning considerations - focus purely on current MVP needs  
- No migration paths - optimize for simplicity over backward compatibility
- Fix don't deprecate - transform problematic code into better solutions
- Active improvement mindset - every problem gets fixed, not marked obsolete
- Parallel worker isolation - each worker operates on isolated requirements folder
- Workers unaware of each other - complete development independence
- Folder-specific development cycles - no cross-folder coordination or dependencies
- Worker-scoped validation - build and test validation within worker's changes only
- Aggressive development with isolated quality checks
- Zero tolerance for errors within worker's scope
- Session artifact generation - records documenting worker's isolated development
- Integration documentation - capture dependencies and API changes for stabilizer
- Direct execution from folder's development cycle index

## Command

### Execute - Parallel Worker TDD Development from Folder Requirements

The execute command performs isolated parallel-worker TDD development with worker-scoped validation:

1. Loads folder-specific development cycle index with phase-organized requirements
2. Identifies current development phase within folder and validates prerequisites
3. Executes TDD cycles with integration documentation:
   - RED: Write focused failing test for worker's requirement
   - GREEN: Implement minimal viable solution with worker-scope build validation
   - REFACTOR: Optimize within worker's scope with local test validation
   - VALIDATE: Worker-scope build and test verification only
4. Documents development decisions and integration points for stabilizer
5. Updates folder cycle index with phase progress
6. Ensures zero issues within worker's development scope
7. Documents dependencies and API changes for stabilizer review
8. Generates session artifacts in worker's requirements folder
9. Worker-isolated completion validation

```bash
@CODEBASE_TDD_ACTORS execute \
  /path/to/codebase-source \
  /path/to/worker-directory \
  /path/to/codebase-tdd-actors-template.md
```

### Parallel-Worker Isolated MVP Development

This protocol **executes TDD development for isolated parallel-worker MVP delivery**:
- Writes focused failing tests for worker's requirements
- Implements minimal viable solutions with worker-scope build validation
- Refactors within worker's scope with local test verification
- Validates build and tests for worker's changes only
- Eliminates all compatibility concerns in favor of MVP clarity
- Operates in complete isolation from other parallel workers
- Measures improvements within worker's development scope
- Documents patterns and integration points for stabilizer
- Produces working MVP-ready code within worker's requirements
- Ensures completion with zero errors in worker's scope
- Generates all session artifacts within worker's isolated requirements folder

### Fix Don't Deprecate Principle

**Core Philosophy**: Every problematic API, pattern, or implementation gets actively fixed and transformed into a better solution. We never just mark things as deprecated or obsolete.

**In Practice**:
- Duplicate code → Fixed by extracting clean abstractions
- Complex APIs → Fixed by simplifying to MVP essentials
- Performance bottlenecks → Fixed through targeted optimization
- Inconsistent patterns → Fixed by standardizing across codebase
- Over-engineered solutions → Fixed by removing unnecessary layers
- Confusing interfaces → Fixed by redesigning for clarity

**Why This Matters for MVP**:
- Deprecation leaves problems unsolved and creates technical debt
- Fixing transforms the codebase into a better tool immediately
- MVP developers get clean, working solutions instead of warnings
- Every session improves the codebase rather than just marking issues

### Work Types Supported

**Implementation Work** (MVP feature development):
- Adding core MVP capabilities with minimal API surface
- Resolving critical developer friction blocking MVP progress
- Implementing essential functionality with aggressive simplification

**Refactoring Work** (MVP optimization through fixing):
- Fixing duplicate code by consolidating into clean abstractions
- Fixing complex implementations through aggressive simplification
- Fixing over-engineering by removing unnecessary abstractions
- Fixing inconsistent patterns by standardizing for MVP clarity
- Fixing performance bottlenecks through targeted optimization
- Note: Always fix rather than deprecate - transform problematic code into better solutions

### Example Usage

**Parallel Worker Examples (2-8 workers operating simultaneously):**

```bash
# Worker 1 operates on its isolated directory
@CODEBASE_TDD_ACTORS execute \
  /path/to/codebase-source \
  /path/to/worker-01-directory \
  /path/to/codebase-tdd-actors-template.md

# Worker 2 operates on its isolated directory
@CODEBASE_TDD_ACTORS execute \
  /path/to/codebase-source \
  /path/to/worker-02-directory \
  /path/to/codebase-tdd-actors-template.md

# Additional workers with their own isolated directories
@CODEBASE_TDD_ACTORS execute \
  /path/to/codebase-source \
  /path/to/worker-XX-directory \
  /path/to/codebase-tdd-actors-template.md
```

**Key Parallel Worker Isolation Features:**
- Each worker accesses codebase from: `<codebase_directory>/`
- Each worker operates on isolated directory: `<worker_directory>/`
- Each worker reads only its directory's DEVELOPMENT-CYCLE-INDEX.md
- Each worker generates session artifacts (CB-SESSION-XXX.md) in its directory
- Workers are completely unaware of each other's work and progress
- No coordination or communication between parallel workers

## Parallel-Worker Isolated Process Flow

```text
1. FOLDER-ISOLATED CYCLE INITIALIZATION
   - Load folder-specific development cycle index to identify current phase and requirements
   - Validate folder prerequisites satisfied
   - Check for existing session progress within folder's current phase
   - Establish worker-scope baselines (build/test status for worker's code)
   - Operate in complete isolation from other parallel workers

2. FOLDER-ISOLATED TDD EXECUTION
   
   IMPLEMENTATION (MVP features):
   - RED: Write focused test for worker's requirement
   - BUILD: Verify build for worker's test addition
   - GREEN: Implement minimal solution for worker's test
   - BUILD: Verify build after worker's implementation
   - TEST: Run worker's tests to verify functionality
   - REFACTOR: Optimize within worker's scope
   - VALIDATE: Worker-scope build + test verification
   
   REFACTORING (MVP fixing and optimization):
   - RED: Write preservation tests for worker's code
   - BUILD: Verify build with preservation tests
   - GREEN: Fix problematic code within worker's scope
   - BUILD: Verify build after fixes
   - TEST: Run worker's tests to ensure preservation
   - REFACTOR: Transform and improve worker's code
   - VALIDATE: Worker-scope build + test verification
   
3. FOLDER-ISOLATED DOCUMENTATION
   - Document development patterns and decisions
   - Document integration points for stabilizer
   - Update folder cycle index with phase progress
   - Track worker-scope quality metrics
   - Maintain complete isolation from other parallel workers

4. FOLDER PHASE COMPLETION
   - Worker-scope build validation
   - Worker's test suite execution
   - Coverage tracking for worker's code
   - Document dependencies for stabilizer
   - No coordination with other parallel workers

5. FOLDER CYCLE COMPLETION
   - Final worker-scope validation
   - Zero errors in worker's changes
   - Zero test failures for worker's tests
   - Worker coverage thresholds met
   - Integration points documented
   - Session artifacts generated in worker's folder
```

## Folder Development Cycle Index Format

The protocol works directly with folder-specific development cycle indexes generated by the requirements protocol:

```markdown
# DEVELOPMENT-CYCLE-INDEX (WORKER-XX Folder)

## Executive Summary  
- [N] requirements generated from folder's assigned improvement areas
- [N] development phases identified within folder
- Estimated timeline: [N] weeks MVP development (folder-isolated)
- Parallel Worker: WORKER-XX (isolated from other workers)

## Current Folder Phase Status
**Phase 1: Foundation** - IN PROGRESS (within folder)
**Phase 2: Integration** - PENDING (within folder)

## Folder Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2) - CURRENT FOLDER PHASE
- REQUIREMENTS-001-ASYNCSTREAM-TEST-UTILITIES [COMPLETED]
- REQUIREMENTS-002-STATE-ERROR-HANDLING [IN PROGRESS]
- Dependencies: None (within folder)
- Exit Criteria: Core testing and error handling enhanced
- MVP Focus: Essential utilities for folder's assigned improvement areas

### Phase 2: Integration (Weeks 3)
- REQUIREMENTS-003-TESTING-CODEBASE-UTILITIES
- Dependencies: Phase 1 complete (within folder)
- Exit Criteria: Folder requirements integrated and complete
- MVP Focus: Final integration of folder's assigned capabilities

## Folder Development Session History
- WORKER-XX/CB-SESSION-001.md [COMPLETED] - Phase 1 start
- WORKER-XX/CB-SESSION-002.md [COMPLETED] - REQUIREMENTS-001 completion  
- WORKER-XX/CB-SESSION-003.md [IN PROGRESS] - REQUIREMENTS-002 development

## Next Folder Session Plan
**Target**: Complete REQUIREMENTS-002, advance Phase 1 toward completion
**Estimated Duration**: 2-3 hours
**MVP Priority**: Complete folder's testing and error handling foundation
**Isolation Note**: No coordination with other parallel workers required
```

## Phase-Driven Development Process

The execute command performs rapid TDD development organized by development phases:

### 1. Session Initialization

```
Loading development cycle index...
✓ Found [N] phases with [N] total requirements
✓ Current Phase: Phase 1 (Foundation) - 1/2 requirements completed
✓ Phase Progress: REQUIREMENTS-001 [COMPLETED], REQUIREMENTS-002 [IN PROGRESS]

Checking session history...
✓ Found existing sessions: CB-SESSION-001.md, CB-SESSION-002.md
✓ This will be: CB-SESSION-003.md

Planning current session...
✓ Phase 1 Focus: Complete REQUIREMENTS-002-STATE-UPDATE-OPTIMIZATION
✓ Dependencies: None (REQUIREMENTS-001 completed)
✓ MVP Priority: Critical for Phase 2 entry
✓ Estimated work: 2-3 hours MVP development
✓ Session goal: Complete Phase 1, unlock Phase 2 development

OR (if starting fresh)

✗ No existing sessions found
✓ This will be: CB-SESSION-001.md (beginning Phase 1 development)
✓ Starting Phase 1: REQUIREMENTS-001-STATE-PERSISTENCE-CAPABILITY
✓ MVP Focus: Essential state management foundation
```

### 2. Phase-Driven Analysis

**Development Cycle Processing:**
- **Phase Structure**: Parse current phase requirements and dependencies
- **Progress Tracking**: Identify phase completion status and blocking issues
- **MVP Prioritization**: Focus on requirements critical for MVP functionality
- **Session Scope**: Target phase milestones and natural breakpoints

**Per-Requirement Analysis (for current session scope):**

**For Implementation Requirements (MVP Features):**
- **MVP Pain Points**: Extract critical friction blocking MVP development
- **Minimal API Design**: Design simplest viable interfaces
- **MVP Success Criteria**: Focus on essential functionality validation
- **Focused Testing**: Test core behavior without exhaustive edge cases

**For Refactoring Requirements (MVP Fixing and Optimization):**
- **Fix Code Complexity**: Target and fix complexity that slows MVP development
- **Fix Over-Engineering**: Preserve only functionality needed for MVP, fix the rest
- **Fix Through Consolidation**: Aggressively fix duplications and inconsistencies
- **Transformation Testing**: Test that fixes preserve essential behavior
- **Active Improvement**: Transform problematic code into clean solutions, never just deprecate

### 3. TDD Cycle Execution

#### RED Phase Execution

**Implementation Example:**
```
Starting RED Phase for MVP State Persistence...

Writing focused MVP test in Tests/StateTests/PersistenceTests.[ext]:
[test_function_declaration] testMVPStatePersistence() async throws {
    let stateManager = StateManager()
    await stateManager.setState("mvp_key", value: "mvp_data")
    // MVP requirement: basic persistence checking
    assert(stateManager.isPersisted("mvp_key"))
}

Quality Validation Checkpoint:
Running build...
✓ Build integrity maintained after test addition

Running test...
✗ Test failed as expected: isPersisted method doesn't exist

Coverage Analysis:
✓ Test added to coverage tracking
✓ Coverage baseline established for new functionality

Session file updated with MVP RED phase progress and quality metrics
```

**Refactoring Example:**
```
Starting RED Phase for MVP State Update Consolidation...

Writing essential behavior tests in Tests/StateTests/MVPBehaviorTests.[ext]:
[test_function_declaration] testMVPStateUpdateBehaviorPreserved() {
    // Test critical MVP state update patterns only
    let manager = StateManager()
    // Focus on behavior needed for MVP applications
}

Quality Validation Checkpoint:
Running build...
✓ Build integrity maintained after preservation test addition

Running test...
✓ All MVP behavior tests pass

Coverage Analysis:
✓ Preservation tests added to coverage tracking
✓ Baseline coverage for existing functionality validated

Session file updated with MVP behavior preservation and quality metrics
```

#### GREEN Phase Execution

**Implementation Example:**
```
Starting GREEN Phase...

Implementing minimal viable solution in Sources/State/PersistenceManager.[ext]:
extension StateManager {
    func isPersisted(_ key: String) -> Bool {
        // MVP implementation: simple, focused, working
        return persistentStore.contains(key)
    }
}

Quality Validation Checkpoint:
Running build...
✓ Build integrity maintained after implementation

Running test...
✓ Worker's test passes with minimal implementation
✓ Worker's existing tests still pass

Coverage Analysis:
✓ New implementation covered by worker's tests
✓ Worker coverage maintained or improved

Session file updated with MVP GREEN phase completion and quality validation
```

**Refactoring Example:**
```
Starting GREEN Phase...

Aggressively fixing StateUpdateManager.[ext] for MVP:
- Fixed duplication by extracting MVPStateUpdatePattern protocol
- Fixed 5 duplicate implementations by consolidating into simple shared protocol
- Fixed bloat by reducing file from 200 lines to 50 lines (75% reduction)
- Fixed over-engineering by removing compatibility layers
- All problems actively fixed, nothing deprecated or left broken

Quality Validation Checkpoint:
Running build...
✓ Build integrity maintained after aggressive refactoring

Running test...
✓ All MVP behavior tests still pass
✓ All preservation tests validate behavior unchanged
✓ Code dramatically simplified for MVP development

Coverage Analysis:
✓ Coverage maintained across refactored code
✓ Simplified code still fully tested
✓ No coverage gaps introduced

Session file updated with aggressive refactoring metrics and quality validation
```

#### REFACTOR Phase Execution

**Implementation Example:**
```
Starting REFACTOR Phase...

Optimizing for MVP development velocity:
protocol MVPPersistenceProvider {
    func store(_ key: String, value: Any)
    func retrieve(_ key: String) -> Any?
    func contains(_ key: String) -> Bool
}

Worker Quality Validation:
Running build...
✓ Build maintained for worker's optimization

Running test...
✓ Worker's MVP tests still passing
✓ Worker's test validation successful

Coverage Analysis:
✓ Coverage maintained for worker's code
✓ New protocol covered by worker's tests

Performance Validation:
Running worker's benchmarks...
✓ Worker performance improved by 15%
✓ No regressions in worker's code
✓ Developer experience simplified for worker's components

Session file updated with worker's optimization results and quality metrics
```

**Refactoring Example:**
```
Starting REFACTOR Phase...

Further optimizing for MVP development:
- Added protocol extensions for MVP common cases
- Improved performance by 25%
- Simplified error handling for MVP debugging
- Removed unnecessary abstractions

Worker Quality Validation:
Running build...
✓ Build maintained after worker's optimization

Running test...
✓ Worker's MVP tests still passing
✓ Worker's preservation tests validate behavior unchanged
✓ Worker's test validation successful

Coverage Analysis:
✓ Coverage maintained for worker's optimizations
✓ Protocol extensions covered by worker's tests
✓ Error handling simplification validated

Performance and Quality Metrics:
✓ Performance improved by 25% (validated)
✓ Code complexity reduced by 40% (measured)
✓ MVP developer experience significantly improved
✓ No quality regressions introduced

Session updated: Documented MVP optimizations, quality validations, and velocity improvements
```

### 4. Quality-Tracked Session Documentation

Throughout execution, the session file documents actual fixes, improvements, and validation:
- Real TDD cycle progress and timings with worker checkpoints
- Actual code written to fix issues with worker-scope validation
- Transformative refactoring with worker quality preservation
- Design decisions with worker impact analysis
- Real performance metrics within worker's scope
- Build tracking for worker's development process
- Test and coverage progression for worker's code
- Quality validation at worker's development milestones
- Insights discovered about worker-isolated patterns
- For refactoring: before/after code with preservation proof

### Example Output

**Single-Worker Quality-Validated Session:**
```
Executing Single-Worker Quality-Validated MVP Development...

Session: CB-SESSION-003.md
Phase 1 Progress: 1/2 requirements completed
Current Focus: Complete REQUIREMENTS-002 to unlock Phase 2
Quality Baseline: Build ✓, Tests ✓, Coverage 87%

┌─────────────────────────────────────────────┐
│ REQUIREMENTS-002: STATE-UPDATE-OPTIMIZATION │
└─────────────────────────────────────────────┘

═══ RED PHASE: MVP Behavior Tests ═══
Writing essential MVP behavior tests... Done
Quality Check: Build ✓, Tests Pass ✓
Coverage Update: 87% → 89%
Time: 2m 45s

═══ GREEN PHASE: Aggressive Consolidation ═══
Consolidating 5 duplicate implementations... Done
Quality Check: Build ✓, Worker Tests Pass ✓, Worker Regression Check ✓
Coverage Validation: 89% maintained ✓
Time: 8m 15s
Refactoring: 200 lines → 50 lines (75% reduction)
MVP Focus: Simplified for rapid development

═══ REFACTOR PHASE: MVP Optimization ═══
Optimizing for MVP development velocity... Done
Worker Quality Validation:
- Build integrity ✓
- Worker tests ✓
- Worker coverage maintained at 89% ✓
- Worker performance improved by 15% ✓
Time: 6m 30s
Developer experience significantly improved

✓ REQUIREMENTS-002 COMPLETED!
✓ PHASE 1 FOUNDATION COMPLETE!

┌─────────────────────────────────────────────┐
│ PHASE 2: INFRASTRUCTURE DEVELOPMENT READY   │
└─────────────────────────────────────────────┘

═══ PHASE 1 COMPLETION VALIDATION ═══
Worker Quality Validation... 
Build Validation: Worker configurations ✓
Test Validation: Worker tests, zero failures ✓
Coverage Validation: Worker 89% achieved ✓
Performance Validation: No regressions in worker scope ✓
Integration Documentation: Dependencies documented ✓

All Phase 1 worker requirements completed ✓
Worker's state management enhanced ✓
Worker's MVP foundation solid ✓

═══ PHASE 2 ENTRY CONDITIONS ═══
Checking Phase 2 dependencies... Satisfied ✓
Worker Gates: Phase 1 gates passed ✓
Phase 2 requirements available for worker
Next session focus: Worker's testing infrastructure

▶ Worker's Phase 1 complete, ready for Phase 2 initiation

Phase 1 Complete with Quality Assurance!
Generated: [CodebaseName]/CB-SESSION-003.md
Total Duration: 1.8 hours
Completed: REQUIREMENTS-002 (MVP OPTIMIZATION)
Phase Status: PHASE 1 FOUNDATION [COMPLETED] ✓
Quality Status: Build ✓, Tests ✓, Coverage 89% ✓, Performance +15% ✓
Overall Cycle Progress: Phase 1 complete with quality validation, Phase 2 ready
Next Session: Begin Phase 2 testing infrastructure development
```

**Cycle Completion Session with Comprehensive Quality Validation:**
```
Executing Final Phase Development with Quality Assurance...

Session: CB-SESSION-007.md
Phase [N] Progress: Final integration phase
Current Session Scope: Complete Phase [N] and finalize MVP codebase
Quality Status: Build ✓, Tests ✓, Coverage 91%

┌─────────────────────────────────────────────┐
│ REQUIREMENTS-007: ASYNC-STATE-COORDINATION  │
└─────────────────────────────────────────────┘

═══ RED PHASE: testMVPAsyncStateCoordination ═══
Writing MVP async coordination test... Done
Quality Check: Build ✓, Test Failed (expected) ✓
Coverage Update: XX% → YY%
Time: Xm XXs

═══ GREEN PHASE: MVP Implementation ═══
Implementing minimal viable async coordination... Done
Quality Check: Build ✓, Test Passed ✓, Regression Check ✓
Coverage Validation: XX% maintained ✓
Time: XXm XXs

═══ REFACTOR PHASE: MVP Optimization ═══
Optimizing for MVP async patterns... Done
Worker Quality Validation:
- Build integrity ✓
- Worker tests ✓
- Worker coverage improved to XX% ✓
- Worker performance validated ✓
Time: Xm XXs

✓ REQUIREMENTS-00X COMPLETED!
✓ PHASE [N] INTEGRATION COMPLETE!

┌─────────────────────────────────────────────┐
│ 🏆 WORKER MVP DEVELOPMENT COMPLETE! 🏆 │
└─────────────────────────────────────────────┘

═══ WORKER CYCLE COMPLETION VALIDATION ═══
Final Worker Quality Check:
Build Validation: Worker configurations ✓
Test Validation: Worker tests, zero failures ✓
Coverage Validation: Worker XX% achieved ✓
Performance Validation: Worker benchmarks passed ✓
Integration Documentation: Dependencies documented ✓
Documentation: Worker sessions documented ✓

Worker Development Complete!
Generated: WORKER-XX/CB-SESSION-007.md
Session Duration: X.X hours
Total Worker Sessions: N
Total Worker Requirements: N/N
Total Worker Time: XX.X hours
Worker Phases: N/N Complete ✓
Final Worker Status: Build ✓, Tests ✓, Coverage XX% ✓
Worker MVP Ready - Ready for stabilizer integration!
```

## Worker Session Artifact Structure

The session file is continuously updated during development with integration documentation:

### 1. Worker Session Header (Initial)
- **Development Cycle Index**: Link to worker's cycle index
- **Current Phase**: Worker's phase being developed
- **Phase Progress**: Worker's phase completion status
- **Session Number**: Auto-determined from worker's existing sessions
- **Start Time**: When worker's development began
- **MVP Focus**: Worker's phase objectives
- **Integration Documentation**: Dependencies and API changes for stabilizer
- **Worker Isolation**: Complete independence from other workers

### 2. Worker TDD Development Log (Updated per cycle)
Each RED→GREEN→REFACTOR cycle is documented with integration notes:
- **Worker Test Code**: 
  - Implementation: Test for worker's MVP behavior
  - Refactoring: Test for behavior preservation within worker scope
- **Worker Development**: 
  - Implementation: Minimal viable code for worker's requirement
  - Refactoring: Simplification within worker's scope
- **Worker Optimization**: Performance improvements within worker's components
- **Development Insights**: Patterns discovered within worker's development
- **Worker Metrics**: Duration, code reduction, improvements within scope

### 3. Worker API Design Decisions (As they occur)
- **Decision Point**: When design choice needed within worker scope
- **Options Considered**: Alternatives evaluated for worker's requirements
- **Choice Made**: Final decision with rationale
- **Pain Point Link**: How it addresses worker's specific issue
- **API Documentation**: Public API changes documented for stabilizer
- **Dependencies**: Integration points documented for stabilizer

### 4. Worker Validation Results (Continuous)
- **Test Results**: Pass/fail status for worker's tests
- **Performance Metrics**: Benchmarks within worker's scope
- **Compatibility**: Worker's existing test status
- **Worker Validation**: Real usage validation within scope
- **Integration Notes**: Dependencies documented for stabilizer

### 5. Worker Session Metrics (Final)
- **Total Duration**: Worker's session time
- **Phase Progress**: Worker's phase advancement
- **Requirements Status**: 
  - Requirements completed by worker this session
  - Worker's phase completion status
  - Worker's critical path advancement
- **TDD Cycles Completed**: Number of worker's cycles
- **Worker Quality Metrics**:
  - Build integrity: Maintained for worker's code (✓/✗)
  - Test completeness: Worker's coverage progression
  - Performance impact: Worker's benchmarks
  - Quality gates: Worker's checkpoints passed
- **Worker Code Metrics**:
  - Implementation: Features delivered by worker
  - Refactoring: Complexity reduced within worker scope
- **Development Velocity**: Time for worker's MVP features
- **Integration Documentation**: Dependencies and API changes captured

## Continuous Documentation

The protocol updates the session file at key points:

### During RED Phase
```[language]
// Session file updated with:
### RED Phase - testAutomaticStatePersistence
**Test Intent**: Validate automatic state persistence works
[test_function_declaration] testAutomaticStatePersistence() async throws {
    // Test implementation
}
**Insight**: Need persistence protocol for flexibility
```

### During GREEN Phase
```[language]
// Session file updated with:
### GREEN Phase - testAutomaticStatePersistence
**Approach**: Implement minimal PersistenceManager
// Implementation code
**MVP Optimization**: Simplified for maximum development velocity
```

### During REFACTOR Phase
```[language]
// Session file updated with:
### REFACTOR Phase - testAutomaticStatePersistence
**Optimization Focus**: Extract reusable provider pattern
// Refactored code
**Pattern Emerged**: Provider pattern for storage abstraction
```

## TDD Execution Workflow

The protocol executes development through strict TDD phases:

### 1. Test-First Implementation
For each pain point from requirements:
- Write failing test that validates resolution
- Run test to confirm it fails correctly
- Implement minimal code to pass
- Refactor while keeping tests green

### 2. Continuous Validation
After each code change:
- Run worker's tests to ensure no regression
- Measure performance within worker's scope
- Verify MVP simplicity maintained in worker's code
- Update session file with results

### 3. Session File Updates
The protocol updates the session file:
- After each phase completion
- When insights are discovered
- At design decision points
- With final metrics and outcomes

### 4. Final Artifact Generation
Upon completion:
- Session file saved in codebase directory
- All TDD cycles documented
- Metrics and validations recorded
- Ready for analysis protocol

## Issue Resolution Verification

The protocol ensures each issue is truly resolved through active fixing:

### Requirements Traceability (Fix Verification)
- **Implementation**: Every test links to specific pain point that gets fixed
- **Refactoring**: Every test ensures fixes preserve essential behavior while transforming code
- Metrics prove problems are fixed, not just marked or avoided
- **Implementation**: Original scenario now works smoothly through fixes
- **Refactoring**: Problems are fixed through dramatic simplification, code is transformed not deprecated
- **No Deprecation**: Every identified issue results in a fix, never just a deprecation notice

### Continuous Testing
- Tests run after every change
- Performance benchmarked throughout
- Integration verified with examples
- No new friction introduced

### Documentation Quality
- Session captures complete journey (implementation or refactoring)
- Decisions explained with context
- Patterns identified for reuse
- Insights valuable for future work
- **Refactoring**: Before/after comparisons with measurable improvements

## Worker-Isolated Best Practices

1. **Worker Session Management**
   - Parse requirements index to understand worker's scope
   - Check existing sessions within worker's folder
   - Plan session scope based on worker's priorities
   - Number sessions sequentially within worker folder
   - Save session file after each requirement completion
   - Update index progress with worker metrics

2. **Worker TDD Execution Discipline**
   - **RED**: Test must fail for the right reason
   - **BUILD**: Verify build for worker's test addition
   - **GREEN**: Write only enough code to pass worker's test
   - **BUILD**: Verify build after worker's implementation
   - **TEST**: Run worker's tests to ensure no regressions
   - **REFACTOR**: Improve without breaking worker's tests
   - **VALIDATE**: Worker-scope build + test verification
   - Never skip phases or write code without validation

3. **Worker Documentation**
   - Update session file immediately after insights
   - Include actual code snippets with validation
   - Document why decisions were made
   - Track exact timings for each phase
   - Document integration points for stabilizer

4. **Worker Issue Validation**
   - **Implementation**: Test with exact scenarios
   - **Refactoring**: Verify behavior preservation
   - Measure improvement metrics within scope
   - **Implementation**: Verify workarounds eliminated
   - **Refactoring**: Confirm problems fixed
   - Confirm no new issues in worker's code

5. **Worker MVP Evolution**
   - Fix patterns within worker's scope
   - Fix complexity through simplification
   - Run worker's tests frequently
   - Fix friction points in worker's code
   - Transform worker's APIs into clean solutions

6. **Worker Session Completion**
   - **Per Requirement**: Verify pain points addressed
   - **Session Level**: Update worker's index progress
   - Run final benchmarks for worker's code
   - Update session with worker metrics
   - Save in worker's session directory
   - **Overall**: Track worker's completion

7. **Worker Completion Assurance**
   - **Build Validation**: Zero errors in worker's code
   - **Test Validation**: Worker's tests pass
   - **Coverage Validation**: Worker's thresholds met
   - **Performance Validation**: No regressions in worker
   - **Integration Documentation**: Dependencies documented
   - **Documentation**: Worker decisions recorded

## Worker Session Artifact Storage

Generated session artifacts are stored in the worker's directory for future consumption by stabilization processes:

```
<codebase_directory>/
└── [Source code files being developed]

<worker_directory>/
├── DEVELOPMENT-CYCLE-INDEX.md (worker-specific cycle)
├── REQUIREMENTS-001-[DESCRIPTIVE-TITLE].md
├── REQUIREMENTS-002-[DESCRIPTIVE-TITLE].md
├── REQUIREMENTS-003-[DESCRIPTIVE-TITLE].md
├── CB-SESSION-001.md (session 1 artifacts)
├── CB-SESSION-002.md (session 2 artifacts)
└── CB-SESSION-003.md (session 3 artifacts)
```

**Directory Usage:**
- `<codebase_directory>/`: Source code being developed (read/write)
- `<worker_directory>/`: Worker's isolated requirements and session artifacts

This enables tracking of worker-specific progress and provides complete development history for this worker. The worker directory contains complete isolation with its own requirements and session artifacts. These session artifacts are available for consumption by external processes such as stabilization cycles.

## Index Progress Management

The protocol automatically updates the requirements index as work progresses:

### Phase Progress Tracking
- **PENDING**: Phase not yet started, dependencies not satisfied
- **IN-PROGRESS**: Phase partially completed, active development
- **COMPLETED**: Phase fully implemented with exit criteria met
- **READY**: Phase dependencies satisfied, ready for development

### Automatic Updates
After each session, the protocol updates:
```markdown
**Phase 1**: COMPLETED ✓
**Phase 2**: COMPLETED ✓
**Phase 3**: IN-PROGRESS

### Phase 1: Foundation
**Status**: COMPLETED ✓
**Sessions**: CB-SESSION-001, CB-SESSION-002, CB-SESSION-003
**Completion Date**: 2024-01-15
**MVP Impact**: Core state management ready for application development

### Phase 3: Integration  
**Status**: IN-PROGRESS (1/3 requirements complete)
**Current Session**: CB-SESSION-007
**Next Steps**: Complete async state coordination for MVP readiness
**Critical Path**: Blocking final MVP codebase release
```

### Session Planning Updates
The protocol automatically plans next sessions:
```markdown
## Next Session Plan (CB-SESSION-008)
**Priority**: Begin Phase [N] final integration requirements
**MVP Milestone**: Complete codebase for application development
**Estimated Duration**: 2-3 hours
**Critical Path**: Final MVP codebase delivery
**Dependencies**: Phase 2 completed (testing infrastructure ready)
```

## Error Handling and Resumption

### Development Interruptions
If phase development is interrupted:
- Session file preserves progress on current phase requirements
- Cycle index maintains phase-level progress tracking
- Phases marked as IN-PROGRESS can be resumed at requirement level
- Next execution detects incomplete phase and continues appropriately
- MVP development momentum preserved through comprehensive documentation

### Test Failures (Unexpected)
When tests fail unexpectedly:
- Document the failure in session
- Analyze why the failure occurred
- Simplify approach aggressively, breaking changes welcomed
- Continue with MVP-optimized implementation

### Session Recovery
The phase-driven protocol can recover from:
- Build failures (fix and continue with current phase)
- Test timeouts (adjust MVP scope and retry, aggressive simplification)
- Design pivots (document rationale and update phase requirements)
- Performance issues (profile and optimize for MVP, breaking changes acceptable for simplicity)
- Dependency issues (reorder within phase or escalate to phase dependencies)

All challenges become part of the MVP development learning record and inform rapid iteration strategies.

## Fix Don't Deprecate Summary

This protocol enforces a strict "Fix Don't Deprecate" policy throughout all development:
- Every problem identified gets actively fixed, not marked as deprecated
- Breaking changes are used to fix issues properly, not to deprecate functionality
- Code transformation replaces problematic implementations with better solutions
- Session documentation tracks fixes made, not deprecations added
- The codebase continuously improves through fixing, never accumulates deprecation warnings
- MVP development benefits from clean, fixed code rather than deprecated APIs with warnings

The result: A codebase that gets progressively better through active problem-solving, not one that accumulates technical debt through deprecation.