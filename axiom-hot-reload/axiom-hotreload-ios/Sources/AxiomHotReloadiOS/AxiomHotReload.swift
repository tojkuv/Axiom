import SwiftUI
import NetworkClient
import SwiftUIRenderer
import HotReloadProtocol

public struct AxiomHotReload<Content: View>: View {
    
    @ViewBuilder private let content: () -> Content
    private let configuration: AxiomHotReloadConfiguration
    
    @StateObject private var connectionManager: ConnectionManager
    @StateObject private var renderer: SwiftUIJSONRenderer
    @StateObject private var stateManager: SwiftUIStateManager
    @StateObject private var errorReportingManager: ErrorReportingManager
    @StateObject private var gracefulDegradationManager: GracefulDegradationManager
    @StateObject private var memoryProfiler: MemoryProfiler
    @StateObject private var cpuProfiler: CPUProfiler
    
    @State private var isInitialized = false
    @State private var showingDebugInfo = false
    
    public init(
        configuration: AxiomHotReloadConfiguration = AxiomHotReloadConfiguration(),
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.content = content
        self.configuration = configuration
        
        let stateManager = SwiftUIStateManager(configuration: configuration.stateConfiguration)
        self._stateManager = StateObject(wrappedValue: stateManager)
        
        let renderer = SwiftUIJSONRenderer(
            configuration: configuration.renderConfiguration,
            stateManager: stateManager
        )
        self._renderer = StateObject(wrappedValue: renderer)
        
        let connectionManager = ConnectionManager(
            configuration: configuration.networkConfiguration
        )
        self._connectionManager = StateObject(wrappedValue: connectionManager)
        
        // Initialize error reporting manager
        let errorReportingConfig = configuration.enableDebugMode ? 
            ErrorReportingConfiguration.development() : 
            ErrorReportingConfiguration.production()
        let errorReportingManager = ErrorReportingManager(configuration: errorReportingConfig)
        self._errorReportingManager = StateObject(wrappedValue: errorReportingManager)
        
        // Initialize graceful degradation manager
        let degradationConfig = configuration.enableDebugMode ? 
            GracefulDegradationConfiguration.development() : 
            GracefulDegradationConfiguration.production()
        let gracefulDegradationManager = GracefulDegradationManager(
            configuration: degradationConfig,
            connectionManager: connectionManager,
            renderer: renderer
        )
        self._gracefulDegradationManager = StateObject(wrappedValue: gracefulDegradationManager)
        
        // Initialize memory profiler
        let memoryConfig = configuration.enableDebugMode ? 
            MemoryProfilerConfiguration.development() : 
            MemoryProfilerConfiguration.production()
        let memoryProfiler = MemoryProfiler(configuration: memoryConfig)
        self._memoryProfiler = StateObject(wrappedValue: memoryProfiler)
        
        // Initialize CPU profiler
        let cpuConfig = configuration.enableDebugMode ? 
            CPUProfilerConfiguration.development() : 
            CPUProfilerConfiguration.production()
        let cpuProfiler = CPUProfiler(configuration: cpuConfig)
        self._cpuProfiler = StateObject(wrappedValue: cpuProfiler)
    }
    
