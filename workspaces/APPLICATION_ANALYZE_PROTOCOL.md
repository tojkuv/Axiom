# APPLICATION_ANALYZE_PROTOCOL.md

Analyze application implementation for framework insights.

## Protocol Activation

```text
@APPLICATION_ANALYZE [command] [arguments]
```

## Commands

```text
generate [app-path]     → Generate analysis from implementation
compare [id1] [id2]     → Compare two application analyses
insights [analysis-id]  → Extract framework improvement insights
report [cycle-id]       → Generate cycle summary report
list                    → Show all analyses in workspace
```

## Process Flow

```text
1. Scan completed application implementation
2. Aggregate session metrics and test results
3. Identify framework usage patterns
4. Generate actionable insights
5. Feed into framework evolution
```

## Command Details

### Generate Command

Analyze completed application:

```bash
@APPLICATION_ANALYZE generate task-manager-001-MVP
```

Actions:
1. Load implementation from codebase
2. Process all APP-SESSION files
3. Analyze test results and coverage
4. Identify framework patterns
5. Generate ANALYSIS-XXX.md

Output:
```
Analyzing task-manager-001-MVP...

Loaded:
  - 5 session files (10.5 hours)
  - 2,847 lines of code
  - 35 tests (94.2% coverage)
  - 15 framework APIs used

Key Findings:
  - TaskStore persistence API needs batch operations
  - UI binding pattern requires 40% less code than expected
  - Filter performance degrades with >1000 items

Generated: ANALYSIS-001-TASK-MANAGER-MVP.md
Next: Review insights with @APPLICATION_ANALYZE insights 001
```

### Compare Command

Compare two analyses:

```bash
@APPLICATION_ANALYZE compare 001 003
```

Output:
```
Comparing Application Analyses:

ANALYSIS-001-TASK-MANAGER-MVP vs ANALYSIS-003-TASK-MANAGER-COLLABORATIVE

Metrics Evolution:
  Development Time:     10.5h → 7.2h (-31%)
  Test Coverage:        94.2% → 96.8% (+2.6%)
  Framework APIs Used:  15 → 18 (+3 new)
  Code/Test Ratio:      1:0.8 → 1:1.1

Framework Improvements Applied:
  ✓ Batch operations added to DataStore (reduced code by 23%)
  ✓ Improved error handling patterns (eliminated 5 workarounds)
  ✗ Filter performance still degrades (needs optimization)

New Insights from 003:
  - Concurrent editing requires transaction support
  - WebSocket integration pattern works well
  - Need better conflict resolution APIs
```

### Insights Command

Extract framework improvements:

```bash
@APPLICATION_ANALYZE insights 001
```

Output:
```
Framework Insights from ANALYSIS-001-TASK-MANAGER-MVP

HIGH PRIORITY:
1. DataStore Batch Operations
   - Problem: Individual saves cause performance issues
   - Evidence: 5 sessions mentioned this friction
   - Solution: Add store.saveMany([items]) API
   - Impact: 40% reduction in persistence code

2. Filter Query Builder
   - Problem: Complex queries require manual SQL
   - Evidence: FilterService.swift has 150 lines of boilerplate
   - Solution: Add fluent query builder API
   - Impact: More readable, type-safe queries

MEDIUM PRIORITY:
3. UI Binding Memory Leaks
   - Problem: Manual cleanup required for observers
   - Evidence: 3 memory leaks found and fixed
   - Solution: Automatic lifecycle management
   - Impact: Fewer bugs, cleaner code

LOW PRIORITY:
4. Test Data Builders
   - Problem: Repetitive test setup code
   - Evidence: 200+ lines of test fixtures
   - Solution: Add builder pattern utilities
   - Impact: Faster test writing

Recommended for Next Framework Cycle:
- Implement batch operations (1-2 days)
- Design query builder API (2-3 days)
- Update documentation with patterns from this app
```

### Report Command

Generate cycle summary:

```bash
@APPLICATION_ANALYZE report CYCLE-001-TASK-MANAGER-MVP
```

Output:
```
Cycle Report: CYCLE-001-TASK-MANAGER-MVP

Overview:
  Started: 2024-01-10
  Completed: 2024-01-15
  Total Duration: 5 days
  Sessions: 5 (10.5 hours coding)

Requirements Completion: 5/5 (100%)
  ✓ REQ-001: Task CRUD operations
  ✓ REQ-002: Persistence layer
  ✓ REQ-003: List and filtering
  ✓ REQ-004: Status management
  ✓ REQ-005: Basic UI

Quality Metrics:
  Test Coverage: 94.2%
  Code Quality: A-
  Performance: Meets targets
  Framework Compliance: 100%

Key Achievements:
  - Validated core framework APIs
  - Identified 4 improvement areas
  - Created reusable patterns
  - Established TDD workflow

Next Steps:
  - Apply insights to framework
  - Plan local-chat application
  - Document patterns for reuse
```

