# View Implementation Guide

Comprehensive guide for implementing SwiftUI views with 1:1 context relationships and reactive binding in the Axiom framework.

## Overview

AxiomView defines the presentation layer that maintains a strict 1:1 relationship with AxiomContext. Views observe context state through reactive binding and trigger actions through context orchestration.

## 1:1 View-Context Relationship

### Core Principles

1. **Single Context**: Each view has exactly one primary context
2. **Reactive Binding**: Views automatically update when context state changes
3. **Action Delegation**: All business logic is delegated to context
4. **Architectural Constraint**: 1:1 relationship is enforced at compile-time and runtime

### Basic Implementation

```swift
import Axiom
import SwiftUI

// Manual view implementation
struct UserView: AxiomView {
    @ObservedObject var context: UserContext
    
    var body: some View {
        VStack(spacing: 16) {
            Text("User Profile")
                .font(.title)
            
            TextField("Name", text: context.bind(\.name))
            TextField("Email", text: context.bind(\.email))
            
            Button("Save") {
                Task {
                    await context.saveUserProfile()
                }
            }
        }
        .padding()
    }
    
    // AxiomView protocol requirements
    func handleStateChange() {
        // Custom state change handling if needed
        // Usually automatic through @ObservedObject
    }
    
    func validateArchitecturalConstraints() -> Bool {
        // Validate 1:1 relationship
        return true
    }
}
```

### Macro-Generated Implementation

```swift
// Automatic view generation using @View macro
@View(context: UserContext)
struct UserView {
    var body: some View {
        VStack {
            Text("Welcome, \(context.bind(\.name).wrappedValue)!")
            Button("Logout") {
                Task {
                    await context.logout()
                }
            }
        }
    }
}

// Generated code:
struct UserView: AxiomView {
    @ObservedObject var context: UserContext
    
    init(context: UserContext) {
        self.context = context
    }
    
    func handleStateChange() {
        // Framework-generated state change handling
    }
    
    func validateArchitecturalConstraints() -> Bool {
        // Framework-generated constraint validation
        return true
    }
    
    // User-provided body is preserved
    var body: some View {
        VStack {
            Text("Welcome, \(context.bind(\.name).wrappedValue)!")
            Button("Logout") {
                Task {
                    await context.logout()
                }
            }
        }
    }
}
```

## Reactive Binding

### Basic State Binding

```swift
struct UserView: AxiomView {
    @ObservedObject var context: UserContext
    
    var body: some View {
        Form {
            Section("Personal Information") {
                // Direct property binding
                TextField("First Name", text: context.bind(\.firstName))
                TextField("Last Name", text: context.bind(\.lastName))
                TextField("Email", text: context.bind(\.email))
            }
            
            Section("Preferences") {
                // Nested property binding
                Toggle("Notifications", isOn: context.bind(\.preferences.notifications))
                Picker("Theme", selection: context.bind(\.preferences.theme)) {
                    Text("Light").tag(Theme.light)
                    Text("Dark").tag(Theme.dark)
                    Text("Auto").tag(Theme.auto)
                }
            }
            
            Section("Status") {
                // Read-only computed properties
                Text("Status: \(context.userStatus)")
                Text("Last Login: \(context.formattedLastLogin)")
                Text("Member Since: \(context.formattedMemberSince)")
            }
        }
    }
}
```

### Advanced Binding Patterns

```swift
extension UserView {
    // Conditional binding based on state
    private var conditionalContent: some View {
        Group {
            if context.bind(\.isLoggedIn).wrappedValue {
                AuthenticatedUserView(context: context)
            } else {
                LoginPromptView(context: context)
            }
        }
    }
    
    // Dynamic content based on state
    private var dynamicContent: some View {
        VStack {
            ForEach(context.bind(\.notifications).wrappedValue, id: \.id) { notification in
                NotificationRow(notification: notification) {
                    Task {
                        await context.markNotificationAsRead(notification.id)
                    }
                }
            }
        }
    }
    
    // Computed binding with transformation
    private var formattedContent: some View {
        VStack {
            Text(context.bindDerived(\.name) { name in
                name.isEmpty ? "No name set" : "Hello, \(name)!"
            })
            
            Text(context.bindDerived(\.createdAt) { date in
                "Member since \(DateFormatter.short.string(from: date))"
            })
        }
    }
}
```

