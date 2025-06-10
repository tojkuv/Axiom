# FRAMEWORK-ANALYZE-PROTOCOL-REVISED

Autonomous multi-worker framework analysis protocol for continuous gap identification and optimization discovery. Enables independent workers with no inter-worker communication to systematically explore framework codebase while preventing duplication through filesystem-based coordination.

## Protocol Activation

```
@FRAMEWORK_ANALYZE generate <framework_dir> <analysis_template>
```

## Command

### Generate - Framework Codebase Analysis

The generate command analyzes the framework to build technical advantages over existing iOS frameworks. It identifies opportunities to simplify SwiftUI's complexity, streamline Combine's patterns, reduce TCA's boilerplate, and improve upon VIPER's architecture through better design decisions and incremental optimizations.

```bash
@FRAMEWORK_ANALYZE generate \
  /path/to/AxiomFramework \
  /path/to/framework-analysis-template.md
```

### Example Usage

```bash
@FRAMEWORK_ANALYZE generate \
  /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-framework/AxiomFramework \
  /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-meta-workspace/workspaces/framework-analysis-template.md

# Creates: /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-framework/AxiomFramework/FW-ANALYSIS-20241210-143052-789123-45678-234.md
```

## Autonomous Worker Coordination

### Zero-Communication Architecture

Workers operate independently with no inter-process communication, coordinating only through filesystem artifacts. Each worker must handle:
- **Race Conditions**: Multiple workers accessing same files simultaneously
- **Naming Collisions**: Workers starting at same time creating identical filenames
- **State Inconsistency**: File state changing between worker read and write operations
- **Write Conflicts**: Multiple workers attempting to modify same artifact

### Collision-Resistant Naming Strategy

```
FW-ANALYSIS-YYYYMMDD-HHMMSS-ssssss-PID-RND.md
```

Components:
- **YYYYMMDD-HHMMSS**: Date and time (second precision)
- **ssssss**: Microseconds (6 digits for sub-second uniqueness)
- **PID**: Process ID (prevents same-machine collisions)
- **RND**: 3-digit random number (000-999, prevents edge case collisions)

Examples:
- FW-ANALYSIS-20241210-143052-789123-45678-234.md
- FW-ANALYSIS-20241210-143052-789124-45679-891.md
- FW-ANALYSIS-20241210-143053-012456-45680-567.md

### Atomic Worker Protocol

1. **Snapshot Read**: Read all existing FW-ANALYSIS-*.md files atomically
2. **Analysis Planning**: Determine unexplored gaps based on snapshot
3. **Collision-Free Creation**: Generate unique filename with timestamp+PID+random
4. **Atomic Write**: Write complete analysis to temp file, then atomic rename
5. **Verification**: Re-read directory to verify successful creation
6. **Retry Logic**: Handle file system conflicts with exponential backoff

### File Size Management

**Individual File Limit**: 1000 lines maximum per worker-created file
**Worker Responsibility**: Each worker creates exactly one analysis file
**No Shared Editing**: Workers never modify files created by other workers
**Size Enforcement**: Workers must count lines and truncate if approaching limit

### Race Condition Handling

**Atomic Write Operations**
```bash
# Worker writes to temporary file first
echo "analysis content" > FW-ANALYSIS-temp-$PID-$RANDOM.md

# Atomic rename to final filename (prevents partial reads)
mv FW-ANALYSIS-temp-$PID-$RANDOM.md FW-ANALYSIS-20241210-143052-789123-45678-234.md
```

**Directory Scan Race Conditions**
- Workers accept that snapshot may be stale by write time
- Multiple workers may select same gap area (acceptable redundancy)
- File conflicts resolved through unique naming scheme
- No attempt to lock or coordinate file access

**Filesystem Conflict Recovery**
```
if (file creation fails):
  wait_exponential_backoff()
  regenerate_filename_with_new_random()
  retry_atomic_write()
  max_retries = 3
```

## Eventual Consistency Duplication Prevention

### Snapshot-Based Analysis Planning

Workers operate on point-in-time snapshots to handle concurrent execution:

1. **Atomic Directory Scan**: Read all existing FW-ANALYSIS-*.md files at startup
2. **Suggestion Extraction**: Parse all suggestions and confirmation counts from snapshot
3. **Gap Identification**: Identify framework areas with zero or minimal coverage
4. **Focus Selection**: Choose specific unexplored area to minimize overlap with concurrent workers
5. **Stale-State Awareness**: Accept that snapshot may be outdated by write time

