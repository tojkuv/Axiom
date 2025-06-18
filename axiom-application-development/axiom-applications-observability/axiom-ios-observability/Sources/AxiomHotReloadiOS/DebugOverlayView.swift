import SwiftUI
import NetworkClient
import SwiftUIRenderer

public struct DebugOverlayView: View {
    
    @ObservedObject var connectionManager: ConnectionManager
    @ObservedObject var renderer: SwiftUIJSONRenderer
    @ObservedObject var stateManager: SwiftUIStateManager
    @ObservedObject var memoryProfiler: MemoryProfiler
    @ObservedObject var cpuProfiler: CPUProfiler
    @ObservedObject var renderingProfiler: RenderingProfiler
    @ObservedObject var networkOptimizer: NetworkOptimizer
    @ObservedObject var stateDebugger: StateDebugger
    let configuration: AxiomHotReloadConfiguration
    
    @State private var selectedTab: DebugTab = .connection
    @State private var isExpanded = false
    
    public init(
        connectionManager: ConnectionManager,
        renderer: SwiftUIJSONRenderer,
        stateManager: SwiftUIStateManager,
        memoryProfiler: MemoryProfiler,
        cpuProfiler: CPUProfiler,
        renderingProfiler: RenderingProfiler,
        networkOptimizer: NetworkOptimizer,
        stateDebugger: StateDebugger,
        configuration: AxiomHotReloadConfiguration
    ) {
        self.connectionManager = connectionManager
        self.renderer = renderer
        self.stateManager = stateManager
        self.memoryProfiler = memoryProfiler
        self.cpuProfiler = cpuProfiler
        self.renderingProfiler = renderingProfiler
        self.networkOptimizer = networkOptimizer
        self.stateDebugger = stateDebugger
        self.configuration = configuration
    }
    
