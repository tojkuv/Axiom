# STABILIZATION-ANALYZERS-PROTOCOL

Parallel analysis actors focused on critical issues and incomplete implementations to stabilize the foundation.

## Activation
```
ultrathink . run protocol @STABILIZATION_ACTOR <codebase_directory> [context_file]
```

*Note: The codebase directory contains the source code to analyze. Optional context file provides additional context about the codebase. Analyses are read from and written to the current working directory. IMPORTANT: Read the full content of existing analyses to understand previous insights, not just filenames.*

## Process
1. **Context** - Read context file (if provided) to understand user preferences, constraints, and focus areas
2. **Discover** - Read and analyze content of existing analyses in current working directory (if any) to understand what critical issues have been identified, what fixes were proposed, and what stability gaps remain unaddressed
3. **Systematic Exploration** - Use Task tool to systematically explore codebase structure and identify the most critical stability gap that hasn't been addressed by existing analyses
4. **Implementation Analysis** - Read actual source files to understand current implementations, their specific failure modes, and missing dependencies
5. **Gap Selection** - Choose the most critical unexplored scope area that blocks other infrastructure or causes immediate failures
6. **Root Cause Analysis** - Identify specific problems by analyzing implementation flaws, missing dependencies, race conditions, and incomplete logic flows
7. **Comprehensive Solutions** - Create complete working implementations and fixes based on understanding current implementation approaches and patterns
8. **Document** - Create uniquely-named analysis report: `STABILIZATION-{TIMESTAMP}-{SCOPE}.md` in the current working directory

## Outputs
- Implementation-focused analysis targeting the most critical stability gap that blocks other infrastructure or causes immediate failures
- Complete working implementations and fixes derived from understanding current implementation problems and missing dependencies
- Stability improvements grounded in analysis of existing implementation patterns and failure points
- Comprehensive solutions with acceptance criteria based on actual implementation analysis
- Unique analysis file preventing conflicts with parallel actors
- Building on previous analysis work to address unexplored critical infrastructure gaps

## Success Criteria
- Context file guidance applied (if provided) to prioritize critical issues
- Systematic codebase exploration using Task tool to identify the most critical unexplored stability gap
- Selected scope addresses foundational infrastructure that other systems depend on
- Actual source files read and analyzed to understand specific implementation failures and missing types/dependencies
- Complete working implementations provided for each critical issue, not just problem identification
- Incomplete features completed with full implementations following existing codebase patterns
- Fixes that respect existing implementation patterns and architectural decisions
- Unique file created with no naming conflicts in current working directory
- Analysis builds meaningfully on previous work without duplication
- Critical blocking infrastructure gaps resolved to enable other systems to function

## Artifact Template

*Generated in current working directory as STABILIZATION-{TIMESTAMP}-{SCOPE}.md*

# STABILIZATION-{TIMESTAMP}-{SCOPE}

*Stability-Focused Analysis Building on Previous Work*

## Meta-Data
- **Date**: {DATE}
- **Artifact Type**: Analysis
- **Actor ID**: {ACTOR_ID}
- **Selected Scope**: {SCOPE_AREA}
- **Codebase Directory**: {CODEBASE_DIRECTORY}
- **Context File Applied**: {CONTEXT_FILE_PATH}
- **Existing Analyses Reviewed**: {EXISTING_ANALYSIS_COUNT} in current working directory
- **Previous Analysis Insights**: {PREVIOUS_STABILITY_ANALYSIS_SUMMARY}
- **Scope Selection Rationale**: {WHY_THIS_SCOPE_CHOSEN_GIVEN_PREVIOUS_WORK}
- **Stability Gap Identified**: {STABILITY_GAP_DESCRIPTION}

## Previous Analysis Review
### Existing Analyses Found
- **{EXISTING_ANALYSIS_1}**: {CRITICAL_ISSUES_IDENTIFIED_1}
- **{EXISTING_ANALYSIS_2}**: {CRITICAL_ISSUES_IDENTIFIED_2}
- **{EXISTING_ANALYSIS_N}**: {CRITICAL_ISSUES_IDENTIFIED_N}

### Stability Gaps Identified from Previous Work
- **{STABILITY_GAP_1}**: {WHY_NOT_ADDRESSED_PREVIOUSLY}
- **{STABILITY_GAP_2}**: {CRITICAL_ISSUE_MISSED}
- **{STABILITY_GAP_3}**: {INCOMPLETE_IMPLEMENTATION_NOT_COVERED}

### Building on Previous Stability Work
{HOW_THIS_ANALYSIS_EXTENDS_PREVIOUS_STABILITY_WORK}

## Critical Issues in {SCOPE_AREA}

### Critical Issue: {CRITICAL_ISSUE_TITLE}
**Scope**: {SCOPE_AREA}
**Impact**: {IMPACT_DESCRIPTION}
**Severity**: {SEVERITY_LEVEL}

**Current Implementation Analysis**:
```{LANGUAGE}
{CURRENT_IMPLEMENTATION_CODE}
```

**Implementation Problem Identified**: {SPECIFIC_ISSUE_ANALYSIS}
**Root Cause**: {ROOT_CAUSE_EXPLANATION}

**Required Fix** (respecting existing patterns):
```{LANGUAGE}
{FIX_CODE}
```

**Acceptance Criteria**:
- {ACCEPTANCE_CRITERION_1}
- {ACCEPTANCE_CRITERION_2}

## Incomplete Features in {SCOPE_AREA}

### Incomplete: {INCOMPLETE_FEATURE_TITLE}
**Completion Level**: {COMPLETION_PERCENTAGE}
**Missing**: {MISSING_FUNCTIONALITY}
**Priority**: {COMPLETION_PRIORITY}

**Current Implementation Analysis**:
```{LANGUAGE}
{CURRENT_PARTIAL_IMPLEMENTATION_CODE}
```

**Implementation Assessment**: {WHAT_IS_MISSING_ANALYSIS}
**Completion Strategy**: {HOW_TO_COMPLETE_BASED_ON_PATTERNS}

**Completion Code** (following existing implementation approach):
```{LANGUAGE}
{COMPLETION_CODE}
```

**Completion Requirements**:
- {COMPLETION_REQUIREMENT_1}
- {COMPLETION_REQUIREMENT_2}

## Stability Improvements in {SCOPE_AREA}

### Stability Issue: {STABILITY_ISSUE_TITLE}
**Type**: {STABILITY_TYPE}
**Risk Level**: {RISK_ASSESSMENT}

**Current Implementation Analysis**:
```{LANGUAGE}
{CURRENT_UNSTABLE_IMPLEMENTATION_CODE}
```

**Stability Problem**: {SPECIFIC_STABILITY_ISSUE_ANALYSIS}
**Implementation Weakness**: {WHY_CURRENT_APPROACH_FAILS}

**Stabilized Code** (improved implementation):
```{LANGUAGE}
{STABLE_CODE}
```

**Error Handling Enhancement** (following codebase patterns):
```{LANGUAGE}
{ERROR_HANDLING_CODE}
```

## Completion Requirements
- **{MAJOR_COMPLETION_AREA_1}**: {COMPLETION_DESCRIPTION_1}
- **{MAJOR_COMPLETION_AREA_2}**: {COMPLETION_DESCRIPTION_2}
- **{MAJOR_COMPLETION_AREA_N}**: {COMPLETION_DESCRIPTION_N}