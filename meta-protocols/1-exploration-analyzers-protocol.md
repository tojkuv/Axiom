# EXPANSION-ANALYZERS-PROTOCOL

Parallel analysis actors focused on new features and unexplored implementations to expand capabilities.

## Activation
```
ultrathink . run protocol <protocol_file> <codebase_directory> [context_file] . focus on <specific_focus_area>
```

*Note: The codebase directory contains the source code to analyze. Optional context file provides additional context about the codebase. Analyses are read from and written to the current working directory. Specific focus areas can be provided to guide the analysis scope. IMPORTANT: Read the full content of existing analyses to understand previous insights, not just filenames.*

## Process
1. **Initialize** - Set up task tracking to monitor progress through the analysis phases
2. **Context** - Read context file (if provided) to understand user preferences, constraints, focus areas, and domain-specific requirements
3. **Discover** - Read and analyze content of existing analyses in current working directory to understand what has been covered, key insights, and remaining gaps
4. **Explore** - Systematically explore codebase structure, directory organization, and file patterns using concurrent operations for efficiency
5. **Analyze** - Deep-dive into current implementations, architectural patterns, and technology choices through targeted code examination
6. **Identify** - Identify capability gaps, missing implementations, and enhancement opportunities based on focus area and domain requirements
7. **Implement** - Create specific feature implementations and enhancement recommendations based on actual codebase patterns and architecture
8. **Document** - Create uniquely-named analysis report: `EXPANSION-{TIMESTAMP}-{SCOPE}.md` in the current working directory

## Execution Guidelines
- **Task Tracking**: Use TodoWrite/TodoRead tools to track analysis progress through phases
- **Concurrent Operations**: Use multiple tool calls in parallel when gathering information (file reading, directory listing, etc.)
- **Focus-Driven Analysis**: Let user-provided focus areas guide scope selection and prioritization
- **Domain Awareness**: Consider industry/platform standards and best practices relevant to the technology stack
- **Pattern Recognition**: Identify and leverage existing architectural patterns, coding styles, and technology choices
- **Gap Analysis**: Compare current capabilities against domain requirements and industry standards

## Outputs
- Comprehensive gap analysis targeting missing capabilities and enhancement opportunities based on actual codebase patterns
- Domain-specific capability recommendations derived from understanding current implementation approaches and industry standards
- Feature implementations that build upon existing architectural patterns, coding styles, and technology choices
- Requirements-ready specifications grounded in actual codebase implementation analysis and domain expertise
- Progress-tracked analysis with clear task completion status
- Unique analysis file preventing conflicts with parallel actors

## Success Criteria
- Task tracking utilized throughout analysis phases with clear progress indicators
- Context file guidance and focus areas applied to prioritize expansion opportunities
- Existing analyses thoroughly reviewed with insights built upon rather than duplicated
- Codebase structure systematically explored using efficient concurrent operations
- Domain-specific gaps identified through comparison of current capabilities vs industry/platform standards
- Feature implementations provided based on deep analysis of actual code implementations and architectural patterns
- Implementation suggestions that respect existing technology choices, architectural decisions, and coding patterns
- Unique timestamped file created with no naming conflicts in current working directory
- Analysis demonstrates understanding of both technical implementation details and domain-specific requirements

## Artifact Template

*Generated in current working directory as EXPANSION-{TIMESTAMP}-{SCOPE}.md*

# EXPANSION-{TIMESTAMP}-{SCOPE}

*Feature-Focused Analysis Building on Previous Work*

## Meta-Data
- **Date**: {DATE}
- **Artifact Type**: Analysis
- **Selected Scope**: {SCOPE_AREA}
- **Codebase Directory**: {CODEBASE_DIRECTORY}
- **Context File Applied**: {CONTEXT_FILE_PATH}
- **Focus Area**: {USER_PROVIDED_FOCUS_AREA}
- **Existing Analyses Reviewed**: {EXISTING_ANALYSIS_COUNT} in current working directory
- **Previous Analysis Insights**: {PREVIOUS_ANALYSIS_SUMMARY}
- **Scope Selection Rationale**: {WHY_THIS_SCOPE_CHOSEN_GIVEN_PREVIOUS_WORK}
- **Expansion Opportunity Identified**: {EXPANSION_OPPORTUNITY_DESCRIPTION}

