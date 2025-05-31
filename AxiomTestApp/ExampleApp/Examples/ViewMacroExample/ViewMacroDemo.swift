import SwiftUI

#if canImport(Axiom)
import Axiom

// MARK: - ViewMacro Demo Entry Point

/// Complete demonstration of the revolutionary @View macro
/// Showcases 90%+ boilerplate reduction for SwiftUI-Axiom integration
struct ViewMacroDemo: View {
    
    @StateObject private var coordinator = ViewMacroDemoCoordinator()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                demoHeader
                
                if coordinator.isReady {
                    demoContent
                } else {
                    loadingView
                }
            }
            .padding()
            .navigationTitle("@View Macro Demo")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task {
                    await coordinator.initialize()
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private var demoHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "swift")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("@View Macro Revolution")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("90%+ Boilerplate Reduction Achieved")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("The @View macro automatically generates:")
                    .font(.headline)
                    .fontWeight(.medium)
                
                VStack(alignment: .leading, spacing: 4) {
                    MacroFeature(icon: "link", text: "@ObservedObject context property")
                    MacroFeature(icon: "gear", text: "Type-safe initializer")
                    MacroFeature(icon: "arrow.clockwise", text: "Lifecycle integration")
                    MacroFeature(icon: "exclamationmark.triangle", text: "Error handling state")
                    MacroFeature(icon: "brain.head.profile", text: "Intelligence query methods")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.orange.opacity(0.1), .blue.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var demoContent: some View {
        if let context = coordinator.realCounterContext {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Direct ViewMacro test
                    macroTestSection(context: context)
                    
                    // Comparison section
                    comparisonSection
                    
                    // Code generation showcase
                    codeGenerationSection
                }
            }
        } else {
            Text("Setting up demo context...")
                .foregroundColor(.secondary)
        }
    }
    
    private func macroTestSection(context: RealCounterContext) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Live @View Macro Demonstration")
                .font(.headline)
                .fontWeight(.semibold)
            
            // This is the actual ViewMacroTestView using the @View macro!
            ViewMacroTestView(context: context)
                .frame(maxHeight: 600)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
        }
    }
    
    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Before vs After Comparison")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                // Before (Manual)
                VStack(alignment: .leading, spacing: 8) {
                    Text("BEFORE (Manual)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        CodeLine("@ObservedObject var context: MyContext")
                        CodeLine("init(context: MyContext) { ... }")
                        CodeLine("private func onAppear() async { ... }")
                        CodeLine("private func onDisappear() async { ... }")
                        CodeLine("@State private var showingError = false")
                        CodeLine("private func queryIntelligence(...) { ... }")
                        CodeLine("// + Error handling boilerplate")
                        CodeLine("// + Lifecycle management")
                        CodeLine("// + 25+ lines of repetitive code")
                    }
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
                
                // After (Macro)
                VStack(alignment: .leading, spacing: 8) {
                    Text("AFTER (@View Macro)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        CodeLine("@View(MyContext)")
                        CodeLine("struct MyView: View {")
                        CodeLine("    // All boilerplate generated!")
                        CodeLine("    var body: some View {")
                        CodeLine("        // Your UI code here")
                        CodeLine("    }")
                        CodeLine("}")
                        CodeLine("")
                        CodeLine("// 90% less code!")
                    }
                    .foregroundColor(.green)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    private var codeGenerationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Generated Code Showcase")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                GeneratedCodeShowcase(
                    title: "Context Property",
                    code: "@ObservedObject var context: RealCounterContext",
                    description: "Automatic reactive binding to context"
                )
                
                GeneratedCodeShowcase(
                    title: "Type-Safe Initializer",
                    code: "public init(context: RealCounterContext) { self.context = context }",
                    description: "Compile-time type safety enforced"
                )
                
                GeneratedCodeShowcase(
                    title: "Lifecycle Methods",
                    code: "private func axiomOnAppear() async { await context.onAppear() }",
                    description: "Automatic context lifecycle integration"
                )
                
                GeneratedCodeShowcase(
                    title: "Error Handling",
                    code: "@State private var showingError = false",
                    description: "Built-in error presentation state"
                )
                
                GeneratedCodeShowcase(
                    title: "Intelligence Query",
                    code: "private func queryIntelligence(_ query: String) async -> String?",
                    description: "Direct access to AI intelligence system"
                )
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Initializing @View Macro Demo...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Supporting Views

private struct MacroFeature: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 16)
            
            Text(text)
        }
    }
}

private struct CodeLine: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text)
            .font(.system(.caption, design: .monospaced))
            .foregroundColor(.secondary)
    }
}

private struct GeneratedCodeShowcase: View {
    let title: String
    let code: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(code)
                .font(.system(.caption, design: .monospaced))
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Demo Coordinator

@MainActor
class ViewMacroDemoCoordinator: ObservableObject {
    @Published var isReady = false
    @Published var realCounterContext: RealCounterContext?
    
    func initialize() async {
        // Create a real context for testing
        let counterClient = RealCounterClient()
        let intelligence = MockDemoIntelligence()
        
        realCounterContext = RealCounterContext(
            counterClient: counterClient,
            intelligence: intelligence
        )
        
        // Small delay to simulate initialization
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        isReady = true
    }
}

// MARK: - Mock Intelligence for Demo

private struct MockDemoIntelligence: AxiomIntelligence {
    func processQuery(_ query: String) async throws -> IntelligenceResponse {
        // Simulate processing delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        return IntelligenceResponse(
            answer: "Demo Intelligence: \(query) - This demonstrates the @View macro's intelligence integration!",
            confidence: 0.95,
            sources: ["@View Macro Demo"],
            processingTime: 1.0
        )
    }
    
    func query(_ query: String) async -> String? {
        return "Macro Demo Response: \(query)"
    }
}

// MARK: - Preview

#Preview {
    ViewMacroDemo()
}

#else

// MARK: - Fallback View

struct ViewMacroDemo: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "swift")
                .font(.system(size: 64))
                .foregroundColor(.orange)
            
            Text("@View Macro Demo")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Add Axiom Framework to see the macro in action!")
                .foregroundColor(.orange)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    ViewMacroDemo()
}

#endif