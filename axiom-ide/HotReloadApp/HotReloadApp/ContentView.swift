import SwiftUI

struct ContentView: View {
    @StateObject private var previewEngine = PreviewEngine()
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            previewDisplayView
        }
        .task {
            await previewEngine.connect()
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("iOS Hot Reload Previewer")
                .font(.headline)
                .fontWeight(.medium)
            
            Spacer()
            
            HStack(spacing: 6) {
                Circle()
                    .fill(previewEngine.isConnected ? .green : .red)
                    .frame(width: 8, height: 8)
                Text(previewEngine.isConnected ? "Connected" : "Waiting for Controller")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    private var previewDisplayView: some View {
        Group {
            if previewEngine.isUsingLiveExecution, let liveView = previewEngine.liveExecutionEngine.currentLiveView {
                let _ = print("🔥 ContentView rendering Live Execution view")
                liveExecutionHeaderView
                liveView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let currentFile = previewEngine.currentPreviewFile {
                let _ = print("🎨 ContentView rendering traditional ViewRenderer for: \(currentFile.name)")
                ViewRenderer(previewFile: currentFile)
            } else {
                let _ = print("🎨 ContentView showing waitingForSelectionView - no currentPreviewFile")
                waitingForSelectionView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var liveExecutionHeaderView: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("🔥 Live Execution Active")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Text("Real SwiftUI with live state management")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("Executing")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    let stateCount = previewEngine.liveExecutionEngine.stateManager.state.count
                    if stateCount > 0 {
                        Text("\(stateCount) state variable\(stateCount == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.orange.opacity(0.1))
            
            Divider()
        }
    }
    
    private var waitingForSelectionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.on.rectangle")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("Waiting for Preview")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("Use the macOS Hot Reload Controller to select a SwiftUI file to preview")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            if !previewEngine.isConnected {
                VStack(spacing: 4) {
                    Text("Make sure the Hot Reload Controller is running")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Text("Controller should be available on your Mac")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
    }
}

struct ViewInfo: Sendable {
    let name: String
    let filePath: String
    let content: String
}