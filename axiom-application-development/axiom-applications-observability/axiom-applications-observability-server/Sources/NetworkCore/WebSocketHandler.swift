import Foundation
import WebSocketKit
import NIO
import NIOWebSocket
import Logging
import HotReloadProtocol

// Protocol for WebSocket interface needed by ClientSession
public protocol WebSocketProtocol {
    var isClosed: Bool { get }
    func send(_ data: Data) async throws
    func close() async throws
}

// Simple WebSocket wrapper that implements our interface
internal class ChannelWebSocket: WebSocketProtocol {
    private let context: ChannelHandlerContext
    private let handler: WebSocketHandler
    
    init(context: ChannelHandlerContext, handler: WebSocketHandler) {
        self.context = context
        self.handler = handler
    }
    
    var isClosed: Bool {
        return !context.channel.isActive
    }
    
    func send(_ data: Data) async throws {
        var buffer = context.channel.allocator.buffer(capacity: data.count)
        buffer.writeBytes(data)
        let frame = WebSocketFrame(fin: true, opcode: .text, data: buffer)
        let wrappedFrame = handler.wrapOutboundOut(frame)
        try await context.writeAndFlush(wrappedFrame).get()
    }
    
    func close() async throws {
        try await context.close().get()
    }
}

internal final class WebSocketHandler: ChannelInboundHandler {
    typealias InboundIn = WebSocketFrame
    typealias OutboundOut = WebSocketFrame
    
    private weak var server: WebSocketServer?
    private let clientManager: ClientManager
    private let logger: Logger
    private var webSocket: WebSocket?
    private var clientSession: ClientSession?
    
    init(server: WebSocketServer, clientManager: ClientManager, logger: Logger) {
        self.server = server
        self.clientManager = clientManager
        self.logger = logger
    }
    
    func handlerAdded(context: ChannelHandlerContext) {
        // Create WebSocket using NIOWebSocket directly
        logger.info("WebSocket connection established")
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let frame = unwrapInboundIn(data)
        
        switch frame.opcode {
        case .text:
            handleTextFrame(frame, context: context)
        case .binary:
            handleBinaryFrame(frame, context: context)
        case .connectionClose:
            handleCloseFrame(context: context)
        case .ping:
            handlePingFrame(frame, context: context)
        case .pong:
            handlePongFrame(frame, context: context)
        default:
            break
        }
    }
    
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        logger.error("WebSocket error: \(error)")
        
        if let session = clientSession {
            server?.delegate?.server(server!, didEncounterError: error, for: session)
        } else {
            server?.delegate?.server(server!, didEncounterError: error, for: nil)
        }
        
