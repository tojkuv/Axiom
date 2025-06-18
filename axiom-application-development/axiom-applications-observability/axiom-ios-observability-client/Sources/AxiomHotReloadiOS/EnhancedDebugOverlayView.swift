import SwiftUI
import NetworkClient
import SwiftUIRenderer

public struct EnhancedDebugOverlayView: View {
    
    // Core components
    @ObservedObject var connectionManager: ConnectionManager
    @ObservedObject var renderer: SwiftUIJSONRenderer
    @ObservedObject var stateManager: SwiftUIStateManager
    @ObservedObject var memoryProfiler: MemoryProfiler
    @ObservedObject var cpuProfiler: CPUProfiler
    @ObservedObject var renderingProfiler: RenderingProfiler
    @ObservedObject var networkOptimizer: NetworkOptimizer
    @ObservedObject var stateDebugger: StateDebugger
    
    // New observability components
    @ObservedObject var metadataStreamer: MetadataStreamer
    @ObservedObject var screenshotCapture: ScreenshotCapture
    @ObservedObject var hierarchyAnalyzer: ViewHierarchyAnalyzer
    @ObservedObject var contextInspector: ContextInspector
    
    let observabilityData: ObservabilityData?
    let configuration: AxiomObservabilityConfiguration
    
    @State private var selectedTab: DebugTab = .overview
    @State private var isExpanded = true
    @State private var showingFullReport = false
    @State private var currentReport: ComprehensiveObservabilityReport?
    
    public init(
        connectionManager: ConnectionManager,
        renderer: SwiftUIJSONRenderer,
        stateManager: SwiftUIStateManager,
        memoryProfiler: MemoryProfiler,
        cpuProfiler: CPUProfiler,
        renderingProfiler: RenderingProfiler,
        networkOptimizer: NetworkOptimizer,
        stateDebugger: StateDebugger,
        metadataStreamer: MetadataStreamer,
        screenshotCapture: ScreenshotCapture,
        hierarchyAnalyzer: ViewHierarchyAnalyzer,
        contextInspector: ContextInspector,
        observabilityData: ObservabilityData?,
        configuration: AxiomObservabilityConfiguration
    ) {
        self.connectionManager = connectionManager
        self.renderer = renderer
        self.stateManager = stateManager
        self.memoryProfiler = memoryProfiler
        self.cpuProfiler = cpuProfiler
        self.renderingProfiler = renderingProfiler
        self.networkOptimizer = networkOptimizer
        self.stateDebugger = stateDebugger
        self.metadataStreamer = metadataStreamer
        self.screenshotCapture = screenshotCapture
        self.hierarchyAnalyzer = hierarchyAnalyzer
        self.contextInspector = contextInspector
        self.observabilityData = observabilityData
        self.configuration = configuration
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            if isExpanded {
                // Tab selector
                tabSelector
                
                // Content
                ScrollView {
                    VStack(spacing: 16) {
                        switch selectedTab {
                        case .overview:
                            overviewContent
                        case .performance:
                            performanceContent
                        case .network:
                            networkContent
                        case .memory:
                            memoryContent
                        case .context:
                            contextContent
                        case .hierarchy:
                            hierarchyContent
                        case .screenshots:
                            screenshotContent
                        case .metadata:
                            metadataContent
                        }
                    }
                    .padding()
                }
                .frame(maxHeight: 400)
            }
        }
        .background(Color.black.opacity(0.9))
        .cornerRadius(12)
        .padding()
        .sheet(isPresented: $showingFullReport) {
            if let report = currentReport {
                FullReportView(report: report)
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Image(systemName: "eye.circle.fill")
                .foregroundColor(.blue)
            
            Text("Axiom Observability")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            statusIndicators
            
            Button(action: generateFullReport) {
                Image(systemName: "doc.text.magnifyingglass")
                    .foregroundColor(.blue)
            }
            
            Button(action: { isExpanded.toggle() }) {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(.white)
            }
        }
        .padding()
    }
    
