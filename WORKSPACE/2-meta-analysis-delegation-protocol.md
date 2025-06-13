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
4. **Meta-Analyze** - Identify overlapping suggestions, conflicting approaches, and synthesize optimal implementation strategies at suggestion level
5. **Resolve-Conflicts** - Make definitive decisions on conflicting suggestions and consolidate duplicate suggestions
6. **Assess-Feasibility** - Apply technical feasibility assessment to filter individual suggestions
7. **Prioritize-Suggestions** - Rank all feasible suggestions using strategic priority matrix with impact/effort analysis
8. **Identify-Areas** - Determine separable technical implementation areas and module boundaries for suggestion grouping
9. **Allocate-Workers** - Dynamic worker allocation using intelligent suggestion workload analysis (1-16 workers)
10. **Structure-Directories** - Create scalable directory structure: `PROVISIONER/`, `WORKER-{ID}-{AREA}/`
11. **Generate-All-Requirements** - Create MULTIPLE requirements files per worker to preserve full context for each suggestion
12. **Validate-Coverage** - Validate that all requirements artifacts were generated and cover all accepted suggestions

## Technical Feasibility Assessment Framework

### Feasibility Analysis (Acceptance Criteria)
**ACCEPT** if meets ALL criteria:
- **Technical Grounding**: Implementation approach is technically sound and achievable within current technology constraints
- **Ecosystem Alignment**: Fits within the target technology ecosystem and platform constraints (e.g., Apple ecosystem for iOS/macOS frameworks)
- **Codebase Integration**: Can be integrated with existing codebase architecture
- **Resource Feasibility**: Implementation is feasible with available tools, frameworks, and technologies in the ecosystem

**REJECT** only if ANY criteria fails:
- **Technical Impossibility**: Cannot be implemented with current technology or violates fundamental technical constraints
- **Ecosystem Mismatch**: Outside the scope of the target platform/technology stack (e.g., proposing Android features for iOS framework)
- **Architecture Violation**: Would require fundamental architecture changes that break existing patterns and contracts
- **Resource Unavailability**: Requires unavailable tools, services, or technologies not present in the ecosystem
- **Incorrect Assumptions**: Based on misunderstanding of the codebase structure, purpose, or constraints

### Priority Classification (For Accepted Opportunities)
- **Critical Fixes**: System-breaking issues, compilation blockers, security vulnerabilities
- **Foundation Work**: Core infrastructure improvements that enable other work
- **High-Value Enhancements**: Significant feature additions and improvements
- **Quality Improvements**: Code quality, performance, and developer experience

### Strategic Sequencing Factors
- **Dependency Chain**: Items that unblock other implementations
- **Implementation Risk**: Complexity and potential for breaking changes
- **Strategic Value**: Long-term benefit and architectural alignment
- **Urgency Level**: Time-sensitivity and severity of issues

## Dynamic Worker Allocation Protocol

### Workload Analysis Criteria
**Base Worker Count**: Start with accepted suggestions divided by optimal workload per worker
**Technical Separation Factor**: Multiply by number of clearly separable technical domains
**Dependency Analysis**: Adjust for sequential dependencies that require provisioner-first approach
**Parallel Processing Capacity**: Scale based on parallelizable vs sequential work

### Dynamic Allocation Algorithm
```
WORKER_COUNT = MIN(16, MAX(1,
    FLOOR(ACCEPTED_SUGGESTIONS / OPTIMAL_WORKLOAD_PER_WORKER) ×
    TECHNICAL_SEPARATION_FACTOR ×
    DEPENDENCY_ADJUSTMENT_FACTOR
))

Where:
- OPTIMAL_WORKLOAD_PER_WORKER = 3-8 accepted suggestions (fewer due to detailed context preservation)
- TECHNICAL_SEPARATION_FACTOR = SEPARABLE_DOMAINS / TOTAL_DOMAINS
- DEPENDENCY_ADJUSTMENT_FACTOR = 0.1-1.0 (based on sequential dependencies)
```

### Worker Count Decision Matrix
| Accepted Suggestions | Technical Areas | Dependencies | Recommended Workers | Rationale |
|---------------------|-----------------|--------------|-------------------|-----------|
| 1-8 | 1 | High Sequential | 1 (Provisioner Only) | Sequential work required |
| 6-16 | 2-3 | Medium | 2-3 | Minimal parallelization |
| 12-32 | 3-5 | Low-Medium | 3-6 | Moderate parallelization |
| 24-64 | 5-8 | Low | 6-12 | High parallelization |
| 64+ | 8+ | Very Low | 10-16 | Ultra-high parallelization |

### Requirement Artifacts Strategy

