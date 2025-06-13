import Foundation

// MARK: - Network Capability Usage Examples
//
// This file demonstrates how applications can build their own network clients
// using the NetworkCapability as a foundation. The framework provides the
// capability infrastructure, while applications implement their specific
// networking patterns and domain models.

#if EXAMPLE_CODE

// MARK: - Example: HTTP Client Implementation

/// Example of how an application might implement an HTTP client
/// using the NetworkCapability
public actor ApplicationHTTPClient {
    private let networkCapability: NetworkCapability
    private let baseURL: URL
    private let defaultHeaders: [String: String]
    
    public init(networkCapability: NetworkCapability, baseURL: URL, defaultHeaders: [String: String] = [:]) {
        self.networkCapability = networkCapability
        self.baseURL = baseURL
        self.defaultHeaders = defaultHeaders
    }
    
    // Application defines its own request/response models
    public struct HTTPRequest {
        let method: String
        let path: String
        let headers: [String: String]
        let body: Data?
        
        func urlRequest(baseURL: URL, defaultHeaders: [String: String]) throws -> URLRequest {
            let url = baseURL.appendingPathComponent(path)
            var request = URLRequest(url: url)
            request.httpMethod = method
            request.httpBody = body
            
            // Merge headers
            for (key, value) in defaultHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
            
            return request
        }
    }
    
    public struct HTTPResponse<T> {
        let data: Data
        let statusCode: Int
        let headers: [String: String]
        let parsedBody: T?
    }
    
    // Application implements its own request execution logic
    public func execute<T: Codable>(
        _ request: HTTPRequest,
        responseType: T.Type
    ) async throws -> HTTPResponse<T> {
        let urlRequest = try request.urlRequest(baseURL: baseURL, defaultHeaders: defaultHeaders)
        let result = try await networkCapability.execute(urlRequest)
        
        let statusCode = result.httpStatusCode ?? 0
        let headers = result.httpHeaders ?? [:]
        
        // Application handles its own parsing logic
        let parsedBody: T?
        if T.self == Data.self {
            parsedBody = result.data as? T
        } else {
            parsedBody = try? JSONDecoder().decode(T.self, from: result.data)
        }
        
        return HTTPResponse(
            data: result.data,
            statusCode: statusCode,
            headers: headers,
            parsedBody: parsedBody
        )
    }
}

// MARK: - Example: GraphQL Client Implementation

/// Example of how an application might implement a GraphQL client
/// using the NetworkCapability
public actor ApplicationGraphQLClient {
    private let networkCapability: NetworkCapability
    private let endpoint: URL
    private let authToken: String?
    
    public init(networkCapability: NetworkCapability, endpoint: URL, authToken: String? = nil) {
        self.networkCapability = networkCapability
        self.endpoint = endpoint
        self.authToken = authToken
    }
    
    // Application defines its own GraphQL models
    public struct GraphQLRequest {
        let query: String
        let variables: [String: Any]?
        let operationName: String?
    }
    
    public struct GraphQLResponse<T: Codable> {
        let data: T?
        let errors: [GraphQLError]?
    }
    
    public struct GraphQLError: Codable {
        let message: String
        let path: [String]?
        let extensions: [String: String]?
    }
    
    // Application implements its own GraphQL execution logic
    public func execute<T: Codable>(
        _ request: GraphQLRequest,
        responseType: T.Type
    ) async throws -> GraphQLResponse<T> {
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let requestBody = [
            "query": request.query,
            "variables": request.variables as Any,
            "operationName": request.operationName as Any
        ]
        
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let result = try await networkCapability.execute(urlRequest)
        
        // Application handles its own GraphQL response parsing
        let jsonResponse = try JSONSerialization.jsonObject(with: result.data) as? [String: Any]
        
        let data = jsonResponse?["data"] as? [String: Any]
        let errors = jsonResponse?["errors"] as? [[String: Any]]
        
        let parsedData: T?
        if let data = data {
            let dataJSON = try JSONSerialization.data(withJSONObject: data)
            parsedData = try JSONDecoder().decode(T.self, from: dataJSON)
        } else {
            parsedData = nil
        }
        
        let parsedErrors = errors?.compactMap { errorDict -> GraphQLError? in
            guard let message = errorDict["message"] as? String else { return nil }
            return GraphQLError(
                message: message,
                path: errorDict["path"] as? [String],
                extensions: errorDict["extensions"] as? [String: String]
            )
        }
        
        return GraphQLResponse(data: parsedData, errors: parsedErrors)
    }
}

// MARK: - Example: File Upload Client Implementation

