# CODEBASE-DOCUMENTER-PROTOCOL

Documentation generation protocol that runs after stabilizer completion to create comprehensive markdown documentation for the stabilized codebase. Generates user-friendly documentation in a dedicated documentation folder within the codebase workspace.

## Protocol Activation

```text
@CODEBASE_DOCUMENTER execute <source_directory> <documentation_directory> <documenter_template>
```

**Parameters:**
- `<source_directory>`: Directory containing the final codebase to document
- `<documentation_directory>`: Directory where documentation will be generated
- `<documenter_template>`: Path to the documenter template for structuring documentation

**Prerequisites:**
- Final codebase must be available in `<source_directory>/` (typically the stabilized result)

**Explicit Input/Output Structure:**
- **INPUT**: `<source_directory>/` - Final codebase to document (READ-ONLY)
- **OUTPUT**: `<documentation_directory>/` - Generated documentation structure

## Command

### Execute - Documentation Generation

The execute command generates comprehensive markdown documentation:
- Analyzes codebase structure and APIs
- Creates user-friendly documentation for developers
- Generates complete documentation structure

```bash
@CODEBASE_DOCUMENTER execute \
  /path/to/final-codebase \
  /path/to/documentation-output \
  /path/to/codebase-documenter-template.md
```

### Example Usage

```bash
@CODEBASE_DOCUMENTER execute \
  /path/to/final-codebase \
  /path/to/documentation \
  /path/to/codebase-documenter-template.md

# Reads: /path/to/final-codebase/ (primary documentation source)
# Creates: /path/to/documentation/ (complete documentation structure)
```

## Documentation Generation Process

```text
1. FINAL CODEBASE ANALYSIS
   - Analyze final codebase from `<source_directory>/`
   - Extract public APIs, protocols, and key abstractions from final implementation
   - Document component relationships and dependencies
   - Identify usage patterns and architectural decisions
   
2. CODEBASE DOCUMENTATION
   - Analyze source code structure and organization
   - Extract all public interfaces and APIs
   - Identify core components and their relationships
   - Document configuration and setup requirements
   
3. DOCUMENTATION STRUCTURE GENERATION
   - Create documentation in `<documentation_directory>/`
   - Generate README.md with codebase overview
   - Create API reference documentation
   - Generate usage guides and examples based on final codebase
   - Document architectural decisions and patterns
   
4. MARKDOWN DOCUMENTATION CREATION
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

### Documentation Completion Gates
- Structure: Complete documentation hierarchy created ✓
- Content: All public APIs documented with examples ✓
- Guides: Getting started and best practices included ✓
- Quality: Documentation validated for completeness ✓

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