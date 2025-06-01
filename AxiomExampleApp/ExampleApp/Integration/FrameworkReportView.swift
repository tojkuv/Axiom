import SwiftUI
import Axiom

// MARK: - Framework Report View

/// Comprehensive framework integration report showcasing all capabilities and metrics
struct FrameworkReportView: View {
    @ObservedObject var orchestrationDemo: CrossDomainOrchestrationDemo
    @State private var generatedReport: FrameworkIntegrationReport?
    @State private var isGenerating = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                reportHeader
                
                if let report = generatedReport {
                    reportContent(report)
                } else if isGenerating {
                    generatingReportView
                } else {
                    generateReportButton
                }
            }
            .padding()
        }
        .navigationTitle("Framework Report")
        .onAppear {
            generateReport()
        }
    }
    
    // MARK: - Report Header
    
    private var reportHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Framework Integration Report")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Comprehensive analysis of Axiom framework capabilities")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Report Content
    
    @ViewBuilder
    private func reportContent(_ report: FrameworkIntegrationReport) -> some View {
        // Executive Summary
        ReportSection(title: "Executive Summary", icon: "chart.bar.fill") {
            VStack(alignment: .leading, spacing: 12) {
                SummaryMetric(
                    label: "Overall Success Rate",
                    value: "\(Int(report.successRate * 100))%",
                    color: report.successRate > 0.8 ? .green : .orange
                )
                
                SummaryMetric(
                    label: "Scenarios Executed",
                    value: "\(report.executedScenarios)/\(report.totalScenarios)",
                    color: .blue
                )
                
                SummaryMetric(
                    label: "Cross-Domain Events",
                    value: "\(report.crossDomainEvents)",
                    color: .purple
                )
                
                SummaryMetric(
                    label: "AI Insights Generated",
                    value: "\(report.coordinatedInsights)",
                    color: .orange
                )
            }
        }
        
        // Scenario Results
        ReportSection(title: "Scenario Execution", icon: "gearshape.2.fill") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Successfully executed \(report.successfulScenarios) out of \(report.executedScenarios) scenarios")
                    .font(.body)
                
                Text("Average execution time: \(String(format: "%.2f", report.averageExecutionTime))s")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if report.successRate < 1.0 {
                    Text("⚠️ Some scenarios experienced issues - see detailed logs for more information")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.top, 4)
                }
            }
        }
        
        // Capability Utilization
        if !report.capabilityUtilization.isEmpty {
            ReportSection(title: "Capability Utilization", icon: "cpu.fill") {
                VStack(spacing: 8) {
                    ForEach(Array(report.capabilityUtilization.keys.sorted(by: { $0.displayName < $1.displayName })), id: \.self) { capability in
                        let utilization = report.capabilityUtilization[capability] ?? 0.0
                        CapabilityUtilizationRow(capability: capability, utilization: utilization)
                    }
                }
            }
        }
        
        // Performance Metrics
        if let metrics = report.frameworkMetrics {
            ReportSection(title: "Framework Performance", icon: "speedometer.fill") {
                VStack(spacing: 8) {
                    PerformanceMetricRow(
                        label: "Overall Integration Score",
                        value: "\(Int(metrics.overallIntegrationScore * 100))%",
                        color: .blue
                    )
                    
                    PerformanceMetricRow(
                        label: "State Binding Efficiency",
                        value: "\(Int(metrics.stateBindingEfficiency * 100))%",
                        color: .green
                    )
                    
                    PerformanceMetricRow(
                        label: "Orchestration Latency",
                        value: "\(String(format: "%.1f", metrics.orchestrationLatency * 1000))ms",
                        color: .orange
                    )
                    
                    PerformanceMetricRow(
                        label: "Error Recovery Success",
                        value: "\(Int(metrics.errorRecoverySuccess * 100))%",
                        color: .purple
                    )
                }
            }
        }
        
        // Performance Baseline
        if let baseline = report.performanceBaseline {
            ReportSection(title: "Performance Baseline", icon: "chart.line.uptrend.xyaxis") {
                VStack(spacing: 8) {
                    BaselineMetricRow(
                        label: "User Domain Response Time",
                        value: "\(String(format: "%.3f", baseline.userAverageResponseTime))s"
                    )
                    
                    BaselineMetricRow(
                        label: "Data Domain Response Time", 
                        value: "\(String(format: "%.3f", baseline.dataAverageResponseTime))s"
                    )
                    
                    BaselineMetricRow(
                        label: "User Cache Hit Rate",
                        value: "\(Int(baseline.userCacheHitRate * 100))%"
                    )
                    
                    BaselineMetricRow(
                        label: "Data Cache Hit Rate",
                        value: "\(Int(baseline.dataCacheHitRate * 100))%"
                    )
                }
            }
        }
        
        // Recommendations
        ReportSection(title: "Recommendations", icon: "lightbulb.fill") {
            VStack(alignment: .leading, spacing: 8) {
                if report.successRate == 1.0 {
                    RecommendationRow(
                        icon: "checkmark.circle.fill",
                        color: .green,
                        text: "Excellent! All scenarios executed successfully. Framework is production-ready."
                    )
                } else {
                    RecommendationRow(
                        icon: "exclamationmark.triangle.fill",
                        color: .orange,
                        text: "Some scenarios need attention. Review failed executions and error logs."
                    )
                }
                
                if report.coordinatedInsights > 0 {
                    RecommendationRow(
                        icon: "brain.head.profile",
                        color: .purple,
                        text: "AI intelligence system is generating valuable insights. Consider implementing suggested optimizations."
                    )
                }
                
                if report.crossDomainEvents > 10 {
                    RecommendationRow(
                        icon: "link.badge.plus",
                        color: .blue,
                        text: "Strong cross-domain coordination detected. Framework is demonstrating sophisticated orchestration capabilities."
                    )
                }
            }
        }
        
        // Report Metadata
        ReportSection(title: "Report Details", icon: "info.circle.fill") {
            VStack(alignment: .leading, spacing: 4) {
                Text("Generated: \(DateFormatter.localizedString(from: report.generatedAt, dateStyle: .medium, timeStyle: .short))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Framework Version: Axiom 2.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Integration Test App: Multi-Domain Architecture Demo")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Generating Report View
    
    private var generatingReportView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Generating comprehensive framework report...")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Analyzing scenario results, performance metrics, and capability utilization")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    // MARK: - Generate Report Button
    
    private var generateReportButton: some View {
        VStack(spacing: 16) {
            Text("Generate comprehensive framework integration report")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Generate Report") {
                generateReport()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(40)
    }
    
    // MARK: - Report Generation
    
    private func generateReport() {
        isGenerating = true
        
        Task {
            // Simulate report generation delay
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            let report = await orchestrationDemo.generateFrameworkIntegrationReport()
            
            await MainActor.run {
                self.generatedReport = report
                self.isGenerating = false
            }
        }
    }
}

// MARK: - Supporting Views

private struct ReportSection<Content: View>: View {
    let title: String
    let icon: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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

private struct SummaryMetric: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}

private struct PerformanceMetricRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

private struct BaselineMetricRow: View {
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

private struct RecommendationRow: View {
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

struct FrameworkReportView_Previews: PreviewProvider {
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
            FrameworkReportView(orchestrationDemo: orchestrationDemo)
        }
    }
}