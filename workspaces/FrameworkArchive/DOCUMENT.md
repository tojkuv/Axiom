# DOCUMENT.md

Protocol for generating comprehensive framework architectural documentation.

## Trigger Pattern
```text
@framework-document
```

## Commands

### Generate Framework Documentation
```text
generate → Create comprehensive framework documentation
  - Scans: Entire framework codebase at /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-framework/AxiomFramework
  - Output: /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-meta-workspace/workspaces/FrameworkWorkspace/CYCLE-XXX/DOCUMENTATION-XXX.md
  - Rule: One documentation artifact per framework cycle
```

## Core Process

### Documentation Philosophy
The Framework DOCUMENT protocol creates comprehensive architectural documentation by scanning the entire framework codebase. This documentation serves as the authoritative reference for the current state of the framework architecture, APIs, and implementation patterns.

### Documentation Flow
1. **Initiation**: Generate command triggers comprehensive scan
2. **Analysis**: Extract architecture, components, APIs, and patterns
3. **Synthesis**: Organize findings into structured documentation
4. **Output**: Single authoritative document per cycle

### Workflow Rule
- **One Document Per Cycle**: Each framework development cycle produces exactly one documentation artifact
- **Comprehensive Coverage**: Documentation includes all framework components, APIs, and architectural decisions
- **Architecture Focus**: Primary emphasis on architectural patterns and design decisions

## Format Specifications

### Framework Documentation Format
```text
# Framework Documentation

## Metadata
- Generation Timestamp: [ISO 8601 timestamp]
- Documentation Version: [Version identifier]
- Status: [Draft/Review/Published]
- Technology Versions: [Runtime and dependency versions]
- Platform Targets: [Supported platforms]
- Cycle Reference: CYCLE-XXX-[TITLE]
- Previous Documentation: [Link to previous cycle's documentation]

## Overview
- Executive summary of framework capabilities
- Architecture overview with core design principles
- Core design principles and philosophy
- Technology stack summary
- Key capabilities and feature highlights

## Requirements
### Technology Requirements
- Runtime requirements (iOS/macOS versions)
- Development environment specifications
- Build tool requirements
- Dependency specifications

### Platform Requirements
- Minimum OS versions
- Hardware requirements
- Platform-specific considerations

### Development Environment
- IDE requirements and recommendations
- Build system configuration
- Testing environment setup
- Debugging tool requirements

### Dependencies
- Core framework dependencies
- Optional dependencies
- Version constraints
- Dependency management approach

## Architecture

### Core Architecture
- Architectural principles and patterns
- Component hierarchy diagram
- Layer responsibilities and boundaries
- Communication patterns between layers
- Data flow architecture
- Error handling architecture

### Component Specifications
For each core component:
- Component name and purpose
- Responsibilities and scope
- Public interface specification
- Internal architecture
- Dependencies (internal and external)
- Threading model and concurrency
- Lifecycle management
- Error handling approach
- Performance characteristics

### Data Flow Patterns
- State flow documentation with diagrams
- Action flow documentation
- Event propagation patterns
- Data transformation pipelines
- Error propagation patterns
- Timing requirements and constraints
- Backpressure handling

### Concurrency Model
- Threading architecture overview
- Actor isolation boundaries
- Task and async/await patterns
- Synchronization patterns
- Race condition prevention
- Deadlock avoidance strategies
- Performance considerations

## API Reference

### Public APIs
For each public API:
- Interface definition with full signatures
- Method signatures with generics
- Parameter specifications with constraints
- Return value specifications
- Thrown error specifications
- Preconditions and postconditions
- Thread safety guarantees
- Usage examples with best practices
- Performance characteristics
- Migration notes from previous versions

### Integration Points
- External service interfaces
- Extension points and protocols
- Plugin architecture
- Configuration APIs
- Notification interfaces
- Delegate patterns
- Closure-based APIs
- Combine publishers

## Implementation

### Implementation Guidelines
- Coding standards and conventions
- Architecture patterns to follow
- Best practices for common scenarios
- Anti-patterns to avoid
- Performance optimization techniques
- Memory management guidelines
- Error handling patterns
- Testing patterns

### Performance Considerations
- Performance requirements and benchmarks
- Optimization strategies by component
- Profiling guidelines and tools
- Resource management patterns
- Memory footprint optimization
- Battery usage considerations
- Network efficiency patterns

### Testing Strategy
- Test architecture overview
- Unit testing patterns
- Integration testing approach
- UI testing strategies
- Performance testing methodology
- Coverage requirements
- Continuous integration setup
- Test data management

## Appendices

### Migration Guide
- Breaking changes from previous versions
- Migration strategies and tools
- Compatibility notes
- Deprecation timeline
- Code transformation examples

### Glossary
- Framework-specific term definitions
- Acronym expansions
- Concept explanations

### References
- Related specifications
- External dependency documentation
- Design pattern references
- Further reading recommendations
```

