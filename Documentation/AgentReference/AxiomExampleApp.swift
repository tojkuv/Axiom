import SwiftUI

@main
struct AxiomExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Axiom Framework Example")
                .font(.title)
            Text("Open Package.swift to see the full framework")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}