#### Artifact Generation Rules (Generated During Protocol Execution)
**ALWAYS Generate Multiple Requirements Files** to preserve full context for each suggestion:
- **Provisioner Requirements**: Multiple files for foundational and sequential suggestions
- **Worker Requirements**: Multiple files per worker, one per suggestion or small suggestion groups

#### Provisioner Artifacts (Always Generated - Multiple Files)
- `PROVISIONER/REQUIREMENTS-01-{SUGGESTION-CONTEXT}-{TIMESTAMP}.md` - First foundational suggestion
- `PROVISIONER/REQUIREMENTS-02-{SUGGESTION-CONTEXT}-{TIMESTAMP}.md` - Second foundational suggestion  
- `PROVISIONER/REQUIREMENTS-N-{SUGGESTION-CONTEXT}-{TIMESTAMP}.md` - Additional foundational suggestions

#### Worker Artifacts (Always Multiple Files Per Worker)
- `WORKER-{ID}-{AREA}/REQUIREMENTS-01-{SUGGESTION-CONTEXT}-{TIMESTAMP}.md` - First suggestion implementation
- `WORKER-{ID}-{AREA}/REQUIREMENTS-02-{SUGGESTION-CONTEXT}-{TIMESTAMP}.md` - Second suggestion implementation
- `WORKER-{ID}-{AREA}/REQUIREMENTS-N-{SUGGESTION-CONTEXT}-{TIMESTAMP}.md` - Additional suggestion implementations

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

## Outputs
### Meta-Analysis Artifacts
- `META-ANALYSIS/ANALYSIS-SYNTHESIS-{TIMESTAMP}.md` - Synthesis of all analyses with prioritization
- `META-ANALYSIS/REQUIREMENTS-VALIDATION-{TIMESTAMP}.md` - Validation of requirements coverage
- `META-ANALYSIS/WORKER-ALLOCATION-ANALYSIS-{TIMESTAMP}.md` - Dynamic worker allocation decision matrix

### Provisioner Requirements (Always Multiple Files)
**Directory Structure**: `PROVISIONER/` with multiple suggestion-specific files
- `PROVISIONER/REQUIREMENTS-01-{SUGGESTION-CONTEXT}-{TIMESTAMP}.md` - First foundational suggestion
- `PROVISIONER/REQUIREMENTS-02-{SUGGESTION-CONTEXT}-{TIMESTAMP}.md` - Second foundational suggestion
- `PROVISIONER/REQUIREMENTS-N-{SUGGESTION-CONTEXT}-{TIMESTAMP}.md` - Additional foundational suggestions

### Dynamic Worker Requirements (Always Multiple Files Per Worker)
**Directory Structure**: `WORKER-{ID}-{AREA}/` where ID is sequential number and AREA is technical domain
- `WORKER-{ID}-{AREA}/REQUIREMENTS-01-{SUGGESTION-CONTEXT}-{TIMESTAMP}.md` - First suggestion implementation
- `WORKER-{ID}-{AREA}/REQUIREMENTS-02-{SUGGESTION-CONTEXT}-{TIMESTAMP}.md` - Second suggestion implementation
- `WORKER-{ID}-{AREA}/REQUIREMENTS-N-{SUGGESTION-CONTEXT}-{TIMESTAMP}.md` - Additional suggestion implementations

### Requirement Coverage Validation
All generated requirements files must be validated to ensure:
- **Complete Coverage**: Every accepted suggestion appears in exactly one requirements file with full context preserved
- **Clear Assignment**: Each suggestion is assigned to either provisioner or a specific worker
- **Context Preservation**: Each suggestion maintains complete implementation context in its dedicated file
- **Dependency Resolution**: Sequential dependencies properly assigned to provisioner
- **Parallel Efficiency**: Worker suggestions are truly parallelizable

## Success Criteria
- **Technical Feasibility Gate**: Only technically feasible and ecosystem-aligned suggestions included
- **Complete Artifact Generation**: All requirements artifacts generated during protocol execution
- **Multiple File Generation**: Multiple requirements files generated to preserve full context for each suggestion
- **Coverage Validation**: 100% coverage of accepted suggestions across all generated requirements
- **Context Preservation**: Each suggestion maintains complete implementation context without information loss
- **Worker Isolation**: All worker suggestions can be implemented independently after provisioner completion
- **Dependency Resolution**: All sequential dependencies properly handled in provisioner phase
- **Strategic Alignment**: All suggestions align with codebase objectives and architecture
- **Implementation Feasibility**: All suggestions have clear, technically sound implementation paths
- **Code Verification**: All analysis claims verified against actual source code

## Artifact Template

*Generated in META-ANALYSIS/ANALYSIS-SYNTHESIS-{TIMESTAMP}.md*

# ANALYSIS-SYNTHESIS-{TIMESTAMP}

*Unified Analysis of All Implementation Suggestions*

