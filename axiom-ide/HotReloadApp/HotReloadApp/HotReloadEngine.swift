import Foundation
import SwiftUI

struct ViewInfo {
    let name: String
    let fileName: String
    let sourceCode: String
    let lastModified: Date?
    let viewType: String
}

@MainActor
class HotReloadEngine: ObservableObject {
    @Published var isConnected = false
    @Published var availableViews: [ViewInfo] = []
    @Published var lastUpdateTime: Date?
    @Published var connectionStatus = "Connecting..."
    
    private var webSocketClient: WebSocketClient?
    
    init() {
        setupWebSocketClient()
    }
    
    func connect() {
        webSocketClient?.connect()
    }
    
    func disconnect() {
        webSocketClient?.disconnect()
    }
    
    func refreshView(_ viewName: String) {
        // Trigger a refresh for a specific view
        print("🔄 Refreshing view: \(viewName)")
    }
    
    private func setupWebSocketClient() {
        webSocketClient = WebSocketClient { [weak self] message in
            await self?.handleWebSocketMessage(message)
        }
        
        webSocketClient?.onConnectionChange = { [weak self] connected in
            Task { @MainActor in
                self?.isConnected = connected
                self?.connectionStatus = connected ? "Connected" : "Disconnected"
            }
        }
    }
    
    private func handleWebSocketMessage(_ message: WebSocketMessage) async {
        switch message.type {
        case "view_update":
            await handleViewUpdate(message)
        case "view_list":
            await handleViewList(message)
        case "connection_status":
            await handleConnectionStatus(message)
        default:
            print("📨 Unknown message type: \(message.type)")
        }
    }
    
    private func handleViewUpdate(_ message: WebSocketMessage) async {
        guard let viewName = message.payload["viewName"],
              let fileName = message.payload["fileName"],
              let sourceCode = message.payload["sourceCode"],
              let viewType = message.payload["viewType"] else {
            print("❌ Invalid view update message")
            return
        }
        
        let viewInfo = ViewInfo(
            name: viewName,
            fileName: fileName,
            sourceCode: sourceCode,
            lastModified: Date(),
            viewType: viewType
        )
        
        // Update or add view
        if let index = availableViews.firstIndex(where: { $0.name == viewName }) {
            availableViews[index] = viewInfo
        } else {
            availableViews.append(viewInfo)
        }
        
        lastUpdateTime = Date()
        
        print("🔥 Updated view: \(viewName) (\(viewType))")
    }
    
    private func handleViewList(_ message: WebSocketMessage) async {
        // Handle initial view list from file watcher
        print("📋 Received view list")
    }
    
    private func handleConnectionStatus(_ message: WebSocketMessage) async {
        if let status = message.payload["status"] {
            connectionStatus = status
        }
    }
}