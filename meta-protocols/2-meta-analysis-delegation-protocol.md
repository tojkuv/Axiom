# META-ANALYSIS-DELEGATION-PROTOCOL

Analyze any set of analyses and generate strategically prioritized requirements for implementation work. Delegate foundational work to a provisioner and specialized work to parallel workers using isolated codebase copies.

## Activation
```
ultrathink . run protocol @META_ANALYSIS_DELEGATOR <codebase_directory> <analyses_directory> [context_file]
```

*Note: The codebase directory contains the source code for verification. The analyses directory contains all analysis files to be synthesized. Optional context file provides additional context.*

## Input Requirements
**Required Parameters:**
- **codebase_directory**: The source code for verification
- **analyses_directory**: Contains all analysis files to be synthesized

**Optional Parameters:**
- **context_file**: Additional context about the codebase and analysis priorities

## Process
1. **Collect** - Read and analyze content of ALL analyses in specified analyses directory (any analysis format)
2. **Extract-Suggestions** - Identify and extract each individual suggestion from all analysis files as atomic implementation units
3. **Deep-Analyze** - Perform comprehensive analysis of the actual source in codebase directory to verify each suggestion and assess feasibility
4. **Assess-Feasibility** - Apply technical feasibility assessment to filter individual suggestions
5. **Consolidate-Overlaps** - Identify overlapping suggestions, conflicting approaches, and consolidate duplicate suggestions into unified implementation units
6. **Resolve-Conflicts** - Make definitive decisions on conflicting suggestions and select optimal implementation approaches
7. **Prioritize-Units** - Rank all consolidated implementation units using strategic priority matrix with impact/effort analysis
8. **Identify-Areas** - Determine separable technical implementation areas and module boundaries for unit grouping
9. **Allocate-Workers** - Dynamic worker allocation using intelligent unit workload analysis (1-16 workers)
10. **Structure-Directories** - Create scalable directory structure: `META-ANALYSIS/`, `PROVISIONER/`, `WORKER-{ID}-{AREA}/`
11. **Generate-Artifacts** - Create analysis artifacts in META-ANALYSIS and requirements files in worker directories
12. **Validate-Coverage** - Validate that all requirements artifacts cover all accepted implementation units

## Technical Feasibility Assessment Framework

### Feasibility Analysis (Acceptance Criteria)
**ACCEPT** if meets ALL criteria:
- **Technical Grounding**: Implementation approach is technically sound and achievable within current technology constraints
- **Ecosystem Alignment**: Fits within the target technology ecosystem and platform constraints
- **Codebase Integration**: Can be integrated with existing codebase architecture
- **Resource Feasibility**: Implementation is feasible with available tools, frameworks, and technologies in the ecosystem

**REJECT** only if ANY criteria fails:
- **Technical Impossibility**: Cannot be implemented with current technology or violates fundamental technical constraints
- **Ecosystem Mismatch**: Outside the scope of the target platform/technology stack
- **Architecture Violation**: Would require fundamental architecture changes that break existing patterns and contracts
- **Resource Unavailability**: Requires unavailable tools, services, or technologies not present in the ecosystem
- **Incorrect Assumptions**: Based on misunderstanding of the codebase structure, purpose, or constraints

### Priority Classification (For Accepted Units)
- **Critical Fixes**: System-breaking issues, compilation blockers, security vulnerabilities
- **Foundation Work**: Core infrastructure improvements that enable other work
- **High-Value Enhancements**: Significant feature additions and improvements
- **Quality Improvements**: Code quality, performance, and developer experience

### Strategic Sequencing Factors
- **Dependency Chain**: Items that unblock other implementations
- **Implementation Risk**: Complexity and potential for breaking changes
- **Strategic Value**: Long-term benefit and architectural alignment
- **Urgency Level**: Time-sensitivity and severity of issues

## Consolidation Strategy

### Overlap Identification Criteria
**Overlapping Suggestions** (Consolidate into single unit):
- Multiple suggestions implementing the same functionality
- Suggestions that address the same root problem
- Suggestions with identical or near-identical technical outcomes

**Conflicting Approaches** (Resolve to single approach):
- Different technical approaches to the same problem
- Mutually exclusive implementation strategies
- Competing architectural patterns for same functionality

### Consolidation Rules
1. **Preserve Highest Impact**: When consolidating, retain the approach with highest strategic value
2. **Minimize Risk**: Choose the technically safest approach when capabilities are equivalent
3. **Maintain Context**: Ensure consolidated units preserve complete implementation context
4. **Atomic Units**: Each consolidated unit should be independently implementable
5. **Dependency Clarity**: Consolidated units should have clear dependency relationships

## Dynamic Worker Allocation Protocol

### Workload Analysis Criteria
**Base Worker Count**: Start with consolidated units divided by optimal workload per worker
**Technical Separation Factor**: Multiply by number of clearly separable technical domains
**Dependency Analysis**: Adjust for sequential dependencies that require provisioner-first approach
**Parallel Processing Capacity**: Scale based on parallelizable vs sequential work

