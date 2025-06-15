import SwiftUI

struct ButtonsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("🔘 Interactive Buttons")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.purple)
            
            Button("Primary Action") {
                print("Primary button tapped!")
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Button("Secondary Action") {
                print("Secondary button tapped!")
            }
            .foregroundColor(.blue)
            .padding()
            .background(Color.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Button("Gradient Button") {
                print("Gradient button tapped!")
            }
            .foregroundColor(.white)
            .padding()
            .background(
                LinearGradient(
                    colors: [.orange, .pink],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            
            Text("Try editing this file to test hot reload!")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    ButtonsView()
}