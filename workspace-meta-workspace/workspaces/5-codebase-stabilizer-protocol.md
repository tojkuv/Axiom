# CODEBASE-STABILIZER-PROTOCOL

Gradually integrate parallel worker results into provisioner baseline codebase with conflict resolution across multiple sessions, ensuring legacy implementations are replaced with modern solutions.

## Activation
```
@CODEBASE_STABILIZER execute <workspace_directory>
```

## Process
1. **Review** - Check ARTIFACTS directory for previous stabilizer sessions to determine continuation points
2. **Baseline** - Establish provisioner codebase as integration baseline
3. **Analyze** - Review all worker artifacts and codebases to identify integration scope
4. **Plan** - Determine current session integration targets based on dependencies and conflicts
5. **Integrate** - Gradually merge worker changes into baseline codebase, replacing any remaining legacy implementations
6. **Resolve** - Address integration conflicts and API mismatches as they arise, prioritizing modern solutions over legacy preservation
7. **Test** - Validate integration with comprehensive test execution
8. **Document** - Generate session artifact in ARTIFACTS directory for next session

## Priority Levels
- **Critical** - Compilation fixes, integration conflicts, API conflicts
- **High** - Pattern unification, dependency conflicts, structural issues
- **Medium** - Code health, performance optimization, documentation

## Outputs
- Progressively integrated codebase built from provisioner baseline
- Worker implementations merged with conflict resolution
- Session artifact in ARTIFACTS directory: `ARTIFACTS/STABILIZER-SESSION-{TIMESTAMP}.md`
- Final unified codebase with zero integration conflicts (when complete)
- Stable API contracts across components
- Performance-validated implementation
- Application-ready deliverable

## Success Criteria
- Provisioner baseline codebase established as integration foundation
- All worker artifacts and implementation decisions reviewed
- Worker changes gradually integrated with conflict resolution
- Cross-session continuity maintained through session artifacts
- Final codebase builds successfully with zero compilation errors
- All tests pass including worker-specific and integration tests
- Performance meets baseline requirements
- All workers' functionality validated in integrated codebase

## MVP Focus - Explicitly Excluded
This protocol focuses on current state integration and deliberately excludes:
- Version control integration concerns
- Database schema integration
- Migration pathway integration
- Deprecation management during integration
- Legacy code preservation during integration
- Backward compatibility preservation
- Breaking change mitigation
- Semantic versioning enforcement
- API stability preservation across versions
- Configuration migration support
- Deployment versioning concerns
- Release management integration
- Rollback procedure preservation
- Multi-version API support

## Legacy Implementation Policy
**REQUIREMENT**: Legacy implementations must be replaced, not preserved. This protocol mandates:
- Prioritize modern worker implementations over any legacy baseline code
- Replace outdated patterns discovered during integration with modern equivalents
- Remove deprecated code and obsolete implementations during conflict resolution
- Choose optimal current solutions when resolving conflicts between legacy and modern approaches
- Ensure final integrated codebase contains no legacy implementations
- Document all legacy replacements and modernization decisions in session artifacts

## Session Artifact Template

*Generated in ARTIFACTS/STABILIZER-SESSION-{TIMESTAMP}.md (revise existing if multiple sessions)*

# STABILIZER-SESSION-{SESSION_NUMBER}-{TIMESTAMP}

*Progressive Integration Report*

## Meta-Data
- **Date**: {DATE}
- **Session**: {SESSION_NUMBER}
- **Baseline**: {PROVISIONER_CODEBASE_PATH}
- **Workers**: {TOTAL_WORKER_COUNT}
- **Previous Sessions**: {PREVIOUS_SESSION_COUNT}

## Previous Session Review
- **Completed**: {INTEGRATED_WORKERS_LIST}
- **Pending**: {PENDING_WORKERS_LIST}
- **Current Scope**: {CURRENT_SESSION_TARGETS}

## Current Session Work
### Workers Integrated
- {WORKER_1}: {CHANGES_APPLIED_1} - {CONFLICTS_RESOLVED_1}
- {WORKER_2}: {CHANGES_APPLIED_2} - {CONFLICTS_RESOLVED_2}

### Conflicts Resolved
- {CONFLICT_1}: {RESOLUTION_STRATEGY_1}
- {CONFLICT_2}: {RESOLUTION_STRATEGY_2}

## Quality Validation
- **Build**: {COMPILATION_STATUS} ({BUILD_ERROR_COUNT} errors)
- **Tests**: {PASSING_TEST_COUNT}/{TOTAL_TEST_COUNT} passing
- **Coverage**: {TEST_COVERAGE_PERCENTAGE}%
- **API Consistency**: {API_CONSISTENCY_STATUS}

## Completion Status
- **Integrated**: {FULLY_INTEGRATED_COUNT}/{TOTAL_WORKER_COUNT} workers
- **Criteria**: 
  - [ ] All workers integrated
  - [ ] Conflicts resolved
  - [ ] Build passes
  - [ ] Tests pass
  - [ ] Performance validated

## Next Session
- **Priority**: {NEXT_SESSION_PRIORITY}
- **Strategy**: {INTEGRATION_STRATEGY_NEXT_SESSION}
- **Estimated Sessions Remaining**: {ESTIMATED_SESSIONS_REMAINING}
