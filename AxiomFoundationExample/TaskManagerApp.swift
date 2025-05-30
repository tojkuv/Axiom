import SwiftUI
import Axiom

// MARK: - Task Manager App

/// Complete example application demonstrating all Axiom features
/// Shows proper AxiomApplication setup and usage
@main
struct TaskManagerApp: App {
    
    // MARK: - Application State
    
    @StateObject private var application = TaskManagerApplication()
    @State private var isLaunched = false
    @State private var launchError: Error?
    
    // MARK: - App Body
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isLaunched {
                    MainContentView(application: application)
                } else if let error = launchError {
                    LaunchErrorView(error: error) {
                        Task {
                            await launchApplication()
                        }
                    }
                } else {
                    LaunchingView()
                }
            }
            .task {
                await launchApplication()
            }
        }
    }
    
    // MARK: - Launch Management
    
    private func launchApplication() async {
        do {
            try await application.onLaunch()
            await MainActor.run {
                isLaunched = true
                launchError = nil
            }
        } catch {
            await MainActor.run {
                launchError = error
                isLaunched = false
            }
        }
    }
}

// MARK: - Task Manager Application

/// Main application class implementing AxiomApplication
/// Demonstrates complete application configuration and lifecycle
@MainActor
final class TaskManagerApplication: DefaultAxiomApplication<TaskManagerConfiguration, DashboardContext> {
    
    // MARK: - Initialization
    
    override init() async {
        let config = TaskManagerConfiguration.development
        await super.init(configuration: config, contextFactory: TaskManagerContextFactory())
    }
    
    // MARK: - Root Context Creation
    
    func createDashboardContext() async throws -> DashboardContext {
        try await createRootContext()
    }
}

// MARK: - Application Configuration

/// Configuration for the Task Manager application
/// Demonstrates proper AxiomApplicationConfiguration implementation
struct TaskManagerConfiguration: AxiomApplicationConfiguration {
    
    public let availableCapabilities: Set<Capability>
    public let intelligenceFeatures: Set<IntelligenceFeature>
    public let capabilityValidationConfig: CapabilityValidationConfig
    public let performanceConfig: PerformanceConfiguration
    public let developmentConfig: DevelopmentConfiguration
    
    init(
        availableCapabilities: Set<Capability>,
        intelligenceFeatures: Set<IntelligenceFeature>,
        capabilityValidationConfig: CapabilityValidationConfig,
        performanceConfig: PerformanceConfiguration,
        developmentConfig: DevelopmentConfiguration
    ) {
        self.availableCapabilities = availableCapabilities
        self.intelligenceFeatures = intelligenceFeatures
        self.capabilityValidationConfig = capabilityValidationConfig
        self.performanceConfig = performanceConfig
        self.developmentConfig = developmentConfig
    }
    
    // MARK: - Predefined Configurations
    
    /// Production configuration for release builds
    static var production: TaskManagerConfiguration {
        TaskManagerConfiguration(
            availableCapabilities: [
                .storage, .network, .analytics, .notifications,
                .userDefaults, .businessLogic, .stateManagement
            ],
            intelligenceFeatures: [
                .architecturalDNA, .emergentPatternDetection,
                .selfOptimizingPerformance, .constraintPropagation
            ],
            capabilityValidationConfig: CapabilityValidationConfig(
                enableRuntimeValidation: true,
                enablePerformanceMonitoring: true,
                validationLevel: .strict
            ),
            performanceConfig: PerformanceConfiguration(
                samplingRate: 0.1,
                enableAlerts: true,
                enableAutomaticCleanup: true
            ),
            developmentConfig: .production
        )
    }
    
    /// Development configuration with enhanced debugging
    static var development: TaskManagerConfiguration {
        TaskManagerConfiguration(
            availableCapabilities: Set(Capability.allCases),
            intelligenceFeatures: Set(IntelligenceFeature.allCases),
            capabilityValidationConfig: CapabilityValidationConfig(
                enableRuntimeValidation: true,
                enablePerformanceMonitoring: true,
                validationLevel: .permissive
            ),
            performanceConfig: PerformanceConfiguration(
                samplingRate: 1.0,
                enableAlerts: true,
                enableAutomaticCleanup: false
            ),
            developmentConfig: .development
        )
    }
    
    /// Testing configuration for unit tests
    static var testing: TaskManagerConfiguration {
        TaskManagerConfiguration(
            availableCapabilities: [
                .businessLogic, .stateManagement, .testing
            ],
            intelligenceFeatures: [
                .architecturalDNA
            ],
            capabilityValidationConfig: CapabilityValidationConfig(
                enableRuntimeValidation: false,
                enablePerformanceMonitoring: false,
                validationLevel: .permissive
            ),
            performanceConfig: PerformanceConfiguration(
                samplingRate: 0.0,
                enableAlerts: false,
                enableAutomaticCleanup: true
            ),
            developmentConfig: DevelopmentConfiguration(
                enableDebugLogging: true,
                enablePerformanceLogging: false,
                enableIntelligenceDebugging: false
            )
        )
    }
}

// MARK: - Context Factory

