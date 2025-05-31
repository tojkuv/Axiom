import SwiftUI
import Axiom

// MARK: - Phase 2 API Test View

/// Simple integration view for testing Phase 2 APIs
/// This provides real-world validation of Integration Cycle 2 requirements
struct Phase2APITestView: View {
    
    @State private var validationResults: Phase2APIValidationTests.ValidationResults?
    @State private var isRunningTests = false
    @State private var lastTestTime: Date?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    if let results = validationResults {
                        resultsSection(results)
                    } else {
                        placeholderSection
                    }
                    
                    testActionsSection
                    
                    documentationSection
                }
                .padding()
            }
        }
        .navigationTitle("Phase 2 APIs")
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "gear.badge")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .scaleEffect(isRunningTests ? 1.2 : 1.0)
                .rotationEffect(.degrees(isRunningTests ? 360 : 0))
                .animation(.linear(duration: 2).repeatCount(isRunningTests ? .max : 0, autoreverses: false), 
                          value: isRunningTests)
            
            Text("Phase 2 API Validation")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Integration Cycle 2: Advanced API Testing")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if let lastTest = lastTestTime {
                Text("Last tested: \(lastTest.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
    
    // MARK: - Results Section
    
    private func resultsSection(_ results: Phase2APIValidationTests.ValidationResults) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Validation Results")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(results.passedCount)/\(results.totalCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(results.overallSuccess ? .green : .orange)
            }
            
            ProgressView(value: Double(results.passedCount), total: Double(results.totalCount))
                .progressViewStyle(LinearProgressViewStyle(tint: results.overallSuccess ? .green : .orange))
            
            VStack(spacing: 8) {
                TestResultRow(
                    name: "AxiomDiagnostics System",
                    description: "Health monitoring and recommendations",
                    passed: results.diagnosticsSystemWorking
                )
                
                TestResultRow(
                    name: "DeveloperAssistant Integration",
                    description: "Contextual help and error guidance",
                    passed: results.developerAssistantWorking
                )
                
                TestResultRow(
                    name: "ClientContainerHelpers",
                    description: "Type-safe dependency management",
                    passed: results.clientContainerHelpersWorking
                )
                
                TestResultRow(
                    name: "Performance Targets",
                    description: "<5ms operations, framework efficiency",
                    passed: results.performanceTargetsMet
                )
                
                TestResultRow(
                    name: "Boilerplate Reduction",
                    description: "75% reduction target achievement",
                    passed: results.boilerplateReductionAchieved
                )
            }
            
            if results.overallSuccess {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Integration Cycle 2 requirements validated successfully!")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Placeholder Section
    
    private var placeholderSection: some View {
        VStack(spacing: 16) {
            Text("Ready to Validate Phase 2 APIs")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("This will test all Integration Cycle 2 requirements:")
                .font(.body)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                FeaturePreviewRow(name: "@Client Macro Integration", target: "75% boilerplate reduction")
                FeaturePreviewRow(name: "AxiomDiagnostics Validation", target: "8 health checks")
                FeaturePreviewRow(name: "DeveloperAssistant Testing", target: "Contextual help system")
                FeaturePreviewRow(name: "ClientContainerHelpers", target: "Type-safe patterns")
                FeaturePreviewRow(name: "Performance Assessment", target: "<5ms targets")
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Test Actions Section
    
    private var testActionsSection: some View {
        VStack(spacing: 12) {
            Button("Run Comprehensive Validation") {
                runValidationTests()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isRunningTests)
            
            if isRunningTests {
                HStack {
                    ProgressView()
                        .controlSize(.mini)
                    Text("Running validation tests...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 12) {
                Button("Test Diagnostics") {
                    testDiagnosticsOnly()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isRunningTests)
                
                Button("Test Assistant") {
                    testAssistantOnly()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isRunningTests)
            }
        }
    }
    
    // MARK: - Documentation Section
    
    private var documentationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Integration Cycle 2 Goals")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                GoalRow(
                    title: "API Ergonomics",
                    description: "75% boilerplate reduction in complex scenarios"
                )
                
                GoalRow(
                    title: "Developer Experience",
                    description: "Contextual help and error prevention"
                )
                
                GoalRow(
                    title: "Type Safety",
                    description: "Compile-time validation and runtime safety"
                )
                
                GoalRow(
                    title: "Performance",
                    description: "Maintain <5ms targets with new APIs"
                )
            }
            
            Text("These tests validate that Phase 2 developer experience enhancements work correctly in real-world scenarios while maintaining performance targets.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Actions
    
    private func runValidationTests() {
        isRunningTests = true
        Task {
            let results = await Phase2APIValidationTests.runValidation()
            await MainActor.run {
                self.validationResults = results
                self.isRunningTests = false
                self.lastTestTime = Date()
            }
        }
    }
    
    private func testDiagnosticsOnly() {
        Task {
            print("🔍 Testing AxiomDiagnostics only...")
            let diagnosticResult = await AxiomDiagnostics.shared.runDiagnostics()
            print("📊 Diagnostic Result: \(diagnosticResult.overallHealth.rawValue)")
            print("   Checks: \(diagnosticResult.checks.count)")
            print("   Recommendations: \(diagnosticResult.recommendations.count)")
        }
    }
    
    private func testAssistantOnly() {
        Task {
            print("🔍 Testing DeveloperAssistant only...")
            let quickStart = await DeveloperAssistant.shared.getQuickStartGuide()
            print("📚 Quick Start Guide: \(quickStart.steps.count) steps")
            print("   Common mistakes: \(quickStart.commonMistakes.count)")
        }
    }
}

// MARK: - Supporting Views

private struct TestResultRow: View {
    let name: String
    let description: String
    let passed: Bool
    
    var body: some View {
        HStack {
            Image(systemName: passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(passed ? .green : .red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(passed ? "PASS" : "FAIL")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(passed ? .green : .red)
        }
        .padding(.vertical, 4)
    }
}

private struct FeaturePreviewRow: View {
    let name: String
    let target: String
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle")
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(target)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

private struct GoalRow: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

struct Phase2APITestView_Previews: PreviewProvider {
    static var previews: some View {
        Phase2APITestView()
    }
}