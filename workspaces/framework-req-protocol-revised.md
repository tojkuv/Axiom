# FRAMEWORK-REQ-PROTOCOL-REVISED

Transform insights from multiple analysis files into actionable framework requirements and development cycle index through evidence-based planning and comprehensive framework codebase examination.

## Protocol Activation

```text
@FRAMEWORK_REQUIREMENTS generate <framework_dir> <analysis_files_pattern> <template_file>
```

**Outputs Generated:**
- Multiple framework requirement artifacts (REQUIREMENTS-XXX-*.md)
- Development cycle index (DEVELOPMENT-CYCLE-INDEX.md)
- Implementation roadmap with dependency mapping

**Required Parameters:**
- `<framework_dir>`: Path to framework codebase (examined FIRST to understand current state)
- `<analysis_files_pattern>`: Pattern/path to analysis files (processed after framework review)
- `<template_file>`: Requirements template for each generated artifact

## Command

### Generate - Create Requirements from Analysis

The generate command creates multiple framework requirement artifacts AND a development cycle index by FIRST examining the current framework codebase, then analyzing insights from multiple analysis files. Each requirement is generated as a separate file using the template, followed by an index that organizes them into an implementable development cycle. It requires three inputs processed in order:

1. **Framework Directory**: Path to the current framework codebase (examined FIRST to understand structure, APIs, patterns, and constraints)
2. **Analysis Files Pattern**: Pattern or path to multiple analysis files of any format (*.md, specific files, or directory) (processed AFTER framework examination)
3. **Template File**: Single requirement template to use for each generated requirement

```bash
@FRAMEWORK_REQUIREMENTS generate \
  /path/to/AxiomFramework \
  "/path/to/analyses/*.md" \
  /path/to/framework-requirements-template.md
```

### Example Usage

```bash
@FRAMEWORK_REQUIREMENTS generate \
  /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-framework/AxiomFramework \
  "/Users/tojkuv/Documents/GitHub/axiom-apple/workspace-framework/analyses/*.md" \
  /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-meta-workspace/workspaces/framework-requirements-template.md
```

## Process Flow

```text
1. FRAMEWORK CODEBASE EXAMINATION (MANDATORY FIRST STEP)
   - Map entire framework directory structure
   - Catalog all public APIs and their patterns
   - Identify architectural constraints and opportunities
   - Document current implementation patterns
   - Establish baseline for improvement feasibility
   
2. ANALYSIS FILES PROCESSING (AFTER FRAMEWORK REVIEW)
   - Read and parse all analysis files (any format)
   - Extract common patterns, pain points, and improvement opportunities
   - Cross-reference issues with framework examination findings
   
3. CONFLICT DETECTION AND RESOLUTION
   - Identify conflicting recommendations across analyses
   - Apply decision criteria to resolve conflicts
   - Prioritize based on evidence strength and technical merit
   - Document conflict resolutions for transparency
   
4. COMPREHENSIVE ISSUE TRACKING
   - Create master list of ALL issues from ALL analyses
   - Track which issues are addressed by which requirements
   - Identify any unaddressed issues
   - Ensure complete coverage of identified problems
   
5. EVIDENCE-BASED REQUIREMENT IDENTIFICATION
   - Identify recurring themes across analyses
   - Group related issues and opportunities
   - Apply conflict resolution decisions
   - Prioritize based on frequency, impact, and framework feasibility
   - Map improvement areas to specific framework components identified in step 1
   
6. REQUIREMENT DECOMPOSITION
   - For each identified improvement area:
     - Decompose into implementable requirements
     - Consider dependencies and implementation order
     - Validate against framework constraints from examination
     - Ensure all related issues are addressed
     
7. REQUIREMENT ARTIFACT GENERATION
   - For each requirement:
     - Design improvement using template structure
     - Include evidence from relevant analysis files
     - Reference framework components from codebase examination
     - Document conflict resolutions if applicable
     - Generate individual requirement artifact
     
8. ISSUE COVERAGE VALIDATION
   - Verify every issue from analyses has a requirement
   - Document any intentionally unaddressed issues with rationale
   - Cross-reference requirements to source issues
   - Generate coverage report
     
9. DEVELOPMENT CYCLE INDEX GENERATION
   - Create comprehensive implementation roadmap
   - Map requirement dependencies and implementation order
   - Generate development cycle phases with clear milestones
   - Organize requirements into coherent development sprints
   - Provide progress tracking and validation checkpoints
   
10. OUTPUT VALIDATION
   - Ensure all requirements are framework-feasible
   - Verify analysis traceability maintained
   - Confirm ALL identified issues addressed or documented
   - Validate conflict resolutions are properly documented
   - Ensure development cycle index completeness and sequencing
```

