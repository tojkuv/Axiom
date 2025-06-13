# CONSOLIDATOR-PROTOCOL

Consolidate parallel worker results from explicitly specified worker folders into target codebase with systematic conflict resolution across multiple sessions, ensuring legacy implementations are replaced with modern solutions through dependency-aware integration.

## Activation
```
ultrathink . run protocol @CODEBASE_CONSOLIDATOR <target_codebase_folder> <worker_folder_1> <worker_folder_2> ... <worker_folder_n> [context_file]
```

*Note: The target codebase folder is where consolidated codebase will be built. Worker folders contain codebase and artifacts. Optional context file provides additional context about the codebase, project constraints, and consolidation priorities.*

## Input Requirements
**Required Parameters:**
- **target_codebase_folder**: Path to target folder where consolidated codebase will be built
- **worker_folder_1**: Path to first worker folder containing codebase and artifacts
- **worker_folder_2**: Path to second worker folder containing codebase and artifacts
- **worker_folder_n**: Path to additional worker folders (variable number supported)

**Optional Parameters:**
- **context_file**: Optional context file providing additional context about the codebase, project constraints, and consolidation priorities

**Worker Folder Structure:**
Each worker folder must contain:
```
WORKER-{ID}-{AREA}/
├── REQUIREMENTS-*.md         # Worker requirements and artifacts at same level
├── SESSION-*.md             # Worker session artifacts at same level
└── {codebase}/              # Worker's modified codebase
    ├── Sources/
    ├── Tests/
    └── {other_code_files}
```

**Consolidator Workspace:**
The consolidator creates session artifacts at the same level as the target codebase:
```
consolidator_workspace/
├── CONSOLIDATOR-SESSION-*.md  # Consolidator session artifacts at same level
├── CONSOLIDATION-*.md         # Consolidation artifacts at same level
└── {target_codebase}/         # Output consolidated codebase
    ├── Sources/
    ├── Tests/
    └── {consolidated_files}
```

## Process
1. **Context** - Read context file (if provided) to understand project specifics, consolidation priorities, and constraint guidance
2. **Review** - Check workspace for previous consolidator sessions to determine continuation points and inherited state
3. **Baseline** - Establish target codebase folder as consolidation baseline and inventory existing capabilities
4. **Analyze** - Comprehensively examine worker artifacts (requirements, sessions) to understand scope, implementations, and interdependencies
5. **Plan** - Determine dependency-based consolidation order prioritizing foundation layers (error handling, infrastructure) before dependent features
6. **Consolidate** - Systematically integrate workers in dependency order with continuous build validation and selective integration when conflicts arise
7. **Resolve** - Address integration conflicts through progressive strategies: namespace fixes, type disambiguation, API alignment, and selective removal when necessary
8. **Test** - Validate consolidation with incremental build testing throughout process, accepting minor non-blocking issues for future resolution
9. **Document** - Generate comprehensive session artifact documenting decisions, conflicts resolved, and remaining items for future sessions

## Conflict Types and Resolution Strategies

### Common Conflict Categories
1. **File Duplication Conflicts**
   - Same functionality implemented in multiple locations
   - Resolution: Compare implementations, retain most comprehensive version, remove duplicates

2. **Type Reference Conflicts**
   - Incorrect namespace or module references (e.g., `ModuleA.Type` vs `ModuleB.Type`)
   - Resolution: Systematic find-and-replace to correct type references

3. **Type Name Ambiguity**
   - Same type names with different definitions across workers
   - Resolution: Rename conflicting types with descriptive prefixes, update all references

4. **API Mismatch Conflicts**
   - Missing methods, properties, or types expected by integrated code
   - Resolution: Implement missing APIs, or selectively remove incompatible code

5. **Dependency Order Conflicts**
   - Features depending on functionality not yet integrated
   - Resolution: Reorder integration sequence based on dependency analysis

### Resolution Strategy Priority
1. **Namespace/Reference Fixes** - Correct typing and imports (highest success rate)
2. **API Implementation** - Add missing required APIs when feasible
3. **Type Disambiguation** - Rename conflicting types with clear naming
4. **Selective Removal** - Remove incompatible components when integration cost exceeds benefit
5. **Deferred Resolution** - Document non-blocking issues for future sessions

## Dependency Analysis and Planning

### Worker Dependency Assessment
Before consolidation, analyze worker interdependencies to determine optimal integration order:

1. **Foundation Layer Identification**
   - Error handling and logging infrastructure
   - Core data structures and protocols
   - Base architectural components

2. **Service Layer Analysis**
   - Business logic components
   - Domain-specific functionality
   - Platform-specific implementations

3. **Integration Layer Planning**
   - UI and presentation components
   - External API integrations
   - Cross-cutting concerns

### Integration Order Strategy
1. **Foundation First**: Error handling, logging, core infrastructure
2. **Domain Services**: Business logic and domain-specific functionality
3. **Platform Features**: Platform-specific capabilities and integrations
4. **Presentation Layer**: UI components and user-facing features
5. **Cross-cutting Concerns**: Authentication, analytics, monitoring

### Build Validation Approach
- **Incremental Testing**: Validate build after each worker integration
- **Continuous Integration**: Fix blocking issues immediately before proceeding
- **Progressive Enhancement**: Accept minor issues that don't block core functionality