### Two-way Data Flow

```swift
struct EditableUserView: AxiomView {
    @ObservedObject var context: UserContext
    @State private var isEditing = false
    
    var body: some View {
        VStack {
            if isEditing {
                EditingForm(context: context, isEditing: $isEditing)
            } else {
                ReadOnlyDisplay(context: context, isEditing: $isEditing)
            }
        }
    }
}

struct EditingForm: View {
    @ObservedObject var context: UserContext
    @Binding var isEditing: Bool
    
    var body: some View {
        Form {
            TextField("Name", text: context.bind(\.name))
            TextField("Email", text: context.bind(\.email))
            
            HStack {
                Button("Cancel") {
                    Task {
                        await context.revertChanges()
                        isEditing = false
                    }
                }
                
                Button("Save") {
                    Task {
                        await context.saveChanges()
                        isEditing = false
                    }
                }
                .disabled(!context.hasValidChanges)
            }
        }
    }
}
```

## SwiftUI Integration

### Lifecycle Integration

```swift
struct UserView: AxiomView {
    @ObservedObject var context: UserContext
    
    var body: some View {
        NavigationView {
            ContentView(context: context)
        }
        .onAppear {
            Task {
                await context.loadInitialData()
            }
        }
        .onDisappear {
            Task {
                await context.saveIfNeeded()
            }
        }
        .onChange(of: context.bind(\.preferences.theme).wrappedValue) { newTheme in
            Task {
                await context.applyTheme(newTheme)
            }
        }
    }
}

private struct ContentView: View {
    @ObservedObject var context: UserContext
    
    var body: some View {
        List {
            ProfileSection(context: context)
            PreferencesSection(context: context)
            ActionsSection(context: context)
        }
        .refreshable {
            await context.refresh()
        }
    }
}
```

### Navigation Integration

```swift
struct MainAppView: AxiomView {
    @ObservedObject var context: AppContext
    
    var body: some View {
        NavigationStack(path: context.bind(\.navigationPath)) {
            TabView(selection: context.bind(\.selectedTab)) {
                HomeView(context: context.homeContext)
                    .tabItem { Label("Home", systemImage: "house") }
                    .tag(Tab.home)
                
                ProfileView(context: context.profileContext)
                    .tabItem { Label("Profile", systemImage: "person") }
                    .tag(Tab.profile)
                
                SettingsView(context: context.settingsContext)
                    .tabItem { Label("Settings", systemImage: "gear") }
                    .tag(Tab.settings)
            }
        }
        .sheet(item: context.bind(\.presentedSheet)) { sheet in
            SheetView(sheet: sheet, context: context)
        }
        .alert(item: context.bind(\.alertItem)) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK")) {
                    Task {
                        await context.dismissAlert()
                    }
                }
            )
        }
    }
}
```

### Environment Integration

```swift
struct UserView: AxiomView {
    @ObservedObject var context: UserContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        ContentView(context: context)
            .onChange(of: colorScheme) { newColorScheme in
                Task {
                    await context.updateColorScheme(newColorScheme)
                }
            }
            .onChange(of: scenePhase) { newPhase in
                Task {
                    await context.handleScenePhaseChange(newPhase)
                }
            }
    }
}
```

## State Updates

### Automatic Updates

```swift
struct UserView: AxiomView {
    @ObservedObject var context: UserContext
    
    var body: some View {
        VStack {
            // Automatic updates through binding
            Text("Name: \(context.bind(\.name).wrappedValue)")
            Text("Email: \(context.bind(\.email).wrappedValue)")
            Text("Status: \(context.bind(\.status).wrappedValue)")
            
            // Computed properties update automatically
            Text("Display Name: \(context.displayName)")
            Text("Member Since: \(context.membershipDuration)")
        }
    }
}
```

### Manual Update Triggers

```swift
struct UserView: AxiomView {
    @ObservedObject var context: UserContext
    @State private var refreshTrigger = false
    
    var body: some View {
        List {
            UserInfoSection(context: context)
            
            if refreshTrigger {
                ProgressView("Updating...")
                    .onAppear {
                        refreshTrigger = false
                    }
            }
        }
        .refreshable {
            refreshTrigger = true
            await context.forceRefresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: .userDataChanged)) { _ in
            Task {
                await context.handleExternalDataChange()
            }
        }
    }
}
```

