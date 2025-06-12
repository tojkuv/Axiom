# CODEBASE-REQUIREMENTS-DISPATCHER-PROTOCOL

Analyze codebase and generate prioritized requirements for provisioner, parallel workers, and stabilizer.

## Activation
```
@CODEBASE_REQUIREMENTS_DISPATCHER execute <workspace_directory>
```

## Process
1. **Collect** - Read all existing analyses from `ANALYSES` directory
2. **Deep Analyze** - Perform comprehensive analysis of the actual codebase in `CODEBASE` directory to verify analysis suggestions and inform decisions based on current codebase state
3. **Meta-Analyze** - Identify overlapping suggestions, conflicts, and synthesize correct approaches using codebase verification to make informed decisions
4. **Resolve** - Make definitive decisions on conflicting recommendations and consolidate requirements
5. **Identify** - Determine separable technical areas and module boundaries from synthesized requirements
6. **Allocate** - Set worker count based on identified technical areas (dynamic: 2-8 workers)
7. **Structure** - Create directory structure: `WORKERS/PROVISIONER/ARTIFACTS/`, `WORKERS/WORKER-{AREA}/ARTIFACTS/`, `WORKERS/STABILIZER/ARTIFACTS/`, and `META-ANALYSIS/`
8. **Generate** - Create multiple semantic requirement files, one at a time, with sequenced requirements based on separation of concerns (many files per worker area)
9. **Validate** - Generate requirements validation to confirm all issues are covered and all requirement files created successfully

## Priority Levels
- **Critical** - Framework-breaking issues (immediate priority)
- **Incomplete** - Partially implemented features (high priority)
- **Enhancement** - Quality improvements (low priority)

## Implementation Flow
**Phase 1: Provisioner** → **Phase 2: Parallel Workers** → **Phase 3: Stabilizer**

## Outputs
- `META-ANALYSIS/META-ANALYSIS-{TIMESTAMP}.md` - Synthesis of all analyses with conflict resolutions
- `META-ANALYSIS/REQUIREMENTS-VALIDATION-{TIMESTAMP}.md` - Validation that all requirements were generated and all issues addressed
- **Provisioner Requirements** (Phase 1 - Prerequisites for parallel workers):
  - `WORKERS/PROVISIONER/ARTIFACTS/REQUIREMENTS-0N-{SEMANTIC_CONCERN_N}-{TIMESTAMP}.md`
- **Worker Requirements** (Phase 2 - Parallel implementation in isolation):
  - `WORKERS/WORKER-{AREA}/ARTIFACTS/REQUIREMENTS-0N-{SEMANTIC_CONCERN_N}-{TIMESTAMP}.md`
- **Stabilizer Requirements** (Phase 3 - Parallel work integration and conflict resolution):
  - `WORKERS/STABILIZER/ARTIFACTS/REQUIREMENTS-0N-{SEMANTIC_CONCERN_N}-{TIMESTAMP}.md`

## Success Criteria
- Conflicting recommendations analyzed and definitive approaches chosen
- All critical and incomplete issues assigned
- Clear implementation guidance provided with meta-analysis rationale
- Requirements validation confirms complete coverage of all identified issues

## MVP Focus - Explicitly Excluded
This protocol focuses on current codebase state and deliberately excludes:
- Version control integration requirements
- Database schema refactoring requirements
- Migration pathway requirements
- Deprecation management requirements
- Legacy code preservation requirements
- Backward compatibility requirements
- Breaking change mitigation requirements
- Semantic versioning requirements
- API stability preservation across versions
- Configuration migration requirements
- Deployment versioning requirements
- Release management requirements
- Rollback procedure requirements
- Multi-version API support requirements

## Meta-Analysis Template

*Generated in META-ANALYSIS/META-ANALYSIS-{TIMESTAMP}.md*

# META-ANALYSIS-{TIMESTAMP}

*Synthesis of Framework Analyses*

## Meta-Data
- **Date**: {DATE}
- **Analyses Reviewed**: {ANALYSIS_COUNT}
- **Overlaps Identified**: {OVERLAP_COUNT}
- **Conflicts Resolved**: {CONFLICT_COUNT}
- **Source Directory**: {SOURCE_DIRECTORY}