### Probabilistic Gap Distribution

Since workers can't coordinate directly, use randomized gap selection to distribute effort:

```
Worker Selection Algorithm:
1. Identify all framework components mentioned in existing analyses
2. List unmentioned components (zero coverage)
3. List under-analyzed components (single mentions)
4. Hash worker PID to select consistent gap focus area
5. Generate analysis for selected area only
```

### Autonomous Suggestion Tracking

Each worker includes suggestion status in their analysis based on their snapshot:

```
=== ANALYSIS METADATA ===
Snapshot Time: 2024-12-10 14:30:52
Files Analyzed: 3 existing artifacts
Total Suggestions Tracked: 12
Over-Confirmed (2+): 4 suggestions
Single-Confirmed: 5 suggestions  
Unexplored Areas: NavigationService, ContextCreation, TestUtilities

FOCUS AREA (Worker PID 45678): NavigationService Implementation
Rationale: Zero coverage in snapshot, high complexity component
```

### Convergence Through Redundancy

Accept controlled duplication to ensure comprehensive coverage:

- **2-3 Confirmations Acceptable**: Natural redundancy ensures thorough validation
- **Eventual Consistency**: Workers gradually cover all framework areas
- **Gap Convergence**: Remaining gaps shrink as more workers contribute
- **Self-Terminating**: Workers naturally exhaust unexplored areas

## Autonomous Worker Process Flow

```
1. Startup: Generate unique worker identifier (timestamp+PID+random)
2. Atomic Snapshot: Read all existing FW-ANALYSIS-*.md files in single operation
3. State Analysis: Parse suggestions, confirmations, and coverage gaps from snapshot
4. Gap Selection: Use PID-based hashing to select unexplored framework area
5. Analysis Generation: Create comprehensive analysis for selected gap area only
6. Atomic Write: Write complete analysis to temp file, rename atomically
7. Verification: Confirm successful file creation
8. Termination: Worker exits after single analysis (no continuous operation)
```

### Single-Shot Worker Model

Each worker executes once and terminates:
- **No Continuous Execution**: Workers don't run continuously
- **One Analysis Per Worker**: Each execution produces exactly one analysis file  
- **Independent Lifecycle**: Workers start and stop independently
- **Natural Load Distribution**: Multiple worker invocations gradually cover all areas

### Concurrent Execution Safety

```
Time: 14:30:52.123456
Worker A (PID 1234): Starts, reads snapshot, selects NavigationService
Worker B (PID 1235): Starts, reads snapshot, selects TestingUtils (different area)
Worker C (PID 1236): Starts, reads snapshot, selects NavigationService (same area)

Time: 14:30:58.789012  
Worker A: Writes FW-ANALYSIS-20241210-143052-123456-1234-567.md
Worker B: Writes FW-ANALYSIS-20241210-143052-678901-1235-234.md
Worker C: Writes FW-ANALYSIS-20241210-143052-789012-1236-891.md

Result: Two NavigationService analyses (acceptable redundancy)
        One TestingUtils analysis (unique coverage)
```

## Dynamic Gap Detection Strategy

Rather than following predefined exploration areas, workers identify unexplored gaps and framework deficiencies through systematic discovery:

### Gap Discovery Method

1. **Previous Analysis Review**
   - Scan all existing analysis artifacts
   - Extract covered areas and addressed suggestions
   - Identify framework sections with no analysis coverage
   - Map confirmed vs unconfirmed opportunities

2. **Framework Structure Scanning**
   - Identify components/modules with no analysis mentions
   - Find files/patterns not referenced in previous analyses
   - Discover architectural layers lacking examination
   - Locate API surfaces without improvement suggestions

3. **Confirmation Gap Detection**
   - Find suggestions with only 1 confirmation (need 2nd confirmation)
   - Identify conflicting assessments between analyses
   - Discover partially explored areas needing deeper analysis
   - Locate framework aspects with incomplete coverage

### Priority Framework Areas (Check if Unexplored)

**Structural Analysis**
- Component organization patterns
- API design consistency
- Test coverage gaps
- Documentation completeness
- Build system optimization
- Naming convention standardization

**Implementation Quality**
- Code duplication identification
- Complexity reduction opportunities
- Architectural pattern consistency
- Dead code removal possibilities
- Performance bottleneck discovery
- Memory usage optimization