### Optimistic Updates

```swift
struct OrderView: AxiomView {
    @ObservedObject var context: OrderContext
    @State private var optimisticUpdates: [String: Any] = [:]
    
    var body: some View {
        VStack {
            // Show optimistic state while update is in progress
            Text("Status: \(displayStatus)")
            
            Button("Update Order") {
                Task {
                    // Show optimistic update immediately
                    optimisticUpdates["status"] = "Updating..."
                    
                    do {
                        await context.updateOrder()
                        optimisticUpdates.removeAll()
                    } catch {
                        // Revert optimistic update on error
                        optimisticUpdates.removeAll()
                        await context.handleUpdateError(error)
                    }
                }
            }
        }
    }
    
    private var displayStatus: String {
        if let optimisticStatus = optimisticUpdates["status"] as? String {
            return optimisticStatus
        }
        return context.bind(\.status).wrappedValue
    }
}
```

## Complex View Composition

### Hierarchical Views

```swift
struct DashboardView: AxiomView {
    @ObservedObject var context: DashboardContext
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                HeaderSection(context: context)
                StatsSection(context: context)
                RecentActivitySection(context: context)
                QuickActionsSection(context: context)
            }
            .padding()
        }
    }
}

// Child views maintain reference to parent context
struct HeaderSection: View {
    @ObservedObject var context: DashboardContext
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Welcome back!")
                    .font(.title2)
                Text(context.bind(\.currentUser.name).wrappedValue)
                    .font(.title)
                    .bold()
            }
            
            Spacer()
            
            AsyncImage(url: context.bind(\.currentUser.avatarURL).wrappedValue) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 60, height: 60)
            .clipShape(Circle())
        }
    }
}
```

### Modal Presentations

```swift
struct MainView: AxiomView {
    @ObservedObject var context: MainContext
    
    var body: some View {
        NavigationView {
            ContentView(context: context)
        }
        .sheet(isPresented: context.bind(\.isPresentingUserSettings)) {
            UserSettingsView(context: context.userSettingsContext)
        }
        .fullScreenCover(isPresented: context.bind(\.isPresentingOnboarding)) {
            OnboardingView(context: context.onboardingContext)
        }
    }
}

struct UserSettingsView: AxiomView {
    @ObservedObject var context: UserSettingsContext
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                SettingsContent(context: context)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await context.saveSettings()
                            dismiss()
                        }
                    }
                    .disabled(!context.hasChanges)
                }
            }
        }
    }
}
```

### List and Collection Views

```swift
struct UserListView: AxiomView {
    @ObservedObject var context: UserListContext
    
    var body: some View {
        NavigationView {
            List {
                ForEach(context.bind(\.users).wrappedValue, id: \.id) { user in
                    UserRowView(user: user, context: context)
                }
                .onDelete { indexSet in
                    Task {
                        await context.deleteUsers(at: indexSet)
                    }
                }
            }
            .navigationTitle("Users")
            .searchable(text: context.bind(\.searchText))
            .refreshable {
                await context.refresh()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add User") {
                        Task {
                            await context.presentAddUser()
                        }
                    }
                }
            }
        }
    }
}

struct UserRowView: View {
    let user: User
    @ObservedObject var context: UserListContext
    
    var body: some View {
        HStack {
            AsyncImage(url: user.avatarURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text(user.name)
                    .font(.headline)
                Text(user.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if context.bind(\.selectedUsers).wrappedValue.contains(user.id) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            Task {
                await context.toggleUserSelection(user.id)
            }
        }
    }
}
```

## Performance Optimization

### Efficient View Updates