## Analysis Sources
### Analyses Reviewed
- {ANALYSIS_1}: {SCOPE_1} - {SUGGESTIONS_COUNT_1} suggestions
- {ANALYSIS_2}: {SCOPE_2} - {SUGGESTIONS_COUNT_2} suggestions
- {ANALYSIS_3}: {SCOPE_3} - {SUGGESTIONS_COUNT_3} suggestions

## Overlapping Suggestions
### Overlap: {OVERLAP_TITLE_1}
**Scope Areas**: {OVERLAPPING_SCOPES}
**Duplicate Suggestions**:
- {ANALYSIS_A}: {SUGGESTION_A}
- {ANALYSIS_B}: {SUGGESTION_B}
- {ANALYSIS_C}: {SUGGESTION_C}

**Meta-Analysis Decision**: {CHOSEN_APPROACH}
**Rationale**: {DECISION_RATIONALE}
**Implementation**: {CONSOLIDATED_IMPLEMENTATION}

## Conflicting Recommendations
### Conflict: {CONFLICT_TITLE_1}
**Conflicting Approaches**:
- {ANALYSIS_X}: {APPROACH_X}
- {ANALYSIS_Y}: {APPROACH_Y}

**Analysis Comparison**:
- {APPROACH_X} Benefits: {BENEFITS_X}
- {APPROACH_X} Drawbacks: {DRAWBACKS_X}
- {APPROACH_Y} Benefits: {BENEFITS_Y}
- {APPROACH_Y} Drawbacks: {DRAWBACKS_Y}

**Meta-Analysis Decision**: {CHOSEN_CONFLICT_RESOLUTION}
**Rationale**: {CONFLICT_RESOLUTION_RATIONALE}
**Implementation**: {RESOLVED_IMPLEMENTATION}

## Synthesized Requirements
### Critical Requirements (Consolidated)
- {CRITICAL_REQUIREMENT_1}: {ASSIGNED_TO_AREA_1}
- {CRITICAL_REQUIREMENT_2}: {ASSIGNED_TO_AREA_2}
- {CRITICAL_REQUIREMENT_3}: {ASSIGNED_TO_AREA_3}

### Incomplete Requirements (Consolidated)
- {INCOMPLETE_REQUIREMENT_1}: {ASSIGNED_TO_AREA_1}
- {INCOMPLETE_REQUIREMENT_2}: {ASSIGNED_TO_AREA_2}
- {INCOMPLETE_REQUIREMENT_3}: {ASSIGNED_TO_AREA_3}

### Enhancement Requirements (Consolidated)
- {ENHANCEMENT_REQUIREMENT_1}: {ASSIGNED_TO_AREA_1}
- {ENHANCEMENT_REQUIREMENT_2}: {ASSIGNED_TO_AREA_2}
- {ENHANCEMENT_REQUIREMENT_3}: {ASSIGNED_TO_AREA_3}

## Technical Area Allocation
### Worker Areas Defined
- **Worker 1**: {AREA_1} - {REQUIREMENT_COUNT_1} requirements
- **Worker 2**: {AREA_2} - {REQUIREMENT_COUNT_2} requirements
- **Worker 3**: {AREA_3} - {REQUIREMENT_COUNT_3} requirements

### Implementation Phase Dependencies
#### Phase 1: Provisioner Prerequisites
1. {PROVISIONER_SEQUENCE_1} - {PROVISIONER_RATIONALE_1}
2. {PROVISIONER_SEQUENCE_2} - {PROVISIONER_RATIONALE_2}
3. {PROVISIONER_SEQUENCE_N} - {PROVISIONER_RATIONALE_N}

#### Phase 2: Parallel Worker Sequences (Independent)
- **{WORKER_1}**: {WORKER_1_SEQUENCE_SUMMARY}
- **{WORKER_2}**: {WORKER_2_SEQUENCE_SUMMARY}
- **{WORKER_3}**: {WORKER_3_SEQUENCE_SUMMARY}

#### Phase 3: Stabilizer Integration
1. {STABILIZER_INTEGRATION_1} - {INTEGRATION_RATIONALE_1}
2. {STABILIZER_CONFLICT_RESOLUTION_2} - {CONFLICT_RATIONALE_2}
3. {STABILIZER_GAP_COMPLETION_3} - {GAP_RATIONALE_3}

### Cross-Area Dependencies
- {DEPENDENCY_1}: {AREAS_INVOLVED_1}
- {DEPENDENCY_2}: {AREAS_INVOLVED_2}
- {DEPENDENCY_3}: {AREAS_INVOLVED_3}

