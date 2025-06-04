# @PLAN.md

**Trigger**: `@PLAN [command] [args]`

## Commands

- `status` → Show RFC status across all directories
- `create [title]` → New RFC in Draft/
- `propose [RFC-XXX]` → Move to Proposed/
- `activate [RFC-XXX]` → Move to Active/  
- `deprecate [RFC-XXX] [RFC-YYY]` → Replace with new
- `revise [RFC-XXX]` → Fix unstable requirements
- `explore [RFC-XXX]` → Suggest changes (requires STABLE)
- `accept [RFC-XXX] [selections]` → Apply suggestions
- `ready [RFC-XXX]` → Verify ready for development

## Core Process

Draft/ → Proposed/ → Active/ → Deprecated/ → Archive/

**Philosophy**: Stabilization before expansion.
**Constraint**: Minimum 3-5 stable requirements before propose.

## Workflow

### Stabilization Process
1. `revise` → Get fixes for unstable requirements
2. `accept` → Apply selected fixes
3. Repeat until RFC marked STABLE
4. `ready` → Final verification
5. `propose` → Move to implementation

### Enhancement Process (Optional)
1. `explore` → Get enhancement suggestions (requires STABLE)
2. `accept` → Apply selected changes
3. `revise` → Verify stability maintained

## Technical Details

**Revise Command**:
- Provides numbered fixes [R1], [R2]...
- Technical impossibilities → achievable versions
- Missing acceptance criteria → complete criteria
- Untestable specs → testable versions

**Explore Command**:
- Provides numbered changes [E1], [E2]...
- Removals → requirements to delete
- Simplifications → consolidated versions
- Additions → new requirements with criteria

**Accept Command**:
- `accept RFC-001 R1,R3` → Apply specific revisions
- `accept RFC-001 E2,E4-6` → Apply explorations
- `accept RFC-001 all-revisions` → Apply all

## Known Impossibilities

- Synchronous actor calls (always async)
- Zero-latency operations (minimum overhead)
- UI updates from background (main thread only)
- Runtime generic resolution (compile-time only)
- Mutable shared state without sync (memory unsafe)
- Synchronous cross-actor access (async required)

## Examples

**Create and Stabilize**:
```
@PLAN create awesome-feature
@PLAN revise RFC-001
# Shows: [R1] "Zero-latency" → "<2ms propagation"
@PLAN accept RFC-001 R1
@PLAN ready RFC-001
@PLAN propose RFC-001
```

**Explore Enhancements**:
```
@PLAN explore RFC-001
# Shows: [E1] REMOVE: Custom serialization (-500 LOC)
#        [E2] ADD: Batch updates (70% fewer calls)
@PLAN accept RFC-001 E2
```

Format: [RFC_FORMAT.md](./RFC_FORMAT.md)

Manages RFC lifecycle with requirement stabilization and scope control.