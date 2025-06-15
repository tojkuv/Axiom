import SwiftUI

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("Welcome to Hot Reload!")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("This view updates instantly when you save changes")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack(spacing: 15) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 20, height: 20)
                Circle()
                    .fill(Color.blue)
                    .frame(width: 20, height: 20)
                Circle()
                    .fill(Color.purple)
                    .frame(width: 20, height: 20)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color.mint.opacity(0.1), Color.cyan.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

#Preview {
    WelcomeView()
}