**Developer Experience**
- Boilerplate reduction opportunities
- API friction point identification
- Testing complexity analysis
- Development workflow optimization
- Debugging capability assessment
- Learning curve evaluation

**Technical Excellence**
- Type safety enhancement opportunities
- Concurrency pattern improvement
- Error handling optimization
- State management simplification
- Integration capability assessment
- Extensibility design evaluation

### Unexplored Area Prioritization

1. **Coverage Gaps**: Framework areas with zero analysis mentions
2. **Shallow Coverage**: Areas mentioned but not deeply analyzed
3. **Conflicting Assessments**: Areas with disagreement between analyses
4. **Single Confirmations**: Suggestions needing second validation
5. **Missing Dimensions**: Standard analysis categories not yet applied to specific components

## Continuous Operation Model

### Multi-Worker Execution

Workers operate continuously until sufficient framework coverage achieved:

1. **Parallel Execution**: Multiple workers can analyze simultaneously
2. **Gap-Based Focus**: Each worker identifies different unexplored areas
3. **Duplication Avoidance**: 2-confirmation limit prevents over-analysis
4. **Convergence Detection**: Stop when no new significant gaps discovered

### Termination Criteria

Analysis continues until:
- **Coverage Threshold**: 90%+ of framework components analyzed
- **Suggestion Saturation**: No new improvement opportunities found
- **Confirmation Completion**: All viable suggestions have 2+ confirmations
- **External Signal**: Manual termination by operator

### Example Autonomous Worker Execution

```
=== WORKER INSTANCE 1 ===
Start Time: 2024-12-10 14:30:52.123456
Process ID: 45678
Target File: FW-ANALYSIS-20241210-143052-123456-45678-234.md

SNAPSHOT ANALYSIS (Time: 14:30:52.123456):
- Found 0 existing analysis artifacts
- No previous suggestions to track  
- All framework areas available for exploration

GAP SELECTION (PID Hash 45678 % 8 = 6):
Selected Area: Testing Infrastructure (index 6 of available areas)
Rationale: Zero coverage, critical framework component

ANALYSIS CONTENT:
# Testing Infrastructure Analysis
## Missing AsyncStream Test Utilities
- No built-in helpers for stream testing
- Manual Task/timeout management required  
- 3x development time for async tests
- Impact: HIGH - affects all async component testing

## Performance Benchmark Gaps  
- No memory profiling utilities
- No regression detection framework
- Manual benchmark setup required
- Impact: MEDIUM - affects performance validation

File Written: SUCCESS (347 lines)
Worker Status: TERMINATED

=== WORKER INSTANCE 2 ===  
Start Time: 2024-12-10 14:30:52.678901
Process ID: 45679
Target File: FW-ANALYSIS-20241210-143052-678901-45679-891.md

SNAPSHOT ANALYSIS (Time: 14:30:52.678901):
- Found 0 existing analysis artifacts (Worker 1 not yet written)
- No previous suggestions to track
- All framework areas available for exploration

GAP SELECTION (PID Hash 45679 % 8 = 7):
Selected Area: Navigation Architecture (index 7 of available areas)  
Rationale: Zero coverage, high-complexity component

ANALYSIS CONTENT:
# Navigation Architecture Analysis
## Route Type Safety Gaps
- String-based routing in 5 locations
- No compile-time route validation
- Runtime navigation errors possible
- Impact: HIGH - affects app stability

## Coordinator Pattern Inconsistencies
- Mixed navigation paradigms across screens
- No centralized route management
- Difficult to test navigation flows
- Impact: MEDIUM - affects maintainability

File Written: SUCCESS (423 lines)
Worker Status: TERMINATED

=== WORKER INSTANCE 3 ===
Start Time: 2024-12-10 14:30:58.234567  
Process ID: 45680
Target File: FW-ANALYSIS-20241210-143058-234567-45680-567.md

SNAPSHOT ANALYSIS (Time: 14:30:58.234567):
- Found 2 existing analysis artifacts
- Suggestions tracked: AsyncStream utilities, Performance benchmarks, Route safety
- Over-confirmed: None (all suggestions have 1 confirmation)

GAP SELECTION (PID Hash 45680 % 6 = 2):
Selected Area: Context Creation Patterns (index 2 of remaining areas)
Rationale: Zero coverage, affects developer productivity

ANALYSIS CONTENT:  
# Context Creation Analysis
## Boilerplate Reduction Opportunities
- 20+ lines minimum for functional context
- Repetitive initialization patterns
- No macro assistance for common patterns  
- Impact: HIGH - affects every new screen

## State Ownership Complexity
- Manual ownership validation required
- Error-prone setup for new developers
- No compile-time assistance
- Impact: MEDIUM - affects code correctness

File Written: SUCCESS (389 lines)
Worker Status: TERMINATED

=== AGGREGATED RESULTS ===
Total Workers: 3
Files Created: 3  
Unique Areas Analyzed: 3
Overlapping Areas: 0
Framework Coverage: ~37% (3 of 8 major areas)
Remaining Gaps: State Management, Dependency Injection, Build System, Documentation, Error Handling
```

