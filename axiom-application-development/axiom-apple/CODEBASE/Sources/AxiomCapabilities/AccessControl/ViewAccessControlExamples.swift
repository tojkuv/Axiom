import Foundation
import SwiftUI
import Combine
import AxiomCore

// MARK: - Presentation Component Examples

/// Example of a presentation component that can observe contexts
/// Manages complex state and coordinates multiple UI elements
public class DashboardCoordinator: ObservableObject, PresentationComponent {
    
    public let presentationId = UUID()
    public let presentationName = "Dashboard Coordinator"
    
    @Published public var isLoading = false
    @Published public var userProfile: UserProfile?
    @Published public var dashboardData: DashboardData?
    
    private var uiContext: UIContext?
    private var dataContext: DataContext?
    private var cancellables = Set<AnyCancellable>()
    
    public private(set) var observedContexts: [UUID] = []
    
    public init() {}
    
    /// Setup context observations - only presentation components can do this
    public func setupContexts() async throws {
        // Create contexts
        let uiContext = UIContext(name: "Dashboard UI Context")
        let dataContext = DataContext(name: "Dashboard Data Context")
        
        // Register observations (access control enforced here)
        try await uiContext.allowObservation(by: self)
        try await dataContext.allowObservation(by: self)
        
        self.uiContext = uiContext
        self.dataContext = dataContext
        
        // Set up data binding
        setupDataBinding()
    }
    
    public func willStartObserving(context: AxiomContext) {
        observedContexts.append(context.id)
        print("✅ DashboardCoordinator started observing context: \(context.name)")
    }
    
    public func willStopObserving(context: AxiomContext) {
        observedContexts.removeAll { $0 == context.id }
        print("🔄 DashboardCoordinator stopped observing context: \(context.name)")
    }
    
    /// Load dashboard data using contexts
    public func loadDashboard() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Use data context to fetch data
        guard let dataContext = dataContext else { return }
        
        // Access local capabilities through context
        let coreDataCapability = try await dataContext.capability(CoreDataCapability.self)
        
        // Simulate data loading
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        await MainActor.run {
            self.userProfile = UserProfile(name: "John Doe", email: "john@example.com")
            self.dashboardData = DashboardData(stats: ["Active": 42, "Pending": 12])
        }
    }
    
    private func setupDataBinding() {
        // Bind to context changes
        // This is where presentation components coordinate between contexts and views
    }
}

/// Example SwiftUI presentation component
public struct DashboardScreen: View, PresentationComponent {
    
    public let presentationId = UUID()
    public let presentationName = "Dashboard Screen"
    
    @StateObject private var coordinator = DashboardCoordinator()
    @State private var observedContexts: [UUID] = []
    
    public var body: some View {
        VStack(spacing: 20) {
            // Header section with simple views
            DashboardHeaderView(
                title: "Dashboard",
                subtitle: "Welcome back!",
                isLoading: coordinator.isLoading
            )
            
            // User profile section
            if let profile = coordinator.userProfile {
                UserProfileCardView(profile: profile)
            }
            
            // Stats section
            if let data = coordinator.dashboardData {
                DashboardStatsView(stats: data.stats)
            }
            
            Spacer()
        }
        .padding()
        .task {
            try? await coordinator.setupContexts()
            try? await coordinator.loadDashboard()
        }
    }
    
    public func willStartObserving(context: AxiomContext) {
        observedContexts.append(context.id)
    }
    
    public func willStopObserving(context: AxiomContext) {
        observedContexts.removeAll { $0 == context.id }
    }
}

// MARK: - Simple View Examples

/// Example of a simple view that CANNOT observe contexts
/// Only receives data through parameters - pure presentation
public struct DashboardHeaderView: View, SimpleView {
    let title: String
    let subtitle: String
    let isLoading: Bool
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                if isLoading {
                    LoadingIndicatorView()
                }
            }
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

/// Another simple view - cannot access contexts
public struct UserProfileCardView: View, SimpleView {
    let profile: UserProfile
    
