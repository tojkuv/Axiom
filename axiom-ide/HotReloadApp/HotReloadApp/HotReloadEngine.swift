import SwiftUI
import Foundation

@MainActor
class PreviewEngine: ObservableObject {
    @Published var currentPreviewFile: PreviewFile?
    @Published var isConnected = false
    @Published var isUsingLiveExecution = false
    
    private var webSocketClient: WebSocketClient?
    let liveExecutionEngine = LiveExecutionEngine()
    
    func connect() async {
        webSocketClient = WebSocketClient()
        await webSocketClient?.setDelegate(self)
        await webSocketClient?.connect()
    }
    
    func disconnect() async {
        await webSocketClient?.disconnect()
        webSocketClient = nil
        isConnected = false
    }
}

extension PreviewEngine: WebSocketClientDelegate {
    func webSocketDidConnect() {
        isConnected = true
        print("📱 iOS Previewer connected to controller")
        
        // Send registration message
        Task {
            let registration = PreviewRegistration(
                type: "register_previewer",
                clientType: "iOS_previewer"
            )
            
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(registration)
                let message = String(data: data, encoding: .utf8) ?? ""
                try await webSocketClient?.send(message)
            } catch {
                print("Failed to send registration: \(error)")
            }
        }
    }
    
    func webSocketDidDisconnect() {
        isConnected = false
        print("📱 iOS Previewer disconnected from controller")
    }
    
    func webSocketDidReceiveMessage(_ message: String) {
        print("📱 iOS received raw message: \(message)")
        print("🟢 PreviewEngine.currentPreviewFile before update: \(currentPreviewFile?.name ?? "nil")")
        
        guard let data = message.data(using: .utf8) else { 
            print("❌ Failed to convert message to data")
            return 
        }
        
        print("📱 Message data size: \(data.count) bytes")
        
        // Try to decode as LivePreviewCommand first
        if let liveCommand = tryDecodeLivePreviewCommand(data) {
            handleLivePreviewCommand(liveCommand)
            return
        }
        
        // Fallback to traditional PreviewCommand
        if let traditionalCommand = tryDecodeTraditionalPreviewCommand(data) {
            handleTraditionalPreviewCommand(traditionalCommand)
            return
        }
        
        print("❌ Failed to decode message as any known command type")
        print("❌ Raw message was: \(message)")
    }
    
    private func tryDecodeLivePreviewCommand(_ data: Data) -> LivePreviewCommand? {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let command = try decoder.decode(LivePreviewCommand.self, from: data)
            print("✅ Successfully decoded LivePreviewCommand: \(command.fileName)")
            return command
        } catch {
            print("🔍 Not a LivePreviewCommand: \(error)")
            return nil
        }
    }
    
    private func tryDecodeTraditionalPreviewCommand(_ data: Data) -> PreviewCommand? {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let command = try decoder.decode(PreviewCommand.self, from: data)
            print("✅ Successfully decoded traditional PreviewCommand: \(command.fileName)")
            return command
        } catch {
            print("🔍 Not a traditional PreviewCommand: \(error)")
            return nil
        }
    }
    
    private func handleLivePreviewCommand(_ command: LivePreviewCommand) {
        print("🔥 Handling LivePreviewCommand for: \(command.fileName)")
        print("🔥 Compiled view has \(command.compiledView.stateVariables.count) state variables")
        print("🔥 Compiled view has \(command.compiledView.interactions.count) interactions")
        
        // Execute the live compiled view
        liveExecutionEngine.executeCompiledView(command.compiledView)
        
        // Update flags
        isUsingLiveExecution = true
        
        // Create a preview file for consistency
        let previewFile = PreviewFile(
            name: command.fileName,
            filePath: command.filePath,
            content: command.compiledView.originalCode
        )
        currentPreviewFile = previewFile
        
        print("✅ Successfully executing live compiled view: \(command.fileName)")
        print("🟢 PreviewEngine.currentPreviewFile after live update: \(currentPreviewFile?.name ?? "nil")")
    }
    
    private func handleTraditionalPreviewCommand(_ command: PreviewCommand) {
        print("📱 Handling traditional PreviewCommand for: \(command.fileName)")
        print("📱 Command content preview: \(String(command.content.prefix(100)))...")
        
        switch command.type {
        case "preview_file":
            let previewFile = PreviewFile(
                name: command.fileName,
                filePath: command.filePath,
                content: command.content
            )
            print("🔄 Setting currentPreviewFile to: \(previewFile.name)")
            currentPreviewFile = previewFile
            isUsingLiveExecution = false
            print("📱 Now previewing: \(command.fileName)")
            print("✅ Updated currentPreviewFile successfully")
            print("🟢 PreviewEngine.currentPreviewFile after update: \(currentPreviewFile?.name ?? "nil")")
            
        case "file_updated":
            if let current = currentPreviewFile,
               current.name == command.fileName {
                let updatedFile = PreviewFile(
                    name: command.fileName,
                    filePath: command.filePath,
                    content: command.content
                )
                print("🔄 Updating currentPreviewFile to: \(updatedFile.name)")
                currentPreviewFile = updatedFile
                isUsingLiveExecution = false
                print("📱 Updated preview: \(command.fileName)")
                print("✅ Updated currentPreviewFile successfully")
                print("🟢 PreviewEngine.currentPreviewFile after update: \(currentPreviewFile?.name ?? "nil")")
            } else {
                print("📱 Ignoring file_updated for \(command.fileName) - not currently previewing")
                print("📱 Current file: \(currentPreviewFile?.name ?? "nil")")
            }
            
        case "live_preview":
            print("📱 Received live_preview command but failed to decode as LivePreviewCommand")
            
        default:
            print("❌ Unknown traditional command type: \(command.type)")
        }
    }
}

struct PreviewRegistration: Codable, Sendable {
    let type: String
    let clientType: String
}

struct PreviewCommand: Codable, Sendable {
    let type: String
    let fileName: String
    let filePath: String
    let content: String
    let targetSimulator: String?
    let deviceType: String?
    let environment: String?
    let timestamp: Date?
}

struct PreviewFile: Sendable {
    let name: String
    let filePath: String
    let content: String
}

struct LivePreviewCommand: Codable, Sendable {
    let type: String
    let fileName: String
    let filePath: String
    let compiledView: LiveCompiledView
    let environment: String
    let timestamp: Date
}