    public var body: some View {
        ZStack {
            // Apply graceful degradation if needed
            if gracefulDegradationManager.shouldDegrade() {
                gracefulDegradationManager.getFallbackView(originalContent: AnyView(content()))
            } else {
                // Original content (fallback)
                if !isHotReloadActive {
                    content()
                        .opacity(isHotReloadActive ? 0 : 1)
                        .animation(.easeInOut(duration: 0.3), value: isHotReloadActive)
                }
                
                // Hot reload content
                if let hotReloadView = renderer.renderedView, isHotReloadActive {
                    hotReloadView
                        .opacity(isHotReloadActive ? 1 : 0)
                        .animation(.easeInOut(duration: 0.3), value: isHotReloadActive)
                }
            }
            
            // Status overlay
            if configuration.showStatusIndicator {
                VStack {
                    Spacer()
                    HStack {
                        if configuration.showDebugInfo || showingDebugInfo {
                            Spacer()
                        }
                        
                        StatusIndicatorView(
                            connectionState: connectionManager.connectionState,
                            configuration: configuration
                        )
                        .onTapGesture(count: 2) {
                            if configuration.enableDebugMode {
                                showingDebugInfo.toggle()
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, configuration.statusIndicatorPadding)
                }
            }
            
            // Debug overlay
            if showingDebugInfo && configuration.enableDebugMode {
                DebugOverlayView(
                    connectionManager: connectionManager,
                    renderer: renderer,
                    stateManager: stateManager,
                    memoryProfiler: memoryProfiler,
                    cpuProfiler: cpuProfiler,
                    configuration: configuration
                )
                .transition(.opacity)
                .animation(.easeInOut, value: showingDebugInfo)
            }
        }
        .onAppear {
            setupHotReload()
        }
        .onDisappear {
            cleanup()
        }
        .onChange(of: connectionManager.connectionState) { state in
            handleConnectionStateChange(state)
        }
    }
    
    // MARK: - Private Properties
    
    private var isHotReloadActive: Bool {
        return connectionManager.isConnected && 
               renderer.renderedView != nil && 
               configuration.enableHotReload
    }
    
    // MARK: - Setup and Lifecycle
    
    private func setupHotReload() {
        guard !isInitialized else { return }
        
        // Setup renderer delegate
        renderer.delegate = self
        
        // Setup connection manager delegate  
        connectionManager.delegate = self
        
        // Register components with error reporting manager
        errorReportingManager.registerComponents(
            connectionManager: connectionManager,
            renderer: renderer,
            stateManager: stateManager,
            gracefulDegradationManager: gracefulDegradationManager,
            networkErrorHandler: connectionManager.errorHandler
        )
        
        // Register components with memory profiler
        memoryProfiler.setErrorReportingManager(errorReportingManager)
        memoryProfiler.registerComponent("ConnectionManager")
        memoryProfiler.registerComponent("SwiftUIRenderer")
        memoryProfiler.registerComponent("StateManager")
        memoryProfiler.registerComponent("GracefulDegradation")
        
        // Register caches with memory profiler (when available)
        // These would be registered by the components themselves when they expose their caches
        if configuration.enableDebugMode {
            // In debug mode, we can monitor internal caches more aggressively
            memoryProfiler.registerCache(NSCache<NSString, AnyObject>(), name: "ViewCache", type: .viewCache)
            memoryProfiler.registerCache(NSMutableDictionary(), name: "PropertyCache", type: .dataCache)
            memoryProfiler.registerCache(NSMutableDictionary(), name: "StateCache", type: .stateCache)
        }
        
        // Register components with CPU profiler
        cpuProfiler.setErrorReportingManager(errorReportingManager)
        cpuProfiler.registerComponent("ConnectionManager")
        cpuProfiler.registerComponent("SwiftUIRenderer") 
        cpuProfiler.registerComponent("StateManager")
        cpuProfiler.registerComponent("GracefulDegradation")
        cpuProfiler.registerComponent("MemoryProfiler")
        
        // Start connection if enabled
        if configuration.autoConnect {
            connectionManager.connect()
        }
        
        isInitialized = true
    }
    
    private func cleanup() {
        connectionManager.disconnect()
    }
    
    private func handleConnectionStateChange(_ state: ConnectionState) {
        switch state {
        case .connected:
            if configuration.enableStateLogging {
                print("🔥 AxiomHotReload connected to server")
            }
        case .disconnected:
            if configuration.enableStateLogging {
                print("❄️  AxiomHotReload disconnected from server")
            }
            // Clear rendered view on disconnect if configured
            if configuration.clearOnDisconnect {
                renderer.reset()
            }
        case .connecting:
            if configuration.enableStateLogging {
                print("🔄 AxiomHotReload connecting to server...")
            }
        case .error:
            if configuration.enableStateLogging {
                print("❌ AxiomHotReload connection error")
            }
        }
    }
    
    // MARK: - Error Handling
    
    private func handleRenderingError(_ error: Error) {
        // The renderer will automatically create a fallback view
        // when rendering fails, so we don't need to do anything special here
        // unless we want to provide additional user feedback
    }
    
    private func handleNetworkError(_ networkError: NetworkError) {
        // For critical network errors, we might want to show a specific UI
        if networkError.severity == .critical {
            // The renderer's fallback UI will handle this automatically
            // through the ConnectionManagerDelegate integration
        }
    }
}

// MARK: - AxiomHotReload Extensions

extension AxiomHotReload: ConnectionManagerDelegate {
    
    public func connectionManager(_ manager: ConnectionManager, didReceiveMessage message: BaseMessage) {
        Task { @MainActor in
            do {
                try renderer.render(from: message)
            } catch {
                if configuration.enableStateLogging {
                    print("❌ AxiomHotReload render error: \(error)")
                }
                // Report error to error reporting manager
                errorReportingManager.reportError(
                    error,
                    component: .renderer,
                    context: ErrorReportContext(operation: "Render from message"),
                    severity: .medium
                )
                // Show fallback UI for rendering errors
                handleRenderingError(error)
            }
        }
    }
    
    public func connectionManager(_ manager: ConnectionManager, didChangeState state: ConnectionState) {
        // State change is already handled in onChange modifier
    }
    
    public func connectionManager(_ manager: ConnectionManager, didReceiveError error: Error) {
        if configuration.enableStateLogging {
            print("❌ AxiomHotReload connection error: \(error)")
        }
        // Report error to error reporting manager
        errorReportingManager.reportError(
            error,
            component: .network,
            context: ErrorReportContext(operation: "Connection error"),
            severity: .high
        )
    }
    
    public func connectionManager(_ manager: ConnectionManager, didReceiveNetworkError error: NetworkError) {
        if configuration.enableStateLogging {
            print("🔍 AxiomHotReload network error: \(error.localizedDescription)")
        }
        // Report error to error reporting manager
        errorReportingManager.reportError(
            error.underlyingError,
            component: .network,
            context: ErrorReportContext(operation: "Network error", metadata: ["errorType": error.type]),
            severity: error.severity
        )
        handleNetworkError(error)
    }
    
    public func connectionManager(_ manager: ConnectionManager, didAttemptRecovery success: Bool) {
        if configuration.enableStateLogging {
            print("🔄 AxiomHotReload recovery attempt: \(success ? "successful" : "failed")")
        }
    }
}

extension AxiomHotReload: SwiftUIJSONRendererDelegate {
    
    public func renderer(_ renderer: SwiftUIJSONRenderer, didRenderView view: AnyView, from layout: SwiftUILayoutJSON) {
        if configuration.enableStateLogging {
            print("✅ AxiomHotReload rendered view successfully")
        }
    }
    
    public func renderer(_ renderer: SwiftUIJSONRenderer, didFailToRender error: SwiftUIRenderError) {
        if configuration.enableStateLogging {
            print("❌ AxiomHotReload render failed: \(error)")
        }
        // Report error to error reporting manager
        let severity: ErrorSeverity = error.errorDescription?.contains("critical") == true ? .critical : .medium
        errorReportingManager.reportError(
            error,
            component: .renderer,
            context: ErrorReportContext(operation: "Render failed"),
            severity: severity
        )
    }
    
    public func renderer(_ renderer: SwiftUIJSONRenderer, didUpdateState state: [String: Any], for viewId: String) {
        if configuration.enableStateLogging {
            print("🔄 AxiomHotReload state updated for view: \(viewId)")
        }
    }
}

// MARK: - Public API Extensions

public extension AxiomHotReload {
    
    /// Connect to hot reload server manually
    func connect() {
        connectionManager.connect()
    }
    
    /// Disconnect from hot reload server
    func disconnect() {
        connectionManager.disconnect()
    }
    
    /// Toggle debug info display
    func toggleDebugInfo() {
        guard configuration.enableDebugMode else { return }
        showingDebugInfo.toggle()
    }
    
    /// Reset hot reload state and return to original content
    func reset() {
        renderer.reset()
    }
    
    /// Get current network error message for user display
    func getCurrentErrorMessage() -> ErrorMessage? {
        return connectionManager.getCurrentErrorMessage()
    }
    
    /// Manually trigger error recovery
    func triggerRecovery() {
        connectionManager.triggerRecovery()
    }
    
    /// Clear current error state
    func clearError() {
        connectionManager.clearError()
    }
    
    /// Get network diagnostics for debugging
    func getNetworkDiagnostics() -> NetworkDiagnostics {
        return connectionManager.getNetworkDiagnostics()
    }
    
    // MARK: - Error Reporting and Diagnostics API
    
    /// Generate comprehensive system diagnostics
    func generateSystemDiagnostics() -> SystemDiagnostics {
        return errorReportingManager.generateSystemDiagnostics()
    }
    
    /// Get current system health status
    func getSystemHealth() -> SystemHealth {
        return errorReportingManager.systemHealth
    }
    
    /// Get error statistics and trends
    func getErrorStatistics() -> ErrorStatistics {
        return errorReportingManager.errorStatistics
    }
    
    /// Get recent error reports
    func getRecentErrors(count: Int = 10) -> [ErrorReport] {
        return Array(errorReportingManager.errorReports.suffix(count))
    }
    
    /// Get error trends analysis
    func getErrorTrends(timeWindow: TimeInterval = 3600) -> ErrorTrendAnalysis {
        return errorReportingManager.getErrorTrends(timeWindow: timeWindow)
    }
    
    /// Export error data for external analysis
    func exportErrorData(format: ExportFormat = .json) -> ErrorExportData {
        return errorReportingManager.exportErrorData(format: format)
    }
    
    /// Clear error history
    func clearErrorHistory() {
        errorReportingManager.clearErrorHistory()
    }
    
    /// Trigger comprehensive error recovery
    func triggerComprehensiveRecovery() {
        errorReportingManager.triggerErrorRecovery()
    }
    
    /// Report a custom error
    func reportError(_ error: Error, component: SystemComponent, severity: ErrorSeverity = .medium) {
        errorReportingManager.reportError(error, component: component, severity: severity)
    }
    
    /// Get graceful degradation status
    func getDegradationStatus() -> DegradationStats {
        return gracefulDegradationManager.getDegradationStats()
    }
    
    /// Force graceful degradation for testing
    func forceDegradation(state: DegradationState, strategy: FallbackStrategy) {
        gracefulDegradationManager.forceDegradationState(state, strategy: strategy)
    }
    
    // MARK: - Memory Profiling API
    
    /// Get current memory usage information
    func getCurrentMemoryUsage() -> MemoryUsage {
        return memoryProfiler.currentMemoryUsage
    }
    
    /// Get comprehensive memory analysis
    func generateMemoryAnalysis() -> MemoryAnalysis {
        return memoryProfiler.generateMemoryAnalysis()
    }
    
    /// Detect memory leaks in the system
    func detectMemoryLeaks() -> [MemoryLeak] {
        return memoryProfiler.detectLeaks()
    }
    
    /// Manually trigger memory optimization
    func optimizeMemory() -> MemoryOptimizationResult {
        return memoryProfiler.optimizeMemory()
    }
    
    /// Get memory trends and predictions
    func getMemoryTrends() -> MemoryTrends {
        return memoryProfiler.getMemoryTrends()
    }
    
    /// Get memory usage for specific component
    func getComponentMemoryUsage(_ component: String) -> ComponentMemoryInfo? {
        return memoryProfiler.getComponentMemoryUsage(component)
    }
    
    /// Start memory monitoring
    func startMemoryMonitoring() {
        memoryProfiler.startMonitoring()
    }
    
    /// Stop memory monitoring
    func stopMemoryMonitoring() {
        memoryProfiler.stopMonitoring()
    }
    
    /// Get current memory pressure level
    func getMemoryPressure() -> MemoryPressureLevel {
        return memoryProfiler.memoryPressureLevel
    }
    
    /// Register a cache for memory monitoring
    func registerCache<T: AnyObject>(_ cache: T, name: String, type: CacheType) {
        memoryProfiler.registerCache(cache, name: name, type: type)
    }
    
    /// Update memory usage for a component
    func updateComponentMemory(_ component: String, usage: UInt64) {
        memoryProfiler.updateComponentMemory(component, usage: usage)
    }
    
    // MARK: - CPU Profiling API
    
    /// Get current CPU usage information
    func getCurrentCPUUsage() -> CPUUsage {
        return cpuProfiler.currentCPUUsage
    }
    
    /// Generate comprehensive CPU analysis
    func generateCPUAnalysis() -> CPUAnalysis {
        return cpuProfiler.generateCPUAnalysis()
    }
    
    /// Detect CPU performance bottlenecks
    func detectCPUBottlenecks() -> [PerformanceBottleneck] {
        return cpuProfiler.detectBottlenecks()
    }
    
    /// Manually trigger CPU optimization
    func optimizeCPU() -> CPUOptimizationResult {
        return cpuProfiler.optimizeCPU()
    }
    
    /// Get CPU trends and predictions
    func getCPUTrends() -> CPUTrends {
        return cpuProfiler.getCPUTrends()
    }
    
    /// Get CPU usage for specific component
    func getComponentCPUUsage(_ component: String) -> ComponentCPUInfo? {
        return cpuProfiler.getComponentCPUUsage(component)
    }
    
    /// Start CPU monitoring
    func startCPUMonitoring() {
        cpuProfiler.startMonitoring()
    }
    
    /// Stop CPU monitoring
    func stopCPUMonitoring() {
        cpuProfiler.stopMonitoring()
    }
    
    /// Get current CPU pressure level
    func getCPUPressure() -> CPUPressureLevel {
        return cpuProfiler.cpuPressureLevel
    }
    
    /// Start tracking a performance-critical task
    func startTask(_ taskName: String, component: String = "App") -> TaskTracker {
        return cpuProfiler.startTask(taskName, component: component)
    }
    
    /// Track a task's performance with automatic completion
    func trackTask<T>(_ taskName: String, component: String = "App", operation: () throws -> T) rethrows -> T {
        let tracker = cpuProfiler.startTask(taskName, component: component)
        defer { tracker.end() }
        
        return try operation()
    }
    
    /// Track an async task's performance
    func trackAsyncTask<T>(_ taskName: String, component: String = "App", operation: () async throws -> T) async rethrows -> T {
        let tracker = cpuProfiler.startTask(taskName, component: component)
        defer { tracker.end() }
        
        return try await operation()
    }
}

// MARK: - Convenience Initializers

public extension AxiomHotReload {
    
    /// Create AxiomHotReload with default configuration
    init(@ViewBuilder content: @escaping () -> Content) {
        self.init(configuration: AxiomHotReloadConfiguration(), content: content)
    }
    
    /// Create AxiomHotReload with custom host and port
    init(
        host: String,
        port: Int = 8080,
        @ViewBuilder content: @escaping () -> Content
    ) {
        var config = AxiomHotReloadConfiguration()
        config.networkConfiguration.host = host
        config.networkConfiguration.port = port
        self.init(configuration: config, content: content)
    }
    
    /// Create AxiomHotReload for development with debug features enabled
    static func development(
        host: String = "localhost",
        port: Int = 8080,
        @ViewBuilder content: @escaping () -> Content
    ) -> AxiomHotReload<Content> {
        return AxiomHotReload(
            configuration: .development(host: host, port: port),
            content: content
        )
    }
    
    /// Create AxiomHotReload for production (minimal features)
    static func production(
        @ViewBuilder content: @escaping () -> Content
    ) -> AxiomHotReload<Content> {
        return AxiomHotReload(
            configuration: .production(),
            content: content
        )
    }
}