## Meta-Data
- **Date**: {DATE}
- **Artifact Type**: Synthesis
- **Total Analyses Reviewed**: {TOTAL_ANALYSIS_COUNT}
- **Analysis Types Found**: {ANALYSIS_TYPES_SUMMARY}
- **Individual Suggestions Extracted**: {TOTAL_SUGGESTIONS_COUNT}
- **Accepted Suggestions**: {ACCEPTED_SUGGESTIONS_COUNT}
- **Suggestion Overlaps Resolved**: {OVERLAP_COUNT}
- **Suggestion Conflicts Resolved**: {CONFLICT_COUNT}
- **Source Codebase**: {CODEBASE_DIRECTORY}
- **Analyses Source Directory**: {ANALYSES_DIRECTORY}
- **Dynamic Worker Allocation**: {WORKER_COUNT} workers across {TECHNICAL_AREAS_COUNT} technical areas
- **Requirements Files Generated**: {TOTAL_REQUIREMENTS_FILES} (Multiple files for context preservation)

## Analysis Sources Reviewed
### All Analyses Discovered and Processed
*All analysis files from specified analyses directory: {ANALYSES_DIRECTORY}*
- {ANALYSIS_FILE_1}: {ANALYSIS_TYPE_1} - {SCOPE_1} - {SUGGESTIONS_COUNT_1} suggestions extracted
- {ANALYSIS_FILE_2}: {ANALYSIS_TYPE_2} - {SCOPE_2} - {SUGGESTIONS_COUNT_2} suggestions extracted
- {ANALYSIS_FILE_N}: {ANALYSIS_TYPE_N} - {SCOPE_N} - {SUGGESTIONS_COUNT_N} suggestions extracted

### Suggestion Extraction Summary
- **Total Individual Suggestions**: {TOTAL_SUGGESTIONS}
- **Critical Fixes Identified**: {CRITICAL_FIXES_COUNT}
- **Enhancement Suggestions**: {ENHANCEMENT_SUGGESTIONS_COUNT}
- **Foundation Improvements**: {FOUNDATION_IMPROVEMENTS_COUNT}
- **Quality Improvements**: {QUALITY_IMPROVEMENTS_COUNT}

## Feasibility Assessment Results

### Implementation Evaluation Summary
- **Total Suggestions Identified**: {TOTAL_SUGGESTIONS_COUNT}
- **Suggestions Evaluated**: {EVALUATED_SUGGESTIONS_COUNT}
- **Accepted Suggestions**: {ACCEPTED_SUGGESTIONS_COUNT}
- **Rejected Suggestions**: {REJECTED_SUGGESTIONS_COUNT}
- **Acceptance Rate**: {ACCEPTANCE_PERCENTAGE}%

### Feasibility Assessment Matrix
| Suggestion | Technical Grounding | Ecosystem Alignment | Integration Feasibility | Resource Availability | Decision |
|------------|-------------------|-------------------|------------------------|---------------------|----------|
| {SUGGESTION_1} | {GROUNDING_1} | {ECOSYSTEM_1} | {INTEGRATION_1} | {RESOURCE_1} | {ACCEPT/REJECT} |
| {SUGGESTION_2} | {GROUNDING_2} | {ECOSYSTEM_2} | {INTEGRATION_2} | {RESOURCE_2} | {ACCEPT/REJECT} |

### Rejected Suggestions Analysis
| Suggestion | Primary Rejection Reason | Technical Assessment |
|------------|--------------------------|---------------------|
| {REJECTED_1} | {REJECTION_REASON_1} | {TECHNICAL_ANALYSIS_1} |
| {REJECTED_2} | {REJECTION_REASON_2} | {TECHNICAL_ANALYSIS_2} |

## Strategic Implementation Requirements (Priority-Ordered)

### Critical Fixes (Highest Priority)
- {CRITICAL_FIX_1}: {ASSIGNED_TO_WORKER} - **Priority**: {PRIORITY_LEVEL} - **Impact**: {CRITICAL_IMPACT_1}
- {CRITICAL_FIX_2}: {ASSIGNED_TO_WORKER} - **Priority**: {PRIORITY_LEVEL} - **Impact**: {CRITICAL_IMPACT_2}

### Foundation Work (High Priority)
- {FOUNDATION_WORK_1}: {ASSIGNED_TO_WORKER} - **Priority**: {PRIORITY_LEVEL} - **Impact**: {FOUNDATION_IMPACT_1}
- {FOUNDATION_WORK_2}: {ASSIGNED_TO_WORKER} - **Priority**: {PRIORITY_LEVEL} - **Impact**: {FOUNDATION_IMPACT_2}

