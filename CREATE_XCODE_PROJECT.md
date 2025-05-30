# Setting Up Axiom in Xcode

## Recommended Approach: Use Package.swift

The Axiom framework is built as a Swift Package. The recommended way to work with it in Xcode is:

1. **Open Xcode**
2. **File → Open**
3. **Select `Package.swift`** in the Axiom directory
4. **Click Open**

This will give you:
- ✅ All source files properly organized
- ✅ All tests ready to run (Cmd+U)
- ✅ Proper dependency management
- ✅ Example applications

## Running Tests

Once Package.swift is open:
1. Select the "Axiom" scheme from the toolbar
2. Press `Cmd+U` to run all tests

## Running Example Application

To create an example app that uses the framework:

1. **File → New → Project**
2. Choose **iOS App** or **macOS App**
3. Name it "AxiomExample"
4. Save it in the Axiom directory
5. In the new project:
   - Select the project in navigator
   - Go to project settings
   - Under "Frameworks, Libraries, and Embedded Content"
   - Click "+" and add the Axiom package from local files

## Alternative: Creating Traditional Xcode Project

If you must have a traditional .xcodeproj file, you'll need to:

1. Create a new Xcode project (Framework template)
2. Manually add all files from:
   - Sources/Axiom/**/*.swift
   - Sources/AxiomMacros/**/*.swift
   - Tests/AxiomTests/**/*.swift
3. Configure build settings for Swift 5.9+
4. Add SwiftSyntax dependency for macros

However, this approach is not recommended as it duplicates the Package.swift configuration and can lead to sync issues.

## Current Structure

```
Axiom/
├── Package.swift          # ← Open this in Xcode
├── Sources/
│   ├── Axiom/            # Main framework
│   ├── AxiomMacros/      # Macro implementations
│   └── AxiomTesting/     # Testing utilities
├── Tests/
│   ├── AxiomTests/       # Framework tests
│   └── AxiomMacrosTests/ # Macro tests
└── Examples/
    └── FoundationExample/ # Example application
```

## Quick Start

```bash
# Open in Xcode
open Package.swift

# Or use Xcode command line
xed .
```

Then press Cmd+B to build and Cmd+U to test!