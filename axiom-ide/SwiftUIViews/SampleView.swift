import SwiftUI

struct SampleView: View {
    @State private var counter = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Hot Reload Sample")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text("Counter: \(counter)")
                .font(.title2)
                .padding()
                .background(Color.orange.opacity(0.2))
                .cornerRadius(10)
            
            Button("Increment") {
                counter += 1
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
    }
}

#Preview {
    SampleView()
}