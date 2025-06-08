# FRAMEWORK_DOCUMENT_PROTOCOL.md

Generate comprehensive framework documentation from implementation.

## Protocol Activation

```text
@FRAMEWORK_DOCUMENT [command] [arguments]
```

## Commands

```text
generate              → Generate complete framework documentation
preview [section]     → Preview specific documentation section
validate              → Validate code examples and API references
publish              → Prepare documentation for distribution
diff [version]       → Show documentation changes from version
```

## Process Flow

```text
1. Scan framework implementation
2. Extract APIs and patterns
3. Generate structured documentation
4. Validate examples work
5. Publish for developers
```

## Command Details

### Generate Command

Create complete documentation:

```bash
@FRAMEWORK_DOCUMENT generate
```

Actions:
1. Scan framework codebase
2. Extract public APIs
3. Generate examples
4. Create DOCUMENTATION-XXX.md
5. Validate completeness

Output:
```
Scanning AxiomFramework v002...

Found:
  - 47 public types
  - 234 public methods
  - 18 protocols
  - 12 property wrappers

Generating documentation...
  ✓ API Reference (47 types documented)
  ✓ Architecture Guide (4 layers described)
  ✓ Getting Started (quick start guide)
  ✓ Migration Guide (v001 → v002)
  ✓ Code Examples (23 examples validated)

Generated: DOCUMENTATION-002.md (2,847 lines)
Validation: All examples compile and run
Next: Review with @FRAMEWORK_DOCUMENT preview
```

### Preview Command

Preview documentation sections:

```bash
@FRAMEWORK_DOCUMENT preview "Data Layer"
```

Output:
```
## Data Layer

The Axiom Data layer provides type-safe persistence with automatic migrations.

### Core Components

#### DataStore
Main interface for data operations:

```swift
public class DataStore {
    /// Save a single model instance
    public func save<T: Model>(_ item: T) async throws -> T
    
    /// NEW in v002: Save multiple items efficiently
    public func saveMany<T: Model>(_ items: [T]) async throws -> [T]
    
    /// Fetch by identifier
    public func fetch<T: Model>(_ type: T.Type, id: UUID) async throws -> T?
}
```

#### Model Protocol
Conform your types to enable persistence:

```swift
public protocol Model: Codable, Identifiable {
    var id: UUID? { get set }
    var createdAt: Date { get }
    var updatedAt: Date { get }
}
```

[Preview continues...]
```

### Validate Command

Check documentation accuracy:

```bash
@FRAMEWORK_DOCUMENT validate
```

Output:
```
Validating framework documentation...

Code Examples:
  ✓ 23/23 examples compile
  ✓ 23/23 examples have expected output
  ✗ 0 deprecated API usage found

API Coverage:
  ✓ 47/47 public types documented
  ✓ 234/234 public methods documented
  ✗ 3 methods missing examples

Cross-references:
  ✓ All internal links valid
  ✓ No broken references
  ✗ 2 sections need updates for v002

Status: 3 minor issues
Fix before publishing
```

### Publish Command

Prepare for distribution:

```bash
@FRAMEWORK_DOCUMENT publish
```

Actions:
1. Final validation pass
2. Generate formats (MD, HTML)
3. Create DocC archive
4. Update version references

Output:
```
Publishing framework documentation v002...

✓ Validation passed
✓ Generated Markdown (2,847 lines)
✓ Generated HTML (static site ready)
✓ Generated DocC archive
✓ Updated README.md

Published artifacts:
  - DOCUMENTATION-002.md
  - docs/index.html (and 47 pages)
  - AxiomFramework.doccarchive

Documentation available at:
  - Repository: /docs/DOCUMENTATION-002.md
  - Web: https://axiom-framework.dev/v002/
  - Xcode: Open AxiomFramework.doccarchive
```

### Diff Command

Show changes between versions:

```bash
@FRAMEWORK_DOCUMENT diff v001
```