/// Example of how an application might implement a file upload client
/// using the NetworkCapability
public actor ApplicationFileUploadClient {
    private let networkCapability: NetworkCapability
    private let uploadEndpoint: URL
    
    public init(networkCapability: NetworkCapability, uploadEndpoint: URL) {
        self.networkCapability = networkCapability
        self.uploadEndpoint = uploadEndpoint
    }
    
    // Application defines its own upload models
    public struct FileUploadRequest {
        let fileName: String
        let mimeType: String
        let data: Data
        let additionalFields: [String: String]
    }
    
    public struct UploadProgress {
        let bytesUploaded: Int64
        let totalBytes: Int64
        
        var percentage: Double {
            guard totalBytes > 0 else { return 0 }
            return Double(bytesUploaded) / Double(totalBytes)
        }
    }
    
    // Application implements its own multipart upload logic
    public func upload(_ request: FileUploadRequest) async throws -> String {
        let boundary = "Boundary-\(UUID().uuidString)"
        var urlRequest = URLRequest(url: uploadEndpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Build multipart body
        var body = Data()
        
        // Add additional fields
        for (key, value) in request.additionalFields {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // Add file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(request.fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(request.mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(request.data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        urlRequest.httpBody = body
        
        let result = try await networkCapability.execute(urlRequest)
        
        // Application handles its own response parsing
        guard let responseString = String(data: result.data, encoding: .utf8) else {
            throw NSError(domain: "UploadError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        return responseString
    }
}

// MARK: - Example: WebSocket Client Implementation

/// Example of how an application might implement a WebSocket client
/// using the NetworkCapability for initial handshake and connection management
public actor ApplicationWebSocketClient {
    private let networkCapability: NetworkCapability
    private let url: URL
    private var webSocketTask: URLSessionWebSocketTask?
    
    public init(networkCapability: NetworkCapability, url: URL) {
        self.networkCapability = networkCapability
        self.url = url
    }
    
    // Application defines its own WebSocket message models
    public enum WebSocketMessage {
        case text(String)
        case data(Data)
    }
    
    // Application implements its own WebSocket logic using URLSession
    public func connect() async throws {
        let session = await networkCapability.resources.getSession()
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        
        // Start listening for messages
        Task {
            await listenForMessages()
        }
    }
    
    public func send(_ message: WebSocketMessage) async throws {
        guard let task = webSocketTask else {
            throw NSError(domain: "WebSocketError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not connected"])
        }
        
        let urlMessage: URLSessionWebSocketTask.Message
        switch message {
        case .text(let text):
            urlMessage = .string(text)
        case .data(let data):
            urlMessage = .data(data)
        }
        
        try await task.send(urlMessage)
    }
    
    private func listenForMessages() async {
        guard let task = webSocketTask else { return }
        
        do {
            let message = try await task.receive()
            
            // Application handles its own message processing
            switch message {
            case .string(let text):
                await handleTextMessage(text)
            case .data(let data):
                await handleDataMessage(data)
            @unknown default:
                break
            }
            
            // Continue listening
            await listenForMessages()
        } catch {
            // Handle connection error
            await handleConnectionError(error)
        }
    }
    
    private func handleTextMessage(_ text: String) async {
        // Application-specific text message handling
    }
    
    private func handleDataMessage(_ data: Data) async {
        // Application-specific data message handling
    }
    
    private func handleConnectionError(_ error: Error) async {
        // Application-specific error handling
    }
    
    public func disconnect() async {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }
}

// MARK: - Example: Application Integration

/// Example of how an application would integrate and use these clients
public class ApplicationNetworkManager {
    private let networkCapability: NetworkCapability
    private let httpClient: ApplicationHTTPClient
    private let graphQLClient: ApplicationGraphQLClient
    private let uploadClient: ApplicationFileUploadClient
    
    public init() async throws {
        // Application configures the network capability for its needs
        let configuration = NetworkCapabilityConfiguration(
            timeout: 30.0,
            maxConcurrentConnections: 10,
            allowsCellularAccess: true,
            enableLogging: true
        )
        
        self.networkCapability = NetworkCapability(configuration: configuration)
        try await networkCapability.activate()
        
        // Application builds its own clients on top of the capability
        self.httpClient = ApplicationHTTPClient(
            networkCapability: networkCapability,
            baseURL: URL(string: "https://api.example.com")!,
            defaultHeaders: [
                "User-Agent": "MyApp/1.0",
                "Accept": "application/json"
            ]
        )
        
        self.graphQLClient = ApplicationGraphQLClient(
            networkCapability: networkCapability,
            endpoint: URL(string: "https://api.example.com/graphql")!
        )
        
        self.uploadClient = ApplicationFileUploadClient(
            networkCapability: networkCapability,
            uploadEndpoint: URL(string: "https://api.example.com/upload")!
        )
    }
    
    // Application defines its own domain-specific methods
    public func fetchUserProfile(userId: String) async throws -> UserProfile {
        let request = ApplicationHTTPClient.HTTPRequest(
            method: "GET",
            path: "/users/\(userId)",
            headers: [:],
            body: nil
        )
        
        let response = try await httpClient.execute(request, responseType: UserProfile.self)
        
        guard let profile = response.parsedBody else {
            throw NSError(domain: "APIError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse user profile"])
        }
        
        return profile
    }
    
    public func uploadProfileImage(_ imageData: Data, for userId: String) async throws -> String {
        let request = ApplicationFileUploadClient.FileUploadRequest(
            fileName: "profile.jpg",
            mimeType: "image/jpeg",
            data: imageData,
            additionalFields: ["userId": userId]
        )
        
        return try await uploadClient.upload(request)
    }
}

// MARK: - Application Domain Models

/// Application defines its own domain models
public struct UserProfile: Codable {
    let id: String
    let name: String
    let email: String
    let avatarURL: String?
}

#endif // EXAMPLE_CODE