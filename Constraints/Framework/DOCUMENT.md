# @DOCUMENT.md

**Trigger**: `@DOCUMENT [command] [args]`

## Commands

- `generate` → Create comprehensive framework documentation
- `update [sections]` → Update specific documentation sections
- `validate` → Check documentation completeness and accuracy
- `preview` → Show documentation structure without generating
- `status` → Display current documentation state

## Core Process

Analyze framework → Extract patterns → Generate documentation → Validate completeness

**Philosophy**: Living documentation that reflects actual framework implementation.
**Constraint**: Documentation must match codebase reality, not aspirations.

## Workflow

### Initial Documentation Generation
1. `@DOCUMENT preview` → Review planned structure
2. `@DOCUMENT generate` → Create full documentation
3. `@DOCUMENT validate` → Ensure completeness

### Documentation Updates
1. `@DOCUMENT status` → Check what needs updating
2. `@DOCUMENT update [sections]` → Update specific parts
3. `@DOCUMENT validate` → Verify consistency

### Section-Specific Updates
- `@DOCUMENT update components` → Update component specifications
- `@DOCUMENT update patterns` → Refresh implementation patterns
- `@DOCUMENT update performance` → Update performance metrics
- `@DOCUMENT update testing` → Refresh testing guidelines

## Technical Details

**Output Location**:
```
/Users/tojkuv/Documents/GitHub/axiom-apple/workspace-framework/AxiomFramework/Documentation/
├── AXIOM_FRAMEWORK.md (main documentation)
└── [version backup files]
```

**Documentation Sections** (from DOCUMENTATION_FORMAT):
1. Metadata Header
2. Architecture Overview
3. Component Specifications
4. Data Flow Patterns
5. Common Implementation Patterns
6. Testing Guidelines
7. Performance Considerations
8. Migration & Evolution

**Analysis Sources**:
- Framework source code in `workspace-framework/AxiomFramework/`
- Protocol definitions in `Protocols/`
- Test implementations for patterns
- Performance benchmarks if available

**Validation Checks**:
- All components have specifications
- Code examples compile
- Anti-patterns are documented
- Performance metrics are current
- Version information matches

## Generation Process

### Framework Analysis
```bash
# Scan for Client implementations
find . -name "*.swift" -exec grep -l "actor.*:.*Client" {} \;

# Identify State types
find . -name "*.swift" -exec grep -l "struct.*:.*State" {} \;

# Locate Context classes
find . -name "*.swift" -exec grep -l "@MainActor.*class.*:.*Context" {} \;
```

### Pattern Extraction
1. Analyze component relationships
2. Extract common implementation patterns
3. Identify anti-patterns from code review
4. Document performance characteristics
5. Capture testing approaches

### Documentation Assembly
1. Generate metadata with current version
2. Build architecture overview from component scan
3. Create detailed specifications per component
4. Document discovered patterns with examples
5. Include performance benchmarks
6. Add migration notes for version changes

## Examples

**First-Time Documentation**:
```
@DOCUMENT preview
# Review planned structure
@DOCUMENT generate
# Creates AXIOM_FRAMEWORK.md
@DOCUMENT validate
# Ensures all sections complete
```

**After Framework Changes**:
```
@DOCUMENT status
# Shows: "Components section outdated"
@DOCUMENT update components
# Regenerates component specifications
@DOCUMENT validate
# Confirms documentation accuracy
```

**Major Version Update**:
```
@DOCUMENT update migration
# Updates version compatibility
@DOCUMENT update patterns
# Refreshes implementation examples
@DOCUMENT generate --version=2.0
# Full regeneration with version tag
```

**Validation Only**:
```
@DOCUMENT validate --strict
# Checks:
# - All code examples compile
# - No missing components
# - Version numbers consistent
# - Anti-patterns documented
```

## Error Handling

**Common Issues**:
- "Framework not found" → Check workspace-framework path
- "Invalid format" → Ensure DOCUMENTATION_FORMAT.md exists
- "Compilation errors" → Code examples need updating
- "Missing components" → New components need documentation

**Recovery Procedures**:
1. Missing framework → Verify path configuration
2. Outdated examples → Run update with --fix-examples
3. Incomplete sections → Generate with --fill-missing

## Dependencies

**Required Files**:
- `/Protocols/FrameworkProtocols/DOCUMENTATION_FORMAT.md`
- Framework source in `workspace-framework/`
- Write access to Documentation directory

**Optional Enhancements**:
- Test coverage reports for metrics
- Performance benchmark results
- Version control history for migration

Generates and maintains comprehensive framework documentation aligned with implementation reality.