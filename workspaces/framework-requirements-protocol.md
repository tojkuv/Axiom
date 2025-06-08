# FRAMEWORK_REQUIREMENTS_PROTOCOL.md

Transform validated application pain points into actionable framework requirements through evidence-based planning.

## Protocol Activation

```text
@FRAMEWORK_REQUIREMENTS [command] [arguments]
```

## Commands

```text
explore                 → Review pain points from application analyses for requirement planning
generate                → Create requirements from validated pain points with clear success metrics
list                    → Show requirements with pain point traceability
status                  → Display pain point resolution progress across cycles
validate [id]          → Ensure requirements address original problems effectively
archive [id]           → Archive completed requirements with resolution verification
```

## Process Flow

```text
1. Analyze pain points from multiple application cycles
2. Prioritize by impact and frequency
3. Generate specific requirements with validation criteria
4. Track resolution through implementation and validation
```

## Command Details

### Explore Command

Review aggregated pain points for planning:

```bash
@FRAMEWORK_PLAN explore
```

The explore command now focuses on reviewing validated pain points from application analyses rather than open-ended exploration. It presents quantified friction points with evidence, patterns across multiple applications, and time lost to framework limitations, enabling data-driven requirement prioritization.

Output:
```
Reviewing framework pain points from application cycles...

HIGH IMPACT (>2 hours lost per cycle):
1. Batch Operations Missing
   - Cycles affected: TASK-MANAGER-001, TASK-MANAGER-003, CHAT-002
   - Total time lost: 8.5 hours across 3 cycles
   - Current workaround complexity: HIGH
   - Example: 100 items taking 3+ seconds to save

2. Async Test Utilities Gap
   - Cycles affected: ALL (5 cycles)
   - Total time lost: 12 hours
   - Test complexity increase: 65%
   - Example: 20+ lines for simple async assertions

3. Transaction Boilerplate
   - Cycles affected: TASK-MANAGER-001, TASK-MANAGER-003
   - Total time lost: 4 hours
   - Workaround lines: 50+ per transaction
   - Example: Complex coordination for related updates

Which pain point should we address first?
Based on impact, recommend starting with Async Test Utilities...
```

### Generate Command

Create requirements from validated pain points:

```bash
@FRAMEWORK_PLAN generate
```

Generation now creates requirements directly from analyzed pain points, ensuring each requirement includes evidence from application cycles, specific examples of friction, quantified improvement targets, and clear validation criteria. This maintains traceability from problem identification through solution delivery.

Output:
```
Generated: CYCLE-002-ASYNC-TEST-UTILITIES/REQUIREMENTS-002-ASYNC-TEST-UTILITIES.md

Based on pain points from:
- 5 application cycles (100% encountered this)
- 12 total hours lost to async test complexity
- 65% increase in test code complexity

Key Requirements Generated:
- REQ-001: XCTAssertAsync helper (saves ~5 lines per test)
- REQ-002: Async test timeout handling (prevents flaky tests)
- REQ-003: AsyncStream test utilities (simplifies state testing)

Success Validation:
- Reduce async test setup by >60%
- Eliminate common timeout issues
- Enable single-line async assertions

Ready for development with clear pain point traceability
```

### List Command

Show requirements with pain point context:

```bash
@FRAMEWORK_PLAN list
```

The list command now shows requirements organized by their pain point resolution status, making it clear which developer problems are being addressed and which still need attention:

```
Framework Requirements by Pain Point:

ADDRESSED (In Development):
  Async Test Utilities (12 hours of friction)
    └── REQUIREMENTS-002-ASYNC-TEST-UTILITIES.md
        Status: IN_PROGRESS (60% complete)
        Validates in: Next CHAT application cycle

PRIORITIZED (Ready to Start):
  Batch Operations (8.5 hours of friction)
    └── REQUIREMENTS-003-BATCH-OPERATIONS.md
        Status: APPROVED
        Evidence: 3 cycles affected

IDENTIFIED (Needs Requirements):
  Transaction Complexity (4 hours of friction)
    - No requirements yet
    - Workaround documented in ANALYSIS-001, 003

RESOLVED (Validated):
  State Update Performance (v001)
    └── REQUIREMENTS-001-FOUNDATION.md
        Validation: Confirmed in CYCLE-004
```

### Status Command

Track pain point resolution progress:

```bash
@FRAMEWORK_PLAN status
```

Status tracking emphasizes which pain points are actively being resolved and which are still causing developer friction:

