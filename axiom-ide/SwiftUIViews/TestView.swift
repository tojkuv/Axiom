import SwiftUI

struct TestView: View {
    @State private var counter = 0
    
    var body: some View {
        VStack(spacing: 25) {
            Text("⚡ REAL-TIME HOT RELOAD! ⚡")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.purple)
            
            Text("LIVE UPDATE COUNT: \(counter)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Button("Add +1") {
                counter += 1
            }
            .buttonStyle(.borderedProminent)
            
            Button("Subtract -1") {
                counter -= 1
            }
            .buttonStyle(.borderedProminent)
            
            Button("Reset to Zero") {
                counter = 0
            }
            .buttonStyle(.borderedProminent)
            
            Text("⭐ Changes appear instantly! ⭐")
                .font(.caption)
                .foregroundColor(.green)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    TestView()
}