import SwiftUI

struct ContentView: View {
    @StateObject private var fileManager = SwiftUIFileManager()
    @StateObject private var previewController = PreviewController()
    @StateObject private var webSocketManager = WebSocketManager()
    @StateObject private var simulatorManager = SimulatorManager()
    @StateObject private var serviceManager = ServiceManager()
    
    @State private var isDeployingApp = false
    @State private var deploymentProgress = ""
    @State private var showError: String? = nil
    @State private var lastActivity = ""
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            HSplitView {
                VStack(spacing: 0) {
                    iPhoneEnvironmentView
                    Divider()
                    iPadEnvironmentView
                }
                .frame(minWidth: 400)
                
                previewStatusView
            }
            .frame(minWidth: 800, minHeight: 600)
        }
        .task {
            // Start Hot Reload Server first
            await serviceManager.startFileWatcher()
            
            // Wire up the WebSocket manager with the service manager
            webSocketManager.setServiceManager(serviceManager)
            
            // Connect to the internal server
            await webSocketManager.connect()
            
            // Start file monitoring and load simulators
            fileManager.startWatching()
            await simulatorManager.loadSimulators()
        }
        .onDisappear {
            Task {
                await serviceManager.stopFileWatcher()
            }
        }
        .onChange(of: fileManager.selectediPhoneFile) { _, newFile in
            if let file = newFile, let simulator = simulatorManager.iPhoneSimulator {
                Task {
                    await previewController.sendToPreview(file, to: simulator, via: webSocketManager)
                }
            }
        }
        .onChange(of: fileManager.selectediPadFile) { _, newFile in
            if let file = newFile, let simulator = simulatorManager.iPadSimulator {
                Task {
                    await previewController.sendToPreview(file, to: simulator, via: webSocketManager)
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hot Reload Controller")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if !lastActivity.isEmpty {
                        Text(lastActivity)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                connectionStatusView
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            if let error = showError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.primary)
                    Spacer()
                    Button("Dismiss") {
                        showError = nil
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
            }
            
            if isDeployingApp {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(deploymentProgress.isEmpty ? "Building app..." : deploymentProgress)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
            }
        }
    }
    
    private var connectionStatusView: some View {
        HStack(spacing: 16) {
            statusIndicator(
                title: "FileWatcher",
                status: serviceManager.fileWatcherStatus.displayName,
                color: serviceManager.fileWatcherStatus.color,
                icon: "folder.badge.gearshape"
            )
            
            statusIndicator(
                title: "iOS Previewer",
                status: webSocketManager.isPreviewerConnected ? "Connected" : "Disconnected",
                color: webSocketManager.isPreviewerConnected ? .green : .red,
                icon: "iphone"
            )
            
            if webSocketManager.isPreviewerConnected {
                Button(action: {
                    Task {
                        await testSendTestView()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "paperplane.fill")
                        Text("Test Send")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
    }
    
    private func statusIndicator(title: String, status: String, color: Color, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Text(status)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func testSendTestView() async {
        lastActivity = "Sending TestView to previewer..."
        showError = nil
        
        let testViewPath = "/Users/tojkuv/Documents/GitHub/axiom-full-stack/workspace-meta-workspace/axiom-ide/SwiftUIViews/TestView.swift"
        
        do {
            let content = try String(contentsOfFile: testViewPath, encoding: .utf8)
            let testFile = SwiftUIFile(
                name: "TestView.swift",
                fullPath: testViewPath,
                relativePath: "TestView.swift",
                content: content
            )
            
            await previewController.sendToPreview(testFile, via: webSocketManager)
            lastActivity = "TestView sent successfully"
            
            // Clear activity after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if lastActivity == "TestView sent successfully" {
                    lastActivity = ""
                }
            }
            
        } catch {
            showError = "Failed to load TestView.swift: \(error.localizedDescription)"
            lastActivity = ""
        }
    }
    
    private func deployPreviewApp(to simulator: Simulator) async {
        isDeployingApp = true
        showError = nil
        deploymentProgress = "Starting build..."
        lastActivity = "Deploying preview app to \(simulator.name)"
        
        do {
            deploymentProgress = "Building iOS app..."
            try await simulatorManager.buildAndInstallPreviewApp(on: simulator)
            deploymentProgress = "Deployment completed"
            lastActivity = "App deployed successfully to \(simulator.name)"
            
            // Clear activity after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if lastActivity.contains("deployed successfully") {
                    lastActivity = ""
                }
            }
            
        } catch {
            showError = "Failed to deploy app: \(error.localizedDescription)"
            lastActivity = ""
        }
        
        isDeployingApp = false
        deploymentProgress = ""
    }
    
    private var iPhoneEnvironmentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("iPhone Environment")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                if let simulator = simulatorManager.iPhoneSimulator {
                    simulatorStatus(simulator)
                    iPhoneActionButtons(simulator)
                } else {
                    Text("No iPhone 16 Pro found")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                
                iPhoneFileSelector
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    private var iPadEnvironmentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("iPad Environment")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                if let simulator = simulatorManager.iPadSimulator {
                    simulatorStatus(simulator)
                    iPadActionButtons(simulator)
                } else {
                    Text("No iPad Pro 13-inch found")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                
                iPadFileSelector
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    private func iPhoneActionButtons(_ simulator: Simulator) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Button("Start") {
                    Task {
                        await simulatorManager.bootSimulator(simulator)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(simulator.state == .booted)
                
                Button("Shutdown") {
                    Task {
                        await simulatorManager.shutdownSimulator(simulator)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(simulator.state != .booted)
            }
            
            Button("Load Preview App") {
                Task {
                    do {
                        try await simulatorManager.buildAndInstallPreviewApp(on: simulator)
                    } catch {
                        print("❌ Failed to load preview app: \(error)")
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(simulator.state != .booted || isDeployingApp)
            
            if let selectedFile = fileManager.selectediPhoneFile {
                Button("Send to iPhone Preview") {
                    Task {
                        await previewController.sendToPreview(
                            selectedFile,
                            to: simulator,
                            via: webSocketManager
                        )
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!webSocketManager.isPreviewerConnected || simulator.state != .booted)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func iPadActionButtons(_ simulator: Simulator) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Button("Start") {
                    Task {
                        await simulatorManager.bootSimulator(simulator)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(simulator.state == .booted)
                
                Button("Shutdown") {
                    Task {
                        await simulatorManager.shutdownSimulator(simulator)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(simulator.state != .booted)
            }
            
            Button("Load Preview App") {
                Task {
                    do {
                        try await simulatorManager.buildAndInstallPreviewApp(on: simulator)
                    } catch {
                        print("❌ Failed to load preview app: \(error)")
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(simulator.state != .booted || isDeployingApp)
            
            if let selectedFile = fileManager.selectediPadFile {
                Button("Send to iPad Preview") {
                    Task {
                        await previewController.sendToPreview(
                            selectedFile,
                            to: simulator,
                            via: webSocketManager
                        )
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!webSocketManager.isPreviewerConnected || simulator.state != .booted)
            }
        }
        .padding(.vertical, 4)
    }
    
    
    private var iPhoneFileSelector: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("iPhone Preview File")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Picker("iPhone File", selection: $fileManager.selectediPhoneFile) {
                Text("None").tag(nil as SwiftUIFile?)
                ForEach(fileManager.swiftUIFiles, id: \.id) { file in
                    Text(file.name).tag(file as SwiftUIFile?)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
    
    private var iPadFileSelector: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("iPad Preview File")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Picker("iPad File", selection: $fileManager.selectediPadFile) {
                Text("None").tag(nil as SwiftUIFile?)
                ForEach(fileManager.swiftUIFiles, id: \.id) { file in
                    Text(file.name).tag(file as SwiftUIFile?)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
    
    private func simulatorStatus(_ simulator: Simulator) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(simulator.state == .booted ? .green : .orange)
                .frame(width: 6, height: 6)
            
            Text(simulator.state.displayName)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(6)
    }
    
    private var previewStatusView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Environment Status")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                if let iPhoneFile = fileManager.selectediPhoneFile,
                   let iPhoneSimulator = simulatorManager.iPhoneSimulator {
                    environmentStatusCard(
                        title: "iPhone Environment",
                        file: iPhoneFile,
                        simulator: iPhoneSimulator,
                        color: .blue
                    )
                }
                
                if let iPadFile = fileManager.selectediPadFile,
                   let iPadSimulator = simulatorManager.iPadSimulator {
                    environmentStatusCard(
                        title: "iPad Environment", 
                        file: iPadFile,
                        simulator: iPadSimulator,
                        color: .purple
                    )
                }
                
                if fileManager.selectediPhoneFile == nil && fileManager.selectediPadFile == nil {
                    Text("No files selected for preview")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }
    
    private func environmentStatusCard(title: String, file: SwiftUIFile, simulator: Simulator, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(color)
            
            Text("File: \(file.name)")
                .font(.body)
            
            Text("Simulator: \(simulator.name)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Circle()
                    .fill(simulator.state == .booted ? .green : .orange)
                    .frame(width: 8, height: 8)
                Text(simulator.state.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
    
}