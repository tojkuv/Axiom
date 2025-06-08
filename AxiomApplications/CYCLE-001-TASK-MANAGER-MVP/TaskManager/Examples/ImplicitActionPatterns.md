# Implicit Action Subscription Patterns

## Overview

Implicit action subscription is a powerful pattern in the Axiom framework that enables parent contexts to automatically receive and handle actions emitted by their child contexts without explicit subscription setup. This document demonstrates comprehensive patterns and best practices.

## Core Concepts

### 1. Action Flow

```
TitleFieldContext ──emit(.titleChanged)──┐
                                         ↓
DescriptionFieldContext ──emit(...)──→ TaskFormContext ──emit(.validationChanged)──┐
                                         ↑                                          ↓
CategoryPickerContext ──emit(...)────────┘                                         ↓
                                                                                    ↓
                                                              TaskCreationRootContext
                                                                    (handles all)
```

### 2. Key Benefits

- **Zero Boilerplate**: No subscription setup code needed
- **Type Safety**: Compiler ensures proper action types
- **Selective Handling**: Parents handle only actions they care about
- **Automatic Propagation**: Unhandled actions bubble up automatically
- **Memory Safe**: No retain cycles from subscriptions

## Pattern Examples

### Basic Parent-Child Communication

```swift
// Child emits actions
class FieldContext: Context {
    func userTapped() {
        emit(.fieldTapped)
    }
}

// Parent receives actions implicitly
class FormContext: Context {
    override func handleChildAction<T>(_ action: T, from child: Context) {
        switch action {
        case MyActions.fieldTapped:
            updateFormState()
        default:
            emit(action) // Propagate unhandled actions
        }
    }
}
```

### Multi-Level Hierarchy

The comprehensive example shows a 3-level hierarchy:

1. **Root Level** (`TaskCreationRootContext`)
   - Handles navigation and persistence
   - Responds to form validation state
   - Manages error presentation

2. **Form Level** (`TaskFormContext`)
   - Aggregates field validations
   - Manages form-wide state
   - Emits validation summaries

3. **Field Level** (Various field contexts)
   - Handle user input
   - Perform field-specific validation
   - Emit granular changes

### Async Action Handling

```swift
class AsyncValidationContext: Context {
    func validateAsync() {
        Task { @MainActor in
            let result = await performValidation()
            emit(.validationComplete(result))
        }
    }
}
```

### Selective Action Handling

Parents can choose which actions to handle:

```swift
override func handleChildAction<T>(_ action: T, from child: Context) {
    guard let appAction = action as? AppAction else { return }
    
    switch appAction {
    case .criticalAction:
        handleCritical()  // Handle this one
    default:
        emit(action)      // Let parent handle others
    }
}
```

## Best Practices

### 1. Action Design

```swift
// Good: Specific, well-typed actions
enum TaskActions {
    case titleChanged(String)
    case validationFailed(field: String, error: Error)
    case saveRequested(Task)
}

// Bad: Generic, untyped actions
enum GenericActions {
    case somethingChanged
    case error(Any)
}
```

### 2. Context Hierarchy

- Match context hierarchy to view hierarchy
- Each context should have a single responsibility
- Use composition over deep inheritance

### 3. Testing Strategies

```swift
// Test individual contexts
func testFieldValidation() {
    let field = FieldContext()
    let harness = TestHarness(field)
    
    field.updateValue("test")
    
    XCTAssertEqual(harness.capturedActions.count, 1)
}

// Test integration
func testFormFlow() {
    let root = RootContext()
    // Test complete flow
}
```

### 4. Performance Considerations

- Actions are delivered synchronously by default
- Use `Task { }` for expensive operations
- Batch related actions when possible
- Profile action routing in performance-critical paths

## Anti-Patterns to Avoid

### 1. Circular Action Dependencies

```swift
// BAD: Can create infinite loops
class ParentContext {
    func handleChildAction(...) {
        emit(.parentChanged) // Child might react to this
    }
}
```

### 2. Over-Broad Action Types

```swift
// BAD: Too generic
enum Actions {
    case update(Any)
}

// GOOD: Specific
enum UserActions {
    case nameUpdated(String)
    case emailUpdated(String)
}
```

### 3. Skipping Hierarchy Levels

```swift
// BAD: Grandchild trying to communicate directly with grandparent
class GrandchildContext {
    func notifyGrandparent() {
        emit(.grandparentSpecificAction) // Will go through parent first
    }
}
```

## Migration Guide

### From Explicit to Implicit Actions

**Before (Explicit):**
```swift
class ParentContext {
    func setupChild(_ child: ChildContext) {
        child.actionPublisher
            .sink { [weak self] action in
                self?.handleAction(action)
            }
            .store(in: &cancellables)
    }
}
```

**After (Implicit):**
```swift
class ParentContext {
    override func handleChildAction<T>(_ action: T, from child: Context) {
        // Handle actions directly
    }
}
```

## Advanced Patterns

### 1. Action Transformation

```swift
class FormContext {
    override func handleChildAction<T>(_ action: T, from child: Context) {
        switch action {
        case FieldAction.changed(let value):
            // Transform field action to form action
            emit(FormAction.fieldUpdated(fieldId: child.id, value: value))
        default:
            emit(action)
        }
    }
}
```

### 2. Action Filtering

```swift
class FilteringContext {
    var isEnabled = true
    
    override func handleChildAction<T>(_ action: T, from child: Context) {
        guard isEnabled else { return } // Filter when disabled
        
        // Process action
        super.handleChildAction(action, from: child)
    }
}
```

### 3. Action Aggregation

```swift
class AggregatingContext {
    private var pendingActions: [Action] = []
    
    override func handleChildAction<T>(_ action: T, from child: Context) {
        if let action = action as? DeferrableAction {
            pendingActions.append(action)
            scheduleFlush()
        } else {
            emit(action) // Immediate actions
        }
    }
    
    private func flushActions() {
        emit(BatchAction(actions: pendingActions))
        pendingActions.removeAll()
    }
}
```

## Framework Integration

The implicit action system integrates with other Axiom patterns:

1. **With Navigation**: Actions can trigger navigation
2. **With State Management**: Actions update state atomically
3. **With Error Boundaries**: Errors in action handlers are caught
4. **With Testing**: Test harnesses can intercept actions

## Summary

Implicit action subscription provides a clean, type-safe way to handle parent-child communication in the Axiom framework. By following these patterns and best practices, you can build maintainable, testable applications with clear architectural boundaries.