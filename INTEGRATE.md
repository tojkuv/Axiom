# Axiom Framework Integration Guide

You are Claude Code refining the Axiom framework through real-world testing and integration cycles with AxiomTestApp.

## 🎯 INTEGRATE Mode Mission

**Focus**: Validate framework in real iOS applications, refine APIs based on usage patterns, and ensure delightful developer experience.

**Philosophy**: Working code teaches truth. Every error in example apps reveals framework improvements.

## 🧪 AxiomTestApp Integration Workflow

### **Real-World Validation Environment**
- **Location**: `/AxiomTestApp/ExampleApp/`
- **Purpose**: Test framework APIs in actual iOS application context
- **Integration**: Workspace with live framework dependency resolution
- **Structure**: Modular organization for efficient testing and iteration

### **Modular Testing Structure**
```
AxiomTestApp/ExampleApp/
├── Models/         # State and client definitions
│   ├── CounterState.swift      # State models with mutations
│   └── CounterClient.swift     # Actor-based client implementations
├── Contexts/       # Context orchestration with auto-binding  
│   └── CounterContext.swift    # Streamlined contexts using new APIs
├── Views/          # SwiftUI integration
│   ├── CounterView.swift       # Main UI implementations
│   └── LoadingView.swift       # Loading and error state views
├── Utils/          # Application setup with builders
│   └── ApplicationCoordinator.swift # Streamlined app setup
└── Examples/       # Testing different implementation approaches
    ├── BasicExample/           # Manual patterns for baseline
    ├── StreamlinedExample/     # New convenience APIs
    └── ComparisonExample/      # Side-by-side comparisons
```

## 🔄 Integration Testing Cycle

### **Phase 1: Discover Issues**
1. **Use Real App** → Run AxiomTestApp and identify verbose or error-prone patterns
2. **Document Pain Points** → Note repetitive code, manual synchronization, complex setup
3. **Analyze Root Causes** → Why are these patterns necessary? What's missing from framework?
4. **Prioritize Improvements** → Focus on most common or error-prone patterns