## Analysis Methodology

### Framework Exploration Process

The protocol systematically explores the framework codebase:

1. **Directory Structure Analysis**
   - Map component organization
   - Identify architectural layers
   - Find patterns in file organization
   - Detect inconsistencies or gaps

2. **API Surface Analysis**
   - Catalog all public interfaces
   - Measure API complexity
   - Identify missing functionality
   - Find redundant or confusing APIs

3. **Pattern Detection**
   - Recognize architectural patterns used
   - Find anti-patterns or code smells
   - Identify opportunities for abstraction
   - Detect repeated boilerplate

### Refactoring Analysis

The protocol identifies refactoring opportunities:

1. **Code Duplication Detection**
   - Find repeated patterns across components
   - Identify copy-paste code blocks
   - Detect similar implementations
   - Calculate potential line reduction

2. **Complexity Assessment**
   - Measure cyclomatic complexity
   - Find overly nested structures
   - Identify god objects/methods
   - Detect tight coupling

3. **Consistency Analysis**
   - Compare API patterns across modules
   - Find naming inconsistencies
   - Detect mixed paradigms
   - Identify style violations
   - Analyze language variations (enhanced/comprehensive/simplified)
   - Check file naming conventions
   - Identify terminology conflicts
   - Catalog naming pattern variations:
     * Method names (doSomething vs performSomething vs executeSomething)
     * Type names (Manager vs Controller vs Handler)
     * File names (ComponentName.swift vs component_name.swift)
     * Module names (FeatureModule vs Feature vs FeatureKit)

4. **MVP Refactoring Freedom**
   - Remove dead code without concern
   - Redesign APIs without compatibility
   - Extract new abstractions freely
   - Consolidate duplicated logic aggressively
   - Standardize all naming conventions
   - Unify terminology across codebase

5. **Dead Code Detection**
   - Find unused public APIs through static analysis
   - Identify deprecated patterns that can be removed
   - Locate test-only code in production modules
   - Calculate total lines removable
   - Prioritize removal by impact and risk

### Developer Experience Assessment

The protocol evaluates developer experience by:

1. **Common Task Analysis**
   - How many lines to accomplish basic tasks
   - Amount of boilerplate required
   - Clarity of API usage patterns
   - Error-prone areas

2. **Learning Curve Evaluation**
   - API discoverability
   - Consistency of patterns
   - Quality of error messages
   - Debugging support

3. **Productivity Metrics**
   - Time to implement features
   - Code reusability
   - Test writing complexity
   - Refactoring difficulty

### Architectural Comparison Framework

The protocol identifies specific technical advantages through careful analysis:

#### Improving on SwiftUI
- UI updates: More efficient update mechanisms
- State management: Unified approach for clarity
- View composition: Clear component hierarchy
- Performance: Optimized for common operations
- Testing: Built-in test utilities vs external tools
- Type safety: Compile-time vs runtime validation

#### Streamlining Async Operations
- Async handling: Native Swift concurrency patterns
- Data flow: Direct, understandable connections
- Error handling: Clear and predictable patterns
- Resource management: Automatic lifecycle handling
- Thread safety: Actor isolation guarantees
- Performance: No publisher overhead

#### Reducing Architectural Complexity
- State management: Direct updates where appropriate
- Side effects: Standard Swift patterns
- Testing: Pragmatic test coverage
- Modularity: Natural feature boundaries
- Developer tools: Integrated debugging
- Code generation: Swift macros vs external tools

