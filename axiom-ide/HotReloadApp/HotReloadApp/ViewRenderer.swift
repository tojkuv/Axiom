import SwiftUI

struct ViewRenderer: View {
    let previewFile: PreviewFile
    
    var body: some View {
        VStack(spacing: 0) {
            previewHeaderView
            previewContentView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private var previewHeaderView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(previewFile.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Live Preview • Auto-updating")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                Text("Hot Reload")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }
    
    private var previewContentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                previewSimulationView
                sourceCodeView
            }
            .padding()
        }
    }
    
    private var previewSimulationView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SwiftUI Preview")
                .font(.headline)
            
            // Interpreted SwiftUI preview area
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .frame(height: 400)
                .overlay(
                    interpretedSwiftUIView
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                )
        }
    }
    
    @ViewBuilder
    private var interpretedSwiftUIView: some View {
        let interpreter = SwiftUIInterpreter(sourceCode: previewFile.content)
        
        VStack(spacing: 20) {
            // Show extracted view elements
            if let title = interpreter.extractedTitle {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(interpreter.extractedTitleColor)
            }
            
            if let subtitle = interpreter.extractedSubtitle {
                Text(subtitle)
                    .font(.title2)
                    .foregroundColor(interpreter.extractedSubtitleColor)
            }
            
            // Show buttons
            ForEach(interpreter.extractedButtons, id: \.title) { button in
                Button(button.title) {
                    // Simulate button action
                }
                .buttonStyle(.borderedProminent)
                .foregroundColor(button.color)
            }
            
            // Show additional text elements
            ForEach(interpreter.extractedTexts, id: \.content) { text in
                Text(text.content)
                    .font(text.font)
                    .foregroundColor(text.color)
                    .multilineTextAlignment(.center)
            }
            
            // Show a "live" indicator
            HStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                Text("Live Preview • \(previewFile.name)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)
        }
        .padding()
    }
    
    private var sourceCodeView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Source Code")
                .font(.headline)
            
            Text("File: \(previewFile.filePath)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                Text(previewFile.content)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(8)
            }
        }
    }
}