### Dynamic Allocation Algorithm
```
WORKER_COUNT = MIN(16, MAX(1,
    FLOOR(CONSOLIDATED_UNITS / OPTIMAL_WORKLOAD_PER_WORKER) ×
    TECHNICAL_SEPARATION_FACTOR ×
    DEPENDENCY_ADJUSTMENT_FACTOR
))

Where:
- OPTIMAL_WORKLOAD_PER_WORKER = 3-6 consolidated units (detailed context preservation)
- TECHNICAL_SEPARATION_FACTOR = SEPARABLE_DOMAINS / TOTAL_DOMAINS
- DEPENDENCY_ADJUSTMENT_FACTOR = 0.1-1.0 (based on sequential dependencies)
```

### Worker Count Decision Matrix
| Consolidated Units | Technical Areas | Dependencies | Recommended Workers | Rationale |
|-------------------|-----------------|--------------|-------------------|-----------|
| 1-8 | 1-2 | High Sequential | 1 (Provisioner Only) | Sequential work required |
| 6-16 | 2-4 | Medium | 2-4 | Minimal parallelization |
| 12-32 | 4-6 | Low-Medium | 3-6 | Moderate parallelization |
| 24-64 | 6-10 | Low | 6-12 | High parallelization |
| 64+ | 10+ | Very Low | 10-16 | Ultra-high parallelization |

### Artifact Generation Strategy

#### META-ANALYSIS Artifacts (Analysis Only - No Requirements)
**Directory**: `META-ANALYSIS/` - Contains only analysis and coordination artifacts
- `ANALYSIS-SYNTHESIS-{TIMESTAMP}.md` - Comprehensive synthesis of all analyses with prioritization
- `WORKER-ALLOCATION-ANALYSIS-{TIMESTAMP}.md` - Dynamic worker allocation decision matrix and strategy
- `REQUIREMENTS-VALIDATION-{TIMESTAMP}.md` - Validation of requirements coverage across all workers

#### Requirements Artifacts (Worker Directories Only)
**PROVISIONER Directory**: `PROVISIONER/` - Sequential foundation work
- `REQUIREMENTS-01-{UNIT-CONTEXT}-{TIMESTAMP}.md` - First critical unit
- `REQUIREMENTS-02-{UNIT-CONTEXT}-{TIMESTAMP}.md` - Second critical unit  
- `REQUIREMENTS-N-{UNIT-CONTEXT}-{TIMESTAMP}.md` - Additional foundation units

**WORKER Directories**: `WORKER-{ID}-{AREA}/` - Parallel specialized work
- `REQUIREMENTS-01-{UNIT-CONTEXT}-{TIMESTAMP}.md` - First assigned unit
- `REQUIREMENTS-02-{UNIT-CONTEXT}-{TIMESTAMP}.md` - Second assigned unit
- `REQUIREMENTS-N-{UNIT-CONTEXT}-{TIMESTAMP}.md` - Additional assigned units

### Technical Domain Separation Examples
- **Core Infrastructure**: Build systems, compilation, core protocols, foundations
- **Platform Integration**: OS-specific features, platform APIs, ecosystem services
- **Business Logic**: Application logic, workflow, domain-specific functionality
- **User Interface**: UI components, user experience, presentation layers
- **Data Processing**: Persistence, analytics, reporting, data transformation
- **Performance**: Optimization, caching, resource management, monitoring
- **Testing**: Test infrastructure, coverage, automation, quality assurance
- **Integration**: APIs, external services, third-party integrations

## Implementation Flow
**Phase 1: Provisioner** (Sequential - Foundation) → **Phase 2: Parallel Workers** (Isolated Codebase Copies) → **Phase 3: Consolidator** (Integration)

## Directory Structure
```
{DELEGATION_ROOT}/
├── META-ANALYSIS/                    # Analysis artifacts only
│   ├── ANALYSIS-SYNTHESIS-{TIMESTAMP}.md
│   ├── WORKER-ALLOCATION-ANALYSIS-{TIMESTAMP}.md
│   └── REQUIREMENTS-VALIDATION-{TIMESTAMP}.md
├── PROVISIONER/                      # Sequential foundation requirements
│   ├── REQUIREMENTS-01-{UNIT-CONTEXT}-{TIMESTAMP}.md
│   ├── REQUIREMENTS-02-{UNIT-CONTEXT}-{TIMESTAMP}.md
│   └── REQUIREMENTS-N-{UNIT-CONTEXT}-{TIMESTAMP}.md
├── WORKER-1-{AREA}/                  # Parallel worker requirements
│   ├── REQUIREMENTS-01-{UNIT-CONTEXT}-{TIMESTAMP}.md
│   └── REQUIREMENTS-N-{UNIT-CONTEXT}-{TIMESTAMP}.md
├── WORKER-2-{AREA}/
│   └── [Requirements files...]
└── WORKER-N-{AREA}/
    └── [Requirements files...]
```

