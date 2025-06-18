import SwiftUI
import AxiomStudio_Shared

struct PerformanceTabView: View {
    @EnvironmentObject private var orchestrator: StudioOrchestrator
    @State private var selectedPerformanceTab = 0
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedPerformanceTab) {
                MemoryMonitorView()
                    .tabItem {
                        Image(systemName: "memorychip")
                        Text("Memory")
                    }
                    .tag(0)
                
                PerformanceMetricsView()
                    .tabItem {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("Metrics")
                    }
                    .tag(1)
                
                CapabilityStatusView()
                    .tabItem {
                        Image(systemName: "gearshape.2")
                        Text("Capabilities")
                    }
                    .tag(2)
                
                SystemHealthView()
                    .tabItem {
                        Image(systemName: "stethoscope")
                        Text("Health")
                    }
                    .tag(3)
            }
            .navigationTitle("Performance Monitor")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Export Metrics") {
                            // Handle metrics export
                        }
                        Button("Clear Data") {
                            // Handle data clearing
                        }
                        Button("Settings") {
                            // Navigate to performance settings
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
}

struct MemoryMonitorView: View {
    @EnvironmentObject private var orchestrator: StudioOrchestrator
    @State private var memoryMetrics: [MemoryMetric] = []
    @State private var isMonitoring = false
    @State private var refreshTimer: Timer?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                MemoryOverviewCard(
                    metrics: memoryMetrics.last,
                    isMonitoring: isMonitoring
                ) {
                    toggleMonitoring()
                }
                
                if !memoryMetrics.isEmpty {
                    MemoryUsageChart(metrics: Array(memoryMetrics.suffix(20)))
                    
                    MemoryBreakdownSection(metrics: memoryMetrics.last)
                    
                    MemoryHistorySection(metrics: Array(memoryMetrics.suffix(10)))
                }
            }
            .padding()
        }
        .refreshable {
            await loadMemoryMetrics()
        }
        .onAppear {
            Task {
                await loadMemoryMetrics()
                startAutoRefresh()
            }
        }
        .onDisappear {
            stopAutoRefresh()
        }
    }
    
    private func loadMemoryMetrics() async {
        let state = await orchestrator.applicationState
        memoryMetrics = state.performance.memoryMetrics
    }
    
    private func toggleMonitoring() {
        isMonitoring.toggle()
        
        if isMonitoring {
            startAutoRefresh()
            Task {
                try? await orchestrator.processAction(.performance(.startMemoryMonitoring))
            }
        } else {
            stopAutoRefresh()
            Task {
                try? await orchestrator.processAction(.performance(.stopMemoryMonitoring))
            }
        }
    }
    
    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task {
                await loadMemoryMetrics()
            }
        }
    }
    
    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}

struct MemoryOverviewCard: View {
    let metrics: MemoryMetric?
    let isMonitoring: Bool
    let onToggleMonitoring: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Memory Usage")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if let metrics = metrics {
                        Text("Last updated: \(metrics.timestamp.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: onToggleMonitoring) {
                    HStack(spacing: 4) {
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "play.circle.fill")
                        Text(isMonitoring ? "Stop" : "Start")
                    }
                    .font(.subheadline)
                    .foregroundColor(isMonitoring ? .red : .green)
                }
                .buttonStyle(.bordered)
            }
            
            if let metrics = metrics {
                HStack(spacing: 20) {
                    MemoryStatView(
                        title: "Used",
                        value: formatBytes(metrics.usedMemory),
                        color: memoryUsageColor(for: metrics.memoryPressure)
                    )
                    
                    MemoryStatView(
                        title: "Available",
                        value: formatBytes(metrics.availableMemory),
                        color: .blue
                    )
                    
                    MemoryStatView(
                        title: "Pressure",
                        value: metrics.memoryPressure.displayName,
                        color: memoryUsageColor(for: metrics.memoryPressure)
                    )
                }
                
                ProgressView(value: Double(metrics.usedMemory) / Double(metrics.totalMemory))
                    .progressViewStyle(LinearProgressViewStyle(tint: memoryUsageColor(for: metrics.memoryPressure)))
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "memorychip")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No memory data available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Start monitoring to see memory usage")
                        .font(.caption)
                        .foregroundColor(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func memoryUsageColor(for pressure: MemoryPressure) -> Color {
        switch pressure {
        case .normal: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct MemoryStatView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .foregroundColor(color)
        }
    }
}

