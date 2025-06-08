# FRAMEWORK_ANALYZE_PROTOCOL.md

Analyze framework evolution and aggregate insights for continuous improvement.

## Protocol Activation

```text
@FRAMEWORK_ANALYZE [command] [arguments]
```

## Commands

```text
generate               → Generate framework analysis from all sources
insights               → Extract actionable insights from applications
metrics [cycle-id]     → Show framework evolution metrics
compare [v1] [v2]     → Compare framework versions
report                → Generate executive summary
prioritize            → Rank improvements by impact
```

## Process Flow

```text
1. Aggregate application feedback
2. Analyze framework metrics
3. Identify improvement patterns
4. Generate actionable insights
5. Feed into next planning cycle
```

## Command Details

### Generate Command

Create comprehensive analysis:

```bash
@FRAMEWORK_ANALYZE generate
```

Actions:
1. Collect all application analyses
2. Aggregate session metrics
3. Analyze framework usage
4. Generate ANALYSIS-XXX.md

Output:
```
Analyzing framework v002 usage...

Data Sources:
  - 3 application analyses
  - 15 development sessions
  - 2,456 API calls tracked
  - 47 friction points identified

Key Findings:
  1. Async test utilities requested 12 times
  2. Migration support needed by 2 apps
  3. Batch operations successful (90% satisfaction)
  4. UI bindings memory issue affected 3 apps

Generated: ANALYSIS-002.md
Priority improvements identified: 4
Next: Review with @FRAMEWORK_ANALYZE insights
```

### Insights Command

Extract improvement opportunities:

```bash
@FRAMEWORK_ANALYZE insights
```

Output:
```
Framework Improvement Insights

CRITICAL (Blocking development):
  None identified ✓

HIGH PRIORITY (Major friction):
  1. Async Test Utilities
     - Requested: 12 times across 3 apps
     - Time wasted: ~8 hours total
     - Solution: Add XCTestAsync extensions
     - Effort: 2-3 days

  2. Memory Management in UI Bindings
     - Affected: 3 apps, 5 developers
     - Workarounds: Manual cleanup required
     - Solution: Automatic lifecycle management
     - Effort: 3-4 days

MEDIUM PRIORITY (Quality of life):
  3. Migration Support
     - Requested: 2 apps
     - Current: Manual version checks
     - Solution: Migration protocol
     - Effort: 3-5 days

  4. Debug Diagnostics
     - Requested: 5 times
     - Current: Print statements
     - Solution: Debug overlay/logging
     - Effort: 2-3 days

Next cycle should address: Async Test Utilities
```

### Metrics Command

Show framework evolution:

```bash
@FRAMEWORK_ANALYZE metrics CYCLE-002
```

Output:
```
Framework Metrics - CYCLE-002-BATCH-OPERATIONS

Development Investment:
  - Requirements: 3
  - Sessions: 5 (11 hours)
  - Code changes: +847, -123 lines
  - Tests added: 23

Adoption Metrics:
  - Apps using new APIs: 3/3 (100%)
  - API calls to batch ops: 487
  - Performance improvement: 89% average
  - Developer satisfaction: 4.5/5

Quality Metrics:
  - Bug reports: 1 (memory spike)
  - Test coverage: 96.2%
  - API breaking changes: 0
  - Documentation complete: Yes

ROI Analysis:
  - Dev time saved: ~15 hours across 3 apps
  - Code reduction: 23% in data operations
  - Investment return: 136% (15h saved / 11h invested)
```

### Compare Command

Compare framework versions:

```bash
@FRAMEWORK_ANALYZE compare v001 v002
```

Output:
```
Framework Evolution: v001 → v002

API Growth:
  Public types:     42 → 47 (+5)
  Public methods:   198 → 234 (+36)
  Deprecated:       0 → 3

Usage Patterns:
  Most used API:    DataStore.save() → DataStore.saveMany()
  Avg calls/app:    156 → 189
  Framework size:   2.1MB → 2.3MB

Developer Experience:
  Setup time:       45min → 30min (-33%)
  Time to first feature: 2h → 1.5h (-25%)
  Friction points:  8 → 5 (-37%)

Test Coverage:
  Overall:          92% → 96.2%
  Integration:      85% → 91%
  Performance:      0% → 78% (NEW)

Top Improvements:
  1. Batch operations (89% faster)
  2. Better error messages
  3. Transaction support
```

### Report Command

Executive summary:

```bash
@FRAMEWORK_ANALYZE report
```

