import SwiftUI
import Foundation

@MainActor
class ServiceManager: ObservableObject {
    @Published var fileWatcherStatus: ServiceStatus = .stopped
    @Published var fileWatcherOutput: String = ""
    
    private(set) var hotReloadServer: IntegratedHotReloadServer?
    
    init() {
        // Initialize with internal server
    }
    
    func startFileWatcher() async {
        guard fileWatcherStatus != .running else { return }
        
        fileWatcherStatus = .starting
        
        do {
            // Start integrated file watching with WebSocket server
            let server = IntegratedHotReloadServer()
            try await server.start()
            self.hotReloadServer = server
            
            fileWatcherStatus = .running
            print("🔥 Integrated Hot Reload Server started")
            
        } catch {
            fileWatcherStatus = .error("Failed to start Hot Reload Server: \(error.localizedDescription)")
            print("❌ Failed to start Hot Reload Server: \(error)")
        }
    }
    
    func stopFileWatcher() async {
        guard fileWatcherStatus == .running else { return }
        
        // Stop the integrated server
        await hotReloadServer?.stop()
        hotReloadServer = nil
        
        fileWatcherStatus = .stopped
        print("🔥 Hot Reload Server stopped")
    }
    
    func sendPreviewCommand(_ command: PreviewCommand) async {
        await hotReloadServer?.sendPreviewCommand(command)
    }
    
    deinit {
        if let server = hotReloadServer {
            Task.detached {
                await server.stop()
            }
        }
    }
}

enum ServiceStatus: Equatable {
    case stopped
    case starting
    case running
    case error(String)
    
    var displayName: String {
        switch self {
        case .stopped: return "Stopped"
        case .starting: return "Starting..."
        case .running: return "Running"
        case .error(let message): return "Error: \(message)"
        }
    }
    
    var color: Color {
        switch self {
        case .stopped: return .secondary
        case .starting: return .orange
        case .running: return .green
        case .error: return .red
        }
    }
}

enum ServiceError: Error {
    case buildFailed(String)
    case processError(String)
    
    var localizedDescription: String {
        switch self {
        case .buildFailed(let message): return message
        case .processError(let message): return message
        }
    }
}

struct PreviewCommand: Codable, Sendable {
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