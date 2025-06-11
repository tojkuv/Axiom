# CODEBASE-TDD-PROVISIONER-PROTOCOL

Execute minimal foundational test-driven development cycles to establish only critical infrastructure required for parallel development. Produces foundation-ready session artifacts with comprehensive quality validation. Single provisioner worker operates on provisioner directory requirements, focusing exclusively on dependencies needed by parallel workers.

## Protocol Activation

```text
@CODEBASE_TDD_PROVISIONER execute <source_directory> <provisioner_directory> <session_template>
```

**Parameters:**
- `<source_directory>`: SOURCE/ directory to copy from (READ-ONLY)
- `<provisioner_directory>`: PROVISIONER/ workspace directory (creates CODEBASE/ + ARTIFACTS/)
- `<session_template>`: Provisioner session template for documentation

**Explicit Input/Output Structure:**
- **INPUT**: `<source_directory>/` - Original source codebase (READ-ONLY)
- **OUTPUT**: `<provisioner_directory>/CODEBASE/` - Provisioner's isolated development workspace
- **OUTPUT**: `<provisioner_directory>/ARTIFACTS/` - Provisioner session artifacts and requirements

**Provisioner Role**: Establish minimal foundational infrastructure that enables parallel development

**EXPLICITLY EXCLUDED FROM FOUNDATIONAL DEVELOPMENT (MVP FOCUS):**
- Version control integration (foundation focuses on current codebase state)
- Database versioning foundation (work with current schema)
- Migration pathway foundation (no migration concerns for MVP)
- Deprecation management infrastructure (we fix problems, don't deprecate)
- Legacy code support infrastructure (transform code, don't preserve)
- Backward compatibility foundation (no compatibility constraints)
- Breaking change mitigation (breaking changes welcomed for MVP clarity)
- Semantic versioning infrastructure (MVP operates on current iteration)
- API stability preservation systems (APIs evolve for MVP optimization)
- Configuration migration infrastructure (use current configuration)
- Deployment versioning foundation (deploy current state)
- Release management infrastructure (continuous MVP iteration)
- Rollback procedure foundation (no rollback concerns for MVP)
- Multi-version support infrastructure (single current version)

**Foundational Development Philosophy:**
- **Minimal Infrastructure Only**: Create only what parallel workers absolutely need
- **Foundation-Only Scope**: Build infrastructure, not application functionality
- **Enable Parallel Work**: Focus on what allows parallel development to begin
- **Critical Path Execution**: Must complete before any parallel work begins

## Command

### Execute - Foundational TDD Development from Provisioner Requirements

The execute command performs single-worker foundational TDD development with explicit workspace isolation and continuous quality validation:

1. **Workspace Setup**: Copies `<source_directory>/` to `<provisioner_directory>/CODEBASE/` for isolated development
2. **Requirements Loading**: Loads `<provisioner_directory>/ARTIFACTS/DEVELOPMENT-CYCLE-INDEX.md` with foundational requirements
3. **Critical Infrastructure Development**: Identifies infrastructure requirements that must complete first
4. **Quality-Validated TDD Cycles**: Executes foundation development in `<provisioner_directory>/CODEBASE/`:
   - RED: Write focused failing test for foundational capability
   - GREEN: Implement minimal viable foundation with build validation
   - REFACTOR: Optimize foundation with comprehensive test suite validation
   - VALIDATE: Continuous build, test, coverage verification within isolated workspace
5. **Decision Documentation**: Documents foundational decisions and architectural choices
6. **Progress Tracking**: Updates `<provisioner_directory>/ARTIFACTS/` cycle index with validated progress
7. **Quality Assurance**: Ensures zero quality issues before parallel actors can begin
8. **Infrastructure Foundation**: Establishes critical infrastructure for parallel workers to inherit
9. **Artifact Generation**: Generates session artifacts in `<provisioner_directory>/ARTIFACTS/`
10. **Validation**: Comprehensive foundation validation before parallel work begins

```bash
@CODEBASE_TDD_PROVISIONER execute \
  /path/to/SOURCE \
  /path/to/PROVISIONER \
  /path/to/codebase-tdd-provisioner-template.md
```

### Foundational Development Execution

This protocol **executes foundational TDD development for parallel work enablement**:
- Implements minimal infrastructure for parallel worker dependencies
- Establishes core patterns and abstractions
- Validates foundation through comprehensive testing
- Documents architectural decisions for parallel workers
- Produces stable foundation with zero quality defects

### Foundational Requirements Focus

**Critical Infrastructure Development:**
- Core codebase bootstrapping and initialization
- Essential cross-cutting concerns (logging, error handling, configuration)
- Fundamental patterns and abstractions used throughout codebase
- Base testing infrastructure and utilities
- Core build and validation systems
- Primary architectural decisions and patterns

**Sets Foundation For Parallel Work:**
- Establishes patterns parallel actors will extend
- Creates base infrastructure all workers depend on
- Implements core abstractions parallel work builds upon
- Defines architectural boundaries and conventions
- Provides essential utilities and helpers

### Example Usage

```bash
# Provisioner executes foundational requirements before parallel actors
@CODEBASE_TDD_PROVISIONER execute \
  /path/to/SOURCE \
  /path/to/PROVISIONER \
  /path/to/codebase-tdd-provisioner-template.md
```

**Key Provisioner Explicit Workspace Features:**
- **Source Protection**: Reads from `<source_directory>/` (READ-ONLY, never modified)
- **Isolated Development**: Copies `<source_directory>/` to `<provisioner_directory>/CODEBASE/` for development
- **Development Workspace**: All TDD work performed in `<provisioner_directory>/CODEBASE/`
- **Artifact Storage**: Stores requirements in `<provisioner_directory>/ARTIFACTS/DEVELOPMENT-CYCLE-INDEX.md`
- **Session Tracking**: Generates session artifacts (CB-SESSION-XXX.md) in `<provisioner_directory>/ARTIFACTS/`
- **Foundation Preparation**: `<provisioner_directory>/CODEBASE/` becomes baseline for parallel workers
- **Execution Order**: Must complete before any parallel actors begin
- **Explicit Control**: User controls exactly which directories are input and output

## Provisioner Quality-Validated Process Flow

```text
1. EXPLICIT WORKSPACE SETUP AND INITIALIZATION
   - Copy `<source_directory>/` to `<provisioner_directory>/CODEBASE/` for isolated development
   - Create `<provisioner_directory>/ARTIFACTS/` for session artifacts and requirements
   - Load `<provisioner_directory>/ARTIFACTS/DEVELOPMENT-CYCLE-INDEX.md` for foundational requirements
   - Validate no prerequisites (provisioner runs first)
   - Check for existing provisioner session progress in `<provisioner_directory>/ARTIFACTS/`
   - Establish quality baselines (build, test, coverage status in isolated workspace)
   - Prepare isolated foundation development for parallel work

2. FOUNDATIONAL QUALITY-VALIDATED TDD EXECUTION (in `<provisioner_directory>/CODEBASE/`)
   
   IMPLEMENTATION (Foundational MVP features):
   - RED: Write focused test validating foundational behavior
   - BUILD: Verify build integrity after test addition
   - GREEN: Implement minimal viable foundation with continuous validation
   - BUILD: Verify build integrity after implementation
   - TEST: Run full test suite to ensure no regressions
   - REFACTOR: Optimize foundation for clarity and MVP performance
   - VALIDATE: Comprehensive build + test + coverage verification
   
   REFACTORING (Foundational code optimization):
   - RED: Write preservation tests for critical foundational behavior
   - BUILD: Verify build integrity with preservation tests
   - GREEN: Fix foundational code through aggressive simplification
   - BUILD: Verify build integrity after fixes
   - TEST: Run full test suite to ensure behavior preservation
   - REFACTOR: Transform and improve foundational patterns
   - VALIDATE: Comprehensive build + test + coverage verification
   
3. FOUNDATIONAL CONTINUOUS QUALITY ASSURANCE (in `<provisioner_directory>/CODEBASE/`)
   - Document foundational patterns and architectural decisions
   - Validate quality gates before proceeding to next requirement
   - Update `<provisioner_directory>/ARTIFACTS/` cycle index with validated progress
   - Track build integrity, test completeness, and coverage throughout isolated workspace
   - Establish patterns for parallel actors to follow

4. PROVISIONER PHASE COMPLETION VALIDATION (in `<provisioner_directory>/CODEBASE/`)
   - Comprehensive build validation across all isolated codebase components
   - Complete test suite execution with zero failures in workspace
   - Coverage threshold validation and gap identification
   - Foundation testing across all provisioner requirements
   - Performance benchmarking and baseline establishment in isolated environment
   - Verify foundation ready for parallel work inheritance

5. PROVISIONER COMPLETION ASSURANCE
   - Final comprehensive quality validation across entire `<provisioner_directory>/CODEBASE/`
   - Zero build errors across all configurations in isolated workspace
   - Zero test failures across complete test suite in `<provisioner_directory>/CODEBASE/`
   - Coverage thresholds met or exceeded for all components
   - Performance benchmarks validated in isolated environment
   - Foundation testing completed successfully
   - Documentation updated with architectural decisions
   - Session artifacts generated within `<provisioner_directory>/ARTIFACTS/`
   - `<provisioner_directory>/CODEBASE/` ready for parallel workers to inherit
```

## PROVISIONER Development Cycle Index Format

The protocol works with PROVISIONER-specific development cycle index stored in `<provisioner_directory>/ARTIFACTS/`:

```markdown
# DEVELOPMENT-CYCLE-INDEX (<provisioner_directory>/ARTIFACTS/ Folder)

## Executive Summary  
- [N] foundational requirements identified for provisioner execution
- [N] development phases for foundation establishment in `<provisioner_directory>/CODEBASE/`
- Estimated timeline: [N] week(s) foundational development
- Role: Codebase Foundation Provisioner (executes before parallel actors)
- Workspace: Isolated development in `<provisioner_directory>/CODEBASE/`

## Current PROVISIONER Phase Status
**Phase 1: Core Foundation** - IN PROGRESS
**Phase 2: Infrastructure Setup** - PENDING

## PROVISIONER Implementation Roadmap

### Phase 1: Core Foundation (Days 1-N) - CURRENT
- REQUIREMENTS-001-[DESCRIPTIVE-TITLE] [IN PROGRESS]
- REQUIREMENTS-002-[DESCRIPTIVE-TITLE] [PENDING]
- REQUIREMENTS-003-[DESCRIPTIVE-TITLE] [PENDING]
- Dependencies: None (provisioner runs first)
- Exit Criteria: Core codebase foundation established in `<provisioner_directory>/CODEBASE/`
- MVP Focus: Essential infrastructure all parallel work depends on

### Phase 2: Infrastructure Setup (Days N-N)
- REQUIREMENTS-004-[DESCRIPTIVE-TITLE] [PENDING]
- REQUIREMENTS-005-[DESCRIPTIVE-TITLE] [PENDING]
- Dependencies: Phase 1 complete
- Exit Criteria: `<provisioner_directory>/CODEBASE/` ready for parallel worker inheritance
- MVP Focus: Testing and build infrastructure established

## Development Session History
- `<provisioner_directory>/ARTIFACTS/`CB-SESSION-001.md [IN PROGRESS] - Bootstrap implementation

## Next PROVISIONER Session Plan
**Target**: Complete codebase bootstrap, begin error handling foundation
**Estimated Duration**: X-Y hours
**MVP Priority**: Establish core patterns for parallel work
**Completion Gate**: `<provisioner_directory>/CODEBASE/` must be ready before parallel actors begin
```

## Provisioner-to-Actor Handoff

Upon provisioner completion:
- All foundational requirements implemented and tested in `<provisioner_directory>/CODEBASE/`
- Core infrastructure patterns established for inheritance
- Base utilities and helpers available in foundation codebase
- Architectural decisions documented in `<provisioner_directory>/ARTIFACTS/`
- `<provisioner_directory>/CODEBASE/` foundation stable with zero quality issues
- `<provisioner_directory>/ARTIFACTS/` contains complete session history and requirements
- `<provisioner_directory>/CODEBASE/` ready for parallel workers to copy and extend
- Parallel actors inherit `<provisioner_directory>/CODEBASE/` as their starting point
- No further coordination needed with provisioner during parallel work

## Best Practices

1. **Foundational Requirement Selection**
   - Choose requirements that all parallel work depends on
   - Focus on cross-cutting concerns and core infrastructure
   - Establish patterns parallel actors will extend
   - Create base abstractions used throughout codebase

2. **Quality-First Foundation**
   - Every foundational component must have comprehensive tests
   - Establish testing patterns parallel actors will follow
   - Document architectural decisions clearly
   - Create examples of proper codebase usage

3. **Completion Gates**
   - Build: Zero compilation errors ✓
   - Tests: All foundation tests passing ✓
   - Coverage: Minimum 85% achieved ✓
   - Foundation: Ready for parallel worker inheritance ✓

## Provisioner Session Artifact Storage

Generated artifacts are stored using explicit workspace directories:

```
<source_directory>/                           # Original source codebase (READ-ONLY)
└── [Source code files - never modified]

<provisioner_directory>/
├── CODEBASE/                                # Provisioner's isolated development workspace
│   └── [Source code files with foundation established]
└── ARTIFACTS/                               # Provisioner's session artifacts and requirements
    ├── DEVELOPMENT-CYCLE-INDEX.md          # Provisioner-specific cycle
    ├── REQUIREMENTS-001-[DESCRIPTIVE-TITLE].md
    ├── REQUIREMENTS-002-[DESCRIPTIVE-TITLE].md
    ├── REQUIREMENTS-003-[DESCRIPTIVE-TITLE].md
    ├── REQUIREMENTS-004-[DESCRIPTIVE-TITLE].md
    ├── REQUIREMENTS-005-[DESCRIPTIVE-TITLE].md
    ├── CB-SESSION-001.md
    ├── CB-SESSION-002.md
    ├── CB-SESSION-003.md
    ├── CB-SESSION-004.md
    └── CB-SESSION-005.md
```

**Explicit Workspace Usage:**
- `<source_directory>/`: Original source code (READ-ONLY, never modified by protocols)
- `<provisioner_directory>/CODEBASE/`: Foundation development workspace (copy of `<source_directory>/` + foundation changes)
- `<provisioner_directory>/ARTIFACTS/`: Provisioner's requirements and session artifacts

This enables explicit workspace isolation with foundational development tracking and provides `<provisioner_directory>/CODEBASE/` as the inheritance point for parallel work while preserving original `<source_directory>/` unchanged.