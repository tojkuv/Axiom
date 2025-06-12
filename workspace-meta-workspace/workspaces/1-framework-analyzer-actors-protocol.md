# FRAMEWORK-ANALYZER-ACTORS-PROTOCOL

Parallel framework analysis actors that coordinate to avoid duplicate work and ensure comprehensive coverage.

## Activation
```
@FRAMEWORK_ANALYSIS_ACTOR execute <workspace_directory>
```

*Note: The workspace directory contains CODEBASE (required) and may contain ANALYSES folder with previous analyses*

## Process
1. **Setup** - Create ANALYSES folder if it doesn't exist in the workspace directory
2. **Discover** - Read existing analyses in ANALYSES folder (if any) to identify covered scopes
3. **Analyze Codebase** - Examine the CODEBASE directory to understand framework structure and identify analysis opportunities
4. **Select** - Choose unexplored scope area based on codebase structure and existing analysis coverage
5. **Assess** - Identify critical gaps, incomplete features, enhancement opportunities in selected scope within the codebase
6. **Generate** - Create specific suggestions with code samples based on codebase analysis
7. **Document** - Create uniquely-named analysis report: `ANALYSIS-{SCOPE}-{TIMESTAMP}.md` in the ANALYSES folder

## Outputs
- Scope-focused analysis with critical gaps, incomplete features, enhancements
- Implementation samples for selected scope area
- Requirements-ready suggestions with acceptance criteria
- Unique analysis file preventing conflicts with parallel actors

## Success Criteria
- ANALYSES folder created if it didn't exist
- Selected scope thoroughly analyzed without duplicating existing work
- Implementation samples provided for each suggestion based on actual codebase structure
- Unique file created with no naming conflicts
- Coverage gaps filled efficiently through parallel coordination
- Analysis based on actual code in CODEBASE directory

## MVP Focus - Explicitly Excluded
This protocol focuses on current framework analysis and deliberately excludes:
- Version control integration analysis
- Database schema analysis concerns
- Migration pathway analysis
- Deprecation management analysis
- Legacy code preservation analysis
- Backward compatibility analysis
- Breaking change mitigation analysis
- Semantic versioning analysis
- API stability preservation analysis across versions
- Configuration migration analysis
- Deployment versioning analysis
- Release management analysis
- Rollback procedure analysis
- Multi-version API support analysis

## Session Template

# FRAMEWORK-ANALYSIS-{SCOPE}-{ACTOR_ID}-{TIMESTAMP}

*Scope-Focused Framework Analysis*

## Meta-Data
- **Date**: {DATE}
- **Actor ID**: {ACTOR_ID}
- **Selected Scope**: {SCOPE_AREA}
- **Workspace Directory**: {WORKSPACE_DIRECTORY}
- **Codebase Analyzed**: {CODEBASE_DIRECTORY}
- **Existing Analyses Reviewed**: {EXISTING_ANALYSIS_COUNT}
- **Coverage Gap Identified**: {COVERAGE_GAP_DESCRIPTION}

## Critical Issues in {SCOPE_AREA}
### Critical Gap: {CRITICAL_ISSUE_TITLE}
**Scope**: {SCOPE_AREA}
**Impact**: {IMPACT_DESCRIPTION}

**Current State**:
```swift
{CURRENT_CODE}
```

**Required Fix**:
```swift
{FIX_CODE}
```

## Incomplete Features in {SCOPE_AREA}
### Incomplete: {INCOMPLETE_FEATURE_TITLE}
**Completion Level**: {COMPLETION_PERCENTAGE}
**Missing**: {MISSING_FUNCTIONALITY}

**Current Implementation**:
```swift
{PARTIAL_CODE}
```

**Completion Code**:
```swift
{COMPLETION_CODE}
```

## Enhancement Opportunities in {SCOPE_AREA}
### Enhancement: {ENHANCEMENT_TITLE}
**Type**: {ENHANCEMENT_TYPE}
**Benefit**: {IMPROVEMENT_BENEFIT}

**Current**:
```swift
{CURRENT_CODE}
```

**Enhanced**:
```swift
{ENHANCED_CODE}
```
