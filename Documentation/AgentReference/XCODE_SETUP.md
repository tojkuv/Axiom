# 🔧 Axiom Framework - Complete Xcode Setup Guide

## 🚀 Quick Start (Recommended)

```bash
# Open the complete workspace with all targets
open Axiom.xcworkspace

# Or run the setup script
./setup_xcode_project.sh

# Or just open the package
open Package.swift
```

## 📦 Understanding the Project Structure

Axiom is a **Swift Package Manager (SPM)** project. This is the modern, Apple-recommended approach for frameworks.

### Why Package.swift instead of .xcodeproj?

- ✅ **Automatic file management** - No need to manually add/remove files
- ✅ **Better dependency handling** - SwiftSyntax for macros is handled automatically
- ✅ **Cross-platform** - Works on macOS, iOS, and Linux
- ✅ **Clean version control** - No merge conflicts with .pbxproj files
- ✅ **Xcode integration** - Full IDE support when opening Package.swift

## 🎯 Working in Xcode

### Option 1: Open the Workspace (Recommended)

1. **Launch Xcode**
2. **File → Open** (or Cmd+O)
3. **Navigate to** `/Users/tojkuv/Documents/GitHub/Axiom/`
4. **Select `Axiom.xcworkspace`**
5. **Click Open**

This gives you:
- ✅ All Swift Package targets
- ✅ Example iOS app project
- ✅ Shared schemes for easy testing
- ✅ Unified workspace for all development

### Option 2: Open Package.swift Directly

1. **Launch Xcode**
2. **File → Open** (or Cmd+O)
3. **Navigate to** `/Users/tojkuv/Documents/GitHub/Axiom/`
4. **Select `Package.swift`**
5. **Click Open**

### Available Schemes

Once open, you'll see these schemes in the toolbar:

#### Swift Package Schemes:
- **Axiom** - The main framework
- **AxiomTests** - Framework unit tests
- **AxiomMacros** - Macro implementations
- **AxiomFoundationExample** - Example application

#### Workspace Schemes (when using .xcworkspace):
- **Axiom-Framework** - Build and test the framework
- **AxiomFoundationExample** - Run the example app
- **All-Tests** - Run all test suites at once
- **ExampleApp** - Standalone iOS app demonstrating Axiom usage

### Building the Framework

1. Select **"Axiom"** scheme
2. Press **Cmd+B** or Product → Build

### Running Tests

1. Select **"Axiom"** scheme
2. Press **Cmd+U** or Product → Test

### Running the Example App

1. Select **"AxiomFoundationExample"** scheme
2. Choose your target device/simulator
3. Press **Cmd+R** or Product → Run

## 🛠️ Project Organization

```
Axiom/
├── Package.swift              # ← Open this in Xcode
├── Sources/
│   ├── Axiom/                # Main framework
│   │   ├── Application/      # App lifecycle management
│   │   ├── Capabilities/     # Capability system
│   │   ├── Core/            # Core protocols
│   │   ├── Errors/          # Error handling
│   │   ├── Intelligence/    # AI/ML features
│   │   ├── Macros/          # Macro definitions
│   │   ├── Performance/     # Performance monitoring
│   │   ├── State/           # State management
│   │   └── SwiftUI/         # View integration
│   ├── AxiomMacros/         # Macro implementations
│   └── AxiomTesting/        # Testing utilities
├── Tests/
│   ├── AxiomTests/          # Framework tests
│   └── AxiomMacrosTests/    # Macro tests
└── Examples/
    └── FoundationExample/    # Example app

```

## 🔨 Common Tasks

### Adding New Files

1. Right-click on the appropriate group in Xcode
2. Select "New File..."
3. Files are automatically added to the package

### Running Specific Tests

1. Open Test Navigator (Cmd+6)
2. Click the diamond next to any test to run it
3. Or right-click and select "Run"

### Debugging

1. Set breakpoints by clicking line numbers
2. Run tests or app with Cmd+U or Cmd+R
3. Use Debug Navigator (Cmd+7) when stopped

### Performance Testing

1. Select Product → Profile (Cmd+I)
2. Choose Instruments template
3. Profile the example app or tests

## 🚨 Troubleshooting

### "No such module 'Axiom'" Error

1. Clean build folder: Cmd+Shift+K
2. Resolve packages: File → Packages → Resolve Package Versions
3. Rebuild: Cmd+B

### SwiftSyntax Errors

The package automatically handles SwiftSyntax dependency. If you see errors:
1. File → Packages → Update to Latest Package Versions
2. Clean and rebuild

### Test Discovery Issues

1. Ensure test files end with "Tests.swift"
2. Test methods must start with "test"
3. Clean build folder and re-run

## 💡 Pro Tips

### Keyboard Shortcuts

- **Cmd+B** - Build
- **Cmd+U** - Run all tests
- **Cmd+R** - Run selected scheme
- **Cmd+.** - Stop running
- **Cmd+Shift+O** - Open quickly (find files)
- **Cmd+Shift+F** - Find in project
- **Cmd+Click** - Jump to definition
- **Option+Click** - Quick help

### Using the Console

1. View → Debug Area → Show Debug Area
2. See print statements and test output
3. Use lldb commands when debugging

### Creating a Traditional Xcode Project (Not Recommended)

If you absolutely need a .xcodeproj file:

```bash
# Generate xcodeproj from Package.swift
swift package generate-xcodeproj
```

⚠️ **Note**: This is deprecated and not recommended. The generated project may not work correctly with macros and modern Swift features.

## 📱 Creating an iOS/macOS App Using Axiom

1. **File → New → Project**
2. Choose **iOS/macOS App**
3. Configure:
   - Product Name: "MyAxiomApp"
   - Team: Your team
   - Interface: SwiftUI
   - Language: Swift
4. Save in a separate directory
5. Add Axiom as dependency:
   - Select project in navigator
   - Go to project (not target) settings
   - Click "+" under "Package Dependencies"
   - Click "Add Local..."
   - Select the Axiom directory
   - Click "Add Package"

## 🎉 You're Ready!

Open `Package.swift` in Xcode and start developing! The framework is fully functional and ready for:

- ✅ Building and testing
- ✅ Running the example application
- ✅ Creating your own apps using Axiom
- ✅ Exploring the intelligent architecture features

Happy coding! 🚀