## Generation Process

The command uses the three inputs to create multiple requirement artifacts, each focused on a specific improvement:

### Input Processing

1. **Framework Directory Analysis** (MANDATORY FIRST STEP)
   - Performs comprehensive framework codebase examination
   - Maps complete directory structure and module organization
   - Catalogs all public APIs, protocols, and architectural patterns
   - Identifies existing test patterns and utilities
   - Documents current implementation constraints and opportunities
   - Establishes baseline understanding before any analysis file processing
   - Creates framework component inventory for improvement mapping

2. **Analysis Files Processing**
   - Reads all analysis files regardless of format
   - Extracts pain points, patterns, and opportunities
   - Identifies recurring issues across multiple analyses
   - Detects conflicting recommendations between analyses
   - Groups related problems into improvement themes
   - Prioritizes based on frequency and severity
   - Collects evidence trails from all source files
   - Creates comprehensive issue inventory

3. **Template Application**
   - Uses the single-requirement template for each artifact
   - References relevant analysis evidence
   - Includes combined evidence from multiple source files
   - Maintains traceability to original analyses
   - Generates separate files for each requirement

### Improvement Area Identification

**From Analysis Files:**
- Parses all analysis files for common patterns
- Extracts evidence from contributing analyses
- Identifies recurring problems that can be separate requirements
- Groups related issues into improvement themes
- Assesses combined impact based on frequency and severity

**Framework Mapping:**
- Maps each theme to affected framework components
- Identifies code files requiring modification
- Finds related APIs that need coordination
- Discovers architectural patterns to preserve or change

### Requirement Generation Strategy
- Decomposes improvement areas into implementable chunks
- Creates requirements sized for 1-3 TDD sessions
- Orders requirements by dependencies
- Ensures each requirement is testable and measurable
- Maintains coherence across related requirements

### Example Output

