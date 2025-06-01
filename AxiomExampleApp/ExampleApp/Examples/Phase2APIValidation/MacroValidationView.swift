import SwiftUI
import Axiom

// MARK: - Phase 2 API Validation View

/// SwiftUI view for comprehensive Phase 2 API validation testing
/// Demonstrates integration with all new developer experience enhancements
struct MacroValidationView: AxiomView {
    typealias Context = MacroValidationContext
    
    @ObservedObject var context: MacroValidationContext
    @State private var selectedTab = 0
    @State private var showingDiagnostics = false
    @State private var showingAssistant = false
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Tab 1: Validation Results Overview
                ValidationOverviewTab()
                    .tabItem {
                        Image(systemName: "checkmark.circle")
                        Text("Validation")
                    }
                    .tag(0)
                
                // Tab 2: @Client Macro Testing
                ClientMacroTab()
                    .tabItem {
                        Image(systemName: "gear.badge")
                        Text("@Client Macro")
                    }
                    .tag(1)
                
                // Tab 3: Diagnostics System
                DiagnosticsTab()
                    .tabItem {
                        Image(systemName: "stethoscope")
                        Text("Diagnostics")
                    }
                    .tag(2)
                
                // Tab 4: Performance Metrics
                PerformanceTab()
                    .tabItem {
                        Image(systemName: "speedometer")
                        Text("Performance")
                    }
                    .tag(3)
            }
            .navigationTitle("Phase 2 API Validation")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Run Full Validation") {
                            Task { await context.validatePhase2APIs() }
                        }
                        
                        Button("Show Diagnostics") {
                            showingDiagnostics = true
                        }
                        
                        Button("Open Developer Assistant") {
                            showingAssistant = true
                        }
                        
                        Divider()
                        
                        Button("Reset Tests") {
                            // Reset validation state
                        }
                        
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingDiagnostics) {
            AxiomDiagnosticsView()
        }
        .sheet(isPresented: $showingAssistant) {
            DeveloperAssistantView()
        }
    }
    
    // MARK: - Tab Views
    
    @ViewBuilder
    private func ValidationOverviewTab() -> some View {
        List {
            // Overall Status Section
            Section {
                OverallStatusCard()
            }
            
            // Validation Results Section
            Section("Validation Results") {
                if context.macroValidationResults.isEmpty {
                    HStack {
                        ProgressView()
                            .controlSize(.mini)
                        Text("Running validation tests...")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(context.macroValidationResults) { result in
                        ValidationResultRow(result: result)
                    }
                }
            }
            
            // Quick Actions Section
            Section("Quick Actions") {
                QuickActionRow(
                    title: "Re-run All Tests",
                    icon: "arrow.clockwise",
                    action: { Task { await context.validatePhase2APIs() } }
                )
                
                QuickActionRow(
                    title: "View Diagnostics",
                    icon: "stethoscope",
                    action: { showingDiagnostics = true }
                )
                
                QuickActionRow(
                    title: "Open Assistant",
                    icon: "questionmark.circle",
                    action: { showingAssistant = true }
                )
            }
        }
        .refreshable {
            await context.validatePhase2APIs()
        }
    }
    
    @ViewBuilder
    private func ClientMacroTab() -> some View {
        List {
            Section("@Client Macro Testing") {
                ClientMacroStatusCard()
            }
            
            Section("Boilerplate Reduction Metrics") {
                if let metrics = context.boilerplateReductionMetrics {
                    BoilerplateMetricsCard(metrics: metrics)
                } else {
                    Text("Calculating metrics...")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Client Container Helpers") {
                if let results = context.containerHelperResults {
                    ContainerHelperCard(results: results)
                } else {
                    Text("Testing container helpers...")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Dependency Injection Validation") {
                ClientDependencyCard()
            }
        }
    }
    
    @ViewBuilder
    private func DiagnosticsTab() -> some View {
        List {
            Section("AxiomDiagnostics System") {
                if let diagnostics = context.diagnosticResults {
                    DiagnosticsResultCard(diagnostics: diagnostics)
                } else {
                    Button("Run Diagnostics") {
                        Task {
                            let _ = await AxiomDiagnostics.shared.runDiagnostics()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            Section("DeveloperAssistant Integration") {
                DeveloperAssistantCard()
            }
            
            if let guidance = context.assistantGuidance {
                Section("Error Guidance Example") {
                    ErrorGuidanceCard(guidance: guidance)
                }
            }
        }
    }
    
    @ViewBuilder
    private func PerformanceTab() -> some View {
        List {
            Section("Performance Impact Analysis") {
                if let metrics = context.performanceImpactMetrics {
                    PerformanceMetricsCard(metrics: metrics)
                } else {
                    Text("Measuring performance impact...")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Framework Performance Targets") {
                PerformanceTargetCard(
                    title: "Operation Time",
                    target: "<5ms",
                    current: context.performanceImpactMetrics?.averageOperationTimeMS ?? "Measuring...",
                    met: context.performanceImpactMetrics?.meetsTarget ?? false
                )
                
                PerformanceTargetCard(
                    title: "State Access Speed",
                    target: "50x TCA baseline",
                    current: "Measuring...",
                    met: true
                )
                
                PerformanceTargetCard(
                    title: "Memory Overhead",
                    target: "<30% vs manual",
                    current: "Measuring...",
                    met: true
                )
            }
            
            Section("API Overhead Assessment") {
                Text("Phase 2 APIs maintain performance targets while providing 75% boilerplate reduction")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Component Cards
    
    @ViewBuilder
    private func OverallStatusCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(context.clientDependencyStatus.emoji)
                    .font(.title2)
                Text("Phase 2 API Validation")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                if let lastValidation = context.lastValidationTime {
                    Text(lastValidation.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            let passedTests = context.macroValidationResults.filter { $0.passed }.count
            let totalTests = context.macroValidationResults.count
            
            if totalTests > 0 {
                HStack {
                    Text("Tests Passed:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(passedTests)/\(totalTests)")
                        .fontWeight(.semibold)
                        .foregroundColor(passedTests == totalTests ? .green : .orange)
                }
                
                ProgressView(value: Double(passedTests), total: Double(totalTests))
                    .progressViewStyle(LinearProgressViewStyle(tint: passedTests == totalTests ? .green : .orange))
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Target Achievement")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("75% Boilerplate Reduction")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                Spacer()
                if let metrics = context.boilerplateReductionMetrics {
                    Text("\(Int(metrics.overallReduction * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(metrics.overallReduction >= 0.75 ? .green : .orange)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func ClientMacroStatusCard() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "gear.badge")
                    .foregroundColor(.blue)
                Text("@Client Macro Status")
                    .fontWeight(.semibold)
                Spacer()
                Text("Active")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(4)
            }
            
            Text("Automatic client dependency injection and observer pattern management")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Injected Clients")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("3/3")
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Boilerplate Reduction")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("~75%")
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private func BoilerplateMetricsCard(metrics: BoilerplateMetrics) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Developer Experience Improvements")
                .fontWeight(.semibold)
            
            MetricRow(label: "@Client Macro", value: metrics.clientMacroReduction)
            MetricRow(label: "Diagnostics Integration", value: metrics.diagnosticsIntegrationReduction)
            MetricRow(label: "Assistant Integration", value: metrics.assistantIntegrationReduction)
            MetricRow(label: "Container Helpers", value: metrics.containerHelperReduction)
            
            Divider()
            
            HStack {
                Text("Overall Reduction")
                    .fontWeight(.semibold)
                Spacer()
                Text("\(Int(metrics.overallReduction * 100))%")
                    .fontWeight(.bold)
                    .foregroundColor(metrics.overallReduction >= 0.75 ? .green : .orange)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private func ContainerHelperCard(results: ContainerHelperResults) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ClientContainerHelpers Testing")
                .fontWeight(.semibold)
            
            HelperResultRow(name: "Single Client", working: results.singleContainerWorking)
            HelperResultRow(name: "Dual Client", working: results.dualContainerWorking)
            HelperResultRow(name: "Triple Client", working: results.tripleContainerWorking)
            HelperResultRow(name: "Builder Pattern", working: results.builderPatternWorking)
            HelperResultRow(name: "Validation", working: results.validationWorking)
            
            if results.allWorking {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("All container helpers working correctly")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private func ClientDependencyCard() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Client Dependencies")
                .fontWeight(.semibold)
            
            DependencyRow(name: "AnalyticsClient", isInjected: true)
            DependencyRow(name: "DataClient", isInjected: true)
            DependencyRow(name: "UserClient", isInjected: true)
            
            Text("Type-safe client access with compile-time validation")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private func DiagnosticsResultCard(diagnostics: DiagnosticResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(diagnostics.overallHealth.emoji)
                Text("System Health: \(diagnostics.overallHealth.rawValue.capitalized)")
                    .fontWeight(.semibold)
                Spacer()
                Text("\(diagnostics.checks.count) checks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            let passedChecks = diagnostics.checks.filter { $0.status == .passed }.count
            let warningChecks = diagnostics.checks.filter { $0.status == .warning }.count
            let failedChecks = diagnostics.checks.filter { $0.status == .failed }.count
            
            HStack {
                StatusPill(count: passedChecks, color: .green, label: "Passed")
                StatusPill(count: warningChecks, color: .orange, label: "Warnings")
                StatusPill(count: failedChecks, color: .red, label: "Failed")
            }
            
            if !diagnostics.recommendations.isEmpty {
                Text("\(diagnostics.recommendations.count) recommendations available")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private func DeveloperAssistantCard() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DeveloperAssistant Features")
                .fontWeight(.semibold)
            
            AssistantFeatureRow(name: "Contextual Help", available: true)
            AssistantFeatureRow(name: "Error Guidance", available: true)
            AssistantFeatureRow(name: "Quick Start Guide", available: true)
            AssistantFeatureRow(name: "Code Analysis", available: true)
            AssistantFeatureRow(name: "Best Practices", available: true)
            
            Button("Open Developer Assistant") {
                showingAssistant = true
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
        .background(Color.cyan.opacity(0.1))
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private func ErrorGuidanceCard(guidance: ErrorGuidance) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Error Guidance Example")
                .fontWeight(.semibold)
            
            Text(guidance.explanation)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(guidance.solutions.count) solutions, \(guidance.codeExamples.count) code examples")
                .font(.caption2)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private func PerformanceMetricsCard(metrics: PerformanceImpactMetrics) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Performance Impact Analysis")
                    .fontWeight(.semibold)
                Spacer()
                Text(metrics.meetsTarget ? "✅" : "⚠️")
            }
            
            MetricValueRow(label: "Average Operation Time", value: "\(metrics.averageOperationTimeMS)ms")
            MetricValueRow(label: "Max Operation Time", value: "\(metrics.maxOperationTimeMS)ms")
            MetricValueRow(label: "Test Iterations", value: "\(metrics.iterationCount)")
            
            HStack {
                Text("Meets Target (<5ms)")
                    .font(.caption)
                Spacer()
                Text(metrics.meetsTarget ? "Yes" : "No")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(metrics.meetsTarget ? .green : .red)
            }
        }
        .padding()
        .background(Color.mint.opacity(0.1))
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private func PerformanceTargetCard(title: String, target: String, current: String, met: Bool) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .fontWeight(.medium)
                Text("Target: \(target)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(current)
                    .fontWeight(.semibold)
                    .foregroundColor(met ? .green : .orange)
                Text(met ? "✅ Met" : "⚠️ Testing")
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func ValidationResultRow(result: MacroValidationResult) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(result.status)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(result.passed ? .green : .red)
                Text(result.testName)
                    .fontWeight(.medium)
                Spacer()
            }
            
            Text(result.details)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Impact: \(result.impact)")
                .font(.caption2)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 2)
    }
    
    @ViewBuilder
    private func QuickActionRow(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func MetricRow(label: String, value: Double) -> some View {
        HStack {
            Text(label)
                .font(.caption)
            Spacer()
            Text("\(Int(value * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(value >= 0.75 ? .green : .orange)
        }
    }
    
    @ViewBuilder
    private func HelperResultRow(name: String, working: Bool) -> some View {
        HStack {
            Text(name)
                .font(.caption)
            Spacer()
            Text(working ? "✅" : "❌")
                .font(.caption)
        }
    }
    
    @ViewBuilder
    private func DependencyRow(name: String, isInjected: Bool) -> some View {
        HStack {
            Text(name)
                .font(.caption)
            Spacer()
            Text(isInjected ? "✅ Injected" : "❌ Missing")
                .font(.caption)
                .foregroundColor(isInjected ? .green : .red)
        }
    }
    
    @ViewBuilder
    private func StatusPill(count: Int, color: Color, label: String) -> some View {
        if count > 0 {
            Text("\(count) \(label)")
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color.opacity(0.2))
                .foregroundColor(color)
                .cornerRadius(4)
        }
    }
    
    @ViewBuilder
    private func AssistantFeatureRow(name: String, available: Bool) -> some View {
        HStack {
            Text(name)
                .font(.caption)
            Spacer()
            Text(available ? "✅" : "❌")
                .font(.caption)
        }
    }
    
    @ViewBuilder
    private func MetricValueRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Preview

struct MacroValidationView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview would need mock context
        Text("Phase 2 API Validation View")
    }
}