    private var statusIndicators: some View {
        HStack(spacing: 8) {
            // Connection status
            Circle()
                .fill(connectionManager.isConnected ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            // Streaming status
            if metadataStreamer.isStreaming {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
            
            // Issues indicator
            if hasIssues {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 8)
            }
        }
    }
    
    private var hasIssues: Bool {
        return cpuProfiler.currentCPUUsage.total > 70 ||
               memoryProfiler.currentMemoryUsage.resident > 500_000_000 ||
               !connectionManager.isConnected
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(DebugTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        Text(tab.title)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedTab == tab ? Color.blue : Color.clear)
                            .foregroundColor(selectedTab == tab ? .white : .gray)
                            .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Content Views
    
    private var overviewContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            MetricCard(
                title: "Connection",
                value: connectionManager.connectionState.rawValue,
                color: connectionManager.isConnected ? .green : .red
            )
            
            MetricCard(
                title: "CPU Usage",
                value: String(format: "%.1f%%", cpuProfiler.currentCPUUsage.total),
                color: cpuProfiler.currentCPUUsage.total > 70 ? .red : .green
            )
            
            MetricCard(
                title: "Memory",
                value: formatBytes(Int64(memoryProfiler.currentMemoryUsage.resident)),
                color: memoryProfiler.currentMemoryUsage.resident > 500_000_000 ? .orange : .green
            )
            
            MetricCard(
                title: "Frame Time",
                value: String(format: "%.1fms", renderingProfiler.currentRenderingMetrics.frameTime),
                color: renderingProfiler.currentRenderingMetrics.frameTime > 16.67 ? .orange : .green
            )
            
            if let observabilityData = observabilityData {
                MetricCard(
                    title: "Contexts",
                    value: "\(observabilityData.streamedMetadata.contextHierarchy.count)",
                    color: .blue
                )
                
                MetricCard(
                    title: "Metadata Streaming",
                    value: metadataStreamer.isStreaming ? "Active" : "Inactive",
                    color: metadataStreamer.isStreaming ? .green : .gray
                )
            }
        }
    }
    