```
STEP 1: FRAMEWORK CODEBASE EXAMINATION
Examining framework codebase at /Users/.../AxiomFramework...
✓ Mapped directory structure: 8 modules, 23 subdirectories
✓ Cataloged APIs: 127 public APIs across 15 core components
✓ Documented architectural patterns: 12 identified patterns
✓ Analyzed test infrastructure: 5 test utility categories
✓ Identified integration points: 34 cross-component dependencies
✓ Framework examination complete - baseline established

STEP 2: ANALYSIS FILES PROCESSING

Processing analysis files...
- Framework: /Users/.../AxiomFramework
- Analysis Files: 8 files found (various formats)
- Template: framework-requirements-template.md

Conflict Detection:
✓ Conflict found: State persistence approach
  - ANALYSIS-001: Recommends memory-based caching
  - ANALYSIS-003: Recommends disk-based persistence
  Resolution: Disk-based (stronger evidence, broader applicability)

✓ Conflict found: Async pattern preference
  - ANALYSIS-002: Callbacks for compatibility
  - ANALYSIS-004: Native async/await only
  Resolution: Native async/await (MVP allows breaking changes)

Issue Inventory:
✓ Total issues identified: 23 across 8 analyses
✓ Issues with conflicts: 5 (resolutions documented)
✓ Unique issues after deduplication: 18

Identified Improvement Areas:

State Management Issues (HIGH FREQUENCY)
- Found in: 5 analysis files
- Common patterns: Complex state updates, poor debugging
- Conflicts resolved: Persistence approach unified
- Framework Components: Sources/State/, Sources/Persistence/
- Decomposing into 3 requirements...

Testing Pain Points (HIGH FREQUENCY)
- Found in: 4 analysis files
- Common patterns: Verbose test setup, async test complexity
- Framework Components: Sources/Testing/, Tests/
- Decomposing into 2 requirements...

Async Operation Friction (MEDIUM FREQUENCY)
- Found in: 3 analysis files
- Common patterns: Callback complexity, state coordination
- Framework Components: Sources/Async/, Sources/State/
- Decomposing into 2 requirements...

Generating requirement artifacts:
✓ REQUIREMENTS-001-STATE-PERSISTENCE-CAPABILITY.md
✓ REQUIREMENTS-002-STATE-UPDATE-OPTIMIZATION.md  
✓ REQUIREMENTS-003-STATE-DEBUGGING-UTILITIES.md
✓ REQUIREMENTS-004-TEST-BUILDER-PATTERN.md
✓ REQUIREMENTS-005-ASYNC-TEST-UTILITIES.md
✓ REQUIREMENTS-006-NATIVE-ASYNC-AWAIT.md
✓ REQUIREMENTS-007-ASYNC-STATE-COORDINATION.md

Issue Coverage Report:
✓ Total issues identified: 18
✓ Issues addressed: 18/18 (100%)
✓ Requirements generated: 7
✓ Conflicts resolved: 5
✓ All analysis concerns addressed

Generated 7 requirement artifacts from 3 improvement areas

STEP 3: DEVELOPMENT CYCLE INDEX GENERATION

Creating development cycle index...
✓ Mapped requirement dependencies across 7 artifacts
✓ Organized into 3 development phases
✓ Created implementation roadmap with milestones
✓ Generated progress tracking framework
✓ Validated all 18 issues addressed across requirements
✓ DEVELOPMENT-CYCLE-INDEX.md created

Development Cycle Ready:
- Phase 1: State Management Foundation (REQ-001, REQ-002)
  Issues resolved: ISSUE-001, ISSUE-003, ISSUE-007, ISSUE-012
- Phase 2: Testing Infrastructure (REQ-004, REQ-005) 
  Issues resolved: ISSUE-002, ISSUE-008, ISSUE-009, ISSUE-014
- Phase 3: Async Integration (REQ-003, REQ-006, REQ-007)
  Issues resolved: ISSUE-004, ISSUE-005, ISSUE-006, ISSUE-010, ISSUE-011, ISSUE-013, ISSUE-015-018

All outputs ready for development cycle initiation
100% issue coverage achieved with documented conflict resolutions
```

## Requirements Artifact Generation

Each generated requirement artifact follows the template structure and contains:

### File Naming Convention
```
REQUIREMENTS-XXX-[DESCRIPTIVE-TITLE].md
```
- XXX: Sequential number
- DESCRIPTIVE-TITLE: Clear indication of what the requirement addresses
- Each requirement gets its own file in the framework workspace

### Development Cycle Index
The generated DEVELOPMENT-CYCLE-INDEX.md provides:

1. **Executive Overview**
   - Summary of all improvement areas addressed
   - Total requirements count and estimated effort
   - Expected development timeline and milestones

2. **Implementation Phases**
   - Logical grouping of requirements by dependencies
   - Phase-by-phase development roadmap
   - Clear entry and exit criteria for each phase

3. **Requirement Cross-Reference**
   - Complete catalog of all generated requirements
   - Dependency mapping between requirements
   - Priority and effort estimation matrix

4. **Progress Tracking Framework**
   - Development milestones and validation checkpoints
   - Success metrics for each phase
   - Risk mitigation strategies

### Content per Artifact
Using the single-requirement template, each file contains:

