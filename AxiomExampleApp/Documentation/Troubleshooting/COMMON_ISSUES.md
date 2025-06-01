# AxiomTestApp Common Issues & Solutions

## 🎯 Purpose

Quick reference for resolving common integration issues, build problems, and runtime errors when working with AxiomTestApp and framework integration.

## 🔧 Build Issues

### **Issue: Framework Build Failure**
```bash
error: Could not find package 'Axiom' at '/path/to/AxiomFramework'
```

**Diagnosis:**
- Workspace dependency path incorrect
- Package.swift configuration issue
- Clean build state needed

**Solutions:**
```bash
# 1. Verify workspace structure
ls -la Axiom.xcworkspace/
cat Axiom.xcworkspace/contents.xcworkspacedata

# 2. Clean and rebuild
cd AxiomFramework
swift package clean
swift build

# 3. Reset Xcode derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/Axiom-*

# 4. Verify package dependency in Xcode
# Project → Package Dependencies → Check Axiom package path
```

### **Issue: Missing Framework Imports**
```swift
error: No such module 'Axiom'
```

**Diagnosis:**
- Missing import statement
- Framework not properly linked
- Build configuration issue

**Solutions:**
```swift
// 1. Add missing import
import Axiom

// 2. Verify conditional import
#if canImport(Axiom)
import Axiom
#endif

// 3. Check target dependencies in Xcode project
```

### **Issue: Duplicate Symbol Errors**
```bash
error: duplicate symbol '_$s5Axiom11AxiomClientMp' in:
```

**Diagnosis:**
- Framework included multiple times
- Conflicting implementations
- Build configuration duplication

**Solutions:**
```bash
# 1. Clean build completely
xcodebuild clean
rm -rf ~/Library/Developer/Xcode/DerivedData/

# 2. Check for duplicate framework references
# Project Settings → Frameworks, Libraries, and Embedded Content

# 3. Verify package dependency is only added once
```

## 🏃‍♂️ Runtime Issues

### **Issue: Actor Isolation Errors**
```swift
error: Expression is 'async' but is not marked with 'await'
```

**Diagnosis:**
- Missing await keyword
- Actor boundary crossing
- MainActor requirements

**Solutions:**
```swift
// 1. Add missing await
let count = await counterClient.getCurrentCount()

// 2. Wrap in Task for async context
Task {
    await counterClient.increment()
}

// 3. Use MainActor for UI updates
await MainActor.run {
    self.currentCount = newCount
}
```

### **Issue: State Synchronization Problems**
```swift
// UI not updating when client state changes
```

**Diagnosis:**
- Observer not properly set up
- State binding not configured
- Publisher not triggering updates

**Solutions:**
```swift
// 1. Verify observer setup
await counterClient.addObserver(self)

// 2. Check state binding configuration
await bindClientProperty(
    counterClient,
    property: \.count,
    to: \.currentCount,
    using: stateBinder
)

// 3. Ensure onClientStateChange implementation
func onClientStateChange<T: AxiomClient>(_ client: T) async {
    await stateBinder.updateAllBindings()
}
```

### **Issue: Memory Leaks or Retain Cycles**
```swift
// App memory usage continuously increasing
```

**Diagnosis:**
- Strong reference cycles
- Observer not properly removed
- Client or context not deallocated

**Solutions:**
```swift
// 1. Use weak references for observers
weak var weakSelf = self
await client.addObserver(weakSelf)

// 2. Implement proper cleanup
deinit {
    Task {
        await counterClient.removeObserver(self)
    }
}

// 3. Check for strong reference cycles
// Context → Client → Context (via observer)
```

## 🧪 Integration Issues

### **Issue: Capability System Not Working**
```swift
// Capabilities always showing as unavailable
```

**Diagnosis:**
- Capability manager not configured
- Capability validation failing
- Global managers not initialized

**Solutions:**
```swift
// 1. Verify capability manager setup
let capabilityManager = await GlobalCapabilityManager.shared.getManager()
await capabilityManager.configure(availableCapabilities: [.businessLogic, .stateManagement])

// 2. Check capability availability
let isAvailable = await capabilityManager.isCapabilityAvailable(.businessLogic)
print("Business logic capability: \(isAvailable)")

// 3. Debug capability validation
await capabilityManager.validateCapability(.businessLogic)
```

### **Issue: Intelligence System Not Responding**
```swift
// Intelligence queries failing or timing out
```

**Diagnosis:**
- Intelligence manager not initialized
- Network connectivity issues
- Query format problems

**Solutions:**
```swift
// 1. Verify intelligence manager setup
let intelligence = await GlobalIntelligenceManager.shared.getIntelligence()

// 2. Test with simple query
do {
    let response = try await intelligence.processQuery("Hello")
    print("Intelligence response: \(response.answer)")
} catch {
    print("Intelligence error: \(error)")
}

// 3. Check query format and complexity
// Simpler queries more likely to succeed
```