## Previous Analysis Review
### Existing Analyses Found
- **{EXISTING_ANALYSIS_1}**: {KEY_INSIGHTS_1}
- **{EXISTING_ANALYSIS_2}**: {KEY_INSIGHTS_2}
- **{EXISTING_ANALYSIS_N}**: {KEY_INSIGHTS_N}

### Gaps Identified from Previous Work
- **{GAP_1}**: {WHY_NOT_COVERED_PREVIOUSLY}
- **{GAP_2}**: {OPPORTUNITY_MISSED}
- **{GAP_3}**: {SCOPE_FOR_DEEPER_ANALYSIS}

### Building on Previous Insights
{HOW_THIS_ANALYSIS_EXTENDS_PREVIOUS_WORK}

## New Features in {SCOPE_AREA}
### New Feature: {NEW_FEATURE_TITLE}
**Scope**: {SCOPE_AREA}
**Benefit**: {FEATURE_BENEFIT}
**Complexity**: {IMPLEMENTATION_COMPLEXITY}

**Current Implementation Analysis**:
```{PROGRAMMING_LANGUAGE}
{CURRENT_IMPLEMENTATION_CODE}
```

**Implementation Pattern Identified**: {PATTERN_ANALYSIS}
**Extension Points**: {EXTENSION_OPPORTUNITIES}

**New Feature Implementation** (building on existing patterns):
```{PROGRAMMING_LANGUAGE}
{NEW_FEATURE_CODE}
```

**Feature Requirements**:
- {FEATURE_REQUIREMENT_1}
- {FEATURE_REQUIREMENT_2}

## Enhancement Opportunities in {SCOPE_AREA}
### Enhancement: {ENHANCEMENT_TITLE}
**Type**: {ENHANCEMENT_TYPE}
**Benefit**: {IMPROVEMENT_BENEFIT}
**Impact**: {ENHANCEMENT_IMPACT}

**Current Implementation Analysis**:
```{PROGRAMMING_LANGUAGE}
{CURRENT_IMPLEMENTATION_CODE}
```

**Implementation Assessment**: {CURRENT_APPROACH_ANALYSIS}
**Enhancement Opportunity**: {SPECIFIC_IMPROVEMENT_IDENTIFIED}

**Enhanced Implementation** (respecting existing patterns):
```{PROGRAMMING_LANGUAGE}
{ENHANCED_CODE}
```

**Enhancement Value**:
- {ENHANCEMENT_VALUE_1}
- {ENHANCEMENT_VALUE_2}

## Unexplored Implementations in {SCOPE_AREA}
### Unexplored: {UNEXPLORED_IMPLEMENTATION_TITLE}
**Potential**: {IMPLEMENTATION_POTENTIAL}
**Use Cases**: {PRIMARY_USE_CASES}

**Related Implementation Patterns**:
```{PROGRAMMING_LANGUAGE}
{RELATED_PATTERNS_CODE}
```

**Implementation Approach**: {ARCHITECTURAL_APPROACH_ANALYSIS}

**Full Implementation** (consistent with codebase patterns):
```{PROGRAMMING_LANGUAGE}
{FULL_IMPLEMENTATION_CODE}
```

**Integration Points**:
```{PROGRAMMING_LANGUAGE}
{INTEGRATION_CODE}
```

**Implementation Roadmap**:
- {ROADMAP_STEP_1}
- {ROADMAP_STEP_2}
- {ROADMAP_STEP_3}

## Completion Requirements
- {COMPLETION_REQUIREMENT_1}
- {COMPLETION_REQUIREMENT_2}
- {COMPLETION_REQUIREMENT_3}