## Priority Levels
- **Critical** - Compilation failures, integration conflicts, missing foundation APIs
- **High** - Incomplete implementations, dependency conflicts, structural issues
- **Medium** - Performance optimizations, code quality improvements, documentation
- **Low** - Code refinements, non-essential enhancements

## Outputs
- Progressively consolidated codebase built in target folder
- All worker implementations merged with conflict resolution
- Session artifact in workspace: `CONSOLIDATOR-SESSION-{TIMESTAMP}.md`
- Final unified codebase with zero integration conflicts (when complete)
- Stable API contracts across all consolidated components
- Performance-validated implementation with all worker functionality integrated
- Application-ready deliverable meeting all requirements

## Success Criteria

### Primary Success Criteria (Session Completion)
- Target codebase established as consolidation foundation
- All worker artifacts and requirements comprehensively analyzed
- Workers integrated in dependency-aware priority order
- Major integration conflicts resolved through systematic strategies
- Core functionality from all workers successfully consolidated
- Session artifacts generated with comprehensive documentation

### Secondary Success Criteria (Quality Validation)
- Codebase builds successfully with critical functionality intact
- Major compilation errors resolved (minor API issues acceptable for future sessions)
- Core tests pass for consolidated functionality
- Performance baseline maintained or improved
- Cross-session continuity preserved through detailed documentation

### Completion Criteria (Full Consolidation)
- All specified workers fully integrated
- All worker requirements satisfied
- Codebase builds without errors
- Complete test suite passes
- Performance meets all requirements
- Documentation updated for consolidated capabilities

## Artifact Template

*Generated in CONSOLIDATOR-SESSION-{TIMESTAMP}.md (revise existing if multiple sessions)*

# CONSOLIDATOR-SESSION-{SESSION_NUMBER}-{TIMESTAMP}

*Progressive Consolidation Report*

## Meta-Data
- **Date**: {DATE}
- **Artifact Type**: Session
- **Session**: {SESSION_NUMBER}
- **Target Codebase**: {TARGET_CODEBASE_PATH}
- **Workers Processed**: {WORKER_FOLDER_PATHS}
- **Total Workers**: {TOTAL_WORKER_COUNT}
- **Integration Status**: {OVERALL_STATUS}

## Dependency Analysis and Priority Order
- **Dependency Mapping**: {WORKER_DEPENDENCIES}
- **Integration Order**: {PRIORITIZED_WORKER_LIST}
- **Rationale**: {PRIORITY_RATIONALE}

## Detailed Integration Results
### Workers Consolidated

| Worker | Domain | Files Added/Modified | Integration Status |
|--------|---------|---------------------|-------------------|
| {WORKER_ID} | {DOMAIN_AREA} | {FILE_CHANGES} | {STATUS} |

### Files Summary
- **Files Added**: {NEW_FILES_COUNT} new files
- **Files Enhanced**: {ENHANCED_FILES_COUNT} existing files
- **Files Replaced**: {REPLACED_FILES_COUNT} files
- **Files Removed**: {REMOVED_FILES_COUNT} (due to conflicts)

## Conflict Resolution

### Major Conflicts Resolved
1. **{CONFLICT_TYPE_1}** (e.g., File Duplication, Type Ambiguity)
   - **Issue**: {CONFLICT_DESCRIPTION}
   - **Resolution**: {RESOLUTION_STRATEGY}
   - **Files Affected**: {AFFECTED_FILES}

### Minor Issues Fixed
- {MINOR_ISSUE_1}: {RESOLUTION_1}
- {MINOR_ISSUE_2}: {RESOLUTION_2}

### Remaining Issues (Non-Critical)
- {REMAINING_ISSUE_1}: {IMPACT_ASSESSMENT}
- {REMAINING_ISSUE_2}: {FUTURE_RESOLUTION_PLAN}

## Integration Metrics
- **Compilation Status**: {BUILD_STATUS} with {ERROR_COUNT} remaining issues
- **Critical Functionality**: {CORE_FEATURES_STATUS}
- **Code Quality**: {QUALITY_ASSESSMENT}
- **Architecture Enhancements**: {ARCHITECTURAL_IMPROVEMENTS}

## Protocol Compliance
- ✅/⚠️/❌ **Step 1: Review** - {REVIEW_STATUS}
- ✅/⚠️/❌ **Step 2: Baseline** - {BASELINE_STATUS}
- ✅/⚠️/❌ **Step 3: Analyze** - {ANALYSIS_STATUS}
- ✅/⚠️/❌ **Step 4: Plan** - {PLANNING_STATUS}
- ✅/⚠️/❌ **Step 5: Consolidate** - {CONSOLIDATION_STATUS}
- ✅/⚠️/❌ **Step 6: Resolve** - {RESOLUTION_STATUS}
- ✅/⚠️/❌ **Step 7: Test** - {TESTING_STATUS}
- ✅/⚠️/❌ **Step 8: Document** - {DOCUMENTATION_STATUS}

## Recommendations
### Immediate Actions
- {IMMEDIATE_RECOMMENDATION_1}
- {IMMEDIATE_RECOMMENDATION_2}

### Future Considerations
- {FUTURE_CONSIDERATION_1}
- {FUTURE_CONSIDERATION_2}

## Next Steps
- **Remaining Work**: {OUTSTANDING_ITEMS}
- **Priority**: {NEXT_SESSION_PRIORITY}
- **Estimated Completion**: {COMPLETION_ESTIMATE}