## Meta-Analysis Decisions Log
### Decision 1: {DECISION_TITLE_1}
**Options Considered**: {OPTIONS_1}
**Chosen**: {CHOSEN_OPTION_1}
**Rationale**: {DECISION_RATIONALE_1}
**Impact**: {DECISION_IMPACT_1}

### Decision 2: {DECISION_TITLE_2}
**Options Considered**: {OPTIONS_2}
**Chosen**: {CHOSEN_OPTION_2}
**Rationale**: {DECISION_RATIONALE_2}
**Impact**: {DECISION_IMPACT_2}

## Sequenced Semantic Requirements Template

*Generated as REQUIREMENTS-{SEQUENCE_NUMBER}-{SEMANTIC_CONCERN}-{TIMESTAMP}.md (sequentially numbered files)*

# REQUIREMENTS-{SEQUENCE_NUMBER}-{SEMANTIC_CONCERN}-{WORKER_AREA}-{TIMESTAMP}

*{SEMANTIC_CONCERN} Requirements for {WORKER_AREA} (Implementation Sequence {SEQUENCE_NUMBER})*

## Meta-Data
- **Area**: {WORKER_AREA}
- **Sequence Number**: {SEQUENCE_NUMBER} (Implementation order within {WORKER_AREA})
- **Semantic Concern**: {SEMANTIC_CONCERN}
- **Total Requirements**: {TOTAL_REQUIREMENT_COUNT}
- **Critical**: {CRITICAL_COUNT} | **Incomplete**: {INCOMPLETE_COUNT} | **Enhancement**: {ENHANCEMENT_COUNT}
- **Implementation Sequence**: Ordered by dependencies and logical flow
- **Codebase**: {SOURCE_DIRECTORY}
- **Dependencies**: {DEPENDENCY_AREAS}

## Implementation Sequence Overview
1. {SEQUENCE_STEP_1} - {SEQUENCE_RATIONALE_1}
2. {SEQUENCE_STEP_2} - {SEQUENCE_RATIONALE_2}
3. {SEQUENCE_STEP_3} - {SEQUENCE_RATIONALE_3}
4. {SEQUENCE_STEP_N} - {SEQUENCE_RATIONALE_N}

---

## [Sequence 1] Critical: {CRITICAL_REQUIREMENT_TITLE}
**Priority**: Critical | **Impact**: {FRAMEWORK_BREAKING_IMPACT}
**Implementation Order**: First - Required foundation for subsequent work

**Problem**: {CRITICAL_PROBLEM_DESCRIPTION}

**Current State**:
```swift
{CURRENT_BROKEN_CODE}
```

**Required Fix**:
```swift
{REQUIRED_FIX_CODE}
```

**Acceptance Criteria**:
- [ ] {CRITICAL_CRITERION_1}
- [ ] {CRITICAL_CRITERION_2}

**Guidance**: {CRITICAL_GUIDANCE}

**Dependencies**: {PREREQUISITE_REQUIREMENTS}
**Enables**: {SUBSEQUENT_REQUIREMENTS}

---

## [Sequence 2] Incomplete: {INCOMPLETE_REQUIREMENT_TITLE}
**Priority**: High | **Completion**: {COMPLETION_PERCENTAGE}%
**Implementation Order**: Second - Builds on Sequence 1 foundation

**Problem**: {INCOMPLETE_PROBLEM_DESCRIPTION}

**Current Implementation**:
```swift
{PARTIAL_IMPLEMENTATION_CODE}
```

**Required Completion**:
```swift
{COMPLETION_CODE}
```

**Acceptance Criteria**:
- [ ] {INCOMPLETE_CRITERION_1}
- [ ] {INCOMPLETE_CRITERION_2}

**Guidance**: {INCOMPLETE_GUIDANCE}

**Dependencies**: {PREREQUISITE_REQUIREMENTS}
**Enables**: {SUBSEQUENT_REQUIREMENTS}

---

## [Sequence 3] Enhancement: {ENHANCEMENT_REQUIREMENT_TITLE}
**Priority**: Low | **Benefit**: {IMPROVEMENT_VALUE}
**Implementation Order**: Third - Optimizes completed functionality

