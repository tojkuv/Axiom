# CODEBASE-DOCUMENTER-PROTOCOL

Documentation generation protocol that runs after stabilizer completion to create comprehensive markdown documentation for the stabilized codebase. Generates user-friendly documentation in a dedicated documentation folder within the codebase workspace.

## Protocol Activation

```text
@CODEBASE_DOCUMENTER execute <codebase_directory> <development_artifacts_directory> <documentation_directory> <documenter_template>
```

**Parameters:**
- `<codebase_directory>`: Path to directory containing stabilized codebase source code
- `<development_artifacts_directory>`: Path to directory containing completed development artifacts (stabilizer, worker, provisioner session files)
- `<documentation_directory>`: Path to directory where documentation will be generated
- `<documenter_template>`: Path to the documenter template for structuring documentation

**Prerequisites:**
- Development artifacts directory must contain completed stabilizer session files
- Codebase must be fully stabilized and application-ready
- All parallel workers and provisioner work must be finished

## Command

### Execute - Codebase Documentation Generation

The execute command generates comprehensive markdown documentation for the stabilized codebase. It reads the completed development artifacts, analyzes the final codebase structure, and creates user-friendly documentation for application developers.

**Directory Usage:**
- Reads stabilized code from: `<codebase_directory>/`
- Reads development artifacts from: `<development_artifacts_directory>/`
- Writes documentation to: `<documentation_directory>/`

```bash
@CODEBASE_DOCUMENTER execute \
  /path/to/codebase-source \
  /path/to/development-artifacts \
  /path/to/documentation-output \
  /path/to/codebase-documenter-template.md
```

### Example Usage

```bash
@CODEBASE_DOCUMENTER execute \
  /path/to/stabilized-codebase \
  /path/to/development-artifacts \
  /path/to/documentation \
  /path/to/codebase-documenter-template.md

# Reads: /path/to/stabilized-codebase/
# Reads: /path/to/development-artifacts/
# Creates: /path/to/documentation/
```

## Documentation Generation Process

```text
1. STABILIZER ARTIFACT ANALYSIS
   - Read all STABILIZER/ session files and artifacts
   - Extract integration decisions and API stabilization choices
   - Identify final codebase architecture and patterns
   - Gather performance optimization results
   
2. CODEBASE SOURCE DOCUMENTATION
   - Analyze stabilized codebase source code
   - Extract public APIs, protocols, and key abstractions
   - Document component relationships and dependencies
   - Identify usage patterns and architectural decisions
   
3. DEVELOPMENT HISTORY SYNTHESIS
   - Review provisioner foundational decisions from artifacts
   - Summarize worker feature implementations from artifacts
   - Document stabilizer integration and optimization work from artifacts
   - Create narrative of codebase evolution
   
4. DOCUMENTATION STRUCTURE GENERATION
   - Create documentation in specified documentation directory
   - Generate README.md with codebase overview
   - Create API reference documentation
   - Generate usage guides and examples
   - Document architectural decisions and patterns
   
5. MARKDOWN DOCUMENTATION CREATION
   - Write comprehensive getting started guide
   - Document all public APIs with examples
   - Create architectural overview documentation
   - Generate component interaction diagrams (markdown)
   - Document performance characteristics and best practices
```

## Generated Documentation Structure

The documenter creates a complete documentation hierarchy:

```
<documentation_directory>/
├── README.md                    # Codebase overview and getting started
├── API-Reference/
│   ├── Core/                   # Core codebase APIs
│   ├── State/                  # State management APIs
│   ├── Navigation/             # Navigation APIs
│   └── Testing/                # Testing utilities APIs
├── Guides/
│   ├── Getting-Started.md      # Quick start guide
│   ├── Architecture.md         # Architectural overview
│   ├── Best-Practices.md       # Development best practices
│   └── Performance.md          # Performance guidelines
├── Examples/
│   ├── Basic-Usage.md          # Simple usage examples
│   ├── Advanced-Patterns.md    # Complex usage patterns
│   └── Testing-Guide.md        # Testing examples
└── Development/
    ├── Architecture-Decisions.md  # ADRs from development
    ├── Codebase-Evolution.md     # Development history
    └── Contributing.md            # Future development guide
```

## Documentation Content Focus

### Application Developer Focus
- **Getting Started**: Quick setup and basic usage
- **API Reference**: Complete API documentation with examples
- **Usage Patterns**: Common development scenarios
- **Best Practices**: Recommended usage patterns
- **Performance**: Guidelines for optimal performance

### Codebase Understanding
- **Architecture**: High-level codebase design
- **Component Relationships**: How pieces fit together
- **Design Decisions**: Why specific choices were made
- **Extension Points**: How to extend the codebase
- **Testing Strategy**: How to test applications using the codebase

### Generated from Artifacts
- **Development History**: Story of how codebase was built
- **Stabilization Decisions**: Integration choices made by stabilizer
- **Performance Results**: Optimization outcomes
- **API Evolution**: How APIs were refined during development

## Integration Points

### Inputs
1. **Codebase Workspace**: Complete workspace with all artifacts
2. **Stabilized Codebase**: Final [CodebaseName]/ codebase
3. **Development Artifacts**: All session files and development cycle indices
4. **Documenter Template**: Structure for documentation generation

### Outputs
- **Documentation Folder**: `<codebase_workspace>/Documentation/`
- **Markdown Files**: Comprehensive documentation in markdown format
- **No Code Generation**: Only documentation, no codebase modifications
- **Application-Ready Docs**: Focus on codebase usage, not internals

## Best Practices

### Documentation Quality
1. **User-Focused**: Written for application developers using the codebase
2. **Example-Rich**: Every API documented with usage examples
3. **Architecture-Aware**: Explains codebase design and rationale
4. **Complete Coverage**: Documents all public APIs and patterns
5. **Performance-Conscious**: Includes performance characteristics and guidelines

### Markdown Standards
1. **Consistent Structure**: Standard markdown formatting throughout
2. **Code Blocks**: Syntax-highlighted code examples in target language
3. **Cross-References**: Links between related documentation sections
4. **Table of Contents**: Navigation aids for complex documents
5. **Searchable Content**: Well-structured for easy searching

**EXPLICITLY EXCLUDED FROM DOCUMENTATION (MVP FOCUS):**
- Version control strategies (not relevant for MVP documentation)
- API versioning documentation (document current state only)
- Migration guides (no migration concerns for MVP)
- Deprecation notices (we fix problems, don't deprecate)
- Legacy usage patterns (document current patterns only)
- Backward compatibility notes (no compatibility constraints)
- Breaking change documentation (breaking changes welcomed)
- Semantic versioning references (MVP operates on current iteration)
- Release history documentation (focus on current capabilities)
- Database schema evolution (document current schema)
- Configuration migration (document current configuration)
- Upgrade procedures (no upgrade concerns for MVP)

### Integration with Development
1. **Artifact-Based**: Generated from actual development artifacts
2. **Current-State-Aligned**: Reflects the exact stabilized codebase state
3. **Decision-Traceable**: Links documentation to development decisions
4. **Evolution-Aware**: Shows how codebase developed over time
5. **MVP-Ready**: Includes guidance for current codebase usage