### High-Value Enhancements (Medium Priority)
- {ENHANCEMENT_1}: {ASSIGNED_TO_WORKER} - **Priority**: {PRIORITY_LEVEL} - **Value**: {ENHANCEMENT_VALUE_1}
- {ENHANCEMENT_2}: {ASSIGNED_TO_WORKER} - **Priority**: {PRIORITY_LEVEL} - **Value**: {ENHANCEMENT_VALUE_2}

### Quality Improvements (Standard Priority)
- {QUALITY_IMPROVEMENT_1}: {ASSIGNED_TO_WORKER} - **Priority**: {PRIORITY_LEVEL} - **Benefit**: {QUALITY_BENEFIT_1}
- {QUALITY_IMPROVEMENT_2}: {ASSIGNED_TO_WORKER} - **Priority**: {PRIORITY_LEVEL} - **Benefit**: {QUALITY_BENEFIT_2}

## Worker Requirements Template

*Generated as PROVISIONER/REQUIREMENTS-{N}-{SUGGESTION-CONTEXT}-{TIMESTAMP}.md or WORKER-{ID}-{AREA}/REQUIREMENTS-{N}-{SUGGESTION-CONTEXT}-{TIMESTAMP}.md*

# {WORKER_TYPE}: {SUGGESTION_TITLE} IMPLEMENTATION

*Individual Suggestion Implementation with Full Context Preservation*

## Meta-Data
- **Worker Type**: {PROVISIONER/WORKER}
- **Area**: {IMPLEMENTATION_AREA}
- **Suggestion ID**: {SUGGESTION_ID}
- **Suggestion Context**: {SUGGESTION_CONTEXT}
- **Source Analysis**: {SOURCE_ANALYSIS_FILE}
- **Suggestion Category**: {CRITICAL_FIX/FOUNDATION/ENHANCEMENT/QUALITY}
- **Codebase Source**: {CODEBASE_SOURCE_DESCRIPTION}
- **Implementation Strategy**: {SEQUENTIAL/PARALLEL}
- **Dependencies**: {DEPENDENCY_DESCRIPTION}

## Suggestion Overview
**Original Analysis Context**: {ORIGINAL_ANALYSIS_CONTEXT}
**Extracted Suggestion**: {EXTRACTED_SUGGESTION_DESCRIPTION}
**Implementation Rationale**: {IMPLEMENTATION_RATIONALE}

---

## Implementation Specification: {SUGGESTION_TITLE}
**Category**: {PRIORITY_CATEGORY}
**Priority**: {PRIORITY_LEVEL}
**Implementation Context**: {FULL_IMPLEMENTATION_CONTEXT}
**Value Justification**: {VALUE_JUSTIFICATION}

### Technical Assessment
- **Technical Grounding**: {TECHNICAL_GROUNDING_ANALYSIS}
- **Ecosystem Alignment**: {ECOSYSTEM_ALIGNMENT_ANALYSIS}
- **Integration Feasibility**: {INTEGRATION_FEASIBILITY_ANALYSIS}
- **Resource Requirements**: {RESOURCE_REQUIREMENTS_ANALYSIS}

**Implementation Suggestion**: {SUGGESTION_DESCRIPTION}

**Current State Analysis**:
```{LANGUAGE}
{CURRENT_IMPLEMENTATION_CODE}
```

**Required Implementation**:
```{LANGUAGE}
{REQUIRED_IMPLEMENTATION_CODE}
```

**Value Delivered**:
- **Primary Benefit**: {PRIMARY_BENEFIT}
- **Secondary Benefits**: {SECONDARY_BENEFITS}
- **Enables**: {WHAT_THIS_ENABLES}

**Acceptance Criteria**:
- [ ] {ACCEPTANCE_CRITERION_1}
- [ ] {ACCEPTANCE_CRITERION_2}
- [ ] {ACCEPTANCE_CRITERION_N}

**Implementation Guidance**: {IMPLEMENTATION_GUIDANCE}
**Success Metrics**: {SUCCESS_METRICS}
**Dependencies**: {DEPENDENCY_REQUIREMENTS}
**Integration Notes**: {INTEGRATION_CONSIDERATIONS}

---

*Each suggestion receives its own dedicated requirements file with complete context preservation*

## Implementation Sequencing Principles
- **Suggestion-Level Granularity**: Each individual suggestion from analysis files treated as atomic implementation unit
- **Context Preservation**: Each suggestion maintains complete implementation context in dedicated requirements file
- **Dependency-Driven**: Suggestions that unblock others implemented first in provisioner phase
- **Risk-Managed**: Higher-risk suggestions balanced with lower-risk suggestions within worker areas
- **Value-Optimized**: Maximum value delivery with minimum implementation risk at suggestion level
- **Architecture-Consistent**: All suggestion implementations respect existing architectural patterns
- **Multiple File Strategy**: Always generate multiple requirements files to avoid information loss due to file length constraints