**Problem**: {ENHANCEMENT_PROBLEM_DESCRIPTION}

**Current Implementation**:
```swift
{CURRENT_SUBOPTIMAL_CODE}
```

**Enhanced Implementation**:
```swift
{ENHANCED_CODE}
```

**Acceptance Criteria**:
- [ ] {ENHANCEMENT_CRITERION_1}
- [ ] {ENHANCEMENT_CRITERION_2}

**Guidance**: {ENHANCEMENT_GUIDANCE}

**Dependencies**: {PREREQUISITE_REQUIREMENTS}
**Enables**: {SUBSEQUENT_REQUIREMENTS}

---

*Continue with all requirements related to this semantic concern in dependency order*

## Sequencing Principles
- **Foundation First**: Critical infrastructure and core components implemented before dependent features
- **Dependency Order**: Requirements ordered so prerequisites are completed before dependents
- **Logical Flow**: Implementation follows natural progression within semantic concern
- **Priority Integration**: Critical requirements typically early, but sequenced by dependencies within priority levels

## Examples of Semantic Concerns with Sequencing

### Phase 1: Provisioner Semantic Areas (Prerequisites)
- **REQUIREMENTS-01-BUILD-SYSTEM**: Dependencies, compilation, automation
  - *Sequence*: 1) Dependency resolution → 2) Build configuration → 3) Automation scripts
- **REQUIREMENTS-02-CORE-APIS**: Foundation interfaces, shared contracts
  - *Sequence*: 1) Base protocols → 2) Core interfaces → 3) Shared implementations → 4) Integration contracts
- **REQUIREMENTS-03-TESTING-FRAMEWORK**: Test utilities, quality gates
  - *Sequence*: 1) Test infrastructure → 2) Test utilities → 3) Quality gates → 4) CI integration

### Phase 2: Worker Semantic Areas (Parallel Implementation)
- **REQUIREMENTS-01-DATA-MODELS**: Entity definitions, validation, persistence
  - *Sequence*: 1) Core entities → 2) Relationships → 3) Validation rules → 4) Persistence layer
- **REQUIREMENTS-02-AUTHENTICATION**: Login, security, user management
  - *Sequence*: 1) Security foundation → 2) Authentication flow → 3) User management → 4) Authorization
- **REQUIREMENTS-03-NETWORKING**: API clients, communication protocols
  - *Sequence*: 1) Network foundation → 2) API contracts → 3) Client implementation → 4) Error handling
- **REQUIREMENTS-04-UI-COMPONENTS**: Views, controls, user interface
  - *Sequence*: 1) Base components → 2) Composite views → 3) Navigation → 4) Styling/themes
- **REQUIREMENTS-05-BUSINESS-LOGIC**: Domain rules, workflows, processing
  - *Sequence*: 1) Core domain logic → 2) Workflows → 3) Business rules → 4) Validation/processing
- **REQUIREMENTS-06-ERROR-HANDLING**: Exception management, recovery
  - *Sequence*: 1) Error types → 2) Handling mechanisms → 3) Recovery strategies → 4) Logging/reporting

### Phase 3: Stabilizer Semantic Areas (Integration & Resolution)
- **REQUIREMENTS-01-INTEGRATION**: Merge parallel worker implementations
  - *Sequence*: 1) Collect worker outputs → 2) Identify integration points → 3) Merge implementations → 4) Resolve API mismatches
- **REQUIREMENTS-02-CONFLICT-RESOLUTION**: Resolve implementation conflicts
  - *Sequence*: 1) Identify conflicts → 2) Analyze approaches → 3) Choose optimal solution → 4) Implement resolution
- **REQUIREMENTS-03-GAP-COMPLETION**: Complete missing functionality
  - *Sequence*: 1) Identify gaps → 2) Prioritize missing features → 3) Implement completions → 4) Validate integration

## Requirements Validation Template

*Generated in META-ANALYSIS/REQUIREMENTS-VALIDATION-{TIMESTAMP}.md*

# REQUIREMENTS-VALIDATION-{TIMESTAMP}

*Validation of Complete Requirements Coverage*

## Meta-Data
- **Date**: {DATE}
- **Source Meta-Analysis**: META-ANALYSIS-{TIMESTAMP}.md
- **Total Issues Identified**: {TOTAL_ISSUES_COUNT}
- **Total Requirements Generated**: {TOTAL_REQUIREMENTS_COUNT}
- **Validation Status**: {PASS/FAIL}
- **Source Directory**: {SOURCE_DIRECTORY}

