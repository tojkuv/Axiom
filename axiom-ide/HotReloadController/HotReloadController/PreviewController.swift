import SwiftUI
import Foundation

@MainActor
class PreviewController: ObservableObject {
    @Published var currentPreviewFile: SwiftUIFile?
    @Published var isPreviewActive = false
    @Published var isUsingLiveCompilation = true
    
    private let liveCompiler = LiveCompiler()
    
    func selectFile(_ file: SwiftUIFile, via webSocketManager: WebSocketManager) async {
        currentPreviewFile = file
        print("Selected file for preview: \(file.name)")
    }
    
    func sendToPreview(_ file: SwiftUIFile, via webSocketManager: WebSocketManager) async {
        await sendToPreview(file, to: nil, via: webSocketManager)
    }
    
    func sendToPreview(_ file: SwiftUIFile, to simulator: Simulator?, via webSocketManager: WebSocketManager) async {
        print("🎯 PreviewController.sendToPreview called")
        print("🎯 File: \(file.name)")
        print("🎯 Simulator: \(simulator?.name ?? "none")")
        print("🎯 WebSocket connected: \(webSocketManager.isPreviewerConnected)")
        print("🎯 Live Compilation: \(isUsingLiveCompilation)")
        
        guard webSocketManager.isPreviewerConnected else {
            print("❌ iOS Previewer not connected - aborting send")
            return
        }
        
        let environment = simulator?.deviceType == .iPhone ? "iPhone" : "iPad"
        
        if isUsingLiveCompilation {
            // Use Live Compilation approach
            await sendLiveCompiledPreview(file, environment: environment, via: webSocketManager)
        } else {
            // Use traditional approach
            await sendTraditionalPreview(file, environment: environment, simulator: simulator, via: webSocketManager)
        }
        
        isPreviewActive = true
        currentPreviewFile = file
    }
    
    private func sendLiveCompiledPreview(_ file: SwiftUIFile, environment: String, via webSocketManager: WebSocketManager) async {
        print("🔥 Using Live Compilation for \(file.name)")
        
        do {
            // Extract view name from file name
            let viewName = file.name.replacingOccurrences(of: ".swift", with: "")
            
            // Compile the SwiftUI code
            let compiledView = try await liveCompiler.generateExecutableSwiftUICode(file.content, viewName: viewName)
            
            print("🔥 Successfully compiled \(viewName)")
            print("🔥 State variables: \(compiledView.stateVariables.count)")
            print("🔥 Interactions: \(compiledView.interactions.count)")
            
            // Create live preview command
            let liveCommand = LivePreviewCommand(
                type: "live_preview",
                fileName: file.name,
                filePath: file.fullPath,
                compiledView: compiledView,
                environment: environment
            )
            
            // Send to iOS
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(liveCommand)
            let message = String(data: data, encoding: .utf8) ?? ""
            
            print("🔥 Sending live compiled view to iOS...")
            await webSocketManager.sendToPreview(message)
            
            print("✅ Sent live compiled view: \(file.name)")
            
        } catch {
            print("❌ Live compilation failed: \(error)")
            print("🔄 Falling back to traditional preview...")
            
            // Fallback to traditional approach
            await sendTraditionalPreview(file, environment: environment, simulator: nil, via: webSocketManager)
        }
    }
    
    private func sendTraditionalPreview(_ file: SwiftUIFile, environment: String, simulator: Simulator?, via webSocketManager: WebSocketManager) async {
        let previewCommand = EnhancedPreviewCommand(
            type: "preview_file",
            fileName: file.name,
            filePath: file.fullPath,
            content: file.content,
            targetSimulator: simulator?.id,
            deviceType: simulator?.deviceType.rawValue,
            environment: environment
        )
        
        print("🎯 Created traditional preview command: \(previewCommand.fileName)")
        print("🎯 Content preview: \(String(file.content.prefix(100)))...")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(previewCommand)
            let message = String(data: data, encoding: .utf8) ?? ""
            
            print("🎯 Encoded command, sending via WebSocketManager...")
            await webSocketManager.sendToPreview(message)
            
            if let simulator = simulator {
                print("✅ Sent traditional preview command for: \(file.name) to \(simulator.name)")
            } else {
                print("✅ Sent traditional preview command for: \(file.name)")
            }
        } catch {
            print("❌ Failed to encode traditional preview command: \(error)")
        }
    }
    
    private func launchPreviewApp(on simulator: Simulator) async {
        // This would launch the hot reload preview app on the specified simulator
        // Implementation would depend on app bundle ID
        let bundleId = "com.axiom.HotReloadApp"
        
        do {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
            process.arguments = ["simctl", "launch", simulator.id, bundleId]
            
            try process.run()
            process.waitUntilExit()
            
            print("Launched preview app on \(simulator.name)")
        } catch {
            print("Failed to launch preview app: \(error)")
        }
    }
}


struct EnhancedPreviewCommand: Codable, Sendable {
    let type: String
    let fileName: String
    let filePath: String
    let content: String
    let targetSimulator: String?
    let deviceType: String?
    let environment: String?
    let timestamp: Date
    
    init(type: String, fileName: String, filePath: String, content: String, targetSimulator: String? = nil, deviceType: String? = nil, environment: String? = nil) {
        self.type = type
        self.fileName = fileName
        self.filePath = filePath
        self.content = content
        self.targetSimulator = targetSimulator
        self.deviceType = deviceType
        self.environment = environment
        self.timestamp = Date()
    }
}

struct LivePreviewCommand: Codable, Sendable {
    let type: String
    let fileName: String
    let filePath: String
    let compiledView: LiveCompiledView
    let environment: String
    let timestamp: Date
    
    init(type: String, fileName: String, filePath: String, compiledView: LiveCompiledView, environment: String) {
        self.type = type
        self.fileName = fileName
        self.filePath = filePath
        self.compiledView = compiledView
        self.environment = environment
        self.timestamp = Date()
    }
}