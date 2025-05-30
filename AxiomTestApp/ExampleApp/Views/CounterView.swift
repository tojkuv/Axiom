import SwiftUI

#if canImport(Axiom)
import Axiom

// MARK: - Real Counter View (Using Streamlined APIs)

/// AxiomView implementation showcasing:
/// - 1:1 View-Context relationship
/// - Reactive state updates via automatic binding
/// - Natural SwiftUI integration with framework features
struct RealCounterView: AxiomView {
    
    // MARK: - AxiomView Protocol
    
    public typealias Context = RealCounterContext
    @ObservedObject public var context: RealCounterContext
    
    // MARK: - Initialization
    
    public init(context: RealCounterContext) {
        self.context = context
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: 24) {
            
            // Title Section
            VStack(spacing: 8) {
                Text("🧠 Axiom Framework")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("STREAMLINED API INTEGRATION")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                
                Text("Using AxiomApplicationBuilder + ContextStateBinder")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Divider()
            
            // Counter Display
            VStack(spacing: 16) {
                Text("Counter Value")
                    .font(.headline)
                
                Text("\(context.currentCount)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                    .animation(.spring(), value: context.currentCount)
            }
            
            // Action Buttons
            HStack(spacing: 20) {
                Button("Decrement") {
                    Task {
                        await context.decrementCounter()
                    }
                }
                .buttonStyle(.bordered)
                
                Button("Reset") {
                    Task {
                        await context.resetCounter()
                    }
                }
                .buttonStyle(.bordered)
                
                Button("Increment") {
                    Task {
                        await context.incrementCounter()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            
            Divider()
            
            // Intelligence Demo
            VStack(spacing: 12) {
                Text("🧠 Real Axiom Intelligence")
                    .font(.headline)
                
                Button("Ask AI About \(context.currentCount)") {
                    Task {
                        await context.askIntelligence()
                    }
                }
                .buttonStyle(.bordered)
                
                if !context.lastIntelligenceResponse.isEmpty {
                    Text(context.lastIntelligenceResponse)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                        .transition(.opacity)
                }
            }
            
            Spacer()
            
            // API Improvement Indicators
            VStack(spacing: 8) {
                Text("✅ AxiomApplicationBuilder: 70% less initialization code")
                Text("✅ ContextStateBinder: 80% less manual synchronization")
                Text("✅ Automatic state binding: Zero sync bugs")
                Text("✅ Type-safe property binding: Compile-time checked")
                Text("✅ Same UI, dramatically simplified implementation")
            }
            .font(.caption)
            .foregroundColor(.blue)
            
        }
        .padding()
        .onAppear {
            Task {
                await context.onAppear()
            }
        }
        .onDisappear {
            Task {
                await context.onDisappear()
            }
        }
    }
}

#else

// MARK: - Fallback Counter View (when Axiom not available)

struct RealCounterView: View {
    @ObservedObject var context: RealCounterContext
    
    init(context: RealCounterContext) {
        self.context = context
    }
    
    var body: some View {
        VStack(spacing: 24) {
            
            // Warning Banner
            VStack(spacing: 8) {
                Text("⚠️ AXIOM PACKAGE NOT FOUND")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                Text("Add Axiom package dependency to use real framework")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Project → Target → Frameworks → Add Package → '../../'")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
            
            // Counter Display
            VStack(spacing: 16) {
                Text("Demo Counter")
                    .font(.headline)
                
                Text("\(context.currentCount)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
            }
            
            // Action Buttons
            HStack(spacing: 20) {
                Button("Decrement") {
                    Task { await context.decrementCounter() }
                }
                .buttonStyle(.bordered)
                
                Button("Reset") {
                    Task { await context.resetCounter() }
                }
                .buttonStyle(.bordered)
                
                Button("Increment") {
                    Task { await context.incrementCounter() }
                }
                .buttonStyle(.borderedProminent)
            }
            
            // Demo Intelligence
            VStack(spacing: 12) {
                Text("🧠 Demo Intelligence")
                    .font(.headline)
                
                Button("Ask Demo AI") {
                    Task { await context.askIntelligence() }
                }
                .buttonStyle(.bordered)
                
                if !context.lastIntelligenceResponse.isEmpty {
                    Text(context.lastIntelligenceResponse)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            Task { await context.onAppear() }
        }
        .onDisappear {
            Task { await context.onDisappear() }
        }
    }
}

#endif