    public var body: some View {
        HStack(spacing: 12) {
            AvatarView(initials: String(profile.name.prefix(2)))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(.headline)
                
                Text(profile.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

/// Simple view for displaying statistics
public struct DashboardStatsView: View, SimpleView {
    let stats: [String: Int]
    
    public var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            ForEach(Array(stats.keys.sorted()), id: \.self) { key in
                StatCardView(
                    title: key,
                    value: stats[key] ?? 0
                )
            }
        }
    }
}

/// Atomic simple view component
public struct StatCardView: View, SimpleView {
    let title: String
    let value: Int
    
    public var body: some View {
        VStack(spacing: 8) {
            Text("\(value)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

/// Another atomic simple view
public struct AvatarView: View, SimpleView {
    let initials: String
    
    public var body: some View {
        Text(initials)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .frame(width: 40, height: 40)
            .background(Color.blue)
            .clipShape(Circle())
    }
}

/// Loading indicator simple view
public struct LoadingIndicatorView: View, SimpleView {
    public var body: some View {
        ProgressView()
            .scaleEffect(0.8)
    }
}

// MARK: - Context Restricted Components

/// Example of a component that is explicitly restricted from context access
public struct BannerAdView: View, ContextRestrictedComponent {
    let adContent: String
    let onTap: () -> Void
    
    public var body: some View {
        Button(action: onTap) {
            Text(adContent)
                .font(.caption)
                .padding()
                .background(Color.yellow.opacity(0.3))
                .cornerRadius(4)
        }
    }
}

/// Another restricted component - third-party widget
public struct ThirdPartyWidget: View, ContextRestrictedComponent {
    let configuration: WidgetConfiguration
    
    public var body: some View {
        Text("Third Party Widget")
            .font(.caption)
            .padding()
            .border(Color.gray)
    }
}

// MARK: - Supporting Data Types

public struct UserProfile: Sendable {
    let name: String
    let email: String
}

public struct DashboardData: Sendable {
    let stats: [String: Int]
}

public struct WidgetConfiguration: Sendable {
    let title: String
    let data: [String: Any]
    
    init(title: String, data: [String: Any] = [:]) {
        self.title = title
        self.data = data
    }
}

// MARK: - Example Contexts

/// Example UI context for demonstration
public class UIContext: AxiomContext {
    
    public override func onRegistered() async {
        print("✅ UI Context registered: \(name)")
    }
    
    public func updateTheme() async throws {
        let renderingCapability = try await capability(SwiftUIRenderingCapability.self)
        // Update UI theme using local capability
    }
}

/// Example data context for demonstration
public class DataContext: AxiomContext {
    
    public override func onRegistered() async {
        print("✅ Data Context registered: \(name)")
    }
    
    public func saveUserProfile(_ profile: UserProfile) async throws {
        let coreDataCapability = try await capability(CoreDataCapability.self)
        // Save data using local capability
    }
}

// MARK: - Access Violation Examples

/// ❌ This would violate access control - simple view trying to observe context
public struct ViolatingSimpleView: View, SimpleView {
    // This would fail at runtime
    // @ObservedContext var context: UIContext // Compiler error + runtime error
    
    public var body: some View {
        Text("I'm a simple view that cannot observe contexts")
            .onAppear {
                // This would also fail
                // let context = UIContext()
                // try await context.allowObservation(by: self) // Runtime error
            }
    }
}

/// ❌ This shows how access violations are caught
public class ViolationDemonstrator {
    
    public static func demonstrateViolations() async {
        print("\n🚫 Demonstrating View Access Control Violations")
        print("-" * 45)
        
        let context = UIContext(name: "Test Context")
        let simpleView = MockSimpleView()
        let restrictedComponent = MockRestrictedComponent()
        
        // Try to make simple view observe context
        do {
            try await ViewAccessControlManager.shared.validateContextObservation(
                component: simpleView,
                context: context
            )
            print("   ⚠️ This should not succeed!")
        } catch ViewAccessError.simpleViewCannotObserveContext(let viewType, let contextName) {
            print("   ✅ Correctly blocked simple view access")
            print("   ✅ Error: \(viewType) cannot observe \(contextName)")
        } catch {
            print("   ❌ Unexpected error: \(error)")
        }
        
        // Try to make restricted component observe context
        do {
            try await ViewAccessControlManager.shared.validateContextObservation(
                component: restrictedComponent,
                context: context
            )
            print("   ⚠️ This should not succeed!")
        } catch ViewAccessError.contextAccessRestricted(let componentType, let contextName) {
            print("   ✅ Correctly blocked restricted component access")
            print("   ✅ Error: \(componentType) is restricted from \(contextName)")
        } catch {
            print("   ❌ Unexpected error: \(error)")
        }
        
        // Show successful access by presentation component
        let presentationComponent = MockPresentationComponent()
        do {
            try await ViewAccessControlManager.shared.validateContextObservation(
                component: presentationComponent,
                context: context
            )
            print("   ✅ Correctly allowed presentation component access")
        } catch {
            print("   ❌ Unexpected error: \(error)")
        }
    }
}

// MARK: - Mock Components for Testing

private class MockSimpleView: SimpleView {}

private class MockRestrictedComponent: ContextRestrictedComponent {}

private class MockPresentationComponent: PresentationComponent {
    let presentationId = UUID()
    let presentationName = "Mock Presentation Component"
    let observedContexts: [UUID] = []
}

// MARK: - Architecture Documentation

/// Complete view access control architecture documentation
public enum ViewAccessControlArchitecture {
    
    public static let documentation = """
    AxiomApple Framework View Access Control Architecture:
    
    🏗️ **Hierarchical Access Control:**
    
    1. **Contexts** (Device Capabilities)
       ↓ can only be observed by ↓
    2. **Presentation Components** (State Management)
       ↓ pass data to ↓  
    3. **Simple Views** (Pure Presentation)
    
    📱 **Component Classification:**
    
    **Presentation Components (Can Observe Contexts):**
    - Coordinators, ViewControllers, Screens
    - Manage state and business logic
    - Coordinate between contexts and views
    - Examples: DashboardCoordinator, SettingsScreen
    
    **Simple Views (Cannot Observe Contexts):**
    - Pure UI components, buttons, labels
    - Only receive data through parameters
    - No state management or business logic
    - Examples: StatCardView, AvatarView, LoadingIndicator
    
    **Context Restricted Components:**
    - Explicitly forbidden from context access
    - Third-party components, ads, widgets
    - Examples: BannerAdView, ThirdPartyWidget
    
    🔒 **Access Control Rules:**
    
    ✅ Presentation Component → Context (Allowed)
    ❌ Simple View → Context (Blocked)
    ❌ Restricted Component → Context (Blocked)
    
    📊 **Data Flow Pattern:**
    
    External API → Client → Context → Presentation Component → Simple Views
    
    This ensures:
    - Clean separation of concerns
    - Predictable data flow
    - Testable components
    - No prop drilling
    - Clear responsibilities
    """
}

extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}