        context.close(promise: nil)
    }
    
    private func handleTextFrame(_ frame: WebSocketFrame, context: ChannelHandlerContext) {
        var buffer = frame.data
        guard let text = buffer.readString(length: buffer.readableBytes) else { return }
        
        logger.debug("Received text message: \(text.prefix(100))...")
        
        Task {
            do {
                guard let data = text.data(using: .utf8) else {
                    throw WebSocketHandlerError.invalidTextEncoding
                }
                
                let message = try parseMessage(from: data)
                await processMessage(message, context: context)
            } catch {
                logger.error("Failed to process text message: \(error)")
                await sendError(
                    code: "MESSAGE_PARSE_ERROR",
                    message: "Failed to parse message: \(error.localizedDescription)",
                    type: .protocolError,
                    context: context
                )
            }
        }
    }
    
    private func handleBinaryFrame(_ frame: WebSocketFrame, context: ChannelHandlerContext) {
        let buffer = frame.data
        
        logger.debug("Received binary message of \(buffer.readableBytes) bytes")
        
        Task {
            do {
                guard let data = buffer.getData(at: 0, length: buffer.readableBytes) else {
                    throw WebSocketHandlerError.invalidBinaryData
                }
                
                let message = try parseMessage(from: data)
                await processMessage(message, context: context)
            } catch {
                logger.error("Failed to process binary message: \(error)")
                await sendError(
                    code: "MESSAGE_PARSE_ERROR",
                    message: "Failed to parse binary message: \(error.localizedDescription)",
                    type: .protocolError,
                    context: context
                )
            }
        }
    }
    
    private func handleCloseFrame(context: ChannelHandlerContext) {
        Task {
            await handleDisconnection(context: context)
        }
    }
    
    private func handlePingFrame(_ frame: WebSocketFrame, context: ChannelHandlerContext) {
        // Send pong response
        let pongFrame = WebSocketFrame(fin: true, opcode: .pong, data: frame.data)
        context.writeAndFlush(wrapOutboundOut(pongFrame), promise: nil)
    }
    
    private func handlePongFrame(_ frame: WebSocketFrame, context: ChannelHandlerContext) {
        // Handle pong response - could update heartbeat timing
        logger.debug("Received pong frame")
    }
    
    private func parseMessage(from data: Data) throws -> BaseMessage {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(BaseMessage.self, from: data)
    }
    
    private func processMessage(_ message: BaseMessage, context: ChannelHandlerContext) async {
        guard let server = server else { return }
        
        switch message.type {
        case .clientRegister:
            await handleClientRegistration(message, context: context)
        case .pong:
            await handlePong(message)
        case .ping:
            await handlePing(message, context: context)
        default:
            if let session = clientSession {
                server.delegate?.server(server, didReceiveMessage: message, from: session)
            } else {
                logger.warning("Received non-registration message before client registration")
                await sendError(
                    code: "NOT_REGISTERED",
                    message: "Client must register before sending messages",
                    type: .protocolError,
                    context: context
                )
            }
        }
    }
    
    private func handleClientRegistration(_ message: BaseMessage, context: ChannelHandlerContext) async {
        guard case .clientRegister(let payload) = message.payload else {
            await sendError(
                code: "INVALID_REGISTRATION",
                message: "Invalid registration payload",
                type: .protocolError,
                context: context
            )
            return
        }
        
        let clientId = message.clientId ?? UUID().uuidString
        
        // Create a simple WebSocket wrapper for the session
        let channelWebSocket = ChannelWebSocket(context: context, handler: self)
        
        let session = ClientSession(
            id: clientId,
            webSocket: channelWebSocket,
            platform: payload.platform,
            deviceInfo: payload.deviceInfo,
            capabilities: payload.capabilities,
            logger: logger
        )
        
        do {
            try await clientManager.addClient(session)
            self.clientSession = session
            
            logger.info("Client registered: \(clientId) (platform: \(payload.platform.rawValue))")
            
            // Send registration acknowledgment
            let response = BaseMessage(
                type: .capabilityNegotiation,
                clientId: clientId,
                platform: payload.platform,
                payload: .capabilityNegotiation(
                    CapabilityNegotiationPayload(
                        supportedCapabilities: payload.capabilities,
                        recommendedSettings: [:]
                    )
                )
            )
            
            try await session.send(message: response)
            
            server?.delegate?.server(server!, didConnect: session)
        } catch {
            logger.error("Failed to register client: \(error)")
            await sendError(
                code: "REGISTRATION_FAILED",
                message: "Failed to register client: \(error.localizedDescription)",
                type: .client,
                context: context
            )
        }
    }
    
    private func handlePing(_ message: BaseMessage, context: ChannelHandlerContext) async {
        guard case .ping(let payload) = message.payload else { return }
        
        let pongMessage = BaseMessage(
            type: .pong,
            messageId: UUID().uuidString,
            clientId: message.clientId,
            platform: message.platform,
            payload: .pong(PongPayload(sequence: payload.sequence))
        )
        
        if let session = clientSession {
            do {
                try await session.send(message: pongMessage)
            } catch {
                logger.error("Failed to send pong to client \(session.id): \(error)")
            }
        }
    }
    
    private func handlePong(_ message: BaseMessage) async {
        guard case .pong(let payload) = message.payload else { return }
        
        logger.debug("Received pong from client with sequence \(payload.sequence)")
        
        // Update client's last heartbeat time
        if let session = clientSession {
            logger.debug("Heartbeat confirmed for client \(session.id)")
        }
    }
    
    private func sendError(code: String, message: String, type: ErrorType, context: ChannelHandlerContext) async {
        let errorMessage = BaseMessage(
            type: .error,
            clientId: clientSession?.id,
            platform: clientSession?.platform,
            payload: .error(
                ErrorPayload(
                    errorCode: code,
                    errorMessage: message,
                    errorType: type
                )
            )
        )
        
        if let session = clientSession {
            do {
                try await session.send(message: errorMessage)
            } catch {
                logger.error("Failed to send error message to client: \(error)")
            }
        } else {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(errorMessage)
                
                var buffer = context.channel.allocator.buffer(capacity: data.count)
                buffer.writeBytes(data)
                let frame = WebSocketFrame(fin: true, opcode: .text, data: buffer)
                try await context.writeAndFlush(wrapOutboundOut(frame)).get()
            } catch {
                logger.error("Failed to send error message: \(error)")
            }
        }
    }
    
    private func handleDisconnection(context: ChannelHandlerContext) async {
        guard let session = clientSession else { return }
        
        logger.info("Client \(session.id) disconnected")
        
        await clientManager.removeClient(id: session.id)
        
        if let server = server {
            server.delegate?.server(server, didDisconnect: session, reason: nil)
        }
        
        clientSession = nil
    }
}

private enum WebSocketHandlerError: Error, LocalizedError {
    case invalidTextEncoding
    case invalidBinaryData
    case webSocketNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .invalidTextEncoding:
            return "Invalid text encoding in WebSocket message"
        case .invalidBinaryData:
            return "Invalid binary data in WebSocket message"
        case .webSocketNotAvailable:
            return "WebSocket connection not available"
        }
    }
}