#### Simplifying Module Architecture
- Module structure: Appropriate layering for the problem
- Navigation: Clear coordinator patterns
- Dependencies: Simple, testable injection
- Complexity: Reduced code while maintaining benefits
- Extensibility: Capability protocol design
- Evolution: Clean architectural decisions

### Testing Excellence Analysis

The protocol evaluates testing capabilities:

1. **Test Infrastructure Assessment**
   - Available test utilities and helpers
   - Performance benchmarking tools
   - Memory and leak detection
   - Async testing support
   - Mock generation capabilities

2. **Testing Excellence**
   - Already comprehensive utilities
   - Performance benchmarking included
   - Could add more test patterns
   - Coverage already strong

### Type & Thread Safety Analysis

The protocol examines safety guarantees:

1. **Type Safety Features**
   - Compile-time validation opportunities
   - Type-safe API design
   - Error handling structure
   - Advanced type system usage

2. **Concurrency Safety**
   - Actor isolation benefits
   - Structured concurrency patterns
   - Data race prevention
   - Performance characteristics

### Developer Experience Metrics

The protocol measures productivity:

1. **Code Metrics**
   - Lines of code for common tasks
   - Boilerplate requirements
   - API discoverability
   - Learning curve assessment

2. **Tool Support**
   - Debugging capabilities
   - Code generation tools
   - Documentation quality
   - Integration templates

### Ecosystem Evaluation

The protocol assesses extensibility:

1. **Extension Design**
   - Capability protocol pattern
   - Clean boundaries
   - Protocol-based approach
   - No external dependencies

2. **Framework Evolution**
   - Clear architecture
   - Easy to extend
   - Well-defined patterns
   - Stable core APIs

## Integration Points

### Inputs

The generate command requires:
1. **Framework Directory**: Complete framework codebase to analyze (also serves as output location)
2. **Analysis Template**: Structure for documenting findings

### Outputs

The generate command produces:
- **Analysis Files**: FW-ANALYSIS-YYYYMMDD-HHMMSS-XXX.md series in framework directory
- **Size Management**: Maximum 1000 lines per artifact, new files created as needed
- **Gap-Focused Content**: Analysis targeting unexplored framework areas with:
  - Newly discovered improvement opportunities
  - Confirmation of previous suggestions (up to 2 confirmations)
  - Specific focus on unaddressed framework gaps
  - Avoidance of over-confirmed suggestions

## Unique Analysis Identification System

### Timestamp-Based ID Generation
The protocol automatically:
1. Generates timestamp-based unique identifier (YYYYMMDD-HHMMSS)
2. Ensures no conflicts with existing framework analyses
3. Creates analysis with guaranteed unique identifier
4. Enables chronological ordering of analyses

### Naming Convention
```
FW-ANALYSIS-YYYYMMDD-HHMMSS-ssssss-PID-RND.md
```
- FW-ANALYSIS: Framework analysis prefix
- YYYYMMDD-HHMMSS: Timestamp-based unique identifier
- ssssss: Microseconds for sub-second uniqueness
- PID: Process ID for same-machine collision prevention
- RND: 3-digit random number for edge case protection
- Example: FW-ANALYSIS-20241210-143052-789123-45678-234.md

### Benefits
- **Collision-Free**: Timestamps ensure uniqueness across time
- **Multi-Worker Safe**: Multiple workers coordinate through shared artifacts
- **Size Managed**: 1000-line limit prevents unwieldy documents
- **Duplication Prevention**: 2-confirmation limit avoids redundant analysis
- **Automated**: No manual coordination required between workers
- **Continuous**: Analysis continues until comprehensive coverage achieved

### Workflow Integration

Autonomous worker analysis feeds into requirements generation:
1. Independent workers execute periodically, each creating one analysis artifact
2. Each worker analyzes different framework gaps based on PID-hash selection
3. Requirements protocol processes all accumulated analysis artifacts
4. Development protocol implements suggestions with multiple confirmations  
5. New worker executions gradually fill remaining coverage gaps

### Coverage Completion Strategy

Since workers don't coordinate directly:
- **Periodic Execution**: Run workers periodically until no new gaps discovered
- **Convergence Detection**: Monitor for workers producing minimal new insights
- **Manual Termination**: Stop when sufficient framework coverage achieved
- **Natural Exhaustion**: Workers eventually cover all significant framework areas