## Success Criteria
- **Technical Feasibility Gate**: Only technically feasible and ecosystem-aligned suggestions included
- **Effective Consolidation**: Overlapping suggestions consolidated into efficient implementation units
- **Complete Coverage**: 100% coverage of accepted units across all requirements files
- **Context Preservation**: Each unit maintains complete implementation context in dedicated file
- **Worker Isolation**: All worker units can be implemented independently after provisioner completion
- **Dependency Resolution**: All sequential dependencies properly handled in provisioner phase
- **Strategic Alignment**: All units align with codebase objectives and architecture
- **Implementation Feasibility**: All units have clear, technically sound implementation paths
- **Code Verification**: All analysis claims verified against actual source code

## Meta-Analysis Synthesis Template

*Generated in META-ANALYSIS/ANALYSIS-SYNTHESIS-{TIMESTAMP}.md*

```markdown
# ANALYSIS-SYNTHESIS-{TIMESTAMP}

*Unified Analysis of All Implementation Suggestions*

## Meta-Data
- **Date**: {DATE}
- **Total Analyses Reviewed**: {TOTAL_ANALYSIS_COUNT}
- **Individual Suggestions Extracted**: {TOTAL_SUGGESTIONS_COUNT}
- **Accepted Suggestions**: {ACCEPTED_SUGGESTIONS_COUNT}
- **Consolidated Implementation Units**: {CONSOLIDATED_UNITS_COUNT}
- **Consolidation Efficiency**: {EFFICIENCY_PERCENTAGE}%
- **Dynamic Worker Allocation**: {WORKER_COUNT} workers

## Consolidation Analysis
### Overlap Resolution Summary
- **Overlapping Suggestion Groups**: {OVERLAP_GROUPS_COUNT}
- **Conflicting Approaches Resolved**: {CONFLICTS_RESOLVED_COUNT}
- **Consolidation Ratio**: {ORIGINAL_COUNT} → {CONSOLIDATED_COUNT} ({EFFICIENCY}% reduction)

### Feasibility Assessment Results
- **Acceptance Rate**: {ACCEPTANCE_PERCENTAGE}%
- **Rejection Reasons**: {REJECTION_SUMMARY}

## Strategic Implementation Requirements (Priority-Ordered)
[Prioritized list of consolidated implementation units with worker assignments]

## Worker Allocation Strategy
[Dynamic allocation analysis and rationale]
```

## Individual Requirements Template

*Generated in PROVISIONER/ or WORKER-{ID}-{AREA}/ directories*

```markdown
# {WORKER_TYPE}: {UNIT_TITLE} IMPLEMENTATION

*Consolidated Implementation Unit with Full Context Preservation*

## Meta-Data
- **Worker Type**: {PROVISIONER/WORKER-N-AREA}
- **Implementation Area**: {TECHNICAL_AREA}
- **Unit ID**: {UNIT_ID}
- **Consolidated Suggestions**: {ORIGINAL_SUGGESTION_COUNT}
- **Implementation Strategy**: {SEQUENTIAL/PARALLEL}
- **Dependencies**: {DEPENDENCY_LIST}

## Implementation Specification: {UNIT_TITLE}
**Category**: {PRIORITY_CATEGORY}
**Priority**: {PRIORITY_LEVEL}
**Value Justification**: {VALUE_JUSTIFICATION}

### Technical Assessment
- **Technical Grounding**: {ASSESSMENT}
- **Ecosystem Alignment**: {ASSESSMENT}
- **Integration Feasibility**: {ASSESSMENT}
- **Resource Requirements**: {ASSESSMENT}

**Current State Analysis**:
```{LANGUAGE}
{CURRENT_IMPLEMENTATION_CODE}
```

**Required Implementation**:
```{LANGUAGE}
{REQUIRED_IMPLEMENTATION_CODE}
```

**Acceptance Criteria**:
- [ ] {CRITERION_1}
- [ ] {CRITERION_2}

**Implementation Guidance**: {GUIDANCE}
**Dependencies**: {DEPENDENCY_REQUIREMENTS}
**Integration Notes**: {INTEGRATION_CONSIDERATIONS}
```

## Implementation Sequencing Principles
- **Unit-Level Granularity**: Each consolidated unit treated as atomic implementation
- **Context Preservation**: Complete implementation context maintained in dedicated files
- **Dependency-Driven**: Units that unblock others implemented first in provisioner phase
- **Risk-Managed**: Higher-risk units balanced with lower-risk units within worker areas
- **Value-Optimized**: Maximum value delivery with minimum implementation risk
- **Architecture-Consistent**: All implementations respect existing architectural patterns
- **Isolation Strategy**: Requirements files in worker directories enable parallel development