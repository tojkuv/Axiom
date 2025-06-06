# @ANALYZE.md

**Trigger**: `@ANALYZE [command] [args]`

## Commands

- `scan [path]` → Quick architecture overview and compliance check
- `deep [path]` → Comprehensive analysis with all metrics
- `axiom [path]` → Focus on Axiom pattern compliance only
- `performance [path]` → Runtime characteristics and bottlenecks
- `quality [path]` → Code quality metrics and test coverage
- `report [ANLS-XXX]` → View previously generated analysis
- `compare [ANLS-XXX] [ANLS-YYY]` → Compare two analysis reports

## Core Process

Scan → Measure → Validate → Report

**Philosophy**: Objective measurement of Axiom pattern compliance and application health.
**Constraint**: Analysis is read-only - never modifies source code.

## Workflow

### Analysis Types

**Quick Scan** (Default):
1. Component inventory
2. Basic compliance check
3. High-level metrics
4. Executive summary
5. ~30 second execution

**Deep Analysis**:
1. Full component mapping
2. Detailed metrics
3. Performance profiling
4. Test assessment
5. Migration recommendations
6. ~5 minute execution

**Focused Analysis**:
- `axiom`: Pattern compliance only
- `performance`: Runtime metrics only  
- `quality`: Code metrics only

### Report Generation
1. Execute analysis command
2. Generate ANLS-XXX identifier
3. Create report following ANALYSIS_FORMAT.md
4. Store in /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-application/AxiomApplicationTests/Reports/
5. Display summary with path to full report

## Technical Details

**Execution Context**:
- Runs in any directory containing Swift code
- Detects Axiom framework usage automatically
- Works with both application and framework codebases

**Analysis Techniques**:
- Static analysis of Swift files
- Dependency graph construction
- Test coverage measurement
- Memory profiling simulation
- Pattern matching for Axiom components

**Component Detection**:
- Actors implementing Client protocol → Clients
- Structs conforming to State protocol → States
- @MainActor classes with Context suffix → Contexts
- Types conforming to Capability protocol → Capabilities
- SwiftUI Views → Presentations

**Metrics Collection**:
- Lines of Code (LOC) via file parsing
- Test coverage via `swift test --enable-code-coverage`
- Complexity via AST analysis
- Dependencies via `swift package show-dependencies`

## Execution Process

```bash
# ANALYZE can run from any location
ANALYSIS_PATH="${1:-$(pwd)}"

# Verify Swift project
if [[ ! -f "$ANALYSIS_PATH/Package.swift" ]]; then
    echo "Error: No Package.swift found at $ANALYSIS_PATH"
    exit 1
fi

# Detect Axiom framework
if grep -q "Axiom" "$ANALYSIS_PATH/Package.swift"; then
    echo "Axiom framework detected"
    FRAMEWORK_MODE="axiom"
else
    echo "Standard Swift project"
    FRAMEWORK_MODE="standard"
fi

# Create analysis directory
WORKSPACE_ROOT="/Users/tojkuv/Documents/GitHub/axiom-apple/workspace-application"
REPORTS_DIR="$WORKSPACE_ROOT/AxiomApplicationTests/Reports"
mkdir -p "$REPORTS_DIR"

# Generate analysis ID
ANALYSIS_ID="ANLS-$(date +%Y%m%d-%H%M%S)"
REPORT_PATH="$REPORTS_DIR/$ANALYSIS_ID.md"

echo "Starting analysis: $ANALYSIS_ID"
echo "Report will be generated at: $REPORT_PATH"
```

## Pattern Recognition

**Client Detection**:
```swift
// Matches: actor MyClient: Client {
grep -n "actor.*:.*Client" --include="*.swift"
```

**State Detection**:
```swift
// Matches: struct MyState: State, Equatable {
grep -n "struct.*:.*State.*Equatable" --include="*.swift"
```

**Context Detection**:
```swift
// Matches: @MainActor class MyContext: Context {
grep -n "@MainActor.*class.*Context" --include="*.swift"
```

## Error Handling

**Common Issues**:
- "No Swift files found" → Verify correct directory
- "Cannot determine architecture" → May not be using Axiom
- "Test coverage unavailable" → Run tests with coverage first

**Recovery**:
- Use explicit path: `@ANALYZE scan /full/path/to/app`
- Run focused analysis: `@ANALYZE quality .`
- Check previous reports: `@ANALYZE report ANLS-XXX`

## Examples

**Quick Scan**:
```
@ANALYZE scan .
# Scans current directory
# Generates overview in ~30 seconds
# Output: /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-application/AxiomApplicationTests/Reports/ANLS-20240106-143022.md
```

**Deep Analysis**:
```
@ANALYZE deep ~/MyApp
# Comprehensive analysis of MyApp
# All metrics and recommendations
# Output: /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-application/AxiomApplicationTests/Reports/ANLS-20240106-143500.md
```

**Axiom Compliance Check**:
```
@ANALYZE axiom .
# Focus only on Axiom patterns
# Lists all violations with fixes
# Output: /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-application/AxiomApplicationTests/Reports/ANLS-20240106-144000.md
```

**Compare Reports**:
```
@ANALYZE compare ANLS-20240106-143022 ANLS-20240106-144000
# Shows what changed between analyses
# Tracks improvement or regression
```

Analyzes application codebases for Axiom framework compliance and generates detailed reports.