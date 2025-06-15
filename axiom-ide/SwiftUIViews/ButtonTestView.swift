import SwiftUI

struct ButtonTestView: View {
    var body: some View {
        VStack(spacing: 15) {
            Text("Button Style Tests")
                .font(.title)
                .foregroundColor(.purple)
            
            Button("Primary Action") {
                // Action here
            }
            .buttonStyle(.borderedProminent)
            
            Button("Secondary Action") {
                // Action here  
            }
            .buttonStyle(.bordered)
            
            Button("Danger Action") {
                // Action here
            }
            .buttonStyle(.borderedProminent)
            
            Text("Testing different button patterns")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    ButtonTestView()
}