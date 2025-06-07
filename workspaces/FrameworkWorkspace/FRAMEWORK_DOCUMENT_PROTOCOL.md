# Framework DOCUMENT Protocol

## Protocol: @framework-document

## Commands

### Primary Command
```text
generate → Create comprehensive framework documentation
  - Scans: Entire framework codebase at /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-framework/AxiomFramework
  - Output: /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-meta-workspace/workspaces/FrameworkWorkspace/CYCLE-XXX/DOCUMENTATION-XXX.md
  - Rule: One documentation artifact per framework cycle
```

## Core Process

### Linear Documentation Flow
The Framework DOCUMENT protocol follows a deterministic documentation generation process that creates a single, comprehensive architectural specification per framework development cycle.

### Philosophy
- **Comprehensive Scanning**: Analyzes the entire framework codebase to ensure complete documentation
- **Cycle-Aligned**: Each documentation artifact corresponds to exactly one framework development cycle
- **Architecture-Focused**: Captures design decisions, patterns, and implementation details
- **Version-Tracked**: Links to specific framework implementation state

### Workflow Rule
One documentation artifact per framework cycle - enforced through cycle folder structure and naming conventions.

## Format Specifications

### Documentation Format Template
```text
# Framework Documentation

{{METADATA_SECTION}}
- Generation timestamp
- Documentation version
- Status indicator
- Technology versions
- Platform targets
- Cycle reference
- Previous documentation reference

{{OVERVIEW_SECTION}}
- Executive summary
- Architecture overview
- Core design principles
- Technology stack summary
- Key capabilities

{{REQUIREMENTS_SECTION}}
- Technology requirements
- Platform requirements
- Development environment
- Dependencies

{{ARCHITECTURE_SECTIONS}}

### Core Architecture
- Architectural principles
- Component hierarchy diagram
- Layer responsibilities
- Communication patterns

### Component Specifications
For each core component:
- Component name and purpose
- Responsibilities
- Interface specification
- Dependencies
- Threading model
- Lifecycle management

### Data Flow Patterns
- State flow documentation
- Action flow documentation
- Error propagation patterns
- Timing requirements

### Concurrency Model
- Threading architecture
- Isolation boundaries
- Synchronization patterns
- Async operation handling

{{API_REFERENCE_SECTIONS}}

### Public APIs
For each public API:
- Interface definition
- Method signatures
- Parameter specifications
- Return value specifications
- Error conditions
- Usage examples

### Integration Points
- External service interfaces
- Extension points
- Plugin architecture
- Configuration APIs

{{IMPLEMENTATION_SECTIONS}}

### Implementation Guidelines
- Coding standards
- Architecture patterns
- Best practices
- Anti-patterns to avoid

### Performance Considerations
- Performance requirements
- Optimization strategies
- Profiling guidelines
- Resource management

### Testing Strategy
- Test architecture
- Test patterns
- Coverage requirements
- Integration test approach

{{APPENDICES}}

### Migration Guide
- Breaking changes
- Migration strategies
- Compatibility notes

### Glossary
- Term definitions
- Acronym expansions

### References
- Related specifications
- External dependencies
- Further reading
```

## Workflow Procedures

### 1. Generate Command Workflow
```text
WHEN: User executes "generate" command
THEN:
  1. Locate current framework cycle folder
  2. Verify no existing DOCUMENTATION-XXX.md in cycle
  3. Scan entire framework codebase at:
     /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-framework/AxiomFramework
  4. Analyze code structure and patterns
  5. Extract architectural decisions
  6. Document component hierarchies
  7. Capture API specifications
  8. Generate comprehensive documentation
  9. Save to cycle folder as DOCUMENTATION-XXX.md
```

### 2. Codebase Scanning Process
```text
SCAN_TARGETS:
  - Source code files (*.swift, *.h, *.m)
  - Configuration files
  - Build specifications
  - Test suites
  - Documentation comments
  - Architecture decision records

EXTRACTION_FOCUS:
  - Public interfaces
  - Component dependencies
  - Design patterns
  - Threading models
  - State management
  - Error handling strategies
```

### 3. Documentation Generation Rules
```text
GENERATION_RULES:
  - One document per cycle (enforced)
  - Complete framework snapshot
  - Version-specific content
  - Technology stack documentation
  - Platform compatibility notes
  - Migration guidance when applicable
```

## Technical Details

### Path Specifications
```text
FRAMEWORK_CODEBASE: /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-framework/AxiomFramework
FRAMEWORK_WORKSPACE: /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-meta-workspace/workspaces/FrameworkWorkspace
OUTPUT_PATTERN: {{FRAMEWORK_WORKSPACE}}/CYCLE-XXX-[TITLE]/DOCUMENTATION-XXX.md
```

### Validation Requirements
```text
PRE_GENERATION:
  - Verify framework cycle exists
  - Confirm no existing documentation in cycle
  - Validate codebase accessibility

POST_GENERATION:
  - Verify documentation completeness
  - Validate format compliance
  - Ensure all sections populated
```

### Persistence Requirements
```text
STORAGE:
  - Documentation stored in cycle folder
  - Immutable once generated
  - Version-controlled with cycle

NAMING:
  - DOCUMENTATION-XXX.md where XXX = cycle number
  - No title suffix (unlike requirements)
  - Consistent with cycle numbering
```

### Content Extraction Rules
```text
MANDATORY_EXTRACTIONS:
  - All public APIs
  - Component interfaces
  - Configuration options
  - Extension points
  - Error types
  - Threading constraints

ANALYSIS_DEPTH:
  - Follow dependency chains
  - Map component interactions
  - Document state flows
  - Capture lifecycle patterns
```

## Error Handling

### Error Types and Recovery
```text
ERROR: Documentation already exists in cycle
RECOVERY: Inform user of existing documentation, suggest viewing it

ERROR: Framework codebase not accessible
RECOVERY: Verify path configuration and permissions

ERROR: Incomplete code analysis
RECOVERY: Report partial results, identify missing components

ERROR: Invalid cycle structure
RECOVERY: Guide user to proper cycle creation workflow
```

### Validation Failures
```text
VALIDATION: Missing required sections
ACTION: Generate with available content, mark missing sections

VALIDATION: Circular dependencies detected
ACTION: Document circular patterns with warnings

VALIDATION: Undocumented public APIs
ACTION: Flag APIs lacking documentation

VALIDATION: Version mismatch
ACTION: Include version reconciliation notes
```

### Quality Assurance
```text
QA_CHECKS:
  - Section completeness verification
  - Cross-reference validation
  - Example code verification
  - API signature accuracy
  - Dependency graph integrity
```

## Usage Example
```text
User: @framework-document generate
Assistant: 
  - Scanning framework codebase...
  - Analyzing 47 components
  - Extracting API specifications
  - Documenting architecture patterns
  - Generating migration guides
  - Created: CYCLE-001-FOUNDATION-ARCHITECTURE/DOCUMENTATION-001.md
```

## Protocol Integration
This protocol integrates with the framework development cycle:
1. Follows Framework DEVELOP completion
2. Provides input for Application PLAN
3. Captures cycle-specific implementation state
4. Enables framework evolution tracking