## Coverage Summary
- **Critical Issues**: {CRITICAL_ISSUES_COUNT} identified → {CRITICAL_REQUIREMENTS_COUNT} requirements generated
- **Incomplete Issues**: {INCOMPLETE_ISSUES_COUNT} identified → {INCOMPLETE_REQUIREMENTS_COUNT} requirements generated
- **Enhancement Issues**: {ENHANCEMENT_ISSUES_COUNT} identified → {ENHANCEMENT_REQUIREMENTS_COUNT} requirements generated

## Issue-to-Requirement Mapping

### Critical Issues Coverage
| Issue ID | Issue Description | Assigned Requirement | Worker/Provisioner Area | Status |
|----------|------------------|---------------------|------------------------|--------|
| {CRITICAL_ISSUE_1} | {CRITICAL_DESCRIPTION_1} | {REQUIREMENT_FILE_1} | {AREA_1} | Covered |
| {CRITICAL_ISSUE_2} | {CRITICAL_DESCRIPTION_2} | {REQUIREMENT_FILE_2} | {AREA_2} | Covered |
| {CRITICAL_ISSUE_N} | {CRITICAL_DESCRIPTION_N} | {REQUIREMENT_FILE_N} | {AREA_N} | Covered |

### Incomplete Issues Coverage
| Issue ID | Issue Description | Assigned Requirement | Worker/Provisioner Area | Status |
|----------|------------------|---------------------|------------------------|--------|
| {INCOMPLETE_ISSUE_1} | {INCOMPLETE_DESCRIPTION_1} | {REQUIREMENT_FILE_1} | {AREA_1} | Covered |
| {INCOMPLETE_ISSUE_2} | {INCOMPLETE_DESCRIPTION_2} | {REQUIREMENT_FILE_2} | {AREA_2} | Covered |
| {INCOMPLETE_ISSUE_N} | {INCOMPLETE_DESCRIPTION_N} | {REQUIREMENT_FILE_N} | {AREA_N} | Covered |

### Enhancement Issues Coverage
| Issue ID | Issue Description | Assigned Requirement | Worker/Provisioner Area | Status |
|----------|------------------|---------------------|------------------------|--------|
| {ENHANCEMENT_ISSUE_1} | {ENHANCEMENT_DESCRIPTION_1} | {REQUIREMENT_FILE_1} | {AREA_1} | Covered |
| {ENHANCEMENT_ISSUE_2} | {ENHANCEMENT_DESCRIPTION_2} | {REQUIREMENT_FILE_2} | {AREA_2} | Covered |
| {ENHANCEMENT_ISSUE_N} | {ENHANCEMENT_DESCRIPTION_N} | {REQUIREMENT_FILE_N} | {AREA_N} | Covered |

## Requirements File Validation

### Provisioner Requirements Generated (Phase 1)
- `WORKERS/PROVISIONER/ARTIFACTS/REQUIREMENTS-01-{SEMANTIC_AREA_1}-{TIMESTAMP}.md` - {REQUIREMENT_COUNT_1} requirements
- `WORKERS/PROVISIONER/ARTIFACTS/REQUIREMENTS-02-{SEMANTIC_AREA_2}-{TIMESTAMP}.md` - {REQUIREMENT_COUNT_2} requirements
- `WORKERS/PROVISIONER/ARTIFACTS/REQUIREMENTS-0N-{SEMANTIC_AREA_N}-{TIMESTAMP}.md` - {REQUIREMENT_COUNT_N} requirements

### Worker Requirements Generated
#### Worker Area: {WORKER_AREA_1}
- `WORKERS/WORKER-{AREA_1}/ARTIFACTS/REQUIREMENTS-01-{SEMANTIC_CONCERN_1}-{TIMESTAMP}.md` - {REQ_COUNT_1} requirements
- `WORKERS/WORKER-{AREA_1}/ARTIFACTS/REQUIREMENTS-02-{SEMANTIC_CONCERN_2}-{TIMESTAMP}.md` - {REQ_COUNT_2} requirements
- `WORKERS/WORKER-{AREA_1}/ARTIFACTS/REQUIREMENTS-0N-{SEMANTIC_CONCERN_N}-{TIMESTAMP}.md` - {REQ_COUNT_N} requirements