### **Phase 2: Prototype Solutions**
1. **Test in Examples/** → Create isolated implementation in `Examples/NewFeature/`
2. **Validate API Design** → Ensure new APIs work with existing framework
3. **Measure Improvements** → Document code reduction and error prevention
4. **Compare Approaches** → Side-by-side analysis in `Examples/ComparisonExample/`

### **Phase 3: Refine Integration**
1. **Update Components** → Modify relevant files in Models/, Contexts/, Views/, Utils/
2. **Maintain Compatibility** → Keep existing class names (RealAxiomApplication, RealCounterView)
3. **Test Integration** → Ensure app builds and runs correctly
4. **Validate Benefits** → Confirm improvements work in real usage

### **Phase 4: Document Patterns**
1. **Capture Learnings** → Update context guides and documentation
2. **Create Examples** → Working code serves as integration guide
3. **Update STATUS.md** → Document progress and next priorities

## ⚠️ Critical Integration Rules

### **Naming Consistency** (NEVER BREAK!)
- **RealAxiomApplication** → Keep this name, improve implementation underneath
- **RealCounterView** → Keep this name, enhance with new APIs
- **RealCounterContext** → Keep this name, add convenience features
- **Principle**: Improve implementations, don't rename everything

### **API Refinement Approach**
- **Add convenience APIs** without breaking existing patterns
- **Supplement, don't replace** working functionality
- **Test in Examples/ first** before updating main components
- **Measure improvements** with concrete metrics (lines of code, complexity)

## 🎯 Current Integration Successes

### **Streamlined APIs Delivered** ✅
- **AxiomApplicationBuilder**: 70% reduction in initialization boilerplate
- **ContextStateBinder**: 80% reduction in manual state synchronization
- **Type-Safe Binding**: Compile-time checked KeyPath relationships
- **Error Prevention**: Automatic patterns eliminate manual sync bugs

### **Proven Patterns**
```swift
// Before: Complex manual setup (25+ lines)
let capabilityManager = await GlobalCapabilityManager.shared.getManager()
// ... 20+ more lines of manual setup

// After: Simple builder pattern (7 lines)
let appBuilder = AxiomApplicationBuilder.counterApp()
await appBuilder.build()
```

### **Real Usage Validation**
- ✅ Framework builds cleanly with test app
- ✅ All streamlined APIs work in real iOS context
- ✅ Modular structure enables efficient testing
- ✅ No breaking changes to existing functionality

## 🧪 Testing New Framework Features

### **Isolated Feature Testing**
```bash
# 1. Create isolated test directory
mkdir Examples/NewFeatureTest/
cd Examples/NewFeatureTest/

# 2. Implement feature test
# Create isolated Swift files testing new framework capabilities

# 3. Add to main app for integration
# Update ContentView.swift with navigation to new test
```

### **Component Update Workflow**
```bash
# 4. Update relevant component based on learnings
cd Models/        # For state/client changes
cd Contexts/      # For orchestration changes  
cd Views/         # For UI integration changes
cd Utils/         # For app-level changes

# 5. Integration works automatically through imports
# No breaking changes to main app flow
```

### **Comparison Testing**
```bash
# 6. Document improvements
cd Examples/ComparisonExample/
# Create side-by-side before/after analysis
# Measure concrete improvements (lines of code, complexity)
```

## 📊 Integration Success Metrics

### **Code Quality Measurements**
- **Lines of Code Reduction**: Target 50-80% for common patterns
- **Complexity Reduction**: Fewer manual steps, less error-prone code
- **Type Safety**: More compile-time validation, fewer runtime errors
- **Readability**: Code intent clear without extensive comments

### **Developer Experience Metrics**
- **Setup Time**: From complex manual setup to simple builders
- **Learning Curve**: Framework guides developers to correct patterns
- **Error Prevention**: Eliminate entire classes of common mistakes
- **Integration Smoothness**: Works naturally with existing iOS patterns

### **Performance Validation**
- **Build Time**: Framework changes build quickly (<0.5s)
- **App Performance**: No noticeable impact on startup or runtime
- **Memory Usage**: Minimal framework overhead vs manual patterns
- **Responsiveness**: UI updates remain smooth with framework

## 🎯 Integration Priorities

### **Current Focus**
1. **API Ergonomics** → Make common patterns more concise and error-proof
2. **Error Messages** → Clear, actionable guidance when things go wrong
3. **Performance Measurement** → Real metrics from actual usage scenarios
4. **Documentation** → Capture real-world patterns and best practices

### **Success Indicators**
- ✅ AxiomTestApp builds and runs without issues
- ✅ New APIs reduce boilerplate significantly
- ✅ Type safety prevents common errors
- ✅ Framework overhead is minimal and measurable
- ✅ Developer experience is delightful, not just functional

## 🔧 Integration Commands

### **Development Workflow**
```bash
# Test framework changes
cd AxiomFramework && swift build

# Test app integration  
cd AxiomTestApp && xcodebuild -workspace ../Axiom.xcworkspace -scheme ExampleApp build

# Full integration validation
open Axiom.xcworkspace
# Build and run both framework and app together
```

### **Integration Validation**
```bash
# Quick framework check
swift build --target Axiom

# Full integration test
xcodebuild -workspace Axiom.xcworkspace -scheme ExampleApp build

# Clean build validation
xcodebuild clean build
```

## 📚 Integration Context

### **Management Guides**
- **App Context**: `/AxiomTestApp/AXIOM_TEST_APP_CONTEXT.md`
- **Workspace Status**: `/AxiomTestApp/WORKSPACE_STATUS.md`
- **Examples Guide**: `/AxiomTestApp/ExampleApp/Examples/README.md`

### **Key Principles**
1. **Real usage drives design** → App patterns reveal framework needs
2. **Pragmatic over perfect** → Working code today beats perfect code tomorrow
3. **Measure improvements** → Concrete metrics prove API benefits
4. **Maintain compatibility** → No breaking changes to working patterns
5. **Error prevention first** → Eliminate entire classes of mistakes

## 🎯 Integration Goals

**Create framework APIs that feel natural and prevent errors:**
- Developers fall into "pit of success" 
- Common patterns are concise and clear
- Mistakes are caught at compile time
- Real-world usage validates design decisions
- Integration with existing iOS patterns is seamless

**Next Actions**: Use AxiomTestApp → Identify verbose patterns → Prototype improvements → Integrate refinements → Measure benefits