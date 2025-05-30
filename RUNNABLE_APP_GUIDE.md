# How to Run the Axiom Framework iOS App

## 🎯 Quick Start: Runnable iOS Application ✅ **REAL FRAMEWORK READY!**

You now have an **iOS app with ACTUAL Axiom framework integration**!

### Option 1: Run with Fallback Demo (No Setup Required!) ⚡

1. **Open and Run the iOS App**:
   ```bash
   cd Axiom/Examples/ExampleApp
   open ExampleApp.xcodeproj
   ```

2. **Build and Run Immediately**:
   - Select iPhone Simulator from the scheme selector
   - Press `Cmd+R` or click the Run button
   - Shows "⚠️ AXIOM PACKAGE NOT FOUND" with demo functionality

**✅ Runs immediately** but uses fallback demo (not the real framework).

### Option 2: 🧠 **Real Axiom Framework** (RECOMMENDED!) 

Use the ACTUAL framework with real AxiomClient actors and intelligence:

1. **Add Axiom Package Dependency in Xcode**:
   - Select `ExampleApp` project in navigator
   - Go to `ExampleApp` target → "Frameworks, Libraries, and Embedded Content"
   - Click "+" → "Add Package Dependency"
   - Enter: `file:///Users/tojkuv/Documents/GitHub/Axiom` (package root)
   - Select "Axiom" and click "Add Package"

2. **Run the Real Framework**:
   - Build and run (`Cmd+R`)
   - App shows "🧠 REAL FRAMEWORK INTEGRATION" with green banner
   - Uses actual `AxiomClient` actors, `AxiomContext`, `AxiomView`
   - Real intelligence system with natural language queries
   - Console shows "🎯 Real AxiomClient initialized"

### Option 2: Quick Setup Script (Coming Soon)

We'll provide an automated setup script to handle the dependency injection.

## 🚀 What You'll See

### With Fallback Demo (No Package Dependency):
- ⚠️ **Orange Warning Banner**: "AXIOM PACKAGE NOT FOUND"
- **Demo Counter**: Works but not using real framework
- **Simulated Features**: Shows concepts but not actual implementation
- Console: "⚠️ Fallback Demo: ..."

### With Real Framework (Package Dependency Added):
- ✅ **Green Success Banner**: "REAL FRAMEWORK INTEGRATION"
- **Actual AxiomClient**: Real actor-based state management
- **True Intelligence**: Real natural language architectural queries
- **Framework Console Output**: "🎯 Real AxiomClient initialized"

### 🧠 **Real Framework Features**
1. **RealCounterClient**: Actor conforming to `AxiomClient` protocol
2. **RealCounterContext**: ObservableObject conforming to `AxiomContext`
3. **RealCounterView**: SwiftUI View conforming to `AxiomView`
4. **Real Intelligence**: Uses actual `AxiomIntelligence` protocol
5. **Capability Validation**: Real runtime validation with graceful degradation
6. **Performance Monitoring**: Actual metrics collection

### 📱 **Interactive Elements**
- **Increment/Decrement**: Real actor state mutations with observer notifications
- **Reset**: Actual state transactions through the framework
- **Ask Real AI**: Uses the actual intelligence system
- **Console Output**: Watch real framework events: "🔄 Real Framework: ..."

## 🔧 Troubleshooting

### If Import Fails
If you see import errors, ensure the Axiom package dependency is added correctly:
1. Project settings → Target → "Frameworks, Libraries, and Embedded Content"
2. Add local package dependency pointing to `../`

### If Build Fails
1. Clean build folder: `Product` → `Clean Build Folder`
2. Ensure iOS deployment target is 16.0+
3. Check that Swift 5.9+ is being used

## 🎯 Success Criteria

When working correctly, you should see:
- ✅ App launches without errors
- ✅ Counter responds to button taps
- ✅ Console shows framework events
- ✅ Intelligence button triggers AI responses
- ✅ Smooth SwiftUI animations and updates

## 🚀 Next Steps

Once you have the app running:
1. **Explore the Code**: See `ExampleApp/ExampleApp/ContentView.swift` for the complete implementation
2. **Experiment**: Modify the counter logic or add new features
3. **Build More**: Use this as a template for your own Axiom-powered apps

**You now have the world's first intelligent, predictive iOS framework running as a real application!** 🎉

---

**Framework Status**: ✅ **Stable with Runnable Demo**  
**Next Phase**: Add more example apps and advanced features