import SwiftUI
import NetworkClient
import SwiftUIRenderer
import HotReloadProtocol

public struct AxiomObservabilityClient<Content: View>: View {
    
    @ViewBuilder private let content: () -> Content
    private let configuration: AxiomObservabilityConfiguration
    
    // Core hot reload components (from existing AxiomHotReload)
    @StateObject private var connectionManager: ConnectionManager
    @StateObject private var renderer: SwiftUIJSONRenderer
    @StateObject private var stateManager: SwiftUIStateManager
    @StateObject private var errorReportingManager: ErrorReportingManager
    @StateObject private var gracefulDegradationManager: GracefulDegradationManager
    
    // Existing profilers
    @StateObject private var memoryProfiler: MemoryProfiler
    @StateObject private var cpuProfiler: CPUProfiler
    @StateObject private var renderingProfiler: RenderingProfiler
    @StateObject private var networkOptimizer: NetworkOptimizer
    @StateObject private var stateDebugger: StateDebugger
    
    // New observability components
    @StateObject private var metadataStreamer: MetadataStreamer
    @StateObject private var screenshotCapture: ScreenshotCapture
    @StateObject private var hierarchyAnalyzer: ViewHierarchyAnalyzer
    @StateObject private var contextInspector: ContextInspector
    
    @State private var isInitialized = false
    @State private var showingDebugInfo = false
    @State private var observabilityData: ObservabilityData?
    
