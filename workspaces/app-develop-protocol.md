# APPLICATION_DEVELOP_PROTOCOL.md

Test-driven application implementation with focused framework insight capture during development cycles.

## Protocol Activation

```text
@APPLICATION_DEVELOP generate [cycle-folder] [framework-doc] [api-reference] [requirements] [session-template]
```

## Process Flow

```text
1. Check cycle folder for existing session files to determine state:
   - No session files: Start new application development
   - Existing session files with incomplete requirements: Continue development
   - All requirements completed: Report cycle completion
2. Load requirements with TDD checklists and framework validation goals
3. Execute RED-GREEN-REFACTOR cycles with insight tracking
4. Document framework pain points and successes in real-time
5. Create/update session reports in cycle folder
6. Maintain high test coverage while identifying framework gaps
```

## Command Details

### Generate Command

The protocol guides TDD implementation while capturing framework insights:

```bash
@APPLICATION_DEVELOP generate /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-application/CYCLE-001-TASK-MANAGER-MVP /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-framework/AxiomFramework/DOCUMENTATION.md /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-framework/AxiomFramework/API_REFERENCE.md /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-application/CYCLE-001-TASK-MANAGER-MVP/REQUIREMENTS-001-TASK-MANAGER-MVP.md /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-meta-workspace/workspaces/app-session-template.md
```

**Parameters:**
- `cycle-folder`: Development cycle directory where application and session files are created
- `framework-doc`: Framework documentation for reference during development
- `api-reference`: API reference for implementation details
- `requirements`: Application requirements with TDD checklists
- `session-template`: Template for capturing development insights

**Session State Detection**:
The generate command now intelligently determines the development state by scanning the cycle folder:
- **New Application**: No APP-SESSION-*.md files exist - creates initial session and starts from REQ-001
- **Continuing Development**: Finds existing sessions with incomplete requirements - resumes from last completed requirement
- **Cycle Complete**: All requirements marked as completed in latest session - reports completion status

**Enhanced Session Tracking**:
Each session now emphasizes capturing framework insights during TDD cycles, with specific sections for pain points discovered during test writing, successful patterns that should be framework features, missing test utilities or helpers, and performance observations with framework overhead. Session files focus on actionable insights rather than routine development details.

**TDD Workflow with Insight Capture**:

During the RED phase, the protocol prompts developers to note any framework APIs that are difficult to test, identify missing mocks or test utilities, document complex test setup requirements, and track time lost to framework friction. This ensures pain points are captured when they're most apparent.

The GREEN phase tracking includes documenting workarounds needed for framework limitations, noting API awkwardness discovered during implementation, identifying patterns that should be framework-provided, and measuring framework performance overhead.

REFACTOR phase improvements now focus on identifying repeated patterns that indicate framework gaps, documenting ideal APIs that would eliminate boilerplate, noting architectural patterns the framework should encourage, and capturing insights about framework constraints.

**Streamlined Output**:
```
Checking cycle folder: /Users/tojkuv/.../CYCLE-001-TASK-MANAGER-MVP
Detected state: New Application (no existing sessions)

Loading resources:
- Cycle folder: CYCLE-001-TASK-MANAGER-MVP
- Framework documentation: DOCUMENTATION.md
- API reference: API_REFERENCE.md  
- Requirements: REQUIREMENTS-001-TASK-MANAGER-MVP.md
- Session template: app-session-template.md

Creating application structure in cycle folder...
Starting implementation for REQUIREMENTS-001-TASK-MANAGER-MVP
Session: ./CYCLE-001-TASK-MANAGER-MVP/APP-SESSION-001.md

Focus: Capturing framework insights during TDD
- Document pain points when encountered
- Note missing test utilities immediately  
- Track time lost to framework friction
- Identify patterns for framework adoption

Beginning RED phase for REQ-001...
Framework APIs under test: DataStore, Model protocols
Watch for: Test setup complexity, missing utilities
```

**Alternative outputs for different states**:

*Continuing Development*:
```
Checking cycle folder: /Users/tojkuv/.../CYCLE-001-TASK-MANAGER-MVP
Detected state: Continuing Development
Latest session: APP-SESSION-003.md
Last completed: REQ-007 (7 of 15 requirements)

Resuming from REQ-008...
```

*Cycle Complete*:
```
Checking cycle folder: /Users/tojkuv/.../CYCLE-001-TASK-MANAGER-MVP
Detected state: All Requirements Complete
Total sessions: 5
All 15 requirements implemented and tested

Cycle CYCLE-001-TASK-MANAGER-MVP completed successfully.
Review APP-ANALYSIS-001.md for framework insights summary.
```

## Enhanced Session Management

### Real-Time Insight Capture
Sessions now include prompts during development to capture framework insights immediately when encountered, rather than trying to reconstruct them later. This includes specific friction points with time estimates, workaround complexity ratings, and improvement suggestions with examples.

### Focused Documentation
Session reports prioritize high-value information about framework pain points discovered during testing, successful patterns that accelerated development, missing utilities that would improve TDD velocity, and performance characteristics affecting test execution. Routine development details are minimized to reduce administrative overhead.

### Cross-Session Pattern Tracking
The protocol now maintains awareness of patterns across sessions within a cycle, including recurring pain points that indicate systematic issues, successful workarounds that suggest framework features, consistent performance bottlenecks, and frequently accessed documentation sections indicating gaps.

### Application Structure in Cycle Folder
All application development occurs within the designated cycle folder:
- **Application Code**: Created as a subdirectory (e.g., `TaskManagerApp/`) within the cycle folder
- **Session Files**: APP-SESSION-*.md files stored at the cycle folder root for easy access
- **Test Files**: Organized within the application subdirectory following TDD practices
- **Analysis Files**: APP-ANALYSIS-*.md generated at cycle completion in the cycle folder

This structure ensures all cycle artifacts remain together, simplifying navigation and review.

## Integration Improvements

### Requirements Awareness
The protocol now actively references the framework validation goals from requirements during implementation, ensuring developers remain aware of what framework aspects they're testing and can document insights related to specific validation goals.

### Framework Documentation Integration
Quick access to framework documentation during development helps identify whether issues are due to missing features or documentation gaps, with specific tracking of documentation lookups and their outcomes.

### Test Utility Tracking
Special attention is paid to test setup patterns that could be simplified by framework utilities, with session tracking of boilerplate code in tests and suggestions for framework test helpers.

## Metrics and Insights

### Automated Metric Collection
The protocol now automatically tracks TDD cycle times (RED, GREEN, REFACTOR), test coverage progression, framework friction incidents per session, and time spent on workarounds versus productive development.

### Insight Quality Checks
Before completing a session, the protocol ensures all significant pain points are documented with examples, time impacts are estimated for major friction points, improvement suggestions are specific and actionable, and successful patterns are noted for framework adoption.

### Continuous Improvement Tracking
Sessions build on previous insights by noting whether previous session's pain points persist, tracking cumulative time lost to specific issues, identifying when workarounds become patterns, and measuring improvement in TDD velocity over time.

## Best Practices Integration

The protocol now embeds best practices for capturing high-quality insights during development, including documenting issues immediately when encountered, including code examples with pain points, quantifying impact in time or complexity, and suggesting specific framework improvements. This ensures the development process naturally generates the insights needed for framework evolution while minimizing additional documentation burden.

## Success Validation

Each session includes validation that framework insights were captured effectively, pain points include actionable improvement suggestions, test coverage meets targets despite framework friction, and the session advances both application completion and framework understanding. This ensures every development session contributes meaningfully to the framework improvement cycle.