    public var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 0) {
                // Header with tabs
                debugHeader
                
                // Content area
                if isExpanded {
                    debugContent
                        .transition(.move(edge: .bottom))
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .shadow(radius: 10)
            )
            .padding()
        }
        .animation(.spring(), value: isExpanded)
    }
    
    // MARK: - Debug Header
    
    private var debugHeader: some View {
        HStack {
            // Tab selection
            HStack(spacing: 0) {
                ForEach(DebugTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        VStack(spacing: 2) {
                            Image(systemName: tab.icon)
                                .font(.caption)
                            Text(tab.title)
                                .font(.caption2)
                        }
                        .foregroundColor(selectedTab == tab ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedTab == tab ? Color.blue.opacity(0.2) : Color.clear)
                        )
                    }
                }
            }
            
            // Expand/collapse button
            Button(action: { isExpanded.toggle() }) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 0 : 180))
                    .animation(.easeInOut, value: isExpanded)
            }
        }
        .padding()
    }
    
    // MARK: - Debug Content
    
    @ViewBuilder
    private var debugContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                switch selectedTab {
                case .connection:
                    connectionDebugView
                case .renderer:
                    rendererDebugView
                case .state:
                    stateDebugView
                case .performance:
                    performanceDebugView
                case .config:
                    configDebugView
                }
            }
            .padding()
        }
        .frame(maxHeight: 300)
    }
    
    // MARK: - Connection Debug View
    
    private var connectionDebugView: some View {
        VStack(alignment: .leading, spacing: 8) {
            DebugSectionHeader(title: "Connection Status")
            
            DebugInfoRow(label: "State", value: connectionStateText)
            DebugInfoRow(label: "Host", value: connectionManager.configuration.host)
            DebugInfoRow(label: "Port", value: "\(connectionManager.configuration.port)")
            DebugInfoRow(label: "Auto Reconnect", value: connectionManager.configuration.enableAutoReconnect ? "Yes" : "No")
            DebugInfoRow(label: "Reconnect Attempts", value: "\(connectionManager.reconnectAttempts)")
            DebugInfoRow(label: "Last Error", value: connectionManager.lastError?.localizedDescription ?? "None")
            
            if let diagnostics = connectionManager.networkDiagnostics {
                DebugInfoRow(label: "Network Available", value: diagnostics.isNetworkAvailable ? "Yes" : "No")
                DebugInfoRow(label: "Connection Quality", value: diagnostics.connectionQuality.displayName)
                DebugInfoRow(label: "Consecutive Failures", value: "\(diagnostics.consecutiveFailures)")
            }
            
            // Connection actions
            HStack {
                Button("Connect") {
                    connectionManager.connect()
                }
                .buttonStyle(.bordered)
                .disabled(connectionManager.isConnected)
                
                Button("Disconnect") {
                    connectionManager.disconnect()
                }
                .buttonStyle(.bordered)
                .disabled(!connectionManager.isConnected)
                
                Button("Clear Error") {
                    connectionManager.clearError()
                }
                .buttonStyle(.bordered)
                
                Button("Trigger Recovery") {
                    connectionManager.triggerRecovery()
                }
                .buttonStyle(.bordered)
            }
            .font(.caption)
        }
    }
    
    // MARK: - Renderer Debug View
    
    private var rendererDebugView: some View {
        VStack(alignment: .leading, spacing: 8) {
            DebugSectionHeader(title: "Renderer Status")
            
            DebugInfoRow(label: "Is Rendering", value: renderer.isRendering ? "Yes" : "No")
            DebugInfoRow(label: "Has Rendered View", value: renderer.renderedView != nil ? "Yes" : "No")
            DebugInfoRow(label: "Total Renders", value: "\(renderer.renderingStats.totalRenders)")
            DebugInfoRow(label: "Successful Renders", value: "\(renderer.renderingStats.successfulRenders)")
            DebugInfoRow(label: "Success Rate", value: String(format: "%.1f%%", renderer.renderingStats.successRate * 100))
            DebugInfoRow(label: "Average Render Time", value: String(format: "%.2fms", renderer.renderingStats.averageRenderTime * 1000))
            DebugInfoRow(label: "Last Error", value: renderer.lastError?.localizedDescription ?? "None")
            
            // Renderer actions
            HStack {
                Button("Clear Cache") {
                    renderer.clearCache()
                }
                .buttonStyle(.bordered)
                
                Button("Reset") {
                    renderer.reset()
                }
                .buttonStyle(.bordered)
            }
            .font(.caption)
        }
    }
    
    // MARK: - State Debug View
    
    private var stateDebugView: some View {
        VStack(alignment: .leading, spacing: 8) {
            DebugSectionHeader(title: "State Management")
            
            let allState = stateManager.getAllState()
            
            DebugInfoRow(label: "State Keys", value: "\(allState.count)")
            
            if !allState.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current State:")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    ForEach(Array(allState.keys.sorted().prefix(10)), id: \.self) { key in
                        HStack {
                            Text(key)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(allState[key]?.value ?? "nil")")
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                    
                    if allState.count > 10 {
                        Text("... and \(allState.count - 10) more")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // State preservation info
            if let preservationStats = renderer.getStatePreservationStats() {
                Divider()
                DebugSectionHeader(title: "State Preservation")
                DebugInfoRow(label: "Total Snapshots", value: "\(preservationStats.totalSnapshots)")
                DebugInfoRow(label: "Storage Used", value: String(format: "%.2f MB", preservationStats.storageUsedMB))
                DebugInfoRow(label: "Preservation Enabled", value: preservationStats.preservationEnabled ? "Yes" : "No")
                if let lastSnapshot = preservationStats.lastSnapshotDate {
                    DebugInfoRow(label: "Last Snapshot", value: DateFormatter.localizedString(from: lastSnapshot, dateStyle: .none, timeStyle: .medium))
                }
            }
            
            // State debugging info
            if stateDebugger.isMonitoring {
                Divider()
                DebugSectionHeader(title: "State Debugging")
                
                let stats = stateDebugger.monitoringStatistics
                DebugInfoRow(label: "Monitoring", value: "Active")
                DebugInfoRow(label: "Snapshots", value: "\(stats.totalSnapshots)")
                DebugInfoRow(label: "Change Events", value: "\(stats.totalChangeEvents)")
                DebugInfoRow(label: "Issues Detected", value: "\(stats.totalIssuesDetected)")
                DebugInfoRow(label: "Tracked Keys", value: "\(stats.trackedKeys)")
                
                if !stateDebugger.detectedStateIssues.isEmpty {
                    Text("• Recent: \(stateDebugger.detectedStateIssues.last?.description ?? "None")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            // State actions
            VStack(spacing: 8) {
                HStack {
                    Button("Clear State") {
                        stateManager.clearAllState()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Export Debug Data") {
                        let debugData = renderer.exportStatePreservationData()
                        print("State Debug Data:", debugData)
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Capture Snapshot") {
                        let _ = stateDebugger.captureStateSnapshot(reason: "Manual capture")
                    }
                    .buttonStyle(.bordered)
                }
                .font(.caption)
                
                HStack {
                    Button("Inspect State") {
                        let _ = stateDebugger.inspectState()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Validate State") {
                        let _ = stateDebugger.validateState()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("State Analysis") {
                        let _ = stateDebugger.generateStateAnalysis()
                    }
                    .buttonStyle(.bordered)
                }
                .font(.caption)
                
                HStack {
                    Button(stateDebugger.isMonitoring ? "Stop Debugging" : "Start Debugging") {
                        if stateDebugger.isMonitoring {
                            stateDebugger.stopMonitoring()
                        } else {
                            stateDebugger.startMonitoring()
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Export State Data") {
                        let _ = stateDebugger.exportStateData()
                    }
                    .buttonStyle(.bordered)
                }
                .font(.caption)
            }
        }
    }
    
    // MARK: - Performance Debug View
    
    private var performanceDebugView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // CPU Section
            DebugSectionHeader(title: "CPU Usage")
            
            let cpuUsage = cpuProfiler.currentCPUUsage
            
            DebugInfoRow(label: "Current Usage", value: String(format: "%.1f%%", cpuUsage.total))
            DebugInfoRow(label: "Baseline", value: String(format: "%.1f%%", cpuUsage.baseline))
            DebugInfoRow(label: "Growth", value: String(format: "%.1f%%", cpuUsage.growth))
            DebugInfoRow(label: "Threads", value: "\(cpuUsage.threadsCount)")
            DebugInfoRow(label: "Efficiency", value: String(format: "%.1f%%", cpuUsage.efficiency * 100))
            DebugInfoRow(label: "Pressure Level", value: cpuProfiler.cpuPressureLevel.rawValue.capitalized)
            DebugInfoRow(label: "Bottlenecks", value: "\(cpuProfiler.performanceBottlenecks.count)")
            
            if !cpuProfiler.performanceBottlenecks.isEmpty {
                Text("• Recent: \(cpuProfiler.performanceBottlenecks.last?.description ?? "None")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Divider()
            
            // Memory Section
            DebugSectionHeader(title: "Memory Usage")
            
            let memUsage = memoryProfiler.currentMemoryUsage
            let formatter = ByteCountFormatter()
            formatter.countStyle = .memory
            
            DebugInfoRow(label: "Current Usage", value: formatter.string(fromByteCount: Int64(memUsage.resident)))
            DebugInfoRow(label: "Memory Footprint", value: formatter.string(fromByteCount: Int64(memUsage.footprint)))
            DebugInfoRow(label: "Peak Usage", value: formatter.string(fromByteCount: Int64(memUsage.peak)))
            DebugInfoRow(label: "Growth", value: String(format: "%.1f%%", memUsage.growth))
            DebugInfoRow(label: "Pressure Level", value: memoryProfiler.memoryPressureLevel.rawValue.capitalized)
            DebugInfoRow(label: "Memory Leaks", value: "\(memoryProfiler.detectedLeaks.count)")
            
            Divider()
            
            // Rendering Section
            DebugSectionHeader(title: "Rendering Performance")
            
            let renderingMetrics = renderingProfiler.currentRenderingMetrics
            
            DebugInfoRow(label: "Frame Time", value: String(format: "%.1fms", renderingMetrics.frameTime * 1000))
            DebugInfoRow(label: "Frame Drops", value: "\(renderingMetrics.frameDrops)")
            DebugInfoRow(label: "Render Count", value: "\(renderingMetrics.renderCount)")
            DebugInfoRow(label: "Pressure Level", value: renderingProfiler.renderingPressureLevel.rawValue.capitalized)
            DebugInfoRow(label: "Bottlenecks", value: "\(renderingProfiler.detectedBottlenecks.count)")
            
            if !renderingProfiler.detectedBottlenecks.isEmpty {
                Text("• Recent: \(renderingProfiler.detectedBottlenecks.last?.description ?? "None")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Divider()
            
            // Network Section
            DebugSectionHeader(title: "Network Performance")
            
            let networkMetrics = networkOptimizer.networkMetrics
            let bandwidthUsage = networkOptimizer.bandwidthUsage
            
            DebugInfoRow(label: "Connection Quality", value: networkOptimizer.connectionQuality.rawValue.capitalized)
            DebugInfoRow(label: "Bandwidth", value: formatNetworkBytes(bandwidthUsage.current) + "/s")
            DebugInfoRow(label: "Bytes Transmitted", value: formatNetworkBytes(networkMetrics.bytesTransmitted))
            DebugInfoRow(label: "Bytes Received", value: formatNetworkBytes(networkMetrics.bytesReceived))
            DebugInfoRow(label: "Round Trip Time", value: String(format: "%.0fms", networkMetrics.roundTripTime * 1000))
            
            if !memoryProfiler.detectedLeaks.isEmpty {
                Divider()
                DebugSectionHeader(title: "Memory Leaks")
                DebugInfoRow(label: "Detected Leaks", value: "\(memoryProfiler.detectedLeaks.count)")
                
                ForEach(Array(memoryProfiler.detectedLeaks.prefix(3).enumerated()), id: \.offset) { index, leak in
                    HStack {
                        Text("• \(leak.component)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(leak.severity.rawValue.capitalized)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(leak.severity == .critical ? .red : .orange)
                    }
                }
                
                if memoryProfiler.detectedLeaks.count > 3 {
                    Text("... and \(memoryProfiler.detectedLeaks.count - 3) more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let lastOptimization = memoryProfiler.lastOptimizationRun {
                Divider()
                DebugSectionHeader(title: "Optimization")
                DebugInfoRow(label: "Last Run", value: DateFormatter.localizedString(from: lastOptimization, dateStyle: .none, timeStyle: .medium))
            }
            
            // Performance actions
            VStack(spacing: 8) {
                // CPU Actions
                HStack {
                    Button("CPU Analysis") {
                        let _ = cpuProfiler.generateCPUAnalysis()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Find Bottlenecks") {
                        let _ = cpuProfiler.detectBottlenecks()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Optimize CPU") {
                        let _ = cpuProfiler.optimizeCPU()
                    }
                    .buttonStyle(.bordered)
                }
                .font(.caption)
                
                // Memory Actions
                HStack {
                    Button("Memory Analysis") {
                        let _ = memoryProfiler.generateMemoryAnalysis()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Detect Leaks") {
                        let _ = memoryProfiler.detectLeaks()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Optimize Memory") {
                        let _ = memoryProfiler.optimizeMemory()
                    }
                    .buttonStyle(.bordered)
                }
                .font(.caption)
                
                // Rendering Actions
                HStack {
                    Button("Rendering Analysis") {
                        let _ = renderingProfiler.generateRenderingAnalysis()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Detect Render Issues") {
                        let _ = renderingProfiler.detectBottlenecks()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Optimize Rendering") {
                        let _ = renderingProfiler.optimizeRendering()
                    }
                    .buttonStyle(.bordered)
                }
                .font(.caption)
                
                // Network Actions
                HStack {
                    Button("Network Analysis") {
                        let _ = networkOptimizer.generateNetworkAnalysis()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Adapt Network") {
                        networkOptimizer.adaptToNetworkConditions()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Optimize Network") {
                        let _ = networkOptimizer.optimizeNetwork()
                    }
                    .buttonStyle(.bordered)
                }
                .font(.caption)
                
                // Monitoring Controls
                HStack {
                    Button(cpuProfiler.isMonitoring ? "Stop CPU" : "Start CPU") {
                        if cpuProfiler.isMonitoring {
                            cpuProfiler.stopMonitoring()
                        } else {
                            cpuProfiler.startMonitoring()
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Button(memoryProfiler.isMonitoring ? "Stop Memory" : "Start Memory") {
                        if memoryProfiler.isMonitoring {
                            memoryProfiler.stopMonitoring()
                        } else {
                            memoryProfiler.startMonitoring()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .font(.caption)
                
                HStack {
                    Button(renderingProfiler.isMonitoring ? "Stop Rendering" : "Start Rendering") {
                        if renderingProfiler.isMonitoring {
                            renderingProfiler.stopMonitoring()
                        } else {
                            renderingProfiler.startMonitoring()
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Button(networkOptimizer.isOptimizing ? "Stop Network" : "Start Network") {
                        if networkOptimizer.isOptimizing {
                            networkOptimizer.stopOptimization()
                        } else {
                            networkOptimizer.startOptimization()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .font(.caption)
            }
        }
    }
    
    // MARK: - Config Debug View
    
    private var configDebugView: some View {
        VStack(alignment: .leading, spacing: 8) {
            DebugSectionHeader(title: "Configuration")
            
            DebugInfoRow(label: "Hot Reload Enabled", value: configuration.enableHotReload ? "Yes" : "No")
            DebugInfoRow(label: "Auto Connect", value: configuration.autoConnect ? "Yes" : "No")
            DebugInfoRow(label: "Debug Mode", value: configuration.enableDebugMode ? "Yes" : "No")
            DebugInfoRow(label: "State Logging", value: configuration.enableStateLogging ? "Yes" : "No")
            DebugInfoRow(label: "Status Indicator", value: configuration.showStatusIndicator ? "Yes" : "No")
            DebugInfoRow(label: "Clear on Disconnect", value: configuration.clearOnDisconnect ? "Yes" : "No")
            
            Divider()
            
            DebugSectionHeader(title: "Network Configuration")
            DebugInfoRow(label: "Host", value: configuration.networkConfiguration.host)
            DebugInfoRow(label: "Port", value: "\(configuration.networkConfiguration.port)")
            DebugInfoRow(label: "Base Reconnect Delay", value: "\(configuration.networkConfiguration.baseReconnectDelay)s")
            DebugInfoRow(label: "Max Reconnect Attempts", value: "\(configuration.networkConfiguration.maxReconnectAttempts)")
            DebugInfoRow(label: "Enable Heartbeat", value: configuration.networkConfiguration.enableHeartbeat ? "Yes" : "No")
            
            Divider()
            
            DebugSectionHeader(title: "Render Configuration")
            DebugInfoRow(label: "View Caching", value: configuration.renderConfiguration.enableViewCaching ? "Yes" : "No")
            DebugInfoRow(label: "Fallback UI", value: configuration.renderConfiguration.enableFallbackUI ? "Yes" : "No")
            DebugInfoRow(label: "Strict Mode", value: configuration.renderConfiguration.strictModeEnabled ? "Yes" : "No")
            DebugInfoRow(label: "Max Render Time", value: "\(configuration.renderConfiguration.maxRenderTime)s")
        }
    }
    
    // MARK: - Helper Properties
    
    private var connectionStateText: String {
        switch connectionManager.connectionState {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .reconnecting:
            return "Reconnecting..."
        case .disconnected:
            return "Disconnected"
        case .error:
            return "Error"
        }
    }
}

// MARK: - Supporting Views

private struct DebugSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
    }
}

private struct DebugInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
    }
}

// MARK: - Debug Tab Enum

private enum DebugTab: String, CaseIterable {
    case connection = "connection"
    case renderer = "renderer"
    case state = "state"
    case performance = "performance"
    case config = "config"
    
    var title: String {
        switch self {
        case .connection: return "Network"
        case .renderer: return "Render"
        case .state: return "State"
        case .performance: return "Perf"
        case .config: return "Config"
        }
    }
    
    var icon: String {
        switch self {
        case .connection: return "network"
        case .renderer: return "paintbrush"
        case .state: return "memorychip"
        case .performance: return "speedometer"
        case .config: return "gearshape"
        }
    }
    
    private func formatNetworkBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Preview Support

#if DEBUG
struct DebugOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.3)
            
            DebugOverlayView(
                connectionManager: ConnectionManager(),
                renderer: SwiftUIJSONRenderer(),
                stateManager: SwiftUIStateManager(),
                memoryProfiler: MemoryProfiler(),
                cpuProfiler: CPUProfiler(),
                renderingProfiler: RenderingProfiler(),
                networkOptimizer: NetworkOptimizer(),
                stateDebugger: StateDebugger(),
                configuration: .development()
            )
        }
        .previewLayout(.sizeThatFits)
    }
}
#endif