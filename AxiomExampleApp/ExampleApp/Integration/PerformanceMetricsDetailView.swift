import SwiftUI
import Axiom

// MARK: - Performance Metrics Detail View

/// Comprehensive performance metrics view showcasing framework performance across all domains
struct PerformanceMetricsDetailView: View {
    @ObservedObject var userContext: UserContext
    @ObservedObject var dataContext: DataContext
    @ObservedObject var orchestrationDemo: CrossDomainOrchestrationDemo
    
    @State private var selectedCategory: PerformanceCategory = .overall
    @State private var refreshing = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                performanceHeader
                categorySelector
                metricsContent
                performanceInsights
            }
            .padding()
        }
        .navigationTitle("Performance Metrics")
        .navigationBarItems(trailing: refreshButton)
        .onAppear {
            refreshMetrics()
        }
    }
    
    // MARK: - Performance Header
    
    private var performanceHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: "speedometer")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Framework Performance Analytics")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Real-time monitoring across all framework domains")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            overallHealthIndicator
        }
    }
    
    private var overallHealthIndicator: some View {
        HStack(spacing: 20) {
            HealthIndicator(
                title: "User Domain",
                status: userContext.performanceMetrics?.averageResponseTime ?? 0 < 0.1 ? .excellent : .good,
                value: userContext.performanceMetrics?.averageResponseTime ?? 0
            )
            
            HealthIndicator(
                title: "Data Domain",
                status: dataContext.dataMetrics?.averageResponseTime ?? 0 < 0.1 ? .excellent : .good,
                value: dataContext.dataMetrics?.averageResponseTime ?? 0
            )
            
            HealthIndicator(
                title: "Integration",
                status: orchestrationDemo.frameworkMetrics?.overallIntegrationScore ?? 0 > 0.8 ? .excellent : .good,
                value: orchestrationDemo.frameworkMetrics?.overallIntegrationScore ?? 0
            )
        }
    }
    
    // MARK: - Category Selector
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(PerformanceCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Metrics Content
    
    @ViewBuilder
    private var metricsContent: some View {
        switch selectedCategory {
        case .overall:
            overallMetricsView
        case .userDomain:
            userDomainMetricsView
        case .dataDomain:
            dataDomainMetricsView
        case .crossDomain:
            crossDomainMetricsView
        case .intelligence:
            intelligenceMetricsView
        case .caching:
            cachingMetricsView
        case .transactions:
            transactionMetricsView
        }
    }
    
    // MARK: - Overall Metrics
    
    private var overallMetricsView: some View {
        VStack(spacing: 16) {
            MetricsCard(title: "Overall Performance", icon: "gauge.badge.plus") {
                VStack(spacing: 12) {
                    if let frameworkMetrics = orchestrationDemo.frameworkMetrics {
                        OverallMetricRow(
                            label: "Integration Score",
                            value: "\(Int(frameworkMetrics.overallIntegrationScore * 100))%",
                            color: .blue,
                            icon: "checkmark.circle"
                        )
                        
                        OverallMetricRow(
                            label: "State Binding Efficiency",
                            value: "\(Int(frameworkMetrics.stateBindingEfficiency * 100))%",
                            color: .green,
                            icon: "link.circle"
                        )
                        
                        OverallMetricRow(
                            label: "Orchestration Latency",
                            value: "\(String(format: "%.1f", frameworkMetrics.orchestrationLatency * 1000))ms",
                            color: .orange,
                            icon: "timer"
                        )
                        
                        OverallMetricRow(
                            label: "Error Recovery Rate",
                            value: "\(Int(frameworkMetrics.errorRecoverySuccess * 100))%",
                            color: .purple,
                            icon: "shield.checkered"
                        )
                    } else {
                        Text("Loading overall metrics...")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let baseline = orchestrationDemo.performanceBaseline {
                MetricsCard(title: "Performance Targets", icon: "target") {
                    VStack(spacing: 12) {
                        TargetMetricRow(
                            label: "State Access Target",
                            target: "< 10ms",
                            actual: "\(String(format: "%.1f", baseline.userAverageResponseTime * 1000))ms",
                            isOnTarget: baseline.userAverageResponseTime < 0.01
                        )
                        
                        TargetMetricRow(
                            label: "Cache Hit Rate Target", 
                            target: "> 80%",
                            actual: "\(Int(baseline.userCacheHitRate * 100))%",
                            isOnTarget: baseline.userCacheHitRate > 0.8
                        )
                        
                        TargetMetricRow(
                            label: "Data Quality Target",
                            target: "> 90%",
                            actual: "\(Int(dataContext.dataQualityScore * 100))%",
                            isOnTarget: dataContext.dataQualityScore > 0.9
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - User Domain Metrics
    
    private var userDomainMetricsView: some View {
        VStack(spacing: 16) {
            MetricsCard(title: "User Domain Performance", icon: "person.circle") {
                if let metrics = userContext.performanceMetrics {
                    VStack(spacing: 12) {
                        DomainMetricRow(
                            label: "Total Operations",
                            value: "\(metrics.totalOperations)"
                        )
                        
                        DomainMetricRow(
                            label: "Average Response Time",
                            value: "\(String(format: "%.3f", metrics.averageResponseTime))s"
                        )
                        
                        DomainMetricRow(
                            label: "Authentication Latency",
                            value: "\(String(format: "%.3f", metrics.authenticationLatency))s"
                        )
                        
                        DomainMetricRow(
                            label: "State Update Latency",
                            value: "\(String(format: "%.3f", metrics.stateUpdateLatency))s"
                        )
                        
                        DomainMetricRow(
                            label: "Cache Hit Rate",
                            value: "\(Int(metrics.cacheHitRate * 100))%"
                        )
                        
                        DomainMetricRow(
                            label: "Error Rate",
                            value: "\(String(format: "%.2f", metrics.errorRate * 100))%"
                        )
                    }
                } else {
                    Text("Loading user domain metrics...")
                        .foregroundColor(.secondary)
                }
            }
            
            MetricsCard(title: "User Activity", icon: "chart.line.uptrend.xyaxis") {
                VStack(spacing: 8) {
                    ActivityMetricRow(
                        label: "Actions Recorded",
                        value: "\(userContext.userActionHistory.count)"
                    )
                    
                    ActivityMetricRow(
                        label: "Session Status",
                        value: userContext.isAuthenticated ? "Active" : "Inactive"
                    )
                    
                    ActivityMetricRow(
                        label: "Profile Completeness",
                        value: "\(Int(userContext.currentUser.profileCompleteness * 100))%"
                    )
                }
            }
        }
    }
    
    // MARK: - Data Domain Metrics
    
    private var dataDomainMetricsView: some View {
        VStack(spacing: 16) {
            MetricsCard(title: "Data Domain Performance", icon: "cylinder") {
                if let metrics = dataContext.dataMetrics {
                    VStack(spacing: 12) {
                        DomainMetricRow(
                            label: "Total Items",
                            value: "\(metrics.totalItems)"
                        )
                        
                        DomainMetricRow(
                            label: "Active Items",
                            value: "\(metrics.activeItems)"
                        )
                        
                        DomainMetricRow(
                            label: "Total Operations",
                            value: "\(metrics.totalOperations)"
                        )
                        
                        DomainMetricRow(
                            label: "Average Response Time",
                            value: "\(String(format: "%.3f", metrics.averageResponseTime))s"
                        )
                        
                        DomainMetricRow(
                            label: "Cache Hit Rate",
                            value: "\(Int(metrics.cacheHitRate * 100))%"
                        )
                        
                        DomainMetricRow(
                            label: "Data Quality Score",
                            value: "\(Int(metrics.dataQualityScore * 100))%"
                        )
                    }
                } else {
                    Text("Loading data domain metrics...")
                        .foregroundColor(.secondary)
                }
            }
            
            MetricsCard(title: "Data Operations", icon: "square.stack.3d.up") {
                if let metrics = dataContext.dataMetrics {
                    VStack(spacing: 8) {
                        OperationMetricRow(
                            label: "Pending Operations",
                            value: "\(metrics.pendingOperations)"
                        )
                        
                        OperationMetricRow(
                            label: "Active Transactions",
                            value: "\(metrics.activeTransactions)"
                        )
                        
                        OperationMetricRow(
                            label: "Validation Errors",
                            value: "\(metrics.validationErrors)"
                        )
                        
                        OperationMetricRow(
                            label: "Sync Status",
                            value: metrics.syncStatus.rawValue.capitalized
                        )
                    }
                } else {
                    Text("Loading operation metrics...")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Cross Domain Metrics
    
    private var crossDomainMetricsView: some View {
        VStack(spacing: 16) {
            MetricsCard(title: "Cross-Domain Orchestration", icon: "gearshape.2") {
                VStack(spacing: 12) {
                    CrossDomainMetricRow(
                        label: "Total Events",
                        value: "\(orchestrationDemo.crossDomainEvents.count)"
                    )
                    
                    CrossDomainMetricRow(
                        label: "Scenarios Executed",
                        value: "\(orchestrationDemo.scenarioResults.count)"
                    )
                    
                    CrossDomainMetricRow(
                        label: "Success Rate",
                        value: "\(Int(Double(orchestrationDemo.scenarioResults.filter { $0.success }.count) / Double(max(1, orchestrationDemo.scenarioResults.count)) * 100))%"
                    )
                    
                    CrossDomainMetricRow(
                        label: "Coordinated Insights",
                        value: "\(orchestrationDemo.coordinatedInsights.count)"
                    )
                }
            }
        }
    }
    
    // MARK: - Intelligence Metrics
    
    private var intelligenceMetricsView: some View {
        VStack(spacing: 16) {
            MetricsCard(title: "Intelligence System", icon: "brain") {
                VStack(spacing: 12) {
                    IntelligenceMetricRow(
                        label: "Coordination Active",
                        value: orchestrationDemo.intelligenceCoordinationActive ? "Yes" : "No"
                    )
                    
                    IntelligenceMetricRow(
                        label: "Insights Generated",
                        value: "\(orchestrationDemo.coordinatedInsights.count)"
                    )
                    
                    IntelligenceMetricRow(
                        label: "Average Confidence",
                        value: orchestrationDemo.coordinatedInsights.isEmpty ? "N/A" : 
                            "\(Int(orchestrationDemo.coordinatedInsights.map { $0.confidence }.reduce(0, +) / Double(orchestrationDemo.coordinatedInsights.count) * 100))%"
                    )
                }
            }
        }
    }
    
    // MARK: - Caching Metrics
    
    private var cachingMetricsView: some View {
        VStack(spacing: 16) {
            MetricsCard(title: "Cache Performance", icon: "memorychip") {
                VStack(spacing: 12) {
                    CacheMetricRow(
                        label: "User Cache Hit Rate",
                        value: "\(Int((userContext.performanceMetrics?.cacheHitRate ?? 0) * 100))%"
                    )
                    
                    CacheMetricRow(
                        label: "Data Cache Hit Rate",
                        value: "\(Int((dataContext.dataMetrics?.cacheHitRate ?? 0) * 100))%"
                    )
                    
                    CacheMetricRow(
                        label: "Cache Efficiency",
                        value: "\(Int(dataContext.cacheEfficiency * 100))%"
                    )
                }
            }
        }
    }
    
    // MARK: - Transaction Metrics
    
    private var transactionMetricsView: some View {
        VStack(spacing: 16) {
            MetricsCard(title: "Transaction Performance", icon: "creditcard") {
                VStack(spacing: 12) {
                    TransactionMetricRow(
                        label: "Active Transactions",
                        value: "\(dataContext.activeTransactions.count)"
                    )
                    
                    TransactionMetricRow(
                        label: "Success Rate",
                        value: "98%" // Simulated high success rate
                    )
                    
                    TransactionMetricRow(
                        label: "Average Duration",
                        value: "0.15s" // Simulated transaction duration
                    )
                }
            }
        }
    }
    
    // MARK: - Performance Insights
    
    private var performanceInsights: some View {
        MetricsCard(title: "Performance Insights", icon: "lightbulb") {
            VStack(alignment: .leading, spacing: 12) {
                if let userMetrics = userContext.performanceMetrics,
                   let dataMetrics = dataContext.dataMetrics {
                    
                    if userMetrics.averageResponseTime < 0.05 && dataMetrics.averageResponseTime < 0.05 {
                        InsightRow(
                            icon: "checkmark.circle.fill",
                            color: .green,
                            text: "Excellent performance! Both domains are meeting sub-50ms response time targets."
                        )
                    }
                    
                    if userMetrics.cacheHitRate > 0.9 || dataMetrics.cacheHitRate > 0.9 {
                        InsightRow(
                            icon: "speedometer",
                            color: .blue,
                            text: "Cache performance is excellent with >90% hit rates improving overall system responsiveness."
                        )
                    }
                    
                    if dataContext.dataQualityScore > 0.95 {
                        InsightRow(
                            icon: "checkmark.seal.fill",
                            color: .purple,
                            text: "Data quality is outstanding at \(Int(dataContext.dataQualityScore * 100))%. Framework validation is highly effective."
                        )
                    }
                }
                
                if orchestrationDemo.coordinatedInsights.count > 0 {
                    InsightRow(
                        icon: "brain.head.profile",
                        color: .orange,
                        text: "AI intelligence system is actively generating optimization recommendations for improved performance."
                    )
                }
            }
        }
    }
    
    // MARK: - Refresh Button
    
    private var refreshButton: some View {
        Button("Refresh") {
            refreshMetrics()
        }
        .disabled(refreshing)
    }
    
    // MARK: - Refresh Metrics
    
    private func refreshMetrics() {
        refreshing = true
        
        Task {
            await userContext.loadUserMetrics()
            await dataContext.loadDataMetrics()
            await orchestrationDemo.loadFrameworkMetrics()
            
            // Simulate refresh delay
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            await MainActor.run {
                self.refreshing = false
            }
        }
    }
}

// MARK: - Performance Categories

enum PerformanceCategory: String, CaseIterable {
    case overall = "Overall"
    case userDomain = "User Domain"
    case dataDomain = "Data Domain"
    case crossDomain = "Cross-Domain"
    case intelligence = "Intelligence"
    case caching = "Caching"
    case transactions = "Transactions"
}

// MARK: - Supporting Views

private struct HealthIndicator: View {
    let title: String
    let status: HealthStatus
    let value: Double
    
    enum HealthStatus {
        case excellent
        case good
        case warning
        case critical
        
        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .blue
            case .warning: return .orange
            case .critical: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .excellent: return "checkmark.circle.fill"
            case .good: return "checkmark.circle"
            case .warning: return "exclamationmark.triangle.fill"
            case .critical: return "xmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: status.icon)
                .foregroundColor(status.color)
                .font(.title3)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(formattedValue)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var formattedValue: String {
        if title.contains("Domain") {
            return String(format: "%.3fs", value)
        } else {
            return String(format: "%.1f%%", value * 100)
        }
    }
}

private struct CategoryButton: View {
    let category: PerformanceCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? .blue : .blue.opacity(0.1))
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct MetricsCard<Content: View>: View {
    let title: String
    let icon: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            content()
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Metric Row Components

private struct OverallMetricRow: View {
    let label: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}

private struct TargetMetricRow: View {
    let label: String
    let target: String
    let actual: String
    let isOnTarget: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: isOnTarget ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(isOnTarget ? .green : .orange)
            }
            
            HStack {
                Text("Target: \(target)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Actual: \(actual)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isOnTarget ? .green : .orange)
            }
        }
    }
}

private struct DomainMetricRow: View {
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
        }
    }
}

private struct ActivityMetricRow: View {
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
        }
    }
}

private struct OperationMetricRow: View {
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
        }
    }
}

private struct CrossDomainMetricRow: View {
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
        }
    }
}

private struct IntelligenceMetricRow: View {
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
        }
    }
}

private struct CacheMetricRow: View {
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
        }
    }
}

private struct TransactionMetricRow: View {
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
        }
    }
}

private struct InsightRow: View {
    let icon: String
    let color: Color
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Preview

struct PerformanceMetricsDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let mockUserClient = UserClient(capabilities: CapabilityManager())
        let mockDataClient = DataClient(capabilities: CapabilityManager())
        let mockIntelligence = DefaultAxiomIntelligence()
        
        let userContext = UserContext(userClient: mockUserClient, intelligence: mockIntelligence)
        let dataContext = DataContext(dataClient: mockDataClient, intelligence: mockIntelligence)
        let orchestrationDemo = CrossDomainOrchestrationDemo(
            userContext: userContext,
            dataContext: dataContext,
            intelligence: mockIntelligence
        )
        
        NavigationView {
            PerformanceMetricsDetailView(
                userContext: userContext,
                dataContext: dataContext,
                orchestrationDemo: orchestrationDemo
            )
        }
    }
}