1. **Executive Summary**
   - Problem Statement: Specific issue identified across analyses
   - Proposed Solution: Targeted improvement (with conflict resolutions if applicable)
   - Expected Impact: Estimated improvement based on analysis evidence
   - Issues Addressed: List of specific issues from inventory resolved by this requirement

2. **Evidence Base**
   - Source Analyses: References to contributing analysis files
   - Combined Evidence: Data from multiple source analyses
   - Conflict Resolutions: Documentation of any resolved conflicts
   - Current State Example: Code showing the problem
   - Desired Experience: How it should work

3. **Requirement Details**
   - Current/Target State: Clear before/after
   - Acceptance Criteria: Measurable outcomes
   - Problem Resolution: How this addresses the identified issues

4. **API Design**
   - Specific APIs for this requirement only
   - Integration with existing framework
   - Coordination with related requirements

5. **Technical Design**
   - Implementation approach for this requirement
   - Performance and testing considerations
   - Dependencies on other requirements

6. **Success Criteria**
   - Validation specific to this requirement
   - Contribution to problem resolution metrics
   - Analysis-based success indicators
   - Verification that all mapped issues are resolved

## Development Cycle Index Structure

The generated index follows this structure:

```markdown
# DEVELOPMENT-CYCLE-INDEX

## Executive Summary
- X requirements generated from Y improvement areas
- Z development phases identified
- Total issues addressed: N/N (100%)
- Conflicts resolved: M
- Estimated timeline: N weeks

## Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2)
- REQUIREMENTS-001-STATE-PERSISTENCE-CAPABILITY
- REQUIREMENTS-002-STATE-UPDATE-OPTIMIZATION
- Dependencies: None
- Exit Criteria: Core state management enhanced

### Phase 2: Infrastructure (Weeks 3-4)
- REQUIREMENTS-004-TEST-BUILDER-PATTERN  
- REQUIREMENTS-005-ASYNC-TEST-UTILITIES
- Dependencies: Phase 1 complete
- Exit Criteria: Testing framework enhanced

### Phase 3: Integration (Weeks 5-6)
- REQUIREMENTS-003-STATE-DEBUGGING-UTILITIES
- REQUIREMENTS-006-NATIVE-ASYNC-AWAIT
- REQUIREMENTS-007-ASYNC-STATE-COORDINATION
- Dependencies: Phases 1-2 complete
- Exit Criteria: Full improvement areas addressed

## Requirement Dependencies
[Detailed dependency matrix]

## Issue Resolution Tracking
[Issue-to-requirement mapping and coverage validation]

## Progress Tracking
[Milestones and validation framework]
```

## Conflict Resolution Framework

### Conflict Detection
The protocol automatically detects when analyses provide conflicting recommendations:
- Different solutions for the same problem
- Contradictory architectural approaches
- Incompatible API design suggestions
- Opposing performance optimization strategies

### Resolution Criteria
When conflicts arise, apply these criteria in order:

1. **Evidence Strength** (Primary)
   - Frequency of issue across applications
   - Quantified impact metrics
   - Number of affected developers
   - Reproducibility of problem

2. **Technical Merit** (Secondary)
   - Architectural consistency
   - Framework maintainability
   - Performance implications
   - Future extensibility

3. **MVP Alignment** (Tie-breaker)
   - Simplicity over compatibility
   - Speed of implementation
   - Developer experience improvement
   - Breaking changes acceptable

### Documentation Requirements
All conflict resolutions must include:
- Conflicting analyses identified
- Options considered
- Criteria applied
- Final decision rationale
- Impact on other requirements

## Issue Tracking System

### Comprehensive Issue Inventory
The protocol maintains a master list of all issues:
```
ISSUE-001: Complex state updates (ANALYSIS-001, 003, 005)
ISSUE-002: Test setup verbosity (ANALYSIS-002, 004)
ISSUE-003: Async operation friction (ANALYSIS-001, 002, 003)
[...continues for all issues...]
```