```swift
struct OptimizedUserView: AxiomView {
    @ObservedObject var context: UserContext
    
    var body: some View {
        VStack {
            // Use specific bindings to minimize updates
            ProfileHeader(
                name: context.bind(\.name).wrappedValue,
                avatar: context.bind(\.avatarURL).wrappedValue
            )
            
            // Conditional views to avoid unnecessary rendering
            if context.bind(\.isLoggedIn).wrappedValue {
                AuthenticatedContent(context: context)
            } else {
                LoginPrompt(context: context)
            }
        }
    }
}

// Extract stable subviews to reduce re-rendering
struct ProfileHeader: View {
    let name: String
    let avatar: URL?
    
    var body: some View {
        HStack {
            AsyncImage(url: avatar) { image in
                image.resizable()
            } placeholder: {
                Circle().fill(Color.gray)
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            Text(name)
                .font(.title2)
            
            Spacer()
        }
    }
}
```

### Lazy Loading

```swift
struct LazyContentView: AxiomView {
    @ObservedObject var context: ContentContext
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(context.bind(\.contentItems).wrappedValue, id: \.id) { item in
                    LazyItemView(item: item, context: context)
                        .onAppear {
                            Task {
                                await context.loadItemDetailsIfNeeded(item.id)
                            }
                        }
                }
            }
        }
    }
}

struct LazyItemView: View {
    let item: ContentItem
    @ObservedObject var context: ContentContext
    
    var body: some View {
        VStack {
            if let details = context.getItemDetails(item.id) {
                DetailedItemView(item: item, details: details)
            } else {
                PlaceholderItemView(item: item)
                    .redacted(reason: .placeholder)
            }
        }
    }
}
```

## Error Handling in Views

### Error State Display

```swift
struct RobustUserView: AxiomView {
    @ObservedObject var context: UserContext
    
    var body: some View {
        Group {
            switch context.loadingState {
            case .idle:
                ContentView(context: context)
                
            case .loading:
                LoadingView()
                
            case .loaded:
                LoadedContentView(context: context)
                
            case .error(let error):
                ErrorView(error: error) {
                    Task {
                        await context.retry()
                    }
                }
            }
        }
    }
}

struct ErrorView: View {
    let error: Error
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Try Again") {
                retryAction()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
```

## Testing Patterns

### View Testing

```swift
import XCTest
import SwiftUI
import ViewInspector
@testable import Axiom

final class UserViewTests: XCTestCase {
    @MainActor
    func testViewRendering() throws {
        let mockContext = MockUserContext()
        mockContext.setMockState(UserState(name: "Test User", email: "test@example.com"))
        
        let view = UserView(context: mockContext)
        let nameText = try view.inspect().find(text: "Test User")
        
        XCTAssertNotNil(nameText)
    }
    
    @MainActor
    func testUserInteraction() throws {
        let mockContext = MockUserContext()
        let view = UserView(context: mockContext)
        
        // Simulate button tap
        try view.inspect().find(button: "Save").tap()
        
        // Verify context method was called
        XCTAssertTrue(mockContext.saveUserProfileCalled)
    }
    
    @MainActor
    func testStateBinding() throws {
        let mockContext = MockUserContext()
        let view = UserView(context: mockContext)
        
        // Simulate text field input
        try view.inspect().find(ViewType.TextField.self).setInput("New Name")
        
        // Verify state was updated through binding
        XCTAssertEqual(mockContext.currentState.name, "New Name")
    }
}
```

## Best Practices

### Architecture

1. **1:1 Relationship**: Maintain exactly one context per view
2. **Delegate Actions**: Delegate all business logic to context
3. **Reactive Binding**: Use context bindings for all state access
4. **View Composition**: Break complex views into smaller components

### Performance

1. **Specific Bindings**: Bind to specific properties, not entire state
2. **Lazy Loading**: Load content on-demand
3. **View Stability**: Extract stable subviews to minimize re-rendering
4. **Conditional Rendering**: Use conditional views efficiently

### SwiftUI Integration

1. **ObservedObject**: Use @ObservedObject for context references
2. **Environment**: Leverage SwiftUI environment for cross-cutting concerns
3. **Lifecycle**: Handle view lifecycle events appropriately
4. **Navigation**: Integrate with SwiftUI navigation patterns

### Testing

1. **Mock Contexts**: Use mock contexts for view testing
2. **Interaction Testing**: Test user interactions and state changes
3. **Visual Testing**: Verify visual rendering and layout
4. **Performance Testing**: Validate view update performance

---

**View Implementation Guide** - Complete guide for SwiftUI view implementation with 1:1 context relationships, reactive binding, and architectural constraint compliance