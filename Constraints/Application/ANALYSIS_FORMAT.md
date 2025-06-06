# Analysis Format Standards

Analysis report specifications for application codebase exploration and framework compliance validation.

## Analysis Structure

### Metadata Header
```markdown
# Analysis: [Application Name]

**Analysis ID**: ANLS-XXX
**Application**: [Name and version]
**Date**: YYYY-MM-DD
**Type**: Quick Scan | Deep Analysis | Axiom Compliance | Performance Profile
**Codebase Size**: [LOC, file count]
**Framework Version**: [Axiom version used]
```

### 1. Executive Summary
```markdown
## Executive Summary

[1-2 paragraphs, max 150 words]
[Paragraph 1: What the application does and its architecture approach]
[Paragraph 2: Key findings and overall health assessment]
```

### 2. Architecture Overview
```markdown
## Architecture Overview

### Component Inventory
- **Clients**: [Count] actors managing domain state
- **States**: [Count] immutable state types
- **Contexts**: [Count] UI coordinators
- **Capabilities**: [Count] external service interfaces
- **Presentations**: [Count] SwiftUI views
- **Orchestrator**: [Implementation details]

### Axiom Compliance
- **Pattern Adherence**: [Percentage and violations]
- **Component Relationships**: [Valid/Invalid mappings]
- **Navigation Flow**: [Proper Context mediation: Yes/No]

### Domain Model
[Text or diagram showing Client-State ownership and Context-Client dependencies]
Example:
- AuthClient owns AuthState
- UserClient owns UserState
- LoginContext uses AuthClient
- ProfileContext uses AuthClient, UserClient
```

### 3. Code Quality Metrics
```markdown
## Code Quality Metrics

### Quantitative Metrics
- **Test Coverage**: [X]% overall ([X]% Clients, [X]% Contexts)
- **Code Duplication**: [X]% duplicate code
- **Cyclomatic Complexity**: Average [X], Max [X]
- **Dependencies**: [X] external, [X] internal

### Axiom-Specific Metrics
- **Actor Isolation**: [X] proper, [X] violations
- **State Immutability**: [X]% compliance
- **Context Lifecycle**: [X] proper, [X] memory leaks
- **Error Boundaries**: [X]% coverage

### Technical Debt
1. [Issue 1]: [Impact and effort to fix]
2. [Issue 2]: [Impact and effort to fix]
```

### 4. Performance Analysis
```markdown
## Performance Analysis

### Runtime Characteristics
- **State Propagation**: Avg [X]ms, P99 [X]ms (Target: <16ms)
- **Component Init**: Avg [X]ms, Max [X]ms (Target: <50ms)
- **Memory Per Component**: Avg [X]KB (Target: <1KB)
- **Concurrent Operations**: Tested with [X] actors

### Bottlenecks Identified
1. [Operation]: [Current time] → [Suggested improvement]
2. [Component]: [Memory usage] → [Optimization approach]

### Stress Test Results
- **Actor Concurrency**: [Pass/Fail with details]
- **Memory Under Load**: [Growth pattern]
- **Navigation Performance**: [Timing data]
```

### 5. Findings & Recommendations
```markdown
## Findings & Recommendations

### Critical Issues
1. **[Issue Name]**:
   - Finding: [What was discovered]
   - Impact: [How it affects the app]
   - Recommendation: [How to fix]
   - Priority: High | Medium | Low

### Axiom Pattern Violations
1. **[Violation Type]**:
   - Location: [File:line references]
   - Current: [What's wrong]
   - Required: [Axiom-compliant approach]

### Enhancement Opportunities
1. **[Enhancement]**:
   - Current: [Existing implementation]
   - Proposed: [Better approach]
   - Benefit: [Expected improvement]
```

### 6. Test Assessment
```markdown
## Test Assessment

### Test Distribution
- **Unit Tests**: [Count] tests, [X]% of codebase
- **UI Tests**: [Count] tests, [X] user flows
- **Integration Tests**: [Count] tests
- **Performance Tests**: [Count] benchmarks

### Test Quality
- **Axiom Pattern Tests**: [Coverage of component relationships]
- **Error Scenario Tests**: [Edge case coverage]
- **Async/Actor Tests**: [Concurrency test coverage]

### Missing Test Coverage
1. [Component/Feature]: [What needs testing]
2. [Error Path]: [Untested scenario]
```


## Key Principles

1. **Objective Measurement**: Quantify all findings
2. **Axiom Focus**: Validate framework pattern usage
3. **Actionable Insights**: Every finding has a recommendation
4. **Priority Guidance**: Clear fix ordering
5. **Test Coverage**: Validate quality and completeness

---

**This format enables systematic application analysis with focus on Axiom framework compliance.**