### File Location
The generated analysis artifacts are placed directly in the framework directory alongside the codebase being analyzed. This ensures:
- All analysis artifacts stay with the framework they document
- Easy access for requirements generation across multiple files
- Version control tracking of analysis evolution
- Clear association between analysis series and codebase state
- Coordinated multi-worker access to shared artifact location

## Dynamic Gap Categories

Workers identify gaps dynamically by scanning for unexplored areas across these potential dimensions:

### Detection-Based Gap Discovery

Rather than following predefined exploration lists, workers:

1. **Scan Framework Structure** for components/files not mentioned in previous analyses
2. **Identify Unconfirmed Suggestions** requiring second validation
3. **Find Coverage Gaps** in standard analysis dimensions
4. **Detect New Problem Areas** not yet addressed by any worker

### Common Gap Patterns (Check if Unexplored)

**Implementation Quality Issues**
- Code duplication patterns not yet identified
- Complexity hotspots not yet analyzed
- Inconsistency areas not yet catalogued
- Dead code sections not yet discovered

**Developer Productivity Blockers**
- Boilerplate creation steps not yet measured
- Development workflow friction not yet documented
- Testing complexity areas not yet explored
- API usability gaps not yet identified

**Technical Debt Areas**
- Performance bottlenecks not yet profiled
- Memory usage patterns not yet analyzed
- Concurrency issues not yet discovered
- Type safety gaps not yet catalogued

**Framework Completeness Gaps**
- Missing utility functions not yet identified
- API surface inconsistencies not yet documented
- Platform feature gaps not yet explored
- Integration difficulties not yet analyzed

### Gap Prioritization Strategy

1. **Unmentioned Components**: Framework areas with zero analysis coverage
2. **Single-Confirmation Items**: Suggestions needing validation
3. **Shallow Analysis**: Areas mentioned but lacking depth
4. **New Discovery Opportunities**: Framework aspects not yet explored by any dimension

### Dynamic Exploration Instructions

Workers must:
- **Avoid Over-Explored Areas**: Skip suggestions with 2+ confirmations
- **Seek Fresh Perspectives**: Find framework aspects not yet analyzed
- **Validate Previous Findings**: Confirm or refute single-confirmation suggestions
- **Discover New Issues**: Identify problems not yet recognized by other workers

## Improvement Opportunity Framework

### Quick Wins
- Eliminate repetitive code patterns
- Modernize async operations
- Simplify state management
- Remove unnecessary complexity

### Strategic Improvements
- Architecture that solves real problems
- Patterns that meaningfully reduce complexity
- Thoughtful abstractions where beneficial
- APIs designed for stability and evolution

### Long-term Excellence
- Refined architecture using best practices
- Advanced capabilities through careful design
- Holistic solutions to framework challenges
- Continuous performance improvements

## Best Practices

### Autonomous Worker Operations

1. **Atomic File Operations**
   - Generate collision-resistant filenames with PID+timestamp+random
   - Use atomic write operations (temp file + rename) 
   - Verify successful file creation before termination
   - Handle filesystem conflicts with retry logic

2. **Snapshot-Based Analysis**
   - Read all existing analyses at startup (atomic snapshot)
   - Accept that snapshot may be stale by write time
   - Focus analysis on gaps identified in snapshot
   - Don't attempt to coordinate with concurrent workers

3. **Deterministic Gap Selection**
   - Use PID-based hashing for consistent area selection
   - Avoid random selection that could cause clustering
   - Select single framework area per worker execution
   - Document gap selection rationale clearly

### Analysis Quality

4. **Evidence-Based Discovery**
   - Support gap identification with concrete examples
   - Measure impact of discovered issues quantitatively
   - Provide specific, actionable improvement suggestions
   - Document analysis methodology and assumptions

5. **Single-Focus Depth**
   - Analyze selected framework area comprehensively
   - Avoid breadth-first exploration across multiple areas
   - Provide detailed analysis within 1000-line limit
   - Include specific code locations and examples

6. **Termination Discipline**
   - Execute once and terminate cleanly
   - Don't attempt continuous operation or monitoring
   - Create exactly one analysis file per execution
   - Exit gracefully after successful file creation

### Ecosystem Integration

7. **Version Control Awareness**
   - Place analysis files in framework directory for VCS tracking
   - Use descriptive commit messages when analysis files added
   - Consider analysis artifacts as documentation that evolves with code
   - Enable requirements generation to process all accumulated analyses