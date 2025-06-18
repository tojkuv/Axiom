import Foundation
import WebSocketKit
import NIO
import NIOHTTP1
import NIOWebSocket
import Logging
import HotReloadProtocol

public protocol WebSocketServerDelegate: AnyObject {
    func server(_ server: WebSocketServer, didConnect client: ClientSession)
    func server(_ server: WebSocketServer, didDisconnect client: ClientSession, reason: String?)
    func server(_ server: WebSocketServer, didReceiveMessage message: BaseMessage, from client: ClientSession)
    func server(_ server: WebSocketServer, didEncounterError error: Error, for client: ClientSession?)
}

public final class WebSocketServer {
    
    public weak var delegate: WebSocketServerDelegate?
    
    private let eventLoopGroup: EventLoopGroup
    private let logger: Logger
    private let configuration: ServerConfiguration
    private var channel: Channel?
    private var isRunning = false
    private let clientManager = ClientManager()
    
    public init(
        configuration: ServerConfiguration,
        eventLoopGroup: EventLoopGroup? = nil,
        logger: Logger = Logger(label: "axiom.hotreload.websocket")
    ) {
        self.configuration = configuration
        self.eventLoopGroup = eventLoopGroup ?? MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        self.logger = logger
    }
    
    deinit {
        if eventLoopGroup is MultiThreadedEventLoopGroup {
            try? eventLoopGroup.syncShutdownGracefully()
        }
    }
    
    public func start() async throws {
        guard !isRunning else {
            throw WebSocketServerError.alreadyRunning
        }
        
        logger.info("Starting WebSocket server on port \(configuration.port)")
        
        let bootstrap = ServerBootstrap(group: eventLoopGroup)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                let httpHandler = HTTPHandler()
                let websocketUpgrader = NIOWebSocketServerUpgrader(
                    shouldUpgrade: { _, _ in
                        return channel.eventLoop.makeSucceededFuture(HTTPHeaders())
                    },
                    upgradePipelineHandler: { channel, _ in
                        return self.addWebSocketHandlers(to: channel)
                    }
                )
                
                let config = NIOHTTPServerUpgradeConfiguration(
                    upgraders: [websocketUpgrader],
                    completionHandler: { _ in
                        channel.pipeline.removeHandler(httpHandler, promise: nil)
                    }
                )
                
                return channel.pipeline.configureHTTPServerPipeline(withServerUpgrade: config).flatMap {
                    channel.pipeline.addHandler(httpHandler)
                }
            }
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
        
        do {
            channel = try await bootstrap.bind(host: configuration.host, port: configuration.port).get()
            isRunning = true
            logger.info("WebSocket server started successfully on \(configuration.host):\(configuration.port)")
        } catch {
            logger.error("Failed to start WebSocket server: \(error)")
            throw WebSocketServerError.bindFailed(error)
        }
    }
    
    public func stop() async throws {
        guard isRunning else { return }
        
        logger.info("Stopping WebSocket server")
        
        await clientManager.disconnectAllClients()
        
        if let channel = channel {
            try await channel.close()
            self.channel = nil
        }
        
        isRunning = false
        logger.info("WebSocket server stopped")
    }
    
    public func broadcast(message: BaseMessage, to platform: Platform? = nil) async {
        await clientManager.broadcast(message: message, to: platform)
    }
    
    public func send(message: BaseMessage, to clientId: String) async {
        await clientManager.send(message: message, to: clientId)
    }
    
    public func getConnectedClients() async -> [ClientSession] {
        await clientManager.getConnectedClients()
    }
    
    public func getClientCount() async -> Int {
        await clientManager.getClientCount()
    }
    
    private func addWebSocketHandlers(to channel: Channel) -> EventLoopFuture<Void> {
        let webSocketHandler = WebSocketHandler(
            server: self,
            clientManager: clientManager,
            logger: logger
        )
        
        return channel.pipeline.addHandler(webSocketHandler)
    }
}

public struct ServerConfiguration {
    public let host: String
    public let port: Int
    public let maxClients: Int
    public let heartbeatInterval: TimeInterval
    public let maxMessageSize: Int
    public let enableCompression: Bool
    
    public init(
        host: String = "localhost",
        port: Int = 8080,
        maxClients: Int = 100,
        heartbeatInterval: TimeInterval = 30.0,
        maxMessageSize: Int = 1024 * 1024, // 1MB
        enableCompression: Bool = true
    ) {
        self.host = host
        self.port = port
        self.maxClients = maxClients
        self.heartbeatInterval = heartbeatInterval
        self.maxMessageSize = maxMessageSize
        self.enableCompression = enableCompression
    }
}

public enum WebSocketServerError: Error, LocalizedError {
    case alreadyRunning
    case notRunning
    case bindFailed(Error)
    case clientLimitReached
    case invalidMessage(String)
    case clientNotFound(String)
    
    public var errorDescription: String? {
        switch self {
        case .alreadyRunning:
            return "WebSocket server is already running"
        case .notRunning:
            return "WebSocket server is not running"
        case .bindFailed(let error):
            return "Failed to bind server: \(error.localizedDescription)"
        case .clientLimitReached:
            return "Maximum number of clients reached"
        case .invalidMessage(let message):
            return "Invalid message format: \(message)"
        case .clientNotFound(let clientId):
            return "Client not found: \(clientId)"
        }
    }
}

private final class HTTPHandler: ChannelInboundHandler, RemovableChannelHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let reqPart = unwrapInboundIn(data)
        
        switch reqPart {
        case .head(let request):
            if request.uri == "/health" {
                sendHealthResponse(context: context)
            } else {
                send404Response(context: context)
            }
        case .body, .end:
            break
        }
    }
    
    private func sendHealthResponse(context: ChannelHandlerContext) {
        let headers = HTTPHeaders([("content-type", "application/json")])
        let head = HTTPResponseHead(version: .http1_1, status: .ok, headers: headers)
        let body = #"{"status":"healthy","service":"axiom-hotreload-server"}"#
        
        context.write(wrapOutboundOut(.head(head)), promise: nil)
        
        var buffer = context.channel.allocator.buffer(capacity: body.utf8.count)
        buffer.writeString(body)
        context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
    }
    
    private func send404Response(context: ChannelHandlerContext) {
        let head = HTTPResponseHead(version: .http1_1, status: .notFound)
        context.write(wrapOutboundOut(.head(head)), promise: nil)
        context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
    }
}