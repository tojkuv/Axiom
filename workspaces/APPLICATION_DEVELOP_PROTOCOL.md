# APPLICATION_DEVELOP_PROTOCOL.md

Test-driven application implementation following requirements checklists with session tracking.

## Protocol Activation

```text
@APPLICATION_DEVELOP generate
```

## Process Flow

```text
1. Navigate to cycle directory containing requirements
2. Load requirements file with checklists
3. Check for existing sessions (start fresh or resume)
4. Create application subdirectory if needed
5. Work in TDD cycles (RED → GREEN → REFACTOR)
6. Track progress in session files within cycle directory
7. Continue until all requirements met
```

## Command Details

### Generate Command

The protocol automatically determines whether to start fresh or resume based on existing session files:

```bash
@APPLICATION_DEVELOP generate
```

**Inputs** (always provided):
- REQUIREMENTS-XXX-*.md (READ-ONLY - contains RED-GREEN-REFACTOR checklists)
- APPLICATION_SESSION_TEMPLATE.md (used to create session files)
- Framework DOCUMENTATION-XXX.md (READ-ONLY - API reference)
- Framework path: /path/to/AxiomFramework/ (READ-ONLY - actual framework code)

**Actions**:
1. Navigate to cycle directory containing REQUIREMENTS-XXX-*.md
2. Read requirements file to understand checklists
3. Check for existing APP-SESSION-XXX.md files in directory
4. If none exist: Initialize new implementation
5. If sessions exist: Resume from last session state
6. Create new session file in same directory
7. Create/update application code in subdirectory
8. Import and use framework from provided path
9. Execute TDD workflow based on checklist progress
10. Track all progress in session file only

**Fresh Start Output**:
```
Starting implementation for REQUIREMENTS-001-TASK-MANAGER-MVP
Working directory: /Users/.../CYCLE-001-TASK-MANAGER-MVP/

Created: ./task-manager-app/
Session: ./APP-SESSION-001.md

Requirement Checklists Loaded:
  REQ-001: Task Creation (0/9 complete)
    - RED: 0/3 tests written
    - GREEN: 0/3 tasks complete
    - REFACTOR: 0/3 improvements
  REQ-002: Task Persistence (0/9 complete)
  REQ-003: Task Display (0/9 complete)

Beginning RED phase for REQ-001...
[Implementation continues]
```

**Resume Output**:
```
Resuming REQUIREMENTS-001-TASK-MANAGER-MVP
Working directory: /Users/.../CYCLE-001-TASK-MANAGER-MVP/
Previous session: ./APP-SESSION-003.md (2 hours)

Checklist Progress:
  REQ-001: Task Creation (7/9 complete)
    ✓ RED: 3/3 tests written
    ✓ GREEN: 3/3 tasks complete
    ◐ REFACTOR: 1/3 improvements
  REQ-002: Task Persistence (2/9 complete)
    ◐ RED: 2/3 tests written
    ✗ GREEN: 0/3 tasks complete
  REQ-003: Task Display (0/9 complete)

Session: ./APP-SESSION-004.md created
Continuing REQ-001 REFACTOR phase...
[Implementation continues]
```

## Session Tracking

### Session File Structure

Each session creates APP-SESSION-XXX.md in the cycle directory using APPLICATION_SESSION_TEMPLATE.md format:
- Session metadata (date, duration, focus)
- Checklist progress tracking
- TDD phase completion status
- Framework insights
- Next session planning

### Session Continuity

Sessions in the cycle directory maintain:
- Requirement completion checklist
- Test status tracking
- Coverage evolution
- Technical decisions log
- Framework friction points
- Application code progress

## TDD Workflow

### Working with Requirement Checklists

Each requirement has RED-GREEN-REFACTOR checklists:

#### RED Phase (Write Tests)
- Follow the RED checklist items
- Write tests that initially fail
- Focus on testing behavior, not implementation
- Document test purpose and expected outcome

#### GREEN Phase (Make Tests Pass)
- Follow the GREEN checklist items
- Implement minimal code to pass tests
- Don't add features beyond checklist scope
- Verify all RED tests are passing

#### REFACTOR Phase (Improve Code)
- Follow the REFACTOR checklist items
- Improve code quality while keeping tests green
- Apply framework best practices
- Optimize performance where needed

### Tracking Progress
- Track all checklist completion in session files only
- Never modify the requirements file
- Calculate progress percentages in sessions
- Note framework insights discovered
- Document any blockers or deviations

## Technical Details

### Paths

```text
Framework (Input): /path/to/AxiomFramework/
Cycle Directory: /Users/.../workspace-application/CYCLE-XXX-[TITLE]/
  └── Contains all artifacts for this cycle:
      ├── REQUIREMENTS-XXX-*.md (input)
      ├── APP-SESSION-XXX.md (output)
      └── [app-name]/ (output - application code)
```

### Cycle Directory Structure

```text
CYCLE-XXX-[TITLE]/
├── REQUIREMENTS-XXX-*.md (input - from PLAN protocol)
├── APP-SESSION-001.md (created by DEVELOP protocol)
├── APP-SESSION-002.md
├── APP-SESSION-XXX.md
└── [app-name]/
    ├── Package.swift (imports AxiomFramework)
    ├── Sources/
    │   ├── Models/
    │   ├── Views/
    │   └── Services/
    ├── Tests/
    │   ├── Unit/
    │   ├── Integration/
    │   └── UI/
    └── Resources/
```

## Integration Points

### Inputs (Always Provided)
- REQUIREMENTS-XXX-*.md (READ-ONLY - from PLAN protocol)
- APPLICATION_SESSION_TEMPLATE.md (READ-ONLY - template for sessions)
- Framework DOCUMENTATION-XXX.md (READ-ONLY - API reference)
- Framework path: /path/to/AxiomFramework/ (READ-ONLY - framework implementation)

### Outputs (Created in Cycle Directory)
- Application implementation code in ./[app-name]/
- APP-SESSION-XXX.md files in cycle directory
- Complete implementation ready for ANALYZE protocol

### Important: Input File Handling
- All input files and paths are treated as READ-ONLY
- Framework code is referenced but never modified
- Requirements checklists are tracked in session files only
- Progress is never written back to requirements files
- Session files are the single source of truth for progress

### Tools Used
- Xcode for Swift development
- XCTest for testing
- Framework test utilities
- Coverage reporting tools

## Error Handling

### Missing Inputs
```
Error: Required input files not found
Recovery: Ensure all three inputs are provided:
  - REQUIREMENTS-XXX-*.md
  - APPLICATION_SESSION_TEMPLATE.md
  - Framework DOCUMENTATION-XXX.md
```

### Test Framework Failure
```
Error: Failed to initialize test framework
Recovery: Check Xcode project configuration
```

### Session Continuity
```
Error: Cannot parse previous session state
Recovery: Create fresh session with manual progress assessment
```

## Best Practices

1. **Trust the protocol flow** - Let it guide through RED→GREEN→REFACTOR automatically

2. **Follow checklist order** - Complete requirements sequentially for best results

3. **Document framework insights** - Note API friction points in session files

4. **Complete all checklists** - Ensure 100% completion before moving to ANALYZE

5. **Session continuity** - The protocol handles resume automatically

6. **Cycle organization** - All artifacts stay together in the cycle directory for easy tracking