#### Worker Area: {WORKER_AREA_2}
- `WORKERS/WORKER-{AREA_2}/ARTIFACTS/REQUIREMENTS-01-{SEMANTIC_CONCERN_1}-{TIMESTAMP}.md` - {REQ_COUNT_1} requirements
- `WORKERS/WORKER-{AREA_2}/ARTIFACTS/REQUIREMENTS-02-{SEMANTIC_CONCERN_2}-{TIMESTAMP}.md` - {REQ_COUNT_2} requirements

### Stabilizer Requirements Generated (Phase 3)
- `WORKERS/STABILIZER/ARTIFACTS/REQUIREMENTS-01-{INTEGRATION_AREA_1}-{TIMESTAMP}.md` - {INTEGRATION_COUNT_1} requirements
- `WORKERS/STABILIZER/ARTIFACTS/REQUIREMENTS-02-{CONFLICT_RESOLUTION}-{TIMESTAMP}.md` - {CONFLICT_COUNT_2} requirements
- `WORKERS/STABILIZER/ARTIFACTS/REQUIREMENTS-03-{GAP_COMPLETION}-{TIMESTAMP}.md` - {GAP_COUNT_3} requirements

## Gap Analysis

### Uncovered Issues (VALIDATION FAILURE)
*Note: This section should be empty for successful validation*

| Issue ID | Issue Description | Priority | Reason Not Covered |
|----------|------------------|----------|-------------------|
| {UNCOVERED_ISSUE_1} | {UNCOVERED_DESCRIPTION_1} | {PRIORITY_1} | {REASON_1} |

### Orphaned Requirements (WARNING)
*Requirements generated that don't map to identified issues*

| Requirement File | Requirement Description | Rationale |
|-----------------|------------------------|-----------|
| {ORPHANED_REQ_1} | {ORPHANED_DESCRIPTION_1} | {ORPHANED_RATIONALE_1} |

## Meta-Analysis Decision Validation

### Conflict Resolutions Implemented
- **{CONFLICT_1}**: Resolved as {RESOLUTION_1} → Implemented in {REQUIREMENT_FILE_1}
- **{CONFLICT_2}**: Resolved as {RESOLUTION_2} → Implemented in {REQUIREMENT_FILE_2}
- **{CONFLICT_N}**: Resolved as {RESOLUTION_N} → Implemented in {REQUIREMENT_FILE_N}

### Overlap Consolidations Implemented
- **{OVERLAP_1}**: Consolidated as {CONSOLIDATION_1} → Implemented in {REQUIREMENT_FILE_1}
- **{OVERLAP_2}**: Consolidated as {CONSOLIDATION_2} → Implemented in {REQUIREMENT_FILE_2}
- **{OVERLAP_N}**: Consolidated as {CONSOLIDATION_N} → Implemented in {REQUIREMENT_FILE_N}

## Validation Results

### Overall Status: {PASS/FAIL}

**PASS Criteria:**
- All identified issues have corresponding requirements
- All requirement files generated successfully
- No gaps in coverage identified
- Meta-analysis decisions properly implemented

**FAIL Criteria (if any):**
- {FAILURE_REASON_1}
- {FAILURE_REASON_2}
- {FAILURE_REASON_N}

### Recommendations
**If PASS**: Proceed with Phase 1 (Provisioner), Phase 2 (Parallel Workers), Phase 3 (Stabilizer) implementation using generated requirements
**If FAIL**: {REMEDIATION_ACTIONS}

## Quality Metrics
- **Coverage Rate**: {COVERED_ISSUES}/{TOTAL_ISSUES} = {COVERAGE_PERCENTAGE}%
- **Requirements Density**: {TOTAL_REQUIREMENTS}/{TOTAL_ISSUES} = {DENSITY_RATIO} requirements per issue
- **Critical Coverage**: {CRITICAL_COVERED}/{CRITICAL_TOTAL} = {CRITICAL_PERCENTAGE}%
- **Incomplete Coverage**: {INCOMPLETE_COVERED}/{INCOMPLETE_TOTAL} = {INCOMPLETE_PERCENTAGE}%
- **Enhancement Coverage**: {ENHANCEMENT_COVERED}/{ENHANCEMENT_TOTAL} = {ENHANCEMENT_PERCENTAGE}%
