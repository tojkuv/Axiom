# CODEBASE-WORKER-ACTORS-PROTOCOL

Execute parallel development for assigned technical areas with complete worker isolation, replacing legacy implementations with modern solutions.

## Activation
```
@CODEBASE_ACTORS execute <workspace_directory>
```

## Process
1. **Review** - Check ARTIFACTS directory for previous worker sessions to determine continuation points
2. **Analyze** - Read technical area requirements from ARTIFACTS and identify remaining work
3. **Plan** - Determine current session scope based on previous sessions and outstanding requirements
4. **Implement** - Build functionality within assigned area, replacing legacy implementations with modern solutions
5. **Test** - Create comprehensive test coverage
6. **Validate** - Ensure build passes and quality standards met
7. **Document** - Generate session artifact in ARTIFACTS directory for stabilizer context

## Worker Isolation
- Complete independence - no coordination between workers
- Build upon stable foundation from provisioner
- Focus on single technical area with clear boundaries
- Document dependencies and interfaces for integration

## Outputs
- Working implementation for assigned technical area
- Comprehensive test coverage for worker's functionality
- Integration documentation and API specifications
- Session artifact in ARTIFACTS directory: `WORKER-{WORKER_ID}-SESSION-{TIMESTAMP}.md`
- Implementation decisions documented for stabilizer consumption

## Success Criteria
- All assigned requirements implemented and tested
- Build passes with worker's changes
- Performance standards maintained within area
- Integration points clearly documented

## MVP Focus - Explicitly Excluded
This protocol focuses on current area development and deliberately excludes:
- Version control integration workflows
- Database schema development
- Migration pathway development
- Deprecation management
- Legacy code preservation
- Backward compatibility preservation
- Breaking change mitigation
- Semantic versioning considerations
- API stability preservation across versions
- Configuration migration support
- Deployment versioning concerns
- Release management integration
- Rollback procedure preservation
- Multi-version API support

## Legacy Implementation Policy
**REQUIREMENT**: Legacy implementations must be replaced, not preserved. This protocol mandates:
- Replace outdated patterns with modern equivalents within assigned technical area
- Modernize APIs and interfaces without backward compatibility constraints
- Remove deprecated code and obsolete implementations in worker scope
- Focus on optimal current solutions rather than legacy support
- Implement clean, modern architecture without preserving old code patterns
- Document replacement decisions for stabilizer integration

## Session Artifact Template

*Generated in ARTIFACTS/WORKER-{WORKER_ID}-SESSION-{TIMESTAMP}.md (revise existing if multiple sessions)*

# WORKER-{WORKER_ID}-SESSION-{SESSION_NUMBER}-{TIMESTAMP}

*Parallel Worker Implementation Report*

## Meta-Data
- **Date**: {DATE}
- **Worker ID**: {WORKER_ID}
- **Session Number**: {SESSION_NUMBER}
- **Technical Area**: {TECHNICAL_AREA}
- **Requirements**: {REQUIREMENT_COUNT}
- **Previous Sessions**: {PREVIOUS_SESSION_COUNT}

## Previous Session Analysis
### Previous Sessions Reviewed
- {PREVIOUS_SESSION_1}: {COMPLETION_STATUS_1}
- {PREVIOUS_SESSION_2}: {COMPLETION_STATUS_2}
- {PREVIOUS_SESSION_3}: {COMPLETION_STATUS_3}

### Work Completed Previously
- {COMPLETED_FEATURE_1}
- {COMPLETED_FEATURE_2}
- {COMPLETED_FEATURE_3}

### Outstanding Work Identified
- {OUTSTANDING_REQUIREMENT_1}: {PRIORITY_1}
- {OUTSTANDING_REQUIREMENT_2}: {PRIORITY_2}
- {OUTSTANDING_REQUIREMENT_3}: {PRIORITY_3}

### Current Session Scope
Based on previous session analysis:
- {CURRENT_SESSION_FOCUS_1}
- {CURRENT_SESSION_FOCUS_2}
- {CURRENT_SESSION_FOCUS_3}

## Implementation Results
### Features Developed
{FEATURES_IMPLEMENTED}

### Tests Created
- Test count: {TEST_COUNT}
- Coverage: {COVERAGE}%
- Passing: {PASSING_TESTS}

### Code Changes
- Features completed: {FEATURES_COMPLETED}
- APIs implemented: {API_COUNT}
- Integration points: {INTEGRATION_POINTS}

## Quality Validation
### Build Status
- Compilation: {COMPILATION}
- Performance: {PERFORMANCE}
- Quality gates: {QUALITY_GATES}

### Integration Readiness
- Dependencies: {DEPENDENCIES}
- API contracts: {API_STABILITY}
- Documentation: {DOCUMENTATION}

## Implementation Decisions
### Technical Choices Made
- {TECHNICAL_DECISION_1}: {RATIONALE_1}
- {TECHNICAL_DECISION_2}: {RATIONALE_2}
- {TECHNICAL_DECISION_3}: {RATIONALE_3}

### API Design Decisions
- {API_DESIGN_1}: {INTERFACE_CHOICE_1}
- {API_DESIGN_2}: {INTERFACE_CHOICE_2}
- {API_DESIGN_3}: {INTERFACE_CHOICE_3}

### Implementation Patterns
- {PATTERN_1}: {PATTERN_APPLICATION_1}
- {PATTERN_2}: {PATTERN_APPLICATION_2}
- {PATTERN_3}: {PATTERN_APPLICATION_3}

## Session Changes
### New in This Session
- {NEW_FEATURE_1}
- {NEW_FEATURE_2}
- {NEW_FEATURE_3}

### Modified from Previous Sessions
- {MODIFIED_FEATURE_1}: {CHANGE_REASON_1}
- {MODIFIED_FEATURE_2}: {CHANGE_REASON_2}

### Deferred to Future Sessions
- {DEFERRED_ITEM_1}: {DEFERRAL_REASON_1}
- {DEFERRED_ITEM_2}: {DEFERRAL_REASON_2}

## Stabilizer Context
### Integration Dependencies
- {DEPENDENCY_1}: {INTEGRATION_REQUIREMENT_1}
- {DEPENDENCY_2}: {INTEGRATION_REQUIREMENT_2}

### Cross-Worker Interfaces
- {INTERFACE_1}: {WORKER_INTERACTION_1}
- {INTERFACE_2}: {WORKER_INTERACTION_2}

### Conflicts Detected
- {CONFLICT_1}: {RESOLUTION_NEEDED_1}
- {CONFLICT_2}: {RESOLUTION_NEEDED_2}

### Performance Impacts
- {PERFORMANCE_CONCERN_1}: {MITIGATION_1}
- {PERFORMANCE_CONCERN_2}: {MITIGATION_2}

## Next Steps
{NEXT_STEPS}
