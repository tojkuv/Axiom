# Implicit Action Flow Visualization

## Complete Task Creation Form - Action Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         TaskCreationRootContext                              │
│  Handles: .validationStateChanged, .taskCreated, .creationFailed,           │
│           .cancelRequested                                                   │
│  State: canSave, showError, errorMessage                                    │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        TaskFormContext                                │   │
│  │  Handles: all field actions, .saveRequested                         │   │
│  │  State: isValid, validationErrors                                   │   │
│  │  ┌───────────────┐ ┌──────────────────┐ ┌───────────────────┐     │   │
│  │  │TitleFieldCtx  │ │DescriptionField │ │CategoryPickerCtx  │     │   │
│  │  │               │ │    Context       │ │                   │     │   │
│  │  │ emit:         │ │ emit:            │ │ emit:             │     │   │
│  │  │ .titleChanged │ │ .descChanged     │ │ .categorySelected │     │   │
│  │  │ .titleValid   │ │                  │ │                   │     │   │
│  │  └───────────────┘ └──────────────────┘ └───────────────────┘     │   │
│  │  ┌───────────────┐ ┌──────────────────┐                           │   │
│  │  │PriorityPicker │ │DueDatePickerCtx  │                           │   │
│  │  │    Context    │ │                  │                           │   │
│  │  │ emit:         │ │ emit:            │                           │   │
│  │  │ .priorityChg  │ │ .dueDateChanged  │                           │   │
│  │  └───────────────┘ └──────────────────┘                           │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Action Flow Examples

### 1. User Types in Title Field

```
User Input: "New Task Title"
    │
    ↓
TitleFieldContext
    ├─ emit(.titleChanged("New Task Title"))
    │   ↓
    │   TaskFormContext.handleChildAction()
    │       ├─ Updates internal state
    │       ├─ Calls validateForm()
    │       └─ emit(.validationStateChanged(true, []))
    │           ↓
    │           TaskCreationRootContext.handleChildAction()
    │               └─ Updates canSave = true
    │
    └─ After 500ms debounce:
        emit(.titleValidation(true, nil))
            ↓
            TaskFormContext.handleChildAction()
                ├─ Updates titleError = nil
                └─ Calls validateForm()
```

### 2. User Taps Save Button

```
User Action: Tap Save
    │
    ↓
TaskCreationRootContext.save()
    ├─ emit(.saveRequested)
    │   ↓
    │   (Captured by self, but also propagated to children)
    │   ↓
    │   TaskFormContext.handleChildAction()
    │       ├─ Validates isValid == true
    │       ├─ Creates Task object
    │       └─ emit(.taskCreated(task))
    │           ↓
    │           TaskCreationRootContext.handleChildAction()
    │               ├─ Calls client.process(.addTask(...))
    │               └─ On success: emit(.dismissed)
    │
    └─ If validation fails:
        TaskFormContext emits .creationFailed(error)
            ↓
            TaskCreationRootContext shows error alert
```

### 3. Complex Validation Flow

```
User selects past due date
    │
    ↓
DueDatePickerContext
    └─ emit(.dueDateChanged(pastDate))
        ↓
        TaskFormContext.handleChildAction()
            ├─ Detects invalid date
            ├─ Adds error: "Due date must be in the future"
            └─ emit(.validationStateChanged(false, ["Due date..."]))
                ↓
                TaskCreationRootContext.handleChildAction()
                    └─ Updates canSave = false (Save button disabled)
```

## Key Patterns Demonstrated

### 1. Selective Action Handling
```swift
// TaskFormContext handles field actions but not .dismissed
override func handleChildAction<T>(_ action: T, from child: Context) {
    switch action {
    case TaskCreationAction.titleChanged:
        // Handle this
    case TaskCreationAction.dismissed:
        emit(action) // Let parent handle
    }
}
```

### 2. Action Transformation
```swift
// Field emits granular change, form emits aggregate state
case .titleChanged, .descriptionChanged, .priorityChanged:
    validateForm()
    emit(.validationStateChanged(isValid: isValid, errors: errors))
```

### 3. Async Action Handling
```swift
// Title validation happens asynchronously
TitleFieldContext:
    - Immediate: emit(.titleChanged)
    - After 500ms: emit(.titleValidation)
```

### 4. Error Propagation
```swift
// Errors bubble up to appropriate handler
Field → Form → Root
         ↓
    Form handles validation errors
         ↓
    Root handles system errors (save failures)
```

## Benefits of This Architecture

1. **Clear Responsibilities**
   - Fields: Handle input and field-level validation
   - Form: Aggregate validation and create domain objects
   - Root: Handle navigation and persistence

2. **Testability**
   - Each level can be tested independently
   - Actions can be verified at each level
   - No complex mocking required

3. **Maintainability**
   - Adding new fields just requires adding contexts
   - Validation logic is localized
   - Navigation logic separated from form logic

4. **Type Safety**
   - Single TaskCreationAction enum
   - Compiler ensures all actions handled
   - No stringly-typed events

5. **Performance**
   - Minimal overhead from action routing
   - Debouncing built into async validations
   - No unnecessary re-renders