Output:
```
Documentation changes v001 → v002:

NEW SECTIONS:
+ Batch Operations Guide
+ Transaction Support
+ Performance Optimization

NEW APIS:
+ DataStore.saveMany()
+ DataStore.deleteMany()
+ DataStore.transaction()
+ Model.batchValidate()

UPDATED EXAMPLES:
~ Data persistence example now uses batch API
~ Performance guide includes chunking strategy
~ Migration guide updated for v002

STATS:
- Added: 423 lines
- Modified: 156 lines
- Removed: 12 lines (deprecated notes)
```

## Documentation Generation

### API Extraction

From source code:
```swift
/// Save multiple models efficiently in a single transaction
/// - Parameter items: Array of models to save
/// - Returns: Array of saved models with assigned IDs
/// - Throws: DataStoreError if save fails
public func saveMany<T: Model>(_ items: [T]) async throws -> [T]
```

Generated documentation:
```markdown
#### saveMany(_:)

Save multiple models efficiently in a single transaction.

**Declaration**
```swift
func saveMany<T: Model>(_ items: [T]) async throws -> [T]
```

**Parameters**
- `items`: Array of models to save

**Returns**
Array of saved models with assigned IDs

**Throws**
`DataStoreError` if save fails

**Example**
```swift
let tasks = [
    Task(title: "First"),
    Task(title: "Second")
]
let saved = try await store.saveMany(tasks)
print("Saved \(saved.count) tasks")
```
```

### Architecture Documentation

Extracted from code structure:
```text
Sources/
├── AxiomCore/     → Core Layer docs
├── AxiomData/     → Data Layer docs
├── AxiomUI/       → UI Layer docs
└── AxiomTest/     → Test Utilities docs
```

### Example Generation

1. Extract from tests
2. Simplify for clarity
3. Validate execution
4. Include in docs

## Technical Details

### Paths

```text
FrameworkCodebase: /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-framework/AxiomFramework
FrameworkWorkspace: /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-meta-workspace/workspaces/FrameworkWorkspace
Documentation: /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-framework/docs/
```

### Documentation Structure

Uses FRAMEWORK_DOCUMENTATION_TEMPLATE.md:
- Overview and architecture
- Getting started guide
- API reference (auto-generated)
- Patterns and best practices
- Migration guides
- Performance guidelines

### Documentation Formats

1. **Markdown**: Primary source format
2. **HTML**: Static site generation
3. **DocC**: Xcode integration
4. **PDF**: Offline reference (optional)

## Validation Rules

### Code Examples
- Must compile without errors
- Should demonstrate common usage
- Include expected output
- Cover error cases

### API Documentation
- All public APIs documented
- Parameters described
- Return values explained
- Throws conditions listed

### Cross-References
- Internal links must resolve
- Version numbers consistent
- No deprecated API usage
- Examples match current API

## Integration Points

### Inputs
- Framework source code
- Test files (for examples)
- Previous documentation
- Session insights

### Outputs
- DOCUMENTATION-XXX.md
- Published formats
- Feeds application development
- Updates website

### Tools
- Swift-DocC
- SourceKit for parsing
- Swift compiler for validation
- Markdown processors

## Error Handling

### Missing Documentation
```
Warning: 3 public methods lack documentation
Affected:
  - DataStore.internal_reset() 
  - Model.debug_description
  - Transaction.unsafe_commit()

Add doc comments or mark @available(*, deprecated)
```

### Invalid Examples
```
Error: Example code doesn't compile
File: DOCUMENTATION-002.md, Line 234

let result = store.save(task) // Error: Missing 'await'

Fix: Add 'await' keyword
```

### API Mismatch
```
Error: Documented API doesn't match implementation
Documented: func process(input: String) -> String
Actual: func process(input: String) async -> String

Regenerate documentation to fix
```

## Best Practices

1. **Document from code, not memory** - Let implementation drive documentation

2. **Validate everything** - Every example must actually work

3. **Show, don't just tell** - Include examples for every significant API

4. **Keep it current** - Regenerate after each development cycle

5. **Think like a user** - Document what developers need, not implementation details