struct MemoryUsageChart: View {
    let metrics: [MemoryMetric]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Memory Usage Over Time")
                .font(.title3)
                .fontWeight(.semibold)
            
            if metrics.count >= 2 {
                GeometryReader { geometry in
                    Path { path in
                        let width = geometry.size.width
                        let height = geometry.size.height
                        let stepX = width / CGFloat(metrics.count - 1)
                        
                        let maxUsage = metrics.map { $0.usedMemory }.max() ?? 1
                        
                        for (index, metric) in metrics.enumerated() {
                            let x = CGFloat(index) * stepX
                            let y = height - (CGFloat(metric.usedMemory) / CGFloat(maxUsage)) * height
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Color.blue, lineWidth: 2)
                }
                .frame(height: 100)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            } else {
                Text("Collecting data...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
    }
}

struct MemoryBreakdownSection: View {
    let metrics: MemoryMetric?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Memory Breakdown")
                .font(.title3)
                .fontWeight(.semibold)
            
            if let metrics = metrics {
                VStack(spacing: 8) {
                    MemoryBreakdownRow(
                        title: "App Memory",
                        value: formatBytes(metrics.appMemoryUsage),
                        percentage: Double(metrics.appMemoryUsage) / Double(metrics.totalMemory)
                    )
                    
                    MemoryBreakdownRow(
                        title: "System Memory",
                        value: formatBytes(metrics.usedMemory - metrics.appMemoryUsage),
                        percentage: Double(metrics.usedMemory - metrics.appMemoryUsage) / Double(metrics.totalMemory)
                    )
                    
                    MemoryBreakdownRow(
                        title: "Available",
                        value: formatBytes(metrics.availableMemory),
                        percentage: Double(metrics.availableMemory) / Double(metrics.totalMemory)
                    )
                }
            } else {
                Text("No breakdown data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct MemoryBreakdownRow: View {
    let title: String
    let value: String
    let percentage: Double
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("(\(percentage * 100, specifier: "%.1f")%)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct MemoryHistorySection: View {
    let metrics: [MemoryMetric]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent History")
                .font(.title3)
                .fontWeight(.semibold)
            
            if metrics.isEmpty {
                Text("No history available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 4) {
                    ForEach(metrics.reversed(), id: \.id) { metric in
                        MemoryHistoryRow(metric: metric)
                    }
                }
            }
        }
    }
}

struct MemoryHistoryRow: View {
    let metric: MemoryMetric
    
    var body: some View {
        HStack {
            Text(metric.timestamp.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            Text(formatBytes(metric.usedMemory))
                .font(.caption)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(metric.memoryPressure.displayName)
                .font(.caption)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(metric.memoryPressure.color.opacity(0.2))
                .foregroundColor(metric.memoryPressure.color)
                .cornerRadius(4)
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct PerformanceMetricsView: View {
    @EnvironmentObject private var orchestrator: StudioOrchestrator
    @State private var performanceMetrics: [PerformanceMetric] = []
    @State private var batteryLevel: Float = 0.0
    @State private var thermalState: ThermalState = .nominal
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                SystemPerformanceCard(
                    batteryLevel: batteryLevel,
                    thermalState: thermalState
                )
                
                if !performanceMetrics.isEmpty {
                    CPUUsageSection(metrics: performanceMetrics)
                    
                    NetworkUsageSection(metrics: performanceMetrics)
                    
                    DiskUsageSection(metrics: performanceMetrics)
                }
            }
            .padding()
        }
        .refreshable {
            await loadPerformanceMetrics()
        }
        .onAppear {
            Task {
                await loadPerformanceMetrics()
            }
        }
    }
    
    private func loadPerformanceMetrics() async {
        let state = await orchestrator.applicationState
        performanceMetrics = state.performance.performanceMetrics
        
        let summary = await orchestrator.getSystemHealthSummary()
        batteryLevel = summary.batteryLevel
        thermalState = summary.thermalState
    }
}

struct SystemPerformanceCard: View {
    let batteryLevel: Float
    let thermalState: ThermalState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("System Performance")
                .font(.title2)
                .fontWeight(.semibold)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Battery")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: batteryIconName(for: batteryLevel))
                            .foregroundColor(batteryColor(for: batteryLevel))
                        
                        Text("\(batteryLevel * 100, specifier: "%.0f")%")
                            .font(.headline)
                            .foregroundColor(batteryColor(for: batteryLevel))
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Thermal State")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(thermalState.displayName)
                        .font(.headline)
                        .foregroundColor(thermalState.color)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func batteryIconName(for level: Float) -> String {
        switch level {
        case 0.0..<0.25: return "battery.25"
        case 0.25..<0.5: return "battery.50"
        case 0.5..<0.75: return "battery.75"
        default: return "battery.100"
        }
    }
    
    private func batteryColor(for level: Float) -> Color {
        switch level {
        case 0.0..<0.2: return .red
        case 0.2..<0.4: return .orange
        default: return .green
        }
    }
}

struct CPUUsageSection: View {
    let metrics: [PerformanceMetric]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CPU Usage")
                .font(.title3)
                .fontWeight(.semibold)
            
            if let latestMetric = metrics.last {
                Text("\(latestMetric.cpuUsage * 100, specifier: "%.1f")%")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(cpuUsageColor(for: latestMetric.cpuUsage))
            }
            
            // Simple CPU usage indicator
            if let latestMetric = metrics.last {
                ProgressView(value: latestMetric.cpuUsage)
                    .progressViewStyle(LinearProgressViewStyle(tint: cpuUsageColor(for: latestMetric.cpuUsage)))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func cpuUsageColor(for usage: Double) -> Color {
        switch usage {
        case 0.0..<0.5: return .green
        case 0.5..<0.8: return .orange
        default: return .red
        }
    }
}

struct NetworkUsageSection: View {
    let metrics: [PerformanceMetric]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Network Usage")
                .font(.title3)
                .fontWeight(.semibold)
            
            if let latestMetric = metrics.last {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sent")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formatBytes(latestMetric.networkBytesSent))
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Received")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formatBytes(latestMetric.networkBytesReceived))
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                }
            } else {
                Text("No network data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct DiskUsageSection: View {
    let metrics: [PerformanceMetric]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Disk I/O")
                .font(.title3)
                .fontWeight(.semibold)
            
            if let latestMetric = metrics.last {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reads")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formatBytes(latestMetric.diskBytesRead))
                            .font(.headline)
                            .foregroundColor(.purple)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Writes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formatBytes(latestMetric.diskBytesWritten))
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                }
            } else {
                Text("No disk I/O data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct CapabilityStatusView: View {
    @EnvironmentObject private var orchestrator: StudioOrchestrator
    @State private var capabilityStatuses: [CapabilityStatus] = []
    
    var body: some View {
        VStack {
            if capabilityStatuses.isEmpty {
                EmptyCapabilityStatusView()
            } else {
                List {
                    ForEach(capabilityStatuses, id: \.capabilityId) { status in
                        CapabilityStatusRowView(status: status)
                    }
                }
                .refreshable {
                    await loadCapabilityStatuses()
                }
            }
        }
        .onAppear {
            Task {
                await loadCapabilityStatuses()
            }
        }
    }
    
    private func loadCapabilityStatuses() async {
        let state = await orchestrator.applicationState
        capabilityStatuses = state.performance.capabilityStatuses
    }
}

struct EmptyCapabilityStatusView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gearshape.2")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Capability Data")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Capability status information will appear here")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct CapabilityStatusRowView: View {
    let status: CapabilityStatus
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(status.capabilityName)
                    .font(.headline)
                
                Text("Version: \(status.version)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let lastError = status.lastError {
                    Text("Error: \(lastError)")
                        .font(.caption)
                        .foregroundColor(.red)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(status.status.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(status.status.color.opacity(0.2))
                    .foregroundColor(status.status.color)
                    .cornerRadius(6)
                
                Text(status.lastUpdated.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SystemHealthView: View {
    @EnvironmentObject private var orchestrator: StudioOrchestrator
    @State private var systemHealthSummary: SystemHealthSummary?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if let summary = systemHealthSummary {
                    SystemHealthOverviewCard(summary: summary)
                    
                    SystemHealthDetailsSection(summary: summary)
                    
                    SystemHealthRecommendationsSection(summary: summary)
                } else {
                    EmptySystemHealthView()
                }
            }
            .padding()
        }
        .refreshable {
            await loadSystemHealth()
        }
        .onAppear {
            Task {
                await loadSystemHealth()
            }
        }
    }
    
    private func loadSystemHealth() async {
        systemHealthSummary = await orchestrator.getSystemHealthSummary()
    }
}

struct SystemHealthOverviewCard: View {
    let summary: SystemHealthSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("System Health")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(summary.overallStatus.displayName)
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(summary.overallStatus.color.opacity(0.2))
                    .foregroundColor(summary.overallStatus.color)
                    .cornerRadius(8)
            }
            
            Text("Last updated: \(summary.lastUpdated.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct SystemHealthDetailsSection: View {
    let summary: SystemHealthSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Health Details")
                .font(.title3)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                SystemHealthDetailRow(
                    title: "Memory Usage",
                    value: formatBytes(summary.memoryUsage),
                    status: summary.memoryUsage > 8_000_000_000 ? .warning : .healthy
                )
                
                SystemHealthDetailRow(
                    title: "Battery Level",
                    value: "\(summary.batteryLevel * 100, specifier: "%.0f")%",
                    status: summary.batteryLevel < 0.2 ? .critical : .healthy
                )
                
                SystemHealthDetailRow(
                    title: "Thermal State",
                    value: summary.thermalState.displayName,
                    status: summary.thermalState == .nominal ? .healthy : .warning
                )
                
                SystemHealthDetailRow(
                    title: "Active Capabilities",
                    value: "\(summary.activeCapabilities)",
                    status: .healthy
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct SystemHealthDetailRow: View {
    let title: String
    let value: String
    let status: HealthStatus
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Image(systemName: status.iconName)
                .foregroundColor(status.color)
                .font(.caption)
        }
    }
}

enum HealthStatus {
    case healthy
    case warning
    case critical
    
    var iconName: String {
        switch self {
        case .healthy: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .healthy: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }
}

struct SystemHealthRecommendationsSection: View {
    let summary: SystemHealthSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
                .font(.title3)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                if summary.batteryLevel < 0.2 {
                    RecommendationRow(
                        icon: "battery.25",
                        title: "Low Battery",
                        description: "Consider connecting to power to maintain optimal performance",
                        color: .red
                    )
                }
                
                if summary.memoryUsage > 8_000_000_000 {
                    RecommendationRow(
                        icon: "memorychip",
                        title: "High Memory Usage",
                        description: "Close unused applications to free up memory",
                        color: .orange
                    )
                }
                
                if summary.thermalState != .nominal {
                    RecommendationRow(
                        icon: "thermometer",
                        title: "Thermal Throttling",
                        description: "Device is warm. Performance may be reduced",
                        color: .orange
                    )
                }
                
                if summary.overallStatus == .healthy {
                    RecommendationRow(
                        icon: "checkmark.circle.fill",
                        title: "System Healthy",
                        description: "All systems are operating normally",
                        color: .green
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct RecommendationRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct EmptySystemHealthView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "stethoscope")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("System Health Unavailable")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Unable to load system health information")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}