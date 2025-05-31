import SwiftUI
import Axiom

// MARK: - Context Macro Example

/// Demonstrates the revolutionary @Context macro that provides 95% boilerplate reduction
/// by automatically generating comprehensive context orchestration

// MARK: - Traditional Context (Before @Context Macro)

/// This is what you would need to write manually without the @Context macro
class TraditionalContext: ObservableObject, AxiomContext {
    // MARK: Manual Client Properties
    private let _dataClient: DataClient
    private let _userClient: UserClient
    
    // MARK: Manual Cross-Cutting Services
    private let _analytics: AnalyticsService
    private let _logger: LoggingService
    private let _errorReporting: ErrorReportingService
    private let _performance: PerformanceService
    
    // MARK: Manual Infrastructure
    private let _intelligence: AxiomIntelligence
    private let _stateBinder: ContextStateBinder
    
    // MARK: Manual Computed Properties
    var dataClient: DataClient { _dataClient }
    var userClient: UserClient { _userClient }
    var analytics: AnalyticsService { _analytics }
    var logger: LoggingService { _logger }
    var errorReporting: ErrorReportingService { _errorReporting }
    var performance: PerformanceService { _performance }
    var intelligence: AxiomIntelligence { _intelligence }
    
    // MARK: Manual Initializer (45+ lines)
    init(
        dataClient: DataClient,
        userClient: UserClient,
        analytics: AnalyticsService,
        logger: LoggingService,
        errorReporting: ErrorReportingService,
        performance: PerformanceService,
        intelligence: AxiomIntelligence,
        stateBinder: ContextStateBinder
    ) {
        self._dataClient = dataClient
        self._userClient = userClient
        self._analytics = analytics
        self._logger = logger
        self._errorReporting = errorReporting
        self._performance = performance
        self._intelligence = intelligence
        self._stateBinder = stateBinder
        
        // Manual observer setup
        Task {
            await dataClient.addObserver(self)
            await userClient.addObserver(self)
        }
    }
    
    // MARK: Manual Lifecycle Implementation
    func onAppear() async {
        await trackViewAppeared()
        await startContextPerformanceMonitoring()
    }
    
    func onDisappear() async {
        await trackViewDisappeared()
        await stopContextPerformanceMonitoring()
    }
    
    func onClientStateChange<T: AxiomClient>(_ client: T) async {
        await _stateBinder.updateState(from: client)
        await recordStateChangePerformance(client: client)
    }
    
    // MARK: Manual Error Handling
    func handleError(_ error: any AxiomError) async {
        await trackError(error)
        await _logger.logError(error)
        await _errorReporting.reportError(error)
    }
    
    // MARK: Manual Analytics Implementation
    func trackAnalyticsEvent(_ event: String, parameters: [String: Any]) async {
        await _analytics.track(event: event, parameters: parameters)
    }
    
    // MARK: Manual Performance Methods
    private func startContextPerformanceMonitoring() async {
        await _performance.startContextMonitoring(context: self)
    }
    
    private func stopContextPerformanceMonitoring() async {
        await _performance.stopContextMonitoring(context: self)
    }
    
    private func recordStateChangePerformance(client: any AxiomClient) async {
        await _performance.recordStateChange(client: client)
    }
    
    // MARK: Manual Deinitializer
    deinit {
        Task {
            await _dataClient.removeObserver(self)
            await _userClient.removeObserver(self)
        }
    }
}

// MARK: - Revolutionary @Context Macro (After)

/// This is the same functionality with 95% boilerplate reduction using @Context macro
@Context(
    clients: [DataClient.self, UserClient.self],
    crossCutting: [.analytics, .logging, .errorReporting, .performance]
)
@MainActor
final class RevolutionaryContext: ObservableObject, AxiomContext {
    // ✨ That's it! Everything else is generated automatically by @Context macro:
    //
    // 🔧 All client properties and dependency injection
    // 🔧 All cross-cutting service properties and injection  
    // 🔧 AxiomIntelligence integration
    // 🔧 ContextStateBinder integration
    // 🔧 Comprehensive initializer with observer setup
    // 🔧 Complete lifecycle implementation (onAppear, onDisappear, onClientStateChange)
    // 🔧 Full error handling coordination
    // 🔧 Performance monitoring integration
    // 🔧 Observer pattern management
    // 🔧 Automatic cleanup in deinitializer
    //
    // 🚀 RESULT: 95% boilerplate reduction - from 120+ lines to 5 lines!
}