### List Command

Show all analyses:

```bash
@APPLICATION_ANALYZE list
```

Output:
```
Application Analyses:

CYCLE-001-TASK-MANAGER-MVP/
  └── ANALYSIS-001-TASK-MANAGER-MVP.md (2024-01-15)
      Framework v001, 10.5 hours, 4 insights

CYCLE-002-LOCAL-CHAT-BASIC/
  └── ANALYSIS-002-LOCAL-CHAT-BASIC.md (2024-01-22)
      Framework v001, 12.3 hours, 6 insights

CYCLE-003-TASK-MANAGER-COLLABORATIVE/
  └── ANALYSIS-003-TASK-MANAGER-COLLABORATIVE.md (2024-02-05)
      Framework v002, 7.2 hours, 3 insights

Total: 3 analyses, 13 framework improvements identified
```

## Analysis Process

### Data Collection

1. **Code Analysis**
   - Lines of code by component
   - Complexity metrics
   - Framework API usage
   - Pattern identification

2. **Session Aggregation**
   - Total development time
   - TDD cycle counts
   - Friction points
   - Developer feedback

3. **Test Analysis**
   - Coverage by component
   - Test execution time
   - Flaky test identification
   - Test quality metrics

4. **Performance Analysis**
   - Runtime benchmarks
   - Memory usage
   - Framework overhead
   - Optimization opportunities

### Insight Generation

1. **Pattern Recognition**
   - Repeated code structures
   - Common workarounds
   - Successful approaches
   - Anti-patterns

2. **Friction Analysis**
   - API difficulties
   - Missing features
   - Documentation gaps
   - Tool limitations

3. **Recommendation Synthesis**
   - Priority ranking
   - Implementation effort
   - Expected impact
   - Risk assessment

## Technical Details

### Paths

```text
ApplicationCodebase: /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-application/AxiomApplications
ApplicationWorkspace: /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-meta-workspace/workspaces/ApplicationWorkspace
Templates: /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-meta-workspace/workspaces/templates/
```

### Analysis Structure

```text
ApplicationWorkspace/
└── CYCLE-XXX-*/
    ├── REQUIREMENTS-XXX-*.md
    ├── SESSIONS/
    │   └── APP-SESSION-*.md
    └── ANALYSIS-XXX-*.md      # Generated by this protocol
```

### Analysis Document

Uses APPLICATION_ANALYSIS_TEMPLATE.md format with sections:
- Metadata and metrics summary
- Implementation overview
- Framework usage analysis
- Developer experience insights
- Performance validation
- Recommendations

## Integration Points

### Inputs
- Application source code
- APP-SESSION-*.md files
- Test results and coverage
- Performance benchmarks
- REQUIREMENTS for validation

### Outputs
- ANALYSIS-XXX-*.md document
- Framework insights
- Feeds into FRAMEWORK_ANALYZE

### Dependencies
- Completed application
- All session files
- Test execution tools
- Code analysis tools

## Metrics Collected

### Code Metrics
- Total/test lines of code
- Component breakdown
- Complexity scores
- Duplication analysis

### Framework Metrics
- APIs used/unused
- Pattern frequency
- Integration complexity
- Performance overhead

### Development Metrics
- Time per requirement
- TDD compliance
- Bug discovery rate
- Refactoring frequency

### Quality Metrics
- Test coverage
- Code maintainability
- Performance targets
- Security compliance

## Error Handling

### Incomplete Implementation
```
Error: Application has failing tests
Recovery: Run @APPLICATION_DEVELOP finalize first
```

### Missing Sessions
```
Error: No session files found
Warning: Analysis will be limited to code metrics only
Continue? [y/n]
```

### Invalid Application Path
```
Error: Application not found at task-manager-001-MVP
Available applications: [list shown]
```

## Best Practices

1. **Analyze immediately after completion** - Fresh context produces better insights

2. **Include all session files** - Developer experience is crucial for framework improvement

3. **Be specific in recommendations** - Vague suggestions don't drive evolution

4. **Compare across cycles** - Track improvement impact over time

5. **Focus on framework value** - Every insight should improve the framework