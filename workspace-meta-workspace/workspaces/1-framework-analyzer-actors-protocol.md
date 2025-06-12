# FRAMEWORK-ANALYZER-ACTORS-PROTOCOL

Parallel framework analysis actors that coordinate to avoid duplicate work and ensure comprehensive coverage.

## Activation
```
@FRAMEWORK_ANALYSIS_ACTOR execute <source_directory> <analyses_directory> <context_artifact> <unique_actor_id>
```

## Process
1. **Context** - Read framework context artifact to understand user preferences, constraints, and focus areas
2. **Discover** - Read existing analyses in analyses_directory to identify covered scopes
3. **Select** - Choose unexplored scope area
4. **Assess** - Identify critical gaps, incomplete features, enhancement opportunities in selected scope
5. **Analyze** - Generate specific suggestions with code samples following context guidance
6. **Document** - Create uniquely-named analysis report: `framework-analysis-{scope}-{actor_id}-{timestamp}.md`

## Outputs
- Scope-focused analysis with critical gaps, incomplete features, enhancements
- Implementation samples for selected scope area
- Requirements-ready suggestions with acceptance criteria
- Unique analysis file preventing conflicts with parallel actors

## Success Criteria
- Context artifact guidance applied to prioritize and focus analysis
- Selected scope thoroughly analyzed without duplicating existing work
- Implementation samples provided for each suggestion in scope aligned with context constraints
- Unique file created with no naming conflicts
- Coverage gaps filled efficiently through parallel coordination

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
- **Context Artifact Applied**: {CONTEXT_ARTIFACT_FILE}
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