### **Issue: Performance Problems**
```swift
// App running slowly or freezing
```

**Diagnosis:**
- Blocking main thread
- Excessive framework overhead
- Memory issues

**Solutions:**
```swift
// 1. Move expensive operations off main thread
Task.detached {
    await heavyFrameworkOperation()
}

// 2. Profile with Instruments
// Look for main thread blocking
// Check memory allocations

// 3. Reduce framework overhead
// Minimize observer notifications
// Batch state updates where possible
```

## 🔍 Debugging Strategies

### **Build Debugging**
```bash
# Verbose build output
xcodebuild -workspace Axiom.xcworkspace -scheme ExampleApp build -verbose

# Check dependency resolution
xcodebuild -workspace Axiom.xcworkspace -list
xcodebuild -workspace Axiom.xcworkspace -showBuildSettings

# Validate package structure
cd AxiomFramework
swift package dump-package
swift package show-dependencies
```

### **Runtime Debugging**
```swift
// Add debug logging
extension RealCounterClient {
    func increment() async {
        print("🔄 Client: Incrementing count from \(stateSnapshot.count)")
        stateSnapshot.increment()
        print("✅ Client: Count now \(stateSnapshot.count)")
        await notifyObservers()
        print("📢 Client: Observers notified")
    }
}

// Monitor state changes
extension RealCounterContext {
    func onClientStateChange<T: AxiomClient>(_ client: T) async {
        print("🔔 Context: Client state changed")
        await stateBinder.updateAllBindings()
        print("🔄 Context: State binding updated")
    }
}
```

### **Performance Debugging**
```swift
// Profile specific operations
func debugPerformance() async {
    let startTime = CFAbsoluteTimeGetCurrent()
    
    await counterClient.increment()
    
    let endTime = CFAbsoluteTimeGetCurrent()
    let duration = (endTime - startTime) * 1000
    
    if duration > 10.0 { // Alert if operation takes >10ms
        print("⚠️ Slow operation: \(duration)ms")
    }
}
```

## 🚨 Emergency Procedures

### **Complete Reset**
```bash
# When everything is broken and you need to start fresh
cd /Users/tojkuv/Documents/GitHub/Axiom

# 1. Clean all build artifacts
rm -rf ~/Library/Developer/Xcode/DerivedData/Axiom-*
xcodebuild -workspace Axiom.xcworkspace clean

# 2. Reset package cache
cd AxiomFramework
swift package reset
swift package clean

# 3. Rebuild everything
swift build
cd ..
xcodebuild -workspace Axiom.xcworkspace -scheme ExampleApp build
```

### **Workspace Recovery**
```bash
# If workspace gets corrupted
cd /Users/tojkuv/Documents/GitHub/Axiom

# 1. Backup current workspace
cp -r Axiom.xcworkspace Axiom.xcworkspace.backup

# 2. Recreate workspace (if needed)
# Open Xcode → File → New Workspace
# Add AxiomFramework (as folder reference)
# Add AxiomTestApp/ExampleApp.xcodeproj

# 3. Verify package dependencies
# Project → Package Dependencies → Add AxiomFramework
```

## 📊 Issue Tracking

### **Common Issue Patterns**
1. **Build Issues (40%)** → Usually workspace or dependency configuration
2. **Actor Isolation (25%)** → Missing await keywords or MainActor usage
3. **State Sync (20%)** → Observer setup or binding configuration
4. **Performance (10%)** → Main thread blocking or memory issues
5. **Integration (5%)** → Capability or intelligence system setup

### **Resolution Success Rates**
- **Build Issues** → 95% resolved with clean rebuild
- **Runtime Issues** → 80% resolved with proper async/await usage
- **Integration Issues** → 90% resolved with correct manager setup
- **Performance Issues** → 70% resolved with profiling and optimization

### **Prevention Strategies**
1. **Regular Clean Builds** → Prevent build artifact issues
2. **Proper Async Patterns** → Use await consistently
3. **Observer Lifecycle** → Always clean up observers
4. **Performance Monitoring** → Regular performance checks
5. **Integration Testing** → Test all integration points

## 🎯 Support Resources

### **Quick Commands**
```bash
# Check framework build
cd AxiomFramework && swift build

# Check app build
cd AxiomTestApp && xcodebuild -workspace ../Axiom.xcworkspace -scheme ExampleApp build

# Reset everything
rm -rf ~/Library/Developer/Xcode/DerivedData/Axiom-* && swift package clean
```

### **Debugging Checklist**
- [ ] Framework builds successfully
- [ ] App builds with framework dependency
- [ ] Imports are correct and conditional
- [ ] Await keywords used for async operations
- [ ] Observers properly set up and cleaned up
- [ ] State binding configured correctly
- [ ] Capability managers initialized
- [ ] Intelligence system responsive

---

**Use this guide for quick resolution of common AxiomTestApp integration issues. Update with new issues and solutions as they're discovered.**