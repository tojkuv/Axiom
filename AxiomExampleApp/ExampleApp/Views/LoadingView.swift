import SwiftUI

// MARK: - Loading View

/// Loading state view shown during app initialization
/// Demonstrates framework startup and capability setup process
struct LoadingView: View {
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("🧠 Axiom Framework")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("STREAMLINED API INTEGRATION")
                .font(.headline)
                .foregroundColor(.blue)
            
            Text("70% Less Code • 80% Fewer Bugs • 100% Type Safe")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            ProgressView("Initializing with AxiomApplicationBuilder...")
                .padding(.top)
        }
        .padding()
    }
}

// MARK: - Preview

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}