    public init(
        configuration: AxiomObservabilityConfiguration = AxiomObservabilityConfiguration(),
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.content = content
        self.configuration = configuration
        
        // Initialize core components (similar to existing AxiomHotReload)
        let stateManager = SwiftUIStateManager(configuration: configuration.stateConfiguration)
        self._stateManager = StateObject(wrappedValue: stateManager)
        
        let renderer = SwiftUIJSONRenderer(
            configuration: configuration.renderConfiguration,
            stateManager: stateManager
        )
        self._renderer = StateObject(wrappedValue: renderer)
        
        let connectionManager = ConnectionManager(
            configuration: ConnectionConfiguration(
                host: configuration.networkConfiguration.host,
                port: configuration.networkConfiguration.port,
                path: "/ws",
                clientId: UUID().uuidString,
                clientName: "AxiomObservabilityClient",
                enableAutoReconnect: true,
                maxReconnectAttempts: 5,
                baseReconnectDelay: 1.0,
                maxReconnectDelay: 30.0,
                enableHeartbeat: true,
                heartbeatInterval: 30.0,
                enableStatePreservation: true,
                enableDebugLogging: false
            )
        )
        self._connectionManager = StateObject(wrappedValue: connectionManager)
        
        // Initialize error reporting
        let errorReportingConfig = configuration.enableDebugMode ? 
            ErrorReportingConfiguration.development() : 
            ErrorReportingConfiguration.production()
        let errorReportingManager = ErrorReportingManager(configuration: errorReportingConfig)
        self._errorReportingManager = StateObject(wrappedValue: errorReportingManager)
        
        // Initialize graceful degradation
        let degradationConfig = configuration.enableDebugMode ? 
            GracefulDegradationConfiguration.development() : 
            GracefulDegradationConfiguration.production()
        let gracefulDegradationManager = GracefulDegradationManager(
            configuration: degradationConfig,
            connectionManager: connectionManager,
            renderer: renderer
        )
        self._gracefulDegradationManager = StateObject(wrappedValue: gracefulDegradationManager)
        
        // Initialize existing profilers
        let memoryConfig = configuration.enableDebugMode ? 
            MemoryProfilerConfiguration.development() : 
            MemoryProfilerConfiguration.production()
        let memoryProfiler = MemoryProfiler(configuration: memoryConfig)
        self._memoryProfiler = StateObject(wrappedValue: memoryProfiler)
        
        let cpuConfig = configuration.enableDebugMode ? 
            CPUProfilerConfiguration.development() : 
            CPUProfilerConfiguration.production()
        let cpuProfiler = CPUProfiler(configuration: cpuConfig)
        self._cpuProfiler = StateObject(wrappedValue: cpuProfiler)
        
        let renderingConfig = configuration.enableDebugMode ? 
            RenderingProfilerConfiguration.development() : 
            RenderingProfilerConfiguration.production()
        let renderingProfiler = RenderingProfiler(configuration: renderingConfig)
        self._renderingProfiler = StateObject(wrappedValue: renderingProfiler)
        
        let networkConfig = configuration.enableDebugMode ? 
            NetworkOptimizerConfiguration.development() : 
            NetworkOptimizerConfiguration.production()
        let networkOptimizer = NetworkOptimizer(configuration: networkConfig)
        self._networkOptimizer = StateObject(wrappedValue: networkOptimizer)
        
        let stateDebugConfig = configuration.enableDebugMode ? 
            StateDebuggerConfiguration.development() : 
            StateDebuggerConfiguration.production()
        let stateDebugger = StateDebugger(configuration: stateDebugConfig)
        self._stateDebugger = StateObject(wrappedValue: stateDebugger)
        
        // Initialize new observability components
        let metadataStreamer = MetadataStreamer(configuration: configuration.metadataStreamingConfiguration)
        self._metadataStreamer = StateObject(wrappedValue: metadataStreamer)
        
        let screenshotCapture = ScreenshotCapture(configuration: configuration.screenshotCaptureConfiguration)
        self._screenshotCapture = StateObject(wrappedValue: screenshotCapture)
        
        let hierarchyAnalyzer = ViewHierarchyAnalyzer(configuration: configuration.hierarchyAnalyzerConfiguration)
        self._hierarchyAnalyzer = StateObject(wrappedValue: hierarchyAnalyzer)
        
        let contextInspector = ContextInspector(configuration: configuration.contextInspectorConfiguration)
        self._contextInspector = StateObject(wrappedValue: contextInspector)
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
                            configuration: configuration.toHotReloadConfiguration()
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
            
            // Enhanced debug overlay
            if showingDebugInfo && configuration.enableDebugMode {
                EnhancedDebugOverlayView(
                    // Core components
                    connectionManager: connectionManager,
                    renderer: renderer,
                    stateManager: stateManager,
                    memoryProfiler: memoryProfiler,
                    cpuProfiler: cpuProfiler,
                    renderingProfiler: renderingProfiler,
                    networkOptimizer: networkOptimizer,
                    stateDebugger: stateDebugger,
                    // New observability components
                    metadataStreamer: metadataStreamer,
                    screenshotCapture: screenshotCapture,
                    hierarchyAnalyzer: hierarchyAnalyzer,
                    contextInspector: contextInspector,
                    observabilityData: observabilityData,
                    configuration: configuration
                )
                .transition(.opacity)
                .animation(.easeInOut, value: showingDebugInfo)
            }
        }
        .onAppear {
            setupObservabilityClient()
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
    
    private func setupObservabilityClient() {
        guard !isInitialized else { return }
        
        // Setup core components (similar to existing setup)
        setupCoreComponents()
        
        // Setup new observability components
        setupObservabilityComponents()
        
        // Start connection if enabled
        if configuration.autoConnect {
            connectionManager.connect()
        }
        
        // Start metadata streaming if enabled
        if configuration.enableMetadataStreaming {
            metadataStreamer.startStreaming(connectionManager: connectionManager)
        }
        
        isInitialized = true
    }
    
    private func setupCoreComponents() {
        // Create delegate wrapper to handle protocol conformance
        let delegateWrapper = ObservabilityClientDelegateWrapper(client: self)
        
        // Setup renderer delegate using wrapper
        renderer.delegate = delegateWrapper
        
        // Setup connection manager delegate using wrapper
        connectionManager.delegate = delegateWrapper
        
        // Register components with error reporting manager
        errorReportingManager.registerComponents(
            connectionManager: connectionManager,
            renderer: renderer,
            stateManager: stateManager,
            gracefulDegradationManager: gracefulDegradationManager,
            networkErrorHandler: nil
        )
        
        // Setup profilers (existing logic)
        setupExistingProfilers()
    }
    
    private func setupObservabilityComponents() {
        // Create delegate wrapper to handle protocol conformance
        let delegateWrapper = ObservabilityClientDelegateWrapper(client: self)
        
        // Setup metadata streamer using wrapper
        metadataStreamer.delegate = delegateWrapper
        
        // Setup screenshot capture using wrapper
        screenshotCapture.delegate = delegateWrapper
        
        // Setup hierarchy analyzer using wrapper
        hierarchyAnalyzer.delegate = delegateWrapper
        
        // Setup context inspector using wrapper
        contextInspector.delegate = delegateWrapper
        
        // Register contexts with inspector
        registerContextsWithInspector()
    }
    
    private func setupExistingProfilers() {
        // Memory profiler setup
        memoryProfiler.setErrorReportingManager(errorReportingManager)
        memoryProfiler.registerComponent("ConnectionManager")
        memoryProfiler.registerComponent("SwiftUIRenderer")
        memoryProfiler.registerComponent("StateManager")
        memoryProfiler.registerComponent("MetadataStreamer")
        memoryProfiler.registerComponent("ScreenshotCapture")
        memoryProfiler.registerComponent("HierarchyAnalyzer")
        memoryProfiler.registerComponent("ContextInspector")
        
        // CPU profiler setup
        cpuProfiler.setErrorReportingManager(errorReportingManager)
        cpuProfiler.registerComponent("ConnectionManager")
        cpuProfiler.registerComponent("SwiftUIRenderer") 
        cpuProfiler.registerComponent("StateManager")
        cpuProfiler.registerComponent("ObservabilityComponents")
        
        // Rendering profiler setup
        renderingProfiler.setErrorReportingManager(errorReportingManager)
        renderingProfiler.setMemoryProfiler(memoryProfiler)
        renderingProfiler.setCPUProfiler(cpuProfiler)
        renderingProfiler.registerView("HotReloadContent", viewType: .display)
        renderingProfiler.registerView("StatusIndicator", viewType: .display)
        renderingProfiler.registerView("EnhancedDebugOverlay", viewType: .display)
        
        // Network optimizer setup
        networkOptimizer.setErrorReportingManager(errorReportingManager)
        networkOptimizer.setConnectionManager(connectionManager)
        
        // State debugger setup
        stateDebugger.setStateManager(stateManager)
        stateDebugger.setErrorReportingManager(errorReportingManager)
        stateDebugger.setMemoryProfiler(memoryProfiler)
        
        // Register important state keys for tracking
        if configuration.enableDebugMode {
            stateDebugger.registerStateKey("ConnectionState")
            stateDebugger.registerStateKey("RenderingState")
            stateDebugger.registerStateKey("ErrorState")
            stateDebugger.registerStateKey("PerformanceMetrics")
            stateDebugger.registerStateKey("ObservabilityMetadata")
        }
    }
    
    private func registerContextsWithInspector() {
        // In a real implementation, this would scan for actual Axiom contexts
        // For now, register some example contexts
        
        let rootContext = ContextInfo(
            id: "root-context",
            name: "RootContext",
            parentId: nil,
            properties: ["isRoot": "true", "environmentSetup": "complete"],
            performanceMetrics: ContextPerformanceMetrics(
                updateCount: 0,
                averageUpdateTime: 0.0,
                cpuUsage: 0.0,
                memoryFootprint: 0,
                lastUpdateTime: Date()
            )
        )
        contextInspector.registerContext(rootContext)
        
        let appContext = ContextInfo(
            id: "app-context",
            name: "AppContext",
            parentId: "root-context",
            properties: ["screen": "main", "userSession": "active"],
            performanceMetrics: ContextPerformanceMetrics(
                updateCount: 0,
                averageUpdateTime: 0.0,
                cpuUsage: 0.0,
                memoryFootprint: 0,
                lastUpdateTime: Date()
            )
        )
        contextInspector.registerContext(appContext)
    }
    
    private func cleanup() {
        connectionManager.disconnect()
        metadataStreamer.stopStreaming()
    }
    
    func handleConnectionStateChange(_ state: ConnectionState) {
        switch state {
        case .connected:
            if configuration.enableStateLogging {
                print("🔥 AxiomObservabilityClient connected to server")
            }
        case .disconnected:
            if configuration.enableStateLogging {
                print("❄️ AxiomObservabilityClient disconnected from server")
            }
            // Clear rendered view on disconnect if configured
            if configuration.clearOnDisconnect {
                renderer.reset()
            }
        case .connecting:
            if configuration.enableStateLogging {
                print("🔄 AxiomObservabilityClient connecting to server...")
            }
        case .reconnecting:
            if configuration.enableStateLogging {
                print("🔄 AxiomObservabilityClient reconnecting to server...")
            }
        case .error:
            if configuration.enableStateLogging {
                print("❌ AxiomObservabilityClient connection error")
            }
        }
    }
    
    // MARK: - New Observability API Methods
    
    public func streamAppMetadata() -> AsyncStream<AppMetadata> {
        return metadataStreamer.streamAppMetadata()
    }
    
    public func captureStateTransition() async -> StateTransitionData {
        return await metadataStreamer.captureStateTransition()
    }
    
    public func generateComponentScreenshots() async -> [ComponentScreenshot] {
        return await screenshotCapture.generateComponentScreenshots()
    }
    
    public func analyzeContextRelationships() -> ContextGraph {
        return contextInspector.analyzeContextRelationships()
    }
    
    public func analyzeViewHierarchy() async throws -> ViewHierarchyAnalysis {
        return try await hierarchyAnalyzer.analyzeCurrentHierarchy()
    }
    
    public func inspectContext(_ contextId: String) async throws -> ContextInspectionResult {
        return try await contextInspector.inspectContext(contextId)
    }
    
    public func performComprehensiveAnalysis() async -> ComprehensiveObservabilityReport {
        let metadata = await metadataStreamer.collectCurrentMetadata()
        let contextAnalysis = await contextInspector.performComprehensiveAnalysis()
        
        var hierarchyAnalysis: ViewHierarchyAnalysis?
        do {
            hierarchyAnalysis = try await hierarchyAnalyzer.analyzeCurrentHierarchy()
        } catch {
            print("Failed to analyze view hierarchy: \(error)")
        }
        
        let performanceSnapshot = PerformanceSnapshot(
            cpuUsage: await getCurrentCPUUsage(),
            memoryUsage: await getCurrentMemoryUsage(),
            renderTime: await getCurrentRenderTime(),
            networkLatency: await getCurrentNetworkLatency()
        )
        
        return ComprehensiveObservabilityReport(
            timestamp: Date(),
            metadata: metadata,
            contextAnalysis: contextAnalysis,
            hierarchyAnalysis: hierarchyAnalysis,
            performanceSnapshot: performanceSnapshot,
            systemHealth: getSystemHealth(),
            recommendations: generateComprehensiveRecommendations(
                contextAnalysis: contextAnalysis,
                hierarchyAnalysis: hierarchyAnalysis,
                performanceSnapshot: performanceSnapshot
            )
        )
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentCPUUsage() async -> Double {
        return cpuProfiler.currentCPUUsage.total
    }
    
    private func getCurrentMemoryUsage() async -> Int64 {
        return Int64(memoryProfiler.currentMemoryUsage.resident)
    }
    
    private func getCurrentRenderTime() async -> Double {
        return renderingProfiler.currentRenderingMetrics.frameTime
    }
    
    private func getCurrentNetworkLatency() async -> Double {
        return networkOptimizer.networkMetrics.roundTripTime
    }
    
    private func getSystemHealth() -> SystemHealth {
        return errorReportingManager.systemHealth
    }
    
    private func generateComprehensiveRecommendations(
        contextAnalysis: ContextAnalysisResult,
        hierarchyAnalysis: ViewHierarchyAnalysis?,
        performanceSnapshot: PerformanceSnapshot
    ) -> [ComprehensiveRecommendation] {
        var recommendations: [ComprehensiveRecommendation] = []
        
        // Context recommendations
        for contextRec in contextAnalysis.recommendations {
            recommendations.append(ComprehensiveRecommendation(
                category: .context,
                priority: contextRec.priority,
                title: contextRec.description,
                description: contextRec.actionItems.joined(separator: "; "),
                impact: .medium
            ))
        }
        
        // Hierarchy recommendations
        if let hierarchyAnalysis = hierarchyAnalysis {
            for hierarchyRec in hierarchyAnalysis.recommendations {
                recommendations.append(ComprehensiveRecommendation(
                    category: .hierarchy,
                    priority: hierarchyRec.priority,
                    title: hierarchyRec.description,
                    description: hierarchyRec.suggestedAction,
                    impact: .medium
                ))
            }
        }
        
        // Performance recommendations
        if performanceSnapshot.cpuUsage > 70 {
            recommendations.append(ComprehensiveRecommendation(
                category: .performance,
                priority: .high,
                title: "High CPU Usage",
                description: "Optimize CPU-intensive operations",
                impact: .high
            ))
        }
        
        if performanceSnapshot.memoryUsage > 500_000_000 { // 500MB
            recommendations.append(ComprehensiveRecommendation(
                category: .performance,
                priority: .high,
                title: "High Memory Usage",
                description: "Review memory allocations and potential leaks",
                impact: .high
            ))
        }
        
        return recommendations
    }
}

// MARK: - Delegates

// Using wrapper classes to handle protocol conformance since structs cannot conform to class protocols

private class ObservabilityClientDelegateWrapper<Content: View>: ConnectionManagerDelegate, SwiftUIJSONRendererDelegate, MetadataStreamerDelegate, ScreenshotCaptureDelegate, ViewHierarchyAnalyzerDelegate, ContextInspectorDelegate {
    
    var client: AxiomObservabilityClient<Content>?
    
    init(client: AxiomObservabilityClient<Content>) {
        self.client = client
    }
    
    // MARK: - ConnectionManagerDelegate
    
    func connectionManager(_ manager: ConnectionManager, didReceiveMessage message: BaseMessage) {
        client?.handleReceivedMessage(message)
    }
    
    func connectionManager(_ manager: ConnectionManager, didChangeConnectionState state: ConnectionState) {
        client?.handleConnectionStateChange(state)
    }
    
    func connectionManager(_ manager: ConnectionManager, didEncounterError error: Error) {
        client?.handleConnectionError(error)
    }
    
    func connectionManager(_ manager: ConnectionManager, didReceiveNetworkError error: NetworkError) {
        client?.handleNetworkError(error)
    }
    
    func connectionManager(_ manager: ConnectionManager, didAttemptRecovery success: Bool) {
        client?.handleRecoveryAttempt(success: success)
    }
    
    // MARK: - SwiftUIJSONRendererDelegate
    
    func renderer(_ renderer: SwiftUIJSONRenderer, didRenderView view: AnyView, from layout: SwiftUILayoutJSON) {
        client?.handleViewRendered(view, from: layout)
    }
    
    func renderer(_ renderer: SwiftUIJSONRenderer, didFailToRender error: SwiftUIRenderError) {
        client?.handleRenderError(error)
    }
    
    func renderer(_ renderer: SwiftUIJSONRenderer, didStartRendering layout: SwiftUILayoutJSON) {
        client?.handleRenderingStarted(layout)
    }
    
    func renderer(_ renderer: SwiftUIJSONRenderer, didCompleteRendering view: AnyView, duration: TimeInterval) {
        client?.handleRenderingCompleted(view, duration: duration)
    }
    
    func renderer(_ renderer: SwiftUIJSONRenderer, didUpdateState state: [String: Any], for viewId: String) {
        client?.handleStateUpdate(state, for: viewId)
    }
    
    // MARK: - MetadataStreamerDelegate
    
    func streamer(_ streamer: MetadataStreamer, didStreamMetadata metadata: AppMetadata) {
        client?.handleMetadataStreamed(metadata)
    }
    
    func streamer(_ streamer: MetadataStreamer, didEncounterError error: Error) {
        client?.handleMetadataError(error)
    }
    
    // MARK: - ScreenshotCaptureDelegate
    
    func capture(_ capture: ScreenshotCapture, didCaptureScreenshots screenshots: [ComponentScreenshot]) {
        client?.handleScreenshotsCaptured(screenshots)
    }
    
    func capture(_ capture: ScreenshotCapture, didFailWithError error: Error) {
        client?.handleScreenshotError(error)
    }
    
    // MARK: - ViewHierarchyAnalyzerDelegate
    
    func analyzer(_ analyzer: ViewHierarchyAnalyzer, didAnalyzeHierarchy analysis: ViewHierarchyAnalysis) {
        client?.handleHierarchyAnalyzed(analysis)
    }
    
    func analyzer(_ analyzer: ViewHierarchyAnalyzer, didDetectPerformanceIssue issue: ViewPerformanceIssue) {
        client?.handlePerformanceIssueDetected(issue)
    }
    
    func analyzer(_ analyzer: ViewHierarchyAnalyzer, didEncounterError error: Error) {
        client?.handleAnalyzerError(error)
    }
    
    // MARK: - ContextInspectorDelegate
    
    func inspector(_ inspector: ContextInspector, didAnalyzeContext analysis: ContextAnalysisResult) {
        client?.handleContextAnalyzed(analysis)
    }
    
    func inspector(_ inspector: ContextInspector, didDetectContextIssue issue: ContextIssue) {
        client?.handleContextIssueDetected(issue)
    }
    
    func inspector(_ inspector: ContextInspector, didEncounterError error: Error) {
        client?.handleContextInspectorError(error)
    }
}

// Extension to handle delegate callbacks
extension AxiomObservabilityClient {
    
    func handleReceivedMessage(_ message: BaseMessage) {
        Task { @MainActor in
            do {
                try renderer.render(from: message)
            } catch {
                errorReportingManager.reportError(
                    error,
                    component: .renderer,
                    context: ErrorReportContext(operation: "Message processing"),
                    severity: .medium
                )
            }
        }
    }
    
    func handleConnectionError(_ error: Error) {
        errorReportingManager.reportError(
            error,
            component: .network,
            context: ErrorReportContext(operation: "Connection"),
            severity: .high
        )
    }
    
    func handleNetworkError(_ error: NetworkError) {
        errorReportingManager.reportError(
            error.underlyingError,
            component: .network,
            context: ErrorReportContext(operation: "Network"),
            severity: .high
        )
    }
    
    func handleRecoveryAttempt(success: Bool) {
        if configuration.enableStateLogging {
            print("🔄 Recovery attempt: \(success ? "succeeded" : "failed")")
        }
    }
    
    func handleStateUpdate(_ state: [String: Any], for viewId: String) {
        if configuration.enableStateLogging {
            print("🔄 State updated for view: \(viewId)")
        }
    }
    
    func handleViewRendered(_ view: AnyView, from layout: SwiftUILayoutJSON) {
        if configuration.enableStateLogging {
            print("🎨 View rendered from layout")
        }
    }
    
    func handleRenderError(_ error: SwiftUIRenderError) {
        errorReportingManager.reportError(
            error,
            component: .renderer,
            context: ErrorReportContext(operation: "View rendering"),
            severity: .medium
        )
    }
    
    func handleRenderingStarted(_ layout: SwiftUILayoutJSON) {
        if configuration.enableStateLogging {
            print("🎨 Rendering started")
        }
    }
    
    func handleRenderingCompleted(_ view: AnyView, duration: TimeInterval) {
        if configuration.enableStateLogging {
            print("🎨 Rendering completed in \(duration)ms")
        }
    }
    
    func handleMetadataStreamed(_ metadata: AppMetadata) {
        observabilityData = ObservabilityData(
            lastMetadataUpdate: Date(),
            streamedMetadata: metadata,
            isStreaming: true
        )
    }
    
    func handleMetadataError(_ error: Error) {
        errorReportingManager.reportError(
            error,
            component: .system,
            context: ErrorReportContext(operation: "Metadata streaming"),
            severity: .medium
        )
    }
    
    func handleScreenshotsCaptured(_ screenshots: [ComponentScreenshot]) {
        if configuration.enableStateLogging {
            print("📸 Captured \(screenshots.count) component screenshots")
        }
    }
    
    func handleScreenshotError(_ error: Error) {
        errorReportingManager.reportError(
            error,
            component: .system,
            context: ErrorReportContext(operation: "Screenshot capture"),
            severity: .low
        )
    }
    
    func handleHierarchyAnalyzed(_ analysis: ViewHierarchyAnalysis) {
        if configuration.enableStateLogging {
            print("🔍 View hierarchy analyzed: \(analysis.hierarchy.totalNodes) nodes")
        }
    }
    
    func handlePerformanceIssueDetected(_ issue: ViewPerformanceIssue) {
        errorReportingManager.reportError(
            PerformanceError.viewPerformanceIssue(issue),
            component: .renderer,
            context: ErrorReportContext(operation: "Performance analysis"),
            severity: .medium
        )
    }
    
    func handleAnalyzerError(_ error: Error) {
        errorReportingManager.reportError(
            error,
            component: .system,
            context: ErrorReportContext(operation: "Hierarchy analysis"),
            severity: .medium
        )
    }
    
    func handleContextAnalyzed(_ analysis: ContextAnalysisResult) {
        if configuration.enableStateLogging {
            print("📋 Context analysis completed")
        }
    }
    
    func handleContextIssueDetected(_ issue: ContextIssue) {
        errorReportingManager.reportError(
            ContextError.contextIssue(issue),
            component: .system,
            context: ErrorReportContext(operation: "Context inspection"),
            severity: .medium
        )
    }
    
    func handleContextInspectorError(_ error: Error) {
        errorReportingManager.reportError(
            error,
            component: .network,
            context: ErrorReportContext(operation: "Context inspection"),
            severity: .medium
        )
    }
}

// Custom error types for proper error reporting
enum PerformanceError: Error {
    case viewPerformanceIssue(ViewPerformanceIssue)
}

enum ContextError: Error {
    case contextIssue(ContextIssue)
}

/*
// Legacy extension code - replaced with wrapper pattern above
extension AxiomObservabilityClient: ConnectionManagerDelegate {
    
    public func connectionManager(_ manager: ConnectionManager, didReceiveMessage message: BaseMessage) {
        Task { @MainActor in
            do {
                try renderer.render(from: message)
            } catch {
                if configuration.enableStateLogging {
                    print("❌ AxiomObservabilityClient render error: \(error)")
                }
                errorReportingManager.reportError(
                    error,
                    component: .renderer,
                    context: ErrorReportContext(operation: "Render from message"),
                    severity: .medium
                )
            }
        }
    }
    
    public func connectionManager(_ manager: ConnectionManager, didChangeState state: ConnectionState) {
        // State change is already handled in onChange modifier
    }
    
    public func connectionManager(_ manager: ConnectionManager, didReceiveError error: Error) {
        if configuration.enableStateLogging {
            print("❌ AxiomObservabilityClient connection error: \(error)")
        }
        errorReportingManager.reportError(
            error,
            component: .network,
            context: ErrorReportContext(operation: "Connection error"),
            severity: .high
        )
    }
    
    public func connectionManager(_ manager: ConnectionManager, didReceiveNetworkError error: NetworkError) {
        if configuration.enableStateLogging {
            print("🔍 AxiomObservabilityClient network error: \(error.localizedDescription)")
        }
        errorReportingManager.reportError(
            error,
            component: .network,
            context: ErrorReportContext(operation: "Network error", metadata: ["errorType": error.type]),
            severity: error.severity
        )
    }
    
    public func connectionManager(_ manager: ConnectionManager, didAttemptRecovery success: Bool) {
        if configuration.enableStateLogging {
            print("🔄 AxiomObservabilityClient recovery attempt: \(success ? "successful" : "failed")")
        }
    }
}

extension AxiomObservabilityClient: SwiftUIJSONRendererDelegate {
    
    public func renderer(_ renderer: SwiftUIJSONRenderer, didRenderView view: AnyView, from layout: SwiftUILayoutJSON) {
        if configuration.enableStateLogging {
            print("✅ AxiomObservabilityClient rendered view successfully")
        }
    }
    
    public func renderer(_ renderer: SwiftUIJSONRenderer, didFailToRender error: SwiftUIRenderError) {
        if configuration.enableStateLogging {
            print("❌ AxiomObservabilityClient render failed: \(error)")
        }
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
            print("🔄 AxiomObservabilityClient state updated for view: \(viewId)")
        }
    }
}

extension AxiomObservabilityClient: MetadataStreamerDelegate {
    
    public func streamer(_ streamer: MetadataStreamer, didStreamMetadata metadata: AppMetadata) {
        // Update observability data
        observabilityData = ObservabilityData(
            lastMetadataUpdate: Date(),
            streamedMetadata: metadata,
            isStreaming: true
        )
    }
    
    public func streamer(_ streamer: MetadataStreamer, didEncounterError error: Error) {
        errorReportingManager.reportError(
            error,
            component: .network,
            context: ErrorReportContext(operation: "Metadata streaming"),
            severity: .medium
        )
    }
}

extension AxiomObservabilityClient: ScreenshotCaptureDelegate {
    
    public func capture(_ capture: ScreenshotCapture, didCaptureScreenshot screenshot: ComponentScreenshot) {
        if configuration.enableStateLogging {
            print("📸 Captured screenshot for component: \(screenshot.componentName)")
        }
    }
    
    public func capture(_ capture: ScreenshotCapture, didFailWithError error: Error) {
        errorReportingManager.reportError(
            error,
            component: .renderer,
            context: ErrorReportContext(operation: "Screenshot capture"),
            severity: .low
        )
    }
}

extension AxiomObservabilityClient: ViewHierarchyAnalyzerDelegate {
    
    public func analyzer(_ analyzer: ViewHierarchyAnalyzer, didAnalyzeHierarchy analysis: ViewHierarchyAnalysis) {
        if configuration.enableStateLogging {
            print("🔍 View hierarchy analyzed: \(analysis.hierarchy.totalNodes) nodes")
        }
    }
    
    public func analyzer(_ analyzer: ViewHierarchyAnalyzer, didDetectPerformanceIssue issue: ViewPerformanceIssue) {
        if configuration.enableStateLogging {
            print("⚠️ Performance issue detected: \(issue.description)")
        }
    }
    
    public func analyzer(_ analyzer: ViewHierarchyAnalyzer, didEncounterError error: Error) {
        errorReportingManager.reportError(
            error,
            component: .renderer,
            context: ErrorReportContext(operation: "Hierarchy analysis"),
            severity: .low
        )
    }
}

extension AxiomObservabilityClient: ContextInspectorDelegate {
    
    public func inspector(_ inspector: ContextInspector, didAnalyzeContext analysis: ContextAnalysisResult) {
        if configuration.enableStateLogging {
            print("🔍 Context analysis completed: \(analysis.totalContexts) contexts")
        }
    }
    
    public func inspector(_ inspector: ContextInspector, didDetectContextIssue issue: ContextIssue) {
        if configuration.enableStateLogging {
            print("⚠️ Context issue detected: \(issue.description)")
        }
    }
    
    public func inspector(_ inspector: ContextInspector, didEncounterError error: Error) {
        errorReportingManager.reportError(
            error,
            component: .network,
            context: ErrorReportContext(operation: "Context inspection"),
            severity: .medium
        )
    }
}
*/

// MARK: - Supporting Types

public struct AxiomObservabilityConfiguration {
    // Core configuration (from existing AxiomHotReloadConfiguration)
    public var enableHotReload: Bool = true
    public var enableDebugMode: Bool = false
    public var autoConnect: Bool = true
    public var showStatusIndicator: Bool = true
    public var showDebugInfo: Bool = false
    public var enableStateLogging: Bool = false
    public var clearOnDisconnect: Bool = true
    public var statusIndicatorPadding: CGFloat = 20
    
    // Network configuration
    public var networkConfiguration: NetworkConfiguration = NetworkConfiguration()
    public var stateConfiguration: SwiftUIStateConfiguration = SwiftUIStateConfiguration()
    public var renderConfiguration: SwiftUIRenderConfiguration = SwiftUIRenderConfiguration()
    
    // New observability configuration
    public var enableMetadataStreaming: Bool = true
    public var enableScreenshotCapture: Bool = true
    public var enableHierarchyAnalysis: Bool = true
    public var enableContextInspection: Bool = true
    
    public var metadataStreamingConfiguration: MetadataStreamingConfiguration = MetadataStreamingConfiguration()
    public var screenshotCaptureConfiguration: ScreenshotCaptureConfiguration = ScreenshotCaptureConfiguration()
    public var hierarchyAnalyzerConfiguration: ViewHierarchyAnalyzerConfiguration = ViewHierarchyAnalyzerConfiguration()
    public var contextInspectorConfiguration: ContextInspectorConfiguration = ContextInspectorConfiguration()
    
    public init() {}
    
    public func toHotReloadConfiguration() -> AxiomHotReloadConfiguration {
        var config = AxiomHotReloadConfiguration()
        config.enableHotReload = enableHotReload
        config.enableDebugMode = enableDebugMode
        config.autoConnect = autoConnect
        config.showStatusIndicator = showStatusIndicator
        config.showDebugInfo = showDebugInfo
        config.enableStateLogging = enableStateLogging
        config.clearOnDisconnect = clearOnDisconnect
        config.statusIndicatorPadding = statusIndicatorPadding
        config.networkConfiguration = ConnectionConfiguration(
            host: networkConfiguration.host,
            port: networkConfiguration.port,
            path: "/ws",
            clientId: UUID().uuidString,
            clientName: "AxiomObservabilityClient",
            enableAutoReconnect: true,
            maxReconnectAttempts: 5,
            baseReconnectDelay: 1.0,
            maxReconnectDelay: 30.0,
            enableHeartbeat: true,
            heartbeatInterval: 30.0,
            enableStatePreservation: true,
            enableDebugLogging: false
        )
        config.stateConfiguration = stateConfiguration
        config.renderConfiguration = renderConfiguration
        return config
    }
}

public struct ObservabilityData {
    public let lastMetadataUpdate: Date
    public let streamedMetadata: AppMetadata
    public let isStreaming: Bool
    
    public init(lastMetadataUpdate: Date, streamedMetadata: AppMetadata, isStreaming: Bool) {
        self.lastMetadataUpdate = lastMetadataUpdate
        self.streamedMetadata = streamedMetadata
        self.isStreaming = isStreaming
    }
}

public struct ComprehensiveObservabilityReport: Codable {
    public let timestamp: Date
    public let metadata: AppMetadata
    public let contextAnalysis: ContextAnalysisResult
    public let hierarchyAnalysis: ViewHierarchyAnalysis?
    public let performanceSnapshot: PerformanceSnapshot
    public let systemHealth: SystemHealth
    public let recommendations: [ComprehensiveRecommendation]
    
    public init(timestamp: Date, metadata: AppMetadata, contextAnalysis: ContextAnalysisResult, hierarchyAnalysis: ViewHierarchyAnalysis?, performanceSnapshot: PerformanceSnapshot, systemHealth: SystemHealth, recommendations: [ComprehensiveRecommendation]) {
        self.timestamp = timestamp
        self.metadata = metadata
        self.contextAnalysis = contextAnalysis
        self.hierarchyAnalysis = hierarchyAnalysis
        self.performanceSnapshot = performanceSnapshot
        self.systemHealth = systemHealth
        self.recommendations = recommendations
    }
}

public struct ComprehensiveRecommendation: Codable {
    public let category: RecommendationCategory
    public let priority: Priority
    public let title: String
    public let description: String
    public let impact: Impact
    
    public init(category: RecommendationCategory, priority: Priority, title: String, description: String, impact: Impact) {
        self.category = category
        self.priority = priority
        self.title = title
        self.description = description
        self.impact = impact
    }
}

public enum RecommendationCategory: String, Codable {
    case context
    case hierarchy
    case performance
    case memory
    case network
    case architecture
}

// MARK: - Convenience Initializers

public extension AxiomObservabilityClient {
    
    /// Create AxiomObservabilityClient with default configuration
    init(@ViewBuilder content: @escaping () -> Content) {
        self.init(configuration: AxiomObservabilityConfiguration(), content: content)
    }
    
    /// Create AxiomObservabilityClient with custom host and port
    init(
        host: String,
        port: Int = 8080,
        @ViewBuilder content: @escaping () -> Content
    ) {
        var config = AxiomObservabilityConfiguration()
        config.networkConfiguration.host = host
        config.networkConfiguration.port = port
        self.init(configuration: config, content: content)
    }
    
    /// Create AxiomObservabilityClient for development with all features enabled
    static func development(
        host: String = "localhost",
        port: Int = 8080,
        @ViewBuilder content: @escaping () -> Content
    ) -> AxiomObservabilityClient<Content> {
        var config = AxiomObservabilityConfiguration()
        config.enableDebugMode = true
        config.enableStateLogging = true
        config.showDebugInfo = true
        config.networkConfiguration.host = host
        config.networkConfiguration.port = port
        config.enableMetadataStreaming = true
        config.enableScreenshotCapture = true
        config.enableHierarchyAnalysis = true
        config.enableContextInspection = true
        
        return AxiomObservabilityClient(
            configuration: config,
            content: content
        )
    }
    
    /// Create AxiomObservabilityClient for production (minimal observability features)
    static func production(
        @ViewBuilder content: @escaping () -> Content
    ) -> AxiomObservabilityClient<Content> {
        var config = AxiomObservabilityConfiguration()
        config.enableDebugMode = false
        config.enableStateLogging = false
        config.showDebugInfo = false
        config.enableMetadataStreaming = false
        config.enableScreenshotCapture = false
        config.enableHierarchyAnalysis = false
        config.enableContextInspection = false
        
        return AxiomObservabilityClient(
            configuration: config,
            content: content
        )
    }
}

// MARK: - Missing Types

public struct AppMetadata: Codable {
    public let timestamp: Date
    public let contextHierarchy: [ContextInfo]
    public let presentationBindings: [PresentationBinding]
    public let clientMetrics: [ClientMetric]
    public let performanceSnapshot: PerformanceSnapshot
    public let memoryUsage: SystemMemoryUsage
    public let networkActivity: NetworkActivity
    
    public init(
        timestamp: Date,
        contextHierarchy: [ContextInfo],
        presentationBindings: [PresentationBinding],
        clientMetrics: [ClientMetric],
        performanceSnapshot: PerformanceSnapshot,
        memoryUsage: SystemMemoryUsage,
        networkActivity: NetworkActivity
    ) {
        self.timestamp = timestamp
        self.contextHierarchy = contextHierarchy
        self.presentationBindings = presentationBindings
        self.clientMetrics = clientMetrics
        self.performanceSnapshot = performanceSnapshot
        self.memoryUsage = memoryUsage
        self.networkActivity = networkActivity
    }
}

public struct ComponentScreenshot: Codable {
    public let componentId: String
    public let componentName: String
    public let screenshotData: Data
    public let captureTimestamp: Date
    public let bounds: CGRect
    public let scale: CGFloat
    
    public init(
        componentId: String,
        componentName: String,
        screenshotData: Data,
        captureTimestamp: Date,
        bounds: CGRect,
        scale: CGFloat
    ) {
        self.componentId = componentId
        self.componentName = componentName
        self.screenshotData = screenshotData
        self.captureTimestamp = captureTimestamp
        self.bounds = bounds
        self.scale = scale
    }
}

public struct NetworkConfiguration {
    public var host: String = "localhost"
    public var port: Int = 8080
    public var useSSL: Bool = false
    public var timeout: TimeInterval = 30.0
    
    public init() {}
}

public enum Impact: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}