## Workflow

### Generate Command Workflow

1. **Validate Cycle Context**
   - Verify active cycle folder exists
   - Check for existing documentation in cycle
   - Confirm no documentation exists (one per cycle rule)

2. **Scan Framework Codebase**
   - Traverse /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-framework/AxiomFramework
   - Identify all Swift files
   - Extract architectural components
   - Analyze API surfaces
   - Document patterns and conventions

3. **Extract Architecture Information**
   - Component hierarchy and relationships
   - Protocol definitions and conformances
   - Public API signatures
   - Internal architecture patterns
   - Concurrency model implementation
   - Error handling strategies

4. **Generate Documentation**
   - Create structured documentation following format
   - Include code examples from actual implementation
   - Generate architecture diagrams where applicable
   - Cross-reference related components
   - Include migration information if previous cycle exists

5. **Output Documentation**
   - Save to /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-meta-workspace/workspaces/FrameworkWorkspace/CYCLE-XXX/DOCUMENTATION-XXX.md
   - Verify documentation completeness
   - Ensure all sections populated
   - Validate cross-references

### Documentation Generation Rules

1. **Comprehensive Scanning**
   - Include all source files in framework
   - Document both public and internal architecture
   - Capture implementation patterns
   - Extract inline documentation

2. **Architecture Focus**
   - Emphasize architectural decisions
   - Document design patterns used
   - Explain component relationships
   - Highlight extension points

3. **API Completeness**
   - Document every public API
   - Include usage examples
   - Specify thread safety
   - Note performance characteristics

4. **Practical Examples**
   - Extract real code examples
   - Show common usage patterns
   - Demonstrate best practices
   - Include anti-pattern warnings

## Technical Details

### Path Specifications
- **Framework Codebase**: `/Users/tojkuv/Documents/GitHub/axiom-apple/workspace-framework/AxiomFramework`
- **Output Location**: `/Users/tojkuv/Documents/GitHub/axiom-apple/workspace-meta-workspace/workspaces/FrameworkWorkspace/CYCLE-XXX/DOCUMENTATION-XXX.md`
- **Cycle Folder Pattern**: `CYCLE-XXX-[TITLE]`
- **Documentation Name Pattern**: `DOCUMENTATION-XXX.md`

### Validation Requirements

#### Pre-Generation Validation
- Active cycle folder exists
- No existing documentation in cycle
- Framework codebase accessible
- Previous cycle documentation available (if not first cycle)

#### Post-Generation Validation
- All documentation sections populated
- Code examples compile
- Cross-references valid
- Architecture diagrams accurate
- API coverage complete

### Persistence Requirements
- Documentation stored in cycle folder
- Maintains reference to previous documentation
- Preserves generation metadata
- Supports version comparison

### Content Extraction Rules
- Public APIs: Full documentation required
- Internal APIs: Architecture-relevant only
- Code Examples: Simplified for clarity
- Performance Data: Include benchmarks where available
- Migration Info: Changes from previous cycle

## Error Handling

### Error Types and Recovery

#### Documentation Already Exists
- **Error**: Documentation already exists for current cycle
- **Recovery**: Use existing documentation or start new cycle
- **Prevention**: Check before generation

#### Codebase Inaccessible
- **Error**: Cannot access framework codebase directory
- **Recovery**: Verify path and permissions
- **Prevention**: Validate paths at protocol start

#### Incomplete Analysis
- **Error**: Failed to analyze certain components
- **Recovery**: Document accessible components, note failures
- **Prevention**: Robust error handling during scan

#### Invalid Cycle Structure
- **Error**: Cycle folder structure incorrect
- **Recovery**: Create proper structure or select valid cycle
- **Prevention**: Validate cycle before generation

### Error Messages
- Clear indication of error type
- Actionable recovery steps
- Reference to documentation requirements
- Path to seek assistance

### Validation Failures
- List all validation failures
- Provide specific correction steps
- Allow partial documentation with warnings
- Maintain documentation integrity