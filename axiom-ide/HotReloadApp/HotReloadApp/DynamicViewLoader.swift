import SwiftUI

// Future: This will handle dynamic SwiftUI view compilation
// For now, it provides mock views based on view type

struct DynamicViewLoader {
    static func loadView(from viewInfo: ViewInfo) -> AnyView {
        switch viewInfo.viewType.lowercased() {
        case "counter":
            return AnyView(MockCounterView())
        case "button", "buttons":
            return AnyView(MockButtonsView())
        case "card", "cards":
            return AnyView(MockCardsView())
        case "todo":
            return AnyView(MockTodoView())
        default:
            return AnyView(MockDefaultView(viewInfo: viewInfo))
        }
    }
}

// MARK: - Mock Views for Testing

struct MockCounterView: View {
    @State private var count = 0
    
    var body: some View {
        VStack(spacing: 30) {
            Text("🔥 Hot Reload Counter")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.red)
            
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
            
            Text("✅ File Changed! Hot Reload Working!")
                .font(.caption)
                .foregroundColor(.green)
                .fontWeight(.bold)
        }
        .padding()
    }
}

struct MockButtonsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("🔘 Button Styles")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.purple)
            
            Button("Primary Button") { }
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Button("Secondary Button") { }
                .foregroundColor(.blue)
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Button("Gradient Button") { }
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
        }
        .padding()
    }
}

struct MockCardsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("🃏 Card Layout")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.indigo)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Sample Card")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("This is a sample card component with some descriptive text.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Another Card")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Cards can contain various types of content and layouts.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
    }
}

struct MockTodoView: View {
    @State private var tasks = ["Learn SwiftUI", "Build hot reload system", "Test with simulator"]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("📝 Todo List")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.green)
            
            ForEach(tasks, id: \.self) { task in
                HStack {
                    Image(systemName: "circle")
                        .foregroundColor(.green)
                    Text(task)
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .padding()
    }
}

struct MockDefaultView: View {
    let viewInfo: ViewInfo
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🎯 \(viewInfo.name)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.gray)
            
            Text("Type: \(viewInfo.viewType)")
                .font(.body)
                .foregroundColor(.secondary)
            
            Text("File: \(viewInfo.fileName)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            Text("Source Preview:")
                .font(.headline)
            
            ScrollView {
                Text(viewInfo.sourceCode)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .padding()
    }
}