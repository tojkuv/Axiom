# APPLICATION_ANALYZE_PROTOCOL.md

Analyze single application implementation to extract actionable framework insights through focused test-driven development metrics and pain point identification.

## Protocol Activation

```
@APPLICATION_ANALYZE generate [cycle-folder-path] [framework-document-path] [optional-args]
```

## Commands

```
generate [cycle-folder] [framework-document-path] [previous-analysis-id?]     → Generate analysis focused on framework insights
```

## Process Flow

```
1. Scan cycle folder for TDD session insights and pain points
2. Aggregate framework friction metrics and workarounds
3. Identify high-impact improvement opportunities
4. Generate actionable framework requirements
5. Create concise analysis focused on framework evolution
```

## Command Details

### Generate Command

Analyze completed application for framework improvement opportunities:

```bash
# Basic analysis
@APPLICATION_ANALYZE generate /path/to/CYCLE-001-TASK-MANAGER-MVP /path/to/DOCUMENTATION-001.md

# With comparison to show improvement validation
@APPLICATION_ANALYZE generate /path/to/CYCLE-003-TASK-MANAGER-COLLABORATIVE /path/to/DOCUMENTATION-003.md 001
```

Actions:
1. **Extract Framework Insights**:
   - Scan APP-SESSION-*.md for documented pain points
   - Aggregate framework friction incidents
   - Identify missing test utilities
   - Collect successful patterns

2. **Analyze TDD Effectiveness**:
   - Calculate RED→GREEN cycle times
   - Measure test setup complexity
   - Track framework-related delays
   - Identify testing bottlenecks

3. **Generate Prioritized Improvements**:
   - Rank pain points by frequency and impact
   - Estimate time savings from fixes
   - Create specific, actionable requirements
   - Link improvements to evidence

4. **Validate Previous Improvements** (if comparison):
   - Check if previous pain points resolved
   - Measure actual vs. projected improvements
   - Identify any regression areas
   - Confirm patterns scale appropriately

Output Format:
```
Analyzing CYCLE-001-TASK-MANAGER-MVP...

Framework Insights Summary:
  - Critical Pain Points: 3 (12.5 hours lost)
  - High Priority Improvements: 5
  - Successful Patterns to Expand: 2
  - Test Utilities Needed: 4

Top Framework Improvements Needed:
  1. Batch operations for DataStore (would save ~3 hours/cycle)
  2. Async test utilities (would save ~2 hours/cycle)
  3. Context lifecycle helpers (would save ~1.5 hours/cycle)

TDD Metrics:
  - Average RED→GREEN: 12 minutes (target: <10)
  - Test setup overhead: 35% of test code
  - Framework friction: 23% of development time

Generated: CYCLE-001-TASK-MANAGER-MVP/ANALYSIS-001-TASK-MANAGER-MVP.md
Actionable requirements ready for framework planning.
```

## Analysis Focus Areas

### Framework Pain Points
- **Critical**: Blocking efficient development (>1 hour lost)
- **High**: Significant friction (30-60 minutes lost)
- **Medium**: Quality of life issues (<30 minutes lost)

### TDD Effectiveness Metrics
- RED phase duration and blockers
- GREEN phase implementation friction
- REFACTOR frequency and patterns
- Test execution performance

### Pattern Recognition
- Successful framework usage patterns
- Common workarounds indicating gaps
- Emerging architectural patterns
- Cross-cutting concerns

### Actionable Outputs
- Specific API improvements with examples
- Test utility requirements with use cases
- Performance optimization opportunities
- Documentation gaps with context

## Data Aggregation Strategy

### Session Insight Extraction
Focus on high-value insights only:
- Framework friction with time impact
- Specific API pain points with examples
- Missing utilities with use cases
- Performance bottlenecks with metrics

### Pattern Synthesis
Identify recurring themes across sessions:
- Same pain point in multiple sessions
- Similar workarounds implemented
- Consistent performance issues
- Repeated documentation lookups

### Priority Calculation
```
Priority = (Time Lost × Frequency × Developer Frustration) / Implementation Effort
```

### Requirement Generation
Transform insights into specific requirements:
- Clear problem statement with evidence
- Proposed solution with API design
- Success metrics for validation
- Test cases to verify improvement

## Integration Points

### Inputs
- APP-SESSION-*.md files (framework insights)
- Test results and coverage metrics
- Performance benchmarks
- Framework documentation for comparison

### Outputs
- ANALYSIS-XXX.md (focused on actionable insights)
- Prioritized framework improvements
- Specific requirement suggestions
- Validation metrics for next cycle

### Feeds Into
- FRAMEWORK_PLAN for requirement generation
- Next application cycle for validation
- Framework roadmap prioritization

## Quality Checks

### Insight Validation
- Is the pain point quantified with time/complexity?
- Is there a specific example from code?
- Is the proposed improvement clear?
- Can success be measured?

### Requirement Readiness
- Does each requirement address specific pain points?
- Are success criteria measurable?
- Is implementation effort estimated?
- Are test cases defined?

### Analysis Completeness
- All critical pain points captured?
- TDD metrics calculated?
- Patterns documented?
- Improvements prioritized?

## Best Practices

1. **Focus on Actionable Insights**
   - Every insight should lead to a potential improvement
   - Quantify impact in time or complexity reduction
   - Include specific code examples

2. **Maintain Traceability**
   - Link pain points to specific sessions
   - Connect improvements to original issues
   - Track resolution through cycles

3. **Prioritize Ruthlessly**
   - Focus on highest impact improvements
   - Consider implementation effort
   - Balance quick wins with strategic changes

4. **Validate Improvements**
   - Always compare with previous cycles
   - Measure actual vs. projected benefits
   - Document what worked and what didn't

5. **Keep Analysis Concise**
   - Executive summary with key actions
   - Detailed evidence in appendix
   - Clear next steps for framework team