/// Custom context factory for the Task Manager application
/// Demonstrates proper dependency injection and context creation
actor TaskManagerContextFactory: ContextFactory {
    
    private let clientFactory = TaskManagerClientFactory()
    
    func createContext<T: AxiomContext>(
        _ contextType: T.Type,
        capabilityManager: CapabilityManager,
        intelligence: AxiomIntelligence
    ) async throws -> T {
        
        if contextType == DashboardContext.self {
            let context = try await createDashboardContext(
                capabilityManager: capabilityManager,
                intelligence: intelligence
            )
            return context as! T
        }
        
        throw AxiomApplicationError.dependencyResolutionFailed("Unknown context type: \\(contextType)")
    }
    
    func configureContext<T: AxiomContext>(_ context: T) async throws {
        // Configure cross-cutting concerns
        // In a real implementation, this would set up logging, analytics, etc.
    }
    
    func validateContextDependencies<T: AxiomContext>(_ context: T) async throws {
        // Validate all dependencies are properly injected
        // This would include checking that all @Client properties are satisfied
    }
    
    // MARK: - Private Context Creation
    
    private func createDashboardContext(
        capabilityManager: CapabilityManager,
        intelligence: AxiomIntelligence
    ) async throws -> DashboardContext {
        
        // Create all required clients
        let taskClient = try await clientFactory.createTaskClient(capabilityManager: capabilityManager)
        let userClient = try await clientFactory.createUserClient(capabilityManager: capabilityManager)
        let projectClient = try await clientFactory.createProjectClient(capabilityManager: capabilityManager)
        let analyticsClient = try await clientFactory.createAnalyticsClient(capabilityManager: capabilityManager)
        let notificationClient = try await clientFactory.createNotificationClient(capabilityManager: capabilityManager)
        
        // Initialize all clients
        try await taskClient.initialize()
        try await userClient.initialize()
        try await projectClient.initialize()
        try await analyticsClient.initialize()
        try await notificationClient.initialize()
        
        // Create context with injected dependencies
        // In a real @Client macro implementation, this would be automatic
        let context = try await DashboardContext()
        
        // Manually inject clients (normally done by @Client macro)
        await context.injectClients(
            taskClient: taskClient,
            userClient: userClient,
            projectClient: projectClient,
            analyticsClient: analyticsClient,
            notificationClient: notificationClient
        )
        
        return context
    }
}

// MARK: - Client Factory

/// Factory for creating and configuring clients
/// Demonstrates proper client initialization and capability setup
actor TaskManagerClientFactory {
    
    func createTaskClient(capabilityManager: CapabilityManager) async throws -> TaskClient {
        // Ensure required capabilities are available
        let requiredCapabilities: Set<Capability> = [.storage, .businessLogic, .stateManagement, .analytics]
        for capability in requiredCapabilities {
            try await capabilityManager.validate(capability)
        }
        
        return try await TaskClient()
    }
    
    func createUserClient(capabilityManager: CapabilityManager) async throws -> UserClient {
        let requiredCapabilities: Set<Capability> = [.storage, .businessLogic, .userDefaults, .analytics]
        for capability in requiredCapabilities {
            try await capabilityManager.validate(capability)
        }
        
        return try await UserClient()
    }
    
    func createProjectClient(capabilityManager: CapabilityManager) async throws -> ProjectClient {
        let requiredCapabilities: Set<Capability> = [.storage, .businessLogic, .stateManagement, .analytics]
        for capability in requiredCapabilities {
            try await capabilityManager.validate(capability)
        }
        
        return try await ProjectClient()
    }
    
    func createAnalyticsClient(capabilityManager: CapabilityManager) async throws -> AnalyticsClient {
        let requiredCapabilities: Set<Capability> = [.analytics, .network, .storage]
        for capability in requiredCapabilities {
            try await capabilityManager.validate(capability)
        }
        
        return try await AnalyticsClient()
    }
    
    func createNotificationClient(capabilityManager: CapabilityManager) async throws -> NotificationClient {
        let requiredCapabilities: Set<Capability> = [.notifications, .analytics, .userDefaults]
        for capability in requiredCapabilities {
            try await capabilityManager.validate(capability)
        }
        
        return try await NotificationClient()
    }
}

// MARK: - Main Content View

/// Main content view that shows the dashboard when the application is ready
struct MainContentView: View {
    @ObservedObject var application: TaskManagerApplication
    @State private var dashboardContext: DashboardContext?
    @State private var contextError: Error?
    
    var body: some View {
        Group {
            if let context = dashboardContext {
                DashboardView(context: context)
            } else if let error = contextError {
                ContextErrorView(error: error) {
                    Task {
                        await createDashboardContext()
                    }
                }
            } else {
                LoadingContextView()
            }
        }
        .task {
            await createDashboardContext()
        }
    }
    
    private func createDashboardContext() async {
        do {
            let context = try await application.createDashboardContext()
            await MainActor.run {
                dashboardContext = context
                contextError = nil
            }
        } catch {
            await MainActor.run {
                contextError = error
                dashboardContext = nil
            }
        }
    }
}

// MARK: - Launch Views

struct LaunchingView: View {
    @State private var progress = 0.0
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checklist")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("Task Manager")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Powered by Axiom Framework")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(width: 200)
            
            Text("Initializing application...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) {
                progress = 1.0
            }
        }
    }
}

struct LaunchErrorView: View {
    let error: Error
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            VStack(spacing: 8) {
                Text("Launch Failed")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct LoadingContextView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading dashboard...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct ContextErrorView: View {
    let error: Error
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("Context Error")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Retry", action: retry)
                .buttonStyle(.bordered)
        }
        .padding()
    }
}

// MARK: - DashboardContext Extension for Manual Client Injection

extension DashboardContext {
    /// Manual client injection (normally done by @Client macro)
    /// This demonstrates what the macro would generate
    func injectClients(
        taskClient: TaskClient,
        userClient: UserClient,
        projectClient: ProjectClient,
        analyticsClient: AnalyticsClient,
        notificationClient: NotificationClient
    ) async {
        // In a real implementation, this would be generated by the @Client macro
        // For the example, we demonstrate the concept
        
        // Set up client observers
        await taskClient.addObserver(self)
        await userClient.addObserver(self)
        await projectClient.addObserver(self)
        await analyticsClient.addObserver(self)
        await notificationClient.addObserver(self)
    }
}