```
Framework Pain Point Resolution Status

ACTIVE RESOLUTION:
- Async Test Utilities: 60% implemented
  - Original friction: 12 hours across 5 cycles
  - Target improvement: 65% reduction in test code
  - Validation planned: CYCLE-005-CHAT-ADVANCED

QUEUED FOR RESOLUTION:
1. Batch Operations (HIGH) - 8.5 hours friction
2. Transaction Complexity (MEDIUM) - 4 hours friction
3. Mock Generation (MEDIUM) - 3 hours friction

RECENTLY RESOLVED:
- State Performance (v001) - Validated 90% improvement
- Navigation Patterns (v001) - Confirmed easier usage

EMERGING PATTERNS:
- Context lifecycle (seen in 2 recent cycles)
- Platform testing differences (growing friction)

Recommend prioritizing Batch Operations next
```

### Validate Command

Ensure requirements address original problems:

```bash
@FRAMEWORK_PLAN validate 002
```

Validation now explicitly checks that requirements will resolve the original pain points:

```
Validating REQUIREMENTS-002-ASYNC-TEST-UTILITIES...

Pain Point Coverage:
✓ Complex async test setup - REQ-001 provides helper
✓ Timeout handling issues - REQ-002 addresses directly
✓ AsyncStream testing - REQ-003 adds utilities
✓ All examples from applications covered

Success Metrics Defined:
✓ Test line reduction target: 65% (measurable)
✓ Timeout elimination: 100% (testable)
✓ Developer time saving: 2.4 hours/cycle (quantified)

Validation Plan:
✓ Test with CHAT application patterns
✓ Measure actual line reduction
✓ Track developer feedback

Requirements properly address all identified pain points
```

### Archive Command

Archive completed requirements with verification:

```bash
@FRAMEWORK_PLAN archive 001
```

Archival now includes verification that pain points were actually resolved:

```
Archiving REQUIREMENTS-001-FOUNDATION-ARCHITECTURE...

Pain Point Resolution Verified:
✓ State update performance - 90% improvement confirmed
✓ Navigation complexity - New patterns adopted
✓ Initial setup time - Reduced to <5 minutes

Validation Results:
- Used in 3 subsequent applications
- No regression of original issues
- New patterns emerging from solution

Archived with full resolution verification
```

## Pain Point Driven Planning

### Evidence-Based Prioritization
Requirements are prioritized based on objective metrics including total time lost across cycles, number of applications affected, complexity of current workarounds, and potential improvement impact. This ensures framework evolution addresses the most impactful issues first.

### Traceability Maintenance
Every requirement maintains clear traceability to original pain points, including links to specific application sessions, examples of problematic code, measurements of friction, and validation criteria. This enables tracking from problem through solution to verification.

### Pattern Recognition
The protocol identifies patterns across pain points to guide framework architecture decisions. Recurring issues might indicate systematic problems requiring architectural changes rather than point solutions.

### Success Metric Definition
Each requirement includes specific, measurable success criteria derived from the original pain points. This might include time reductions, code line savings, complexity decreases, or performance improvements - all traceable to original developer friction.

## Continuous Improvement Tracking

### Pain Point Lifecycle
The protocol tracks pain points through their complete lifecycle: identification in application development, prioritization in planning, requirement generation, implementation in framework development, validation in subsequent applications, and confirmation of resolution. This ensures no pain point is forgotten and all resolutions are verified.

### Emerging Issue Detection
By continuously analyzing application sessions, the protocol detects emerging pain points before they become major friction sources. This enables proactive framework evolution based on early indicators.

### Resolution Effectiveness
The protocol tracks whether pain point resolutions actually work in practice by monitoring subsequent application cycles for regression, measuring actual vs. projected improvements, and gathering developer feedback on solutions.

## Best Practices

1. **Always Start with Evidence**
   - Base requirements on quantified pain points
   - Include specific examples from applications
   - Link to original session documentation

2. **Define Measurable Success**
   - Set specific improvement targets
   - Define how to validate resolution
   - Plan verification in next cycle

3. **Maintain Traceability**
   - Connect requirements to pain points
   - Track through implementation
   - Verify in application usage

4. **Prioritize by Impact**
   - Address highest friction first
   - Consider frequency across cycles
   - Balance quick wins with systematic fixes

5. **Close the Loop**
   - Always validate resolutions work
   - Track long-term effectiveness
   - Learn from what works