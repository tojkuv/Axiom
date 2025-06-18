# Axiom Swift Client Generator - Examples & Tutorials

Welcome to the comprehensive examples collection for the Axiom Swift Client Generator! This directory contains real-world examples that demonstrate how to build production-ready iOS and macOS applications using generated Swift clients.

## 📚 Table of Contents

1. [Quick Start](#quick-start)
2. [Example Projects](#example-projects)
3. [Learning Path](#learning-path)
4. [Best Practices](#best-practices)
5. [Troubleshooting](#troubleshooting)
6. [Community](#community)

## 🚀 Quick Start

### Prerequisites
- macOS with Xcode 15.0+
- Swift 5.9+
- Axiom framework dependencies
- Axiom Swift Client Generator installed

### 30-Second Start

```bash
# 1. Clone or navigate to the generator
cd axiom-client-generator

# 2. Generate your first Swift client
axiom-client-generator generate \
  --proto-path examples/task_manager/proto/task_service.proto \
  --output-path ./my-first-client \
  --languages swift \
  --validate \
  --verbose

# 3. Check the generated files
ls -la my-first-client/swift/

# 4. View the documentation
open my-first-client/swift/Documentation/README.md
```

## 🎯 Example Projects

### 1. Task Manager 📝
**Best for: Learning core concepts**

A comprehensive task management application demonstrating:
- ✅ **CRUD Operations**: Create, read, update, delete tasks
- ✅ **State Management**: Immutable state with reactive updates
- ✅ **Search & Filtering**: Advanced search capabilities
- ✅ **Pagination**: Handling large datasets
- ✅ **Validation**: Client-side validation with error handling
- ✅ **Categories**: Hierarchical organization

**Difficulty**: Beginner to Intermediate  
**Time to Complete**: 30-45 minutes  
**[👉 Start Tutorial](./task_manager/README.md)**

**Key Concepts Covered**:
- Actor-based clients
- Immutable state updates
- Action validation
- AsyncStream observation
- SwiftUI integration

---

### 2. User Service 🔐
**Best for: Authentication patterns**

A complete user authentication and management system featuring:
- ✅ **Authentication Flow**: Registration, login, logout
- ✅ **Token Management**: JWT with automatic refresh
- ✅ **Profile Management**: User profiles and preferences
- ✅ **Security Features**: Keychain storage, biometric auth
- ✅ **Session Management**: Multi-device support
- ✅ **Admin Operations**: User administration

**Difficulty**: Intermediate to Advanced  
**Time to Complete**: 45-60 minutes  
**[👉 Start Tutorial](./user_service/README.md)**

**Key Concepts Covered**:
- Secure token storage
- Session management
- Profile updates
- Error recovery
- Security best practices

---

### 3. Basic Example 🌱
**Best for: Quick prototype**

A minimal example perfect for understanding the basics:
- ✅ **Simple Service**: Basic CRUD operations
- ✅ **Minimal Setup**: Get started in 5 minutes
- ✅ **Core Patterns**: Essential Axiom patterns
- ✅ **Clean Code**: Well-documented and simple

**Difficulty**: Beginner  
**Time to Complete**: 10-15 minutes  
**[👉 View Code](./basic/)**

---

## 🎓 Learning Path

### For Beginners
1. **Start Here**: [Basic Example](./basic/) (10 mins)
2. **Core Concepts**: [Task Manager](./task_manager/README.md) (30 mins)
3. **Practice**: Create your own simple service
4. **Advanced**: [User Service](./user_service/README.md) (45 mins)

### For Experienced Developers
1. **Quick Overview**: [Task Manager](./task_manager/README.md) (skim)
2. **Authentication**: [User Service](./user_service/README.md) (focus)
3. **Custom Implementation**: Build your own service
4. **Optimization**: Performance and scaling patterns

### For Teams
1. **Architecture Review**: Study the generated code structure
2. **Standards**: Establish coding conventions
3. **Integration**: Plan framework integration
4. **Training**: Team workshops using examples

## 📋 Feature Comparison

| Feature | Basic | Task Manager | User Service |
|---------|-------|--------------|--------------|
| CRUD Operations | ✅ | ✅ | ✅ |
| State Management | ✅ | ✅ | ✅ |
| Validation | ⚠️ Basic | ✅ Advanced | ✅ Advanced |
| Search/Filter | ❌ | ✅ | ✅ |
| Pagination | ❌ | ✅ | ✅ |
| Authentication | ❌ | ❌ | ✅ |
| Real-time Updates | ✅ | ✅ | ✅ |
| Error Handling | ⚠️ Basic | ✅ Comprehensive | ✅ Comprehensive |
| Testing | ❌ | ✅ | ✅ |
| Documentation | ⚠️ Basic | ✅ Complete | ✅ Complete |

## 🏗️ Best Practices

### 1. Project Structure
```
MyApp/
├── Generated/           # Generated Swift clients
│   ├── TaskManager/
│   └── UserService/
├── Services/           # Your business logic
│   ├── TaskService.swift
│   └── AuthService.swift
├── ViewModels/         # MVVM view models
├── Views/             # SwiftUI views
└── Utils/             # Helpers and extensions
```

### 2. Dependency Management
```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/axiom/axiom-core", from: "1.0.0"),
    .package(url: "https://github.com/axiom/axiom-architecture", from: "1.0.0")
]
```

### 3. Error Handling Pattern
```swift
@MainActor
class BaseViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    
    func handleError(_ error: Error) {
        self.isLoading = false
        
        if let axiomError = error as? AxiomError {
            self.error = axiomError.localizedDescription
            
            // Handle specific error types
            switch axiomError.category() {
            case .validation:
                // Show validation errors
                break
            case .network:
                // Show network error with retry option
                break
            default:
                // Generic error handling
                break
            }
        } else {
            self.error = error.localizedDescription
        }
    }
}
```

### 4. State Observation Pattern
```swift
class FeatureViewModel: BaseViewModel {
    private let client: SomeClient
    private var stateObserver: Task<Void, Never>?
    
    init() {
        super.init()
        observeState()
    }
    
    private func observeState() {
        stateObserver = Task {
            for await state in client.stateStream {
                await MainActor.run {
                    self.updateUI(with: state)
                }
            }
        }
    }
    
    deinit {
        stateObserver?.cancel()
    }
}
```

## 🔧 Development Workflow

### 1. Design Phase
1. **Define Proto Schema**: Design your service API
2. **Plan State Structure**: Determine state management needs
3. **Identify Actions**: List all user actions
4. **Validate Design**: Review with team

### 2. Generation Phase
```bash
# Generate with validation
axiom-client-generator generate \
  --proto-path ./proto/my_service.proto \
  --output-path ./Generated \
  --languages swift \
  --validate \
  --verbose

# Check generated documentation
open ./Generated/swift/Documentation/README.md
```

### 3. Integration Phase
1. **Add Generated Files**: Import into Xcode project
2. **Create View Models**: Wrap clients in MVVM pattern
3. **Build UI**: Create SwiftUI views
4. **Add Tests**: Unit and integration tests
5. **Document Usage**: Update team documentation

### 4. Optimization Phase
1. **Profile Performance**: Identify bottlenecks
2. **Optimize State**: Reduce unnecessary updates
3. **Cache Strategy**: Implement appropriate caching
4. **Error Recovery**: Add robust error handling

## 🛠️ Customization

### Custom Proto Options
```proto
service MyService {
  option (axiom.service_options) = {
    client_name: "MyCustomClient"
    state_name: "MyCustomState"
    collections: [
      {
        name: "items"
        item_type: "MyItem"
        max_cached_items: 1000
        searchable: true
        sortable: true
      }
    ]
  };
}
```

### Custom Validation
```swift
extension MyAction {
    var customValidation: [String] {
        var errors: [String] = []
        
        switch self {
        case .createItem(let request):
            if request.name.count < 3 {
                errors.append("Name must be at least 3 characters")
            }
            if !request.email.isValidEmail {
                errors.append("Invalid email format")
            }
        }
        
        return errors
    }
}
```

### Custom Extensions
```swift
extension MyState {
    var sortedItems: [MyItem] {
        items.sorted { $0.createdAt > $1.createdAt }
    }
    
    var itemsByCategory: [String: [MyItem]] {
        Dictionary(grouping: items) { $0.category }
    }
    
    func items(matching query: String) -> [MyItem] {
        guard !query.isEmpty else { return items }
        return items.filter { 
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.description.localizedCaseInsensitiveContains(query)
        }
    }
}
```

## 🧪 Testing

### Unit Testing
```swift
class MyServiceTests: XCTestCase {
    var client: MyClient!
    
    override func setUp() {
        super.setUp()
        client = MyClient()
    }
    
    func testActionValidation() {
        let action = MyAction.create(.init(name: ""))
        XCTAssertFalse(action.isValid)
        XCTAssertTrue(action.validationErrors.contains("Name cannot be empty"))
    }
    
    func testStateUpdate() async throws {
        let initialState = await client.getCurrentState()
        let item = MyItem(id: "1", name: "Test")
        
        try await client.process(.create(.init(name: "Test")))
        
        let newState = await client.getCurrentState()
        XCTAssertEqual(newState.items.count, initialState.items.count + 1)
    }
}
```

### Integration Testing
```swift
class IntegrationTests: XCTestCase {
    func testFullWorkflow() async throws {
        let client = TaskManagerClient()
        
        // Create a task
        try await client.process(.createTask(.init(title: "Test Task")))
        
        // Verify it exists
        let state = await client.getCurrentState()
        XCTAssertFalse(state.tasks.isEmpty)
        
        // Update the task
        let task = state.tasks.first!
        try await client.process(.updateTask(.init(
            taskId: task.id,
            title: "Updated Task"
        )))
        
        // Verify update
        let updatedState = await client.getCurrentState()
        XCTAssertEqual(updatedState.tasks.first?.title, "Updated Task")
    }
}
```

## 🚨 Troubleshooting

### Common Issues

#### 1. Generation Errors
```bash
# Problem: Proto file not found
# Solution: Check path and ensure file exists
ls -la path/to/your/proto/file.proto

# Problem: Validation failures
# Solution: Run with detailed validation
axiom-client-generator validate \
  --path ./generated \
  --detailed \
  --categorize
```

#### 2. Compilation Errors
```swift
// Problem: AxiomClient not found
// Solution: Add required imports
import AxiomCore
import AxiomArchitecture

// Problem: Actor isolation errors
// Solution: Use await for actor methods
let state = await client.getCurrentState()
```

#### 3. Runtime Issues
```swift
// Problem: State not updating
// Solution: Ensure proper observation
private func observeState() {
    stateObserver = Task {
        for await state in client.stateStream {
            await MainActor.run {
                self.updateUI(with: state)
            }
        }
    }
}
```

### Getting Help

1. **Documentation**: Check generated docs first
2. **Examples**: Review similar patterns in examples
3. **Validation**: Run `axiom-client-generator doctor`
4. **Verbose Logging**: Use `--verbose` flag
5. **Community**: Ask questions in discussions

## 🌟 Contributing

### Adding New Examples
1. Create new directory under `examples/`
2. Add comprehensive proto file
3. Write step-by-step tutorial
4. Include complete SwiftUI implementation
5. Add unit tests
6. Update this README

### Improving Existing Examples
1. Fork the repository
2. Make improvements
3. Test thoroughly
4. Submit pull request
5. Update documentation

## 📖 Additional Resources

### Documentation
- [API Reference](../generated/swift/Documentation/APIReference.md)
- [Integration Guide](../generated/swift/Documentation/IntegrationGuide.md)
- [Troubleshooting Guide](../generated/swift/Documentation/Troubleshooting.md)

### Tools
- [Axiom CLI Commands](../docs/cli-commands.md)
- [Proto Conventions](../docs/proto-conventions.md)
- [Performance Guide](../docs/performance.md)

### Community
- [Discussions](https://github.com/axiom/discussions)
- [Issue Tracker](https://github.com/axiom/issues)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/axiom-framework)

---

## 🎉 Success!

You're now ready to build amazing iOS and macOS applications with the Axiom Swift Client Generator! 

### What's Next?
1. **Try the Examples**: Start with the basic example
2. **Build Something**: Create your own service
3. **Share Your Experience**: Help improve the examples
4. **Join the Community**: Connect with other developers

Happy coding! 🚀

---

*Generated by Axiom Swift Client Generator - Making iOS development delightful since 2024*