    private var performanceContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "CPU Performance")
            
            MetricRow(
                label: "Total Usage",
                value: String(format: "%.1f%%", cpuProfiler.currentCPUUsage.total)
            )
            
            MetricRow(
                label: "App Usage",
                value: String(format: "%.1f%%", cpuProfiler.currentCPUUsage.total)
            )
            
            SectionHeader(title: "Rendering Performance")
            
            MetricRow(
                label: "Average Frame Time",
                value: String(format: "%.2fms", renderingProfiler.currentRenderingMetrics.frameTime)
            )
            
            MetricRow(
                label: "Frame Drops",
                value: "\(renderingProfiler.currentRenderingMetrics.frameDrops)"
            )
            
            MetricRow(
                label: "FPS",
                value: String(format: "%.1f", 1000.0 / renderingProfiler.currentRenderingMetrics.frameTime)
            )
        }
    }
    
    private var memoryContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Memory Usage")
            
            MetricRow(
                label: "Total Memory",
                value: formatBytes(Int64(memoryProfiler.currentMemoryUsage.resident))
            )
            
            MetricRow(
                label: "App Memory",
                value: formatBytes(Int64(memoryProfiler.currentMemoryUsage.footprint))
            )
            
            MetricRow(
                label: "Available Memory",
                value: formatBytes(Int64(memoryProfiler.currentMemoryUsage.peak))
            )
            
            MetricRow(
                label: "Memory Pressure",
                value: memoryProfiler.memoryPressureLevel.rawValue.capitalized
            )
            
            SectionHeader(title: "Memory Growth")
            
            MetricRow(
                label: "Growth %",
                value: String(format: "%.1f%%", memoryProfiler.currentMemoryUsage.growth)
            )
        }
    }
    
    private var networkContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Network Metrics")
            
            MetricRow(
                label: "Average Latency",
                value: String(format: "%.0fms", networkOptimizer.networkMetrics.roundTripTime * 1000)
            )
            
            MetricRow(
                label: "Bytes Sent",
                value: formatBytes(Int64(networkOptimizer.networkMetrics.bytesTransmitted))
            )
            
            MetricRow(
                label: "Bytes Received",
                value: formatBytes(Int64(networkOptimizer.networkMetrics.bytesReceived))
            )
            
            MetricRow(
                label: "Success Rate",
                value: String(format: "%.1f%%", (1.0 - networkOptimizer.networkMetrics.packetLoss) * 100)
            )
            
            SectionHeader(title: "Connection")
            
            MetricRow(
                label: "Status",
                value: connectionManager.connectionState.rawValue
            )
            
            if let diagnostics = connectionManager.getCurrentErrorMessage() {
                MetricRow(
                    label: "Last Error",
                    value: diagnostics.description
                )
            }
        }
    }
    
    private var contextContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Context Analysis")
            
            if let relationships = contextInspector.contextRelationships {
                MetricRow(
                    label: "Total Contexts",
                    value: "\(relationships.nodes.count)"
                )
                
                MetricRow(
                    label: "Relationships",
                    value: "\(relationships.edges.count)"
                )
                
                let rootContexts = relationships.nodes.filter { $0.type == .root }
                MetricRow(
                    label: "Root Contexts",
                    value: "\(rootContexts.count)"
                )
            }
            
            Button("Analyze Contexts") {
                Task {
                    let _ = await contextInspector.performComprehensiveAnalysis()
                }
            }
            .foregroundColor(.blue)
        }
    }
    
    private var hierarchyContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "View Hierarchy")
            
            if let analysis = hierarchyAnalyzer.analysisResults {
                MetricRow(
                    label: "Total Views",
                    value: "\(analysis.hierarchy.totalNodes)"
                )
                
                MetricRow(
                    label: "Max Depth",
                    value: "\(analysis.hierarchy.maxDepth)"
                )
                
                MetricRow(
                    label: "Complexity Score",
                    value: String(format: "%.1f", analysis.complexityAnalysis.complexityScore)
                )
                
                MetricRow(
                    label: "Performance Issues",
                    value: "\(analysis.performanceIssues.count)"
                )
            }
            
            Button("Analyze Hierarchy") {
                Task {
                    try? await hierarchyAnalyzer.analyzeCurrentHierarchy()
                }
            }
            .foregroundColor(.blue)
        }
    }
    
    private var screenshotContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Screenshot Capture")
            
            MetricRow(
                label: "Captures Sent",
                value: "\(screenshotCapture.captureStatistics.totalCaptures)"
            )
            
            MetricRow(
                label: "Successful Captures",
                value: "\(screenshotCapture.captureStatistics.successfulCaptures)"
            )
            
            MetricRow(
                label: "Status",
                value: screenshotCapture.isCapturing ? "Capturing" : "Ready"
            )
            
            Button("Generate Screenshots") {
                Task {
                    let _ = await screenshotCapture.generateComponentScreenshots()
                }
            }
            .foregroundColor(.blue)
            .disabled(screenshotCapture.isCapturing)
        }
    }
    
    private var metadataContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Metadata Streaming")
            
            MetricRow(
                label: "Streaming",
                value: metadataStreamer.isStreaming ? "Active" : "Inactive"
            )
            
            MetricRow(
                label: "Streams Sent",
                value: "\(metadataStreamer.streamingStatistics.totalStreamsSent)"
            )
            
            if let lastStream = metadataStreamer.streamingStatistics.lastStreamTime {
                MetricRow(
                    label: "Last Stream",
                    value: formatRelativeTime(lastStream)
                )
            }
            
            if let observabilityData = observabilityData {
                SectionHeader(title: "Latest Metadata")
                
                MetricRow(
                    label: "Contexts",
                    value: "\(observabilityData.streamedMetadata.contextHierarchy.count)"
                )
                
                MetricRow(
                    label: "Bindings",
                    value: "\(observabilityData.streamedMetadata.presentationBindings.count)"
                )
                
                MetricRow(
                    label: "Metrics",
                    value: "\(observabilityData.streamedMetadata.clientMetrics.count)"
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateFullReport() {
        Task {
            // Simulate generating a comprehensive report
            let metadata = await metadataStreamer.collectCurrentMetadata()
            let contextAnalysis = await contextInspector.performComprehensiveAnalysis()
            
            var hierarchyAnalysis: ViewHierarchyAnalysis?
            do {
                hierarchyAnalysis = try await hierarchyAnalyzer.analyzeCurrentHierarchy()
            } catch {
                print("Failed to analyze view hierarchy: \(error)")
            }
            
            let performanceSnapshot = PerformanceSnapshot(
                cpuUsage: cpuProfiler.currentCPUUsage.total,
                memoryUsage: Int64(memoryProfiler.currentMemoryUsage.resident),
                renderTime: renderingProfiler.currentRenderingMetrics.frameTime,
                networkLatency: networkOptimizer.networkMetrics.roundTripTime
            )
            
            let report = ComprehensiveObservabilityReport(
                timestamp: Date(),
                metadata: metadata,
                contextAnalysis: contextAnalysis,
                hierarchyAnalysis: hierarchyAnalysis,
                performanceSnapshot: performanceSnapshot,
                systemHealth: SystemHealth(
                    overallStatus: .excellent,
                    networkHealth: .excellent,
                    renderingHealth: .excellent,
                    stateManagementHealth: .excellent,
                    lastHealthCheck: Date(),
                    healthTrend: .stable,
                    uptime: 0,
                    performance: SystemPerformanceScore()
                ),
                recommendations: []
            )
            
            await MainActor.run {
                currentReport = report
                showingFullReport = true
            }
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: bytes)
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Supporting Views

private struct MetricCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.headline)
                    .foregroundColor(color)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}

private struct MetricRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .foregroundColor(.white)
        }
    }
}

private struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.top, 8)
    }
}

private struct FullReportView: View {
    let report: ComprehensiveObservabilityReport
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Comprehensive Observability Report")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Generated: \(report.timestamp, style: .date) \(report.timestamp, style: .time)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Performance Summary
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Performance Summary")
                            .font(.headline)
                        
                        Text("CPU: \(String(format: "%.1f%%", report.performanceSnapshot.cpuUsage))")
                        Text("Memory: \(formatBytes(report.performanceSnapshot.memoryUsage))")
                        Text("Frame Time: \(String(format: "%.1fms", report.performanceSnapshot.renderTime))")
                        Text("Network Latency: \(String(format: "%.0fms", report.performanceSnapshot.networkLatency))")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Context Analysis
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Context Analysis")
                            .font(.headline)
                        
                        Text("Total Contexts: \(report.contextAnalysis.totalContexts)")
                        Text("Architectural Issues: \(report.contextAnalysis.architecturalIssues.count)")
                        Text("Performance Score: \(String(format: "%.1f", report.contextAnalysis.performanceSummary.performanceScore))")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Hierarchy Analysis
                    if let hierarchyAnalysis = report.hierarchyAnalysis {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("View Hierarchy")
                                .font(.headline)
                            
                            Text("Total Views: \(hierarchyAnalysis.hierarchy.totalNodes)")
                            Text("Max Depth: \(hierarchyAnalysis.hierarchy.maxDepth)")
                            Text("Complexity Score: \(String(format: "%.1f", hierarchyAnalysis.complexityAnalysis.complexityScore))")
                            Text("Performance Issues: \(hierarchyAnalysis.performanceIssues.count)")
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            #if canImport(UIKit)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                // Dismiss action would be handled by parent
            })
            #endif
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Debug Tab Enum

private enum DebugTab: String, CaseIterable {
    case overview = "overview"
    case performance = "performance"
    case memory = "memory"
    case network = "network"
    case context = "context"
    case hierarchy = "hierarchy"
    case screenshots = "screenshots"
    case metadata = "metadata"
    
    var title: String {
        switch self {
        case .overview: return "Overview"
        case .performance: return "Performance"
        case .memory: return "Memory"
        case .network: return "Network"
        case .context: return "Context"
        case .hierarchy: return "Hierarchy"
        case .screenshots: return "Screenshots"
        case .metadata: return "Metadata"
        }
    }
}