import SwiftUI

struct SimpleTest: View {
    var body: some View {
        VStack {
            Text("SIMPLE TEST")
                .font(.largeTitle)
                .foregroundColor(.red)
            
            Button("Test Button") {
                // test
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    SimpleTest()
}