### Issue-to-Requirement Mapping
Every issue must be addressed:
```
ISSUE-001 → REQUIREMENTS-001, REQUIREMENTS-002
ISSUE-002 → REQUIREMENTS-004
ISSUE-003 → REQUIREMENTS-006, REQUIREMENTS-007
[...complete mapping...]
```

### Coverage Validation
The protocol ensures:
- Every issue has at least one requirement
- No issues are overlooked
- Intentional omissions are documented with rationale
- Cross-references are bidirectional

## Best Practices

1. **Effective Input Usage**
   - **Framework Directory**: Examine thoroughly before processing analysis files
     - Map all components and their relationships
     - Understand current architectural patterns
     - Identify integration points for improvement areas
   - **Analysis Files**: Extract all recurring patterns and evidence
     - Focus on high-frequency issues first
     - Understand combined impact across files
     - Identify natural implementation sequencing
   - **Template File**: Follow structure completely, adapt for multiple analysis sources

2. **Improvement Area Decomposition**
   - **From Analysis Patterns:**
     - Break each improvement area into implementable requirements
     - Size requirements for 1-3 TDD sessions each
     - Maintain coherence across related requirements
     - Preserve evidence trails from all sources
   - **Framework Examination:**
     - Map improvement areas to actual code locations
     - Identify all affected components per area
     - Find integration points between requirements
     - Validate technical feasibility of solutions

3. **Framework-Aware Design**
   - Study existing APIs through framework directory examination
   - Maintain consistency with discovered patterns
   - Leverage MVP status for breaking changes where beneficial
   - Design holistic solutions that address entire improvement areas
   - Consider requirement interdependencies within areas

4. **Evidence Traceability**
   - Each requirement links to contributing analysis files
   - Include combined evidence from multiple source analyses
   - Reference original analysis identifiers directly
   - Show how requirement contributes to problem resolution
   - Maintain clear analysis-to-requirement mapping

5. **Validation Planning**
   - Define tests that validate problem resolution
   - Set metrics based on analysis evidence
   - Plan integration tests across requirements
   - Ensure cumulative impact addresses identified issues
   - Coordinate validation across all related requirements

6. **Conflict Resolution Excellence**
   - Detect all conflicts between analyses early
   - Apply consistent resolution criteria
   - Document decisions transparently
   - Consider cumulative impact of resolutions
   - Validate resolutions don't create new conflicts

7. **Comprehensive Issue Coverage**
   - Track every issue from every analysis
   - Map all issues to specific requirements
   - Validate 100% coverage or document exceptions
   - Maintain bidirectional traceability
   - Generate coverage reports for validation

8. **Output Quality**
   - Generate complete requirement sets per improvement area
   - Each artifact contributes to problem resolution
   - Include analysis context in all requirements
   - Provide clear API specifications per requirement
   - Document inter-requirement dependencies
   - Ensure requirements collectively address ALL identified issues

9. **Development Cycle Preparation**
   - Create comprehensive development cycle index
   - Map all requirement dependencies and implementation order
   - Organize requirements into logical development phases
   - Provide clear milestones and progress tracking framework
   - Ensure development cycle is immediately actionable
   - Include risk assessment and mitigation strategies for each phase
   - Validate all issues will be resolved through cycle completion

### Generation Summary
After processing multiple analysis files, the protocol will:
- Detect and resolve all conflicts between analyses
- Create comprehensive issue inventory from all sources
- Generate multiple requirement artifacts (typically 5-12)
- Ensure 100% coverage of identified issues
- Each addresses a specific aspect of an identified improvement area  
- Requirements are grouped by area for coherent implementation
- All artifacts use the same template structure
- Document conflict resolutions and coverage validation
- Generate comprehensive development cycle index with implementation roadmap
- Organize requirements into actionable development phases
- Provide dependency mapping and progress tracking framework
- Output location: Framework workspace requirements folder
- Development cycle ready for immediate initiation with all issues addressed