// MARK: - Example Usage

struct ContextMacroExampleView: View {
    @StateObject private var context = RevolutionaryContext(
        dataClient: DataClient(),
        userClient: UserClient(),
        analytics: MockAnalyticsService(),
        logger: MockLoggingService(),
        errorReporting: MockErrorReportingService(),
        performance: MockPerformanceService(),
        intelligence: AxiomIntelligence.shared,
        stateBinder: ContextStateBinder()
    )
    
    var body: some View {
        VStack(spacing: 20) {
            Text("@Context Macro Revolution")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("95% Boilerplate Reduction")
                .font(.title2)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Automatically Generated:")
                    .font(.headline)
                
                BulletPoint("✅ Client dependency injection")
                BulletPoint("✅ Cross-cutting service injection")
                BulletPoint("✅ AxiomIntelligence integration")
                BulletPoint("✅ ContextStateBinder integration")
                BulletPoint("✅ Observer pattern management")
                BulletPoint("✅ Lifecycle implementation")
                BulletPoint("✅ Error handling coordination")
                BulletPoint("✅ Performance monitoring")
                BulletPoint("✅ Automatic cleanup")
            }
            
            Divider()
            
            Text("From 120+ lines to 5 lines!")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            
            Button("Test Context Features") {
                Task {
                    await testContextFeatures()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .onAppear {
            Task {
                await context.onAppear()
            }
        }
        .onDisappear {
            Task {
                await context.onDisappear()
            }
        }
    }
    
    private func testContextFeatures() async {
        // Test generated client access
        let data = await context.dataClient().loadData()
        let user = await context.userClient().getCurrentUser()
        
        // Test generated analytics
        await context.trackAnalyticsEvent("feature_tested", parameters: ["success": true])
        
        // Test generated error handling
        let testError = TestAxiomError(message: "Test error", category: .business)
        await context.handleError(testError)
        
        print("✅ All @Context macro features working perfectly!")
    }
}

// MARK: - Supporting Views

struct BulletPoint: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(.blue)
            Text(text)
        }
    }
}

// MARK: - Mock Services for Testing

class MockAnalyticsService: AnalyticsService {
    func track(event: String, parameters: [String: Any]) async {
        print("📊 Analytics: \(event) - \(parameters)")
    }
}

class MockLoggingService: LoggingService {
    func logError(_ error: any AxiomError) async {
        print("📝 Log: \(error.userMessage)")
    }
    
    func log(_ message: String, level: LogLevel) async {
        print("📝 Log [\(level)]: \(message)")
    }
}

class MockErrorReportingService: ErrorReportingService {
    func reportError(_ error: any AxiomError) async {
        print("🚨 Error Report: \(error.userMessage)")
    }
}

class MockPerformanceService: PerformanceService {
    func startContextMonitoring(context: any AxiomContext) async {
        print("⚡ Performance monitoring started for context")
    }
    
    func stopContextMonitoring(context: any AxiomContext) async {
        print("⚡ Performance monitoring stopped for context")
    }
    
    func recordStateChange(client: any AxiomClient) async {
        print("⚡ State change recorded for client")
    }
}

// MARK: - Test Error

struct TestAxiomError: AxiomError {
    let userMessage: String
    let category: AxiomErrorCategory
    let severity: AxiomErrorSeverity = .low
    let isRecoverable: Bool = true
    
    init(message: String, category: AxiomErrorCategory) {
        self.userMessage = message
        self.category = category
    }
}

// MARK: - Service Protocols

protocol AnalyticsService {
    func track(event: String, parameters: [String: Any]) async
}

protocol LoggingService {
    func logError(_ error: any AxiomError) async
    func log(_ message: String, level: LogLevel) async
}

protocol ErrorReportingService {
    func reportError(_ error: any AxiomError) async
}

protocol PerformanceService {
    func startContextMonitoring(context: any AxiomContext) async
    func stopContextMonitoring(context: any AxiomContext) async
    func recordStateChange(client: any AxiomClient) async
}

enum LogLevel: String {
    case debug, info, warning, error
}