# CODEBASE-REQUIREMENTS-DISPATCHER-PROTOCOL

Analyze codebase and generate prioritized requirements for provisioner and parallel workers.

## Activation
```
@CODEBASE_REQUIREMENTS_DISPATCHER execute <workspace_directory>
```

## Process
1. **Analyze** - Identify critical gaps, incomplete features, enhancement opportunities
2. **Discover** - Find separable technical areas and module boundaries
3. **Allocate** - Determine optimal worker count (2-8) and assign areas
4. **Generate** - Create requirement files with critical-first prioritization

## Priority Levels
- **Critical** - Framework-breaking issues (immediate priority)
- **Incomplete** - Partially implemented features (high priority)  
- **Enhancement** - Quality improvements (low priority)

## Outputs
- `PROVISIONER/ARTIFACTS/` - Foundation infrastructure requirements
- `WORKERS/WORKER-XX/ARTIFACTS/` - Technical area-specific requirements
- Each requirement includes problem description, implementation guidance, acceptance criteria

## Success Criteria
- All critical and incomplete issues identified and assigned
- Requirements balanced across workers
- Clear implementation guidance provided

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

## Session Template

# REQUIREMENTS-DISPATCHER-SESSION

*Requirements Generation Report*

## Summary
- **Date**: {DATE}
- **Workspace**: {WORKSPACE}
- **Total Requirements**: {TOTAL_COUNT}
- **Workers Allocated**: {WORKER_COUNT}

## Analysis Results
### Technical Areas
{TECHNICAL_AREAS}

### Critical Issues Found
{CRITICAL_ISSUES}

### Incomplete Features
{INCOMPLETE_FEATURES}

## Distribution
### Provisioner Requirements
- Critical: {PROVISIONER_CRITICAL}
- Incomplete: {PROVISIONER_INCOMPLETE}  
- Enhancement: {PROVISIONER_ENHANCEMENT}

### Worker Requirements
{WORKER_BREAKDOWN}

## Next Steps
1. Execute Provisioner
2. Execute Parallel Workers
3. Execute Stabilizer