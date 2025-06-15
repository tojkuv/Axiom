import SwiftUI

struct CounterView: View {
    @State private var count = 0
    
    var body: some View {
        VStack(spacing: 30) {
            Text("🔥 Hot Reload Counter")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.orange)
            
            Text("\(count)")
                .font(.system(size: 80, weight: .bold, design: .rounded))
                .foregroundColor(.blue)
            
            HStack(spacing: 20) {
                Button("-") { count -= 1 }
                    .font(.title)
                    .foregroundColor(.red)
                    .padding()
                    .background(Circle().fill(Color.red.opacity(0.1)))
                
                Button("Reset") { count = 0 }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.orange)
                    .clipShape(Capsule())
                
                Button("+") { count += 1 }
                    .font(.title)
                    .foregroundColor(.green)
                    .padding()
                    .background(Circle().fill(Color.green.opacity(0.1)))
            }
            
            Text("Edit this file to see hot reload!")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    CounterView()
}