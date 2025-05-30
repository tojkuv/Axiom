# 📂 Axiom Workspace Structure

## Overview

The Axiom workspace (`Axiom.xcworkspace`) provides a unified development environment with all targets and schemes properly configured.

## What's Included

### 📦 Swift Package (Package.swift)
Contains all the main framework targets:
- **Axiom** - Core framework
- **AxiomMacros** - Swift macro implementations
- **AxiomTesting** - Testing utilities
- **AxiomTests** - Framework unit tests
- **AxiomMacrosTests** - Macro tests
- **AxiomFoundationExample** - Full example application
- **AxiomFoundationExampleTests** - Example app tests

### 📱 Example iOS App (ExampleApp.xcodeproj)
A standalone iOS app project that demonstrates:
- How to add Axiom as a dependency
- Basic usage patterns
- SwiftUI integration

## Available Schemes

### 🎯 Workspace Schemes
These are available when you open `Axiom.xcworkspace`:

1. **Axiom-Framework**
   - Builds the main framework
   - Runs framework tests
   - Use: `Cmd+B` to build, `Cmd+U` to test

2. **AxiomFoundationExample**
   - Runs the complete example application
   - Shows real-world usage patterns
   - Use: `Cmd+R` to run

3. **All-Tests**
   - Runs all test suites in one go
   - Includes framework, macro, and example tests
   - Use: `Cmd+U` to run all tests

4. **ExampleApp**
   - Simple iOS app showing how to integrate Axiom
   - Currently just a placeholder
   - Add Axiom dependency to use framework features

### 📋 Package Schemes
These are always available when working with Package.swift:

- **Axiom** - Framework library
- **AxiomTests** - Unit tests
- **AxiomMacros** - Macro implementations
- **AxiomMacrosTests** - Macro tests
- **AxiomFoundationExample** - Example app
- **AxiomFoundationExampleTests** - Example tests

## Directory Structure

```
Axiom/
├── Axiom.xcworkspace/              # Unified workspace
│   ├── contents.xcworkspacedata    # Workspace configuration
│   └── xcshareddata/
│       ├── xcschemes/              # Shared schemes
│       │   ├── Axiom-Framework.xcscheme
│       │   ├── AxiomFoundationExample.xcscheme
│       │   └── All-Tests.xcscheme
│       └── WorkspaceSettings.xcsettings
│
├── Package.swift                   # Swift Package Manager manifest
├── Sources/                        # Framework source code
│   ├── Axiom/
│   ├── AxiomMacros/
│   └── AxiomTesting/
├── Tests/                          # Test suites
│   ├── AxiomTests/
│   └── AxiomMacrosTests/
├── Examples/                       # Example applications
│   └── FoundationExample/
└── ExampleApp/                     # Standalone iOS app example
    └── ExampleApp.xcodeproj

```

## How to Use

### For Framework Development
```bash
# Open the workspace
open Axiom.xcworkspace

# Select "Axiom-Framework" scheme
# Press Cmd+B to build
# Press Cmd+U to test
```

### For Running Examples
```bash
# Open the workspace
open Axiom.xcworkspace

# Select "AxiomFoundationExample" scheme
# Choose your target device
# Press Cmd+R to run
```

### For Testing Everything
```bash
# Open the workspace
open Axiom.xcworkspace

# Select "All-Tests" scheme
# Press Cmd+U to run all tests
```

## Adding Axiom to Your Own Project

1. In your project, go to **File → Add Package Dependencies**
2. Click "Add Local..."
3. Navigate to the Axiom directory
4. Select the folder and click "Add Package"
5. Choose which products to add (usually just "Axiom")

## Benefits of Using the Workspace

- ✅ **All targets in one place** - No switching between windows
- ✅ **Shared schemes** - Consistent build configurations
- ✅ **Easy testing** - Run all tests with one command
- ✅ **Example integration** - See how to use Axiom in real apps
- ✅ **Unified debugging** - Set breakpoints across all targets

## Tips

- Use `Cmd+Shift+O` to quickly open any file
- Use `Cmd+1` to show the Navigator
- Use `Cmd+6` to show the Test Navigator
- Use `Cmd+8` to show the Report Navigator
- Hold `Option` while clicking a scheme to edit it

The workspace is configured and ready for development! 🚀