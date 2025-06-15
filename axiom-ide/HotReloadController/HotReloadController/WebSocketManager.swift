import SwiftUI
import Foundation

@MainActor
class WebSocketManager: ObservableObject {
    @Published var isFileWatcherConnected = false
    @Published var isPreviewerConnected = false
    
    private weak var serviceManager: ServiceManager?
    private var webSocket: URLSessionWebSocketTask?
    
    func connect() async {
        // Since everything is integrated, just mark as connected
        isFileWatcherConnected = true
        print("🔌 Connected to Integrated Hot Reload Server")
        
        // Start monitoring the integrated server's status continuously
        if let server = serviceManager?.hotReloadServer {
            await startMonitoringServer(server)
        }
    }
    
    private func startMonitoringServer(_ server: IntegratedHotReloadServer) async {
        // Initial status check
        isPreviewerConnected = server.isPreviewerConnected
        print("📱 iOS Previewer initial status: \(isPreviewerConnected ? "Connected" : "Disconnected")")
        
        // Start continuous monitoring
        Task { @MainActor in
            while serviceManager?.hotReloadServer != nil {
                let currentStatus = server.isPreviewerConnected
                if currentStatus != isPreviewerConnected {
                    isPreviewerConnected = currentStatus
                    print("📱 iOS Previewer status changed: \(isPreviewerConnected ? "Connected" : "Disconnected")")
                }
                
                // Check every 0.5 seconds
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
    }
    
    func setServiceManager(_ serviceManager: ServiceManager) {
        self.serviceManager = serviceManager
    }
    
    func sendToPreview(_ message: String) async {
        print("🔄 WebSocketManager.sendToPreview called with message: \(message)")
        
        // Parse the message and send it via the integrated server
        guard let data = message.data(using: .utf8) else { 
            print("❌ Failed to convert message to data")
            return 
        }
        
        print("🔄 Data created, attempting to decode...")
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let enhancedCommand = try decoder.decode(EnhancedPreviewCommand.self, from: data)
            
            print("✅ Successfully decoded EnhancedPreviewCommand: \(enhancedCommand.fileName)")
            
            let command = PreviewCommand(
                type: enhancedCommand.type,
                fileName: enhancedCommand.fileName,
                filePath: enhancedCommand.filePath,
                content: enhancedCommand.content,
                targetSimulator: enhancedCommand.targetSimulator,
                deviceType: enhancedCommand.deviceType,
                environment: enhancedCommand.environment
            )
            
            print("🔄 Created PreviewCommand, sending to serviceManager...")
            
            if let serviceManager = serviceManager {
                await serviceManager.sendPreviewCommand(command)
                print("📤 Sent preview command via integrated server: \(enhancedCommand.fileName)")
            } else {
                print("❌ ServiceManager is nil!")
            }
        } catch {
            print("❌ Failed to decode preview command: \(error)")
        }
    }
    
    func disconnect() {
        isFileWatcherConnected = false
        isPreviewerConnected = false
        print("🔌 Disconnected from Integrated Hot Reload Server")
    }
}

struct ClientRegistration: Codable, Sendable {
    let type: String
    let clientType: String
}