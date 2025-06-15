import SwiftUI

struct ContentView: View {
    @StateObject private var hotReloadEngine = HotReloadEngine()
    @State private var selectedView: String = "none"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("🔥 Hot Reload")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        
                        HStack(spacing: 8) {
                            Circle()
                                .fill(hotReloadEngine.isConnected ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            
                            Text(hotReloadEngine.isConnected ? "Connected" : "Disconnected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Views: \(hotReloadEngine.availableViews.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let lastUpdate = hotReloadEngine.lastUpdateTime {
                            Text("Updated: \(timeAgoString(from: lastUpdate))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                
                Divider()
                
                // Content Area
                if hotReloadEngine.availableViews.isEmpty {
                    // Welcome Screen
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "swift")
                            .font(.system(size: 80))
                            .foregroundColor(.orange)
                        
                        Text("SwiftUI Hot Reload")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Start editing SwiftUI files to see live updates")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        VStack(spacing: 8) {
                            Text("WebSocket: ws://localhost:9001")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Status: \(hotReloadEngine.connectionStatus)")
                                .font(.caption)
                                .foregroundColor(hotReloadEngine.isConnected ? .green : .red)
                        }
                        .padding()
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                        
                        Spacer()
                    }
                    .padding()
                } else {
                    // Views List & Preview
                    HSplitView {
                        // Views List
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Available Views")
                                .font(.headline)
                                .padding()
                            
                            Divider()
                            
                            List(hotReloadEngine.availableViews, id: \.name, selection: $selectedView) { viewInfo in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(viewInfo.name)
                                        .font(.body)
                                        .fontWeight(.semibold)
                                    
                                    Text(viewInfo.fileName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if let lastModified = viewInfo.lastModified {
                                        Text("Modified: \(timeAgoString(from: lastModified))")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 2)
                                .tag(viewInfo.name)
                            }
                        }
                        .frame(minWidth: 250, maxWidth: 300)
                        
                        // Preview Area
                        VStack {
                            if selectedView != "none", 
                               let viewInfo = hotReloadEngine.availableViews.first(where: { $0.name == selectedView }) {
                                
                                // Preview Header
                                HStack {
                                    Text(viewInfo.name)
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Button(action: { hotReloadEngine.refreshView(viewInfo.name) }) {
                                        Image(systemName: "arrow.clockwise")
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                
                                Divider()
                                
                                // Dynamic View Container
                                DynamicViewContainer(viewInfo: viewInfo)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else {
                                // No View Selected
                                VStack(spacing: 20) {
                                    Spacer()
                                    
                                    Image(systemName: "eye")
                                        .font(.system(size: 60))
                                        .foregroundColor(.gray)
                                    
                                    Text("Select a view to preview")
                                        .font(.title2)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                }
                            }
                        }
                        .frame(minWidth: 400)
                    }
                }
            }
        }
        .onAppear {
            hotReloadEngine.connect()
        }
        .onChange(of: hotReloadEngine.availableViews) { views in
            if selectedView == "none" && !views.isEmpty {
                selectedView = views.first?.name ?? "none"
            }
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct DynamicViewContainer: View {
    let viewInfo: ViewInfo
    
    var body: some View {
        ScrollView {
            VStack {
                // This will be replaced with dynamic view loading
                Text("Preview of \(viewInfo.name)")
                    .font(.title3)
                    .padding()
                
                Text("SwiftUI Code:")
                    .font(.headline)
                    .padding(.top)
                
                Text(viewInfo.sourceCode)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding()
            }
        }
    }
}

#Preview {
    ContentView()
}