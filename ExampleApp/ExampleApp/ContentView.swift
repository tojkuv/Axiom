import SwiftUI
// TODO: Uncomment when adding Axiom dependency
// import Axiom

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Axiom Framework")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Example Application")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Divider()
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 15) {
                    FeatureRow(
                        icon: "brain",
                        title: "Intelligent Architecture",
                        description: "AI-powered architectural decisions"
                    )
                    
                    FeatureRow(
                        icon: "bolt.fill",
                        title: "Blazing Fast",
                        description: "50x faster than traditional frameworks"
                    )
                    
                    FeatureRow(
                        icon: "lock.shield",
                        title: "Type Safe",
                        description: "Compile-time safety with Swift 5.9+"
                    )
                    
                    FeatureRow(
                        icon: "sparkles",
                        title: "SwiftUI Native",
                        description: "Built for modern iOS development"
                    )
                }
                .padding()
                
                Spacer()
                
                Text("Add Axiom package dependency to use framework features")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 40)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    ContentView()
}