Output:
```
AXIOM FRAMEWORK - EXECUTIVE SUMMARY

Period: 2024-01-15 to 2024-02-15
Version: v001 → v002
Applications: 3 validated

ACHIEVEMENTS:
✓ Batch operations reduced code by 23%
✓ 100% backward compatibility maintained
✓ All applications successfully migrated
✓ Performance targets met

KEY METRICS:
- Developer productivity: +25%
- Framework reliability: 99.8%
- API adoption rate: 100%
- Support tickets: 2 (resolved)

LESSONS LEARNED:
1. TDD approach ensures quality
2. Real app validation essential
3. Performance benchmarks critical
4. Developer feedback invaluable

NEXT PRIORITIES:
1. Async test utilities (HIGH)
2. Memory management (HIGH)
3. Migration support (MEDIUM)

RECOMMENDATION:
Continue 2-week cycles with focus on test utilities
```

### Prioritize Command

Rank improvements:

```bash
@FRAMEWORK_ANALYZE prioritize
```

Output:
```
Framework Improvement Prioritization

Scoring: Impact (40%) + Frequency (30%) + Effort (30%)

1. Async Test Utilities                    Score: 92/100
   Impact: HIGH (unblocks testing)
   Frequency: 12 requests
   Effort: LOW (2-3 days)
   → Start in CYCLE-003

2. UI Binding Memory Management           Score: 85/100
   Impact: HIGH (prevents leaks)
   Frequency: 5 incidents
   Effort: MEDIUM (3-4 days)
   → Plan for CYCLE-004

3. Migration Protocol                     Score: 72/100
   Impact: MEDIUM (easier updates)
   Frequency: 2 requests
   Effort: MEDIUM (3-5 days)
   → Consider for CYCLE-005

4. Debug Diagnostics                      Score: 68/100
   Impact: MEDIUM (faster debugging)
   Frequency: 5 requests
   Effort: LOW (2-3 days)
   → Bundle with CYCLE-004

Recommended next cycle: "Async Testing & Memory Management"
```

## Analysis Process

### Data Collection

Sources aggregated:
1. Application ANALYSIS files
2. Development session metrics
3. Framework test results
4. Performance benchmarks
5. Error/crash reports
6. Developer feedback

### Pattern Recognition

Identifies:
- Repeated friction points
- Common workarounds
- Performance bottlenecks
- API usage patterns
- Testing difficulties

### Insight Generation

Evaluates:
- Frequency of issues
- Development impact
- Solution complexity
- ROI potential

## Technical Details

### Paths

```text
FrameworkWorkspace: /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-meta-workspace/workspaces/FrameworkWorkspace
ApplicationWorkspace: /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-meta-workspace/workspaces/ApplicationWorkspace
```

### Analysis Structure

```text
FrameworkWorkspace/
└── CYCLE-XXX-[TITLE]/
    ├── REQUIREMENTS-XXX.md
    ├── SESSIONS/
    ├── DOCUMENTATION-XXX.md
    └── ANALYSIS-XXX.md        # Generated by this protocol
```

### Metrics Tracked

- API usage frequency
- Development time
- Code quality scores
- Test coverage
- Performance benchmarks
- Bug reports
- Developer satisfaction

## Integration Points

### Inputs
- All application ANALYSIS files
- Framework session metrics
- Test/benchmark results
- Error reports
- Developer feedback

### Outputs
- ANALYSIS-XXX.md
- Prioritized improvements
- Feeds into FRAMEWORK_PLAN

### Dependencies
- Completed applications
- Framework documentation
- Session files
- Metrics tools

## Insight Scoring

### Impact (40%)
- **Critical**: Blocks development
- **High**: Major productivity impact
- **Medium**: Quality of life
- **Low**: Nice to have

### Frequency (30%)
- Number of occurrences
- Number of affected developers
- Consistency across apps

### Effort (30%)
- **Low**: 1-3 days
- **Medium**: 4-7 days
- **High**: 8+ days
- **Very High**: Major refactor

## Error Handling

### Missing Application Data
```
Warning: No application analyses found
Limited analysis based on framework metrics only
Recommendation: Complete at least one app cycle
```

### Incomplete Metrics
```
Warning: Performance benchmarks missing
Analysis excludes performance insights
Run @FRAMEWORK_DEVELOP benchmark first
```

### Version Mismatch
```
Error: Applications used different framework versions
App1: v001, App2: v002
Separate analyses by version
```

## Best Practices

1. **Analyze after each cycle** - Fresh insights are most valuable

2. **Include all data sources** - Comprehensive analysis finds hidden patterns

3. **Quantify everything** - Numbers drive better decisions

4. **Focus on patterns, not incidents** - One-off issues aren't priorities

5. **Consider ROI** - Balance impact against implementation effort