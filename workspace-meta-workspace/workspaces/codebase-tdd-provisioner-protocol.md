# CODEBASE-TDD-PROVISIONER-PROTOCOL

Execute minimal foundational test-driven development cycles to establish only critical infrastructure required for parallel development. Produces foundation-ready session artifacts with comprehensive quality validation. Single provisioner worker operates on provisioner directory requirements, focusing exclusively on dependencies needed by parallel workers.

## Protocol Activation

```text
@CODEBASE_TDD_PROVISIONER execute <codebase_directory> <provisioner_directory> <session_template>
```

**Parameters:**
- `<codebase_directory>`: Path to directory containing source code to establish foundation for
- `<provisioner_directory>`: Path to provisioner's directory containing requirements and for storing session artifacts
- `<session_template>`: Provisioner session template for documentation

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
- **Dependency-Focused**: Establish core dependencies, not features
- **Foundation-Only Scope**: Build infrastructure, not application functionality
- **Enable Parallel Work**: Focus on what allows parallel development to begin
- **No Feature Implementation**: Leave all feature development to parallel workers
- Zero compatibility constraints - breaking changes welcomed for MVP clarity
- No versioning considerations - focus purely on current MVP needs  
- No migration paths - optimize for simplicity over backward compatibility
- Single provisioner worker - executes minimal foundation requirements
- Critical path execution - completes before any parallel actor begins
- Foundation-ready artifact generation - session records enable parallel work

## Command

### Execute - Foundational TDD Development from Provisioner Requirements

The execute command performs single-worker foundational TDD development with continuous quality validation, generating foundation-ready session artifacts:

1. Loads provisioner directory development cycle index with foundational requirements
2. Identifies critical infrastructure requirements that must complete first
3. Executes quality-validated TDD cycles establishing foundation:
   - RED: Write focused failing test for foundational capability
   - GREEN: Implement minimal viable foundation with build validation
   - REFACTOR: Optimize foundation with comprehensive test suite validation
   - VALIDATE: Continuous build, test, coverage verification
4. Documents foundational decisions and architectural choices
5. Updates provisioner directory cycle index with validated progress
6. Ensures zero quality issues before parallel actors can begin
7. Establishes critical infrastructure all parallel workers will use
8. Generates session artifacts in provisioner directory
9. Comprehensive foundation validation before parallel work begins

```bash
@CODEBASE_TDD_PROVISIONER execute \
  /path/to/codebase-source \
  /path/to/provisioner-directory \
  /path/to/codebase-tdd-provisioner-template.md
```

### Single-Worker Foundational MVP Development

This protocol **executes quality-assured TDD development for foundational MVP infrastructure**:
- Writes focused failing tests for critical foundation capabilities
- Implements minimal viable foundation with continuous build validation
- Refactors aggressively with full test suite verification after each change
- Validates build integrity, test completeness, and coverage thresholds continuously
- Eliminates all compatibility concerns in favor of MVP clarity and quality
- Establishes infrastructure patterns parallel actors will follow
- Measures real performance and quality improvements throughout development
- Documents foundational patterns and architectural decisions
- Produces working MVP-ready foundational code with zero quality defects
- Ensures foundation completion with zero build errors, test failures, or coverage gaps
- Generates all session artifacts within provisioner directory

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
  /path/to/codebase-workspace \
  /path/to/codebase-tdd-provisioner-template.md
```

**Key Provisioner Features:**
- Accesses codebase from: `<codebase_workspace>/[CodebaseName]/`
- Operates on isolated PROVISIONER/ requirements folder: `<codebase_workspace>/PROVISIONER/`
- Reads only PROVISIONER/DEVELOPMENT-CYCLE-INDEX.md
- Generates session artifacts (CB-PROVISIONER-SESSION-XXX.md) in PROVISIONER/ folder
- Must complete before any parallel actors begin
- Establishes foundation all parallel workers will use

## Provisioner Quality-Validated Process Flow

```text
1. PROVISIONER CYCLE INITIALIZATION
   - Load PROVISIONER/ development cycle index for foundational requirements
   - Validate no prerequisites (provisioner runs first)
   - Check for existing provisioner session progress
   - Establish quality baselines (current build, test, coverage status)
   - Prepare to establish foundation for parallel work

2. FOUNDATIONAL QUALITY-VALIDATED TDD EXECUTION
   
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
   
3. FOUNDATIONAL CONTINUOUS QUALITY ASSURANCE
   - Document foundational patterns and architectural decisions
   - Validate quality gates before proceeding to next requirement
   - Update PROVISIONER cycle index with validated progress
   - Track build integrity, test completeness, and coverage throughout
   - Establish patterns for parallel actors to follow

4. PROVISIONER PHASE COMPLETION VALIDATION
   - Comprehensive build validation across all codebase components
   - Complete test suite execution with zero failures
   - Coverage threshold validation and gap identification
   - Foundation testing across all provisioner requirements
   - Performance benchmarking and baseline establishment
   - Verify foundation ready for parallel work

5. PROVISIONER COMPLETION ASSURANCE
   - Final comprehensive quality validation across entire codebase
   - Zero build errors across all configurations and platforms
   - Zero test failures across complete test suite
   - Coverage thresholds met or exceeded for all components
   - Performance benchmarks validated
   - Foundation testing completed successfully
   - Documentation updated with architectural decisions
   - Session artifacts generated within PROVISIONER/ folder
   - Foundation ready for parallel actors to build upon
```

## PROVISIONER Development Cycle Index Format

The protocol works with PROVISIONER-specific development cycle index:

```markdown
# DEVELOPMENT-CYCLE-INDEX (PROVISIONER Folder)

## Executive Summary  
- [N] foundational requirements identified for provisioner execution
- [N] development phases for foundation establishment
- Estimated timeline: [N] week(s) foundational development
- Role: Codebase Foundation Provisioner (executes before parallel actors)

## Current PROVISIONER Phase Status
**Phase 1: Core Foundation** - IN PROGRESS
**Phase 2: Infrastructure Setup** - PENDING

## PROVISIONER Implementation Roadmap

### Phase 1: Core Foundation (Days 1-N) - CURRENT
- REQUIREMENTS-001-[DESCRIPTIVE-TITLE] [IN PROGRESS]
- REQUIREMENTS-002-[DESCRIPTIVE-TITLE] [PENDING]
- REQUIREMENTS-003-[DESCRIPTIVE-TITLE] [PENDING]
- Dependencies: None (provisioner runs first)
- Exit Criteria: Core codebase foundation established
- MVP Focus: Essential infrastructure all parallel work depends on

### Phase 2: Infrastructure Setup (Days N-N)
- REQUIREMENTS-004-[DESCRIPTIVE-TITLE] [PENDING]
- REQUIREMENTS-005-[DESCRIPTIVE-TITLE] [PENDING]
- Dependencies: Phase 1 complete
- Exit Criteria: Foundation ready for parallel actor work
- MVP Focus: Testing and build infrastructure established

## PROVISIONER Development Session History
- PROVISIONER/CB-PROVISIONER-SESSION-001.md [IN PROGRESS] - Bootstrap implementation

## Next PROVISIONER Session Plan
**Target**: Complete codebase bootstrap, begin error handling foundation
**Estimated Duration**: X-Y hours
**MVP Priority**: Establish core patterns for parallel work
**Completion Gate**: Must finish before parallel actors begin
```

## Provisioner-to-Actor Handoff

Upon provisioner completion:
- All foundational requirements implemented and tested
- Core infrastructure patterns established
- Base utilities and helpers available
- Architectural decisions documented
- Codebase foundation stable with zero quality issues
- PROVISIONER/ folder contains complete session history
- Parallel actors can safely begin their isolated work
- No further coordination needed with provisioner

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

3. **Provisioner Completion Gates**
   - All foundational requirements must complete successfully
   - Zero tolerance for quality issues in foundation
   - Comprehensive validation before parallel work begins
   - Clear handoff documentation for parallel actors

## Provisioner Session Artifact Storage

Generated artifacts are stored in the provisioner directory:

```
<codebase_directory>/
└── [Source code files being developed]

<provisioner_directory>/
├── DEVELOPMENT-CYCLE-INDEX.md (provisioner-specific cycle)
├── REQUIREMENTS-001-[DESCRIPTIVE-TITLE].md
├── REQUIREMENTS-002-[DESCRIPTIVE-TITLE].md
├── REQUIREMENTS-003-[DESCRIPTIVE-TITLE].md
├── REQUIREMENTS-004-[DESCRIPTIVE-TITLE].md
├── REQUIREMENTS-005-[DESCRIPTIVE-TITLE].md
├── CB-PROVISIONER-SESSION-001.md
├── CB-PROVISIONER-SESSION-002.md
├── CB-PROVISIONER-SESSION-003.md
├── CB-PROVISIONER-SESSION-004.md
└── CB-PROVISIONER-SESSION-005.md
```

**Directory Usage:**
- `<codebase_directory>/`: Source code where foundation is established (read/write)
- `<provisioner_directory>/`: Provisioner's requirements and session artifacts

This enables tracking of foundational development and provides complete history of infrastructure establishment before parallel work begins.