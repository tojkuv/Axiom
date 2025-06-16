import Foundation
import Logging
import HotReloadProtocol

public protocol SwiftUIHotReloadParserDelegate: AnyObject {
    func parser(_ parser: SwiftUIHotReloadParser, didParseFile filePath: String, result: SwiftUIParseResult)
    func parser(_ parser: SwiftUIHotReloadParser, didFailWithError error: Error, filePath: String)
}

public final class SwiftUIHotReloadParser {
    
    public weak var delegate: SwiftUIHotReloadParserDelegate?
    
    private let logger: Logger
    private let configuration: SwiftUIParseConfiguration
    
    // Core parsing components
    private let tokenizer: SwiftUITokenizer
    private let astBuilder: SwiftUIASTBuilder
    private let jsonGenerator: SwiftUIJSONGenerator
    private let stateExtractor: SwiftUIStateExtractor
    private let errorHandler: SwiftUIErrorHandler
    
    public init(
        configuration: SwiftUIParseConfiguration = SwiftUIParseConfiguration(),
        logger: Logger = Logger(label: "axiom.hotreload.swiftui.parser")
    ) {
        self.configuration = configuration
        self.logger = logger
        
        // Initialize components
        self.tokenizer = SwiftUITokenizer(configuration: configuration.tokenizerConfig)
        self.astBuilder = SwiftUIASTBuilder(configuration: configuration.astConfig)
        self.jsonGenerator = SwiftUIJSONGenerator(configuration: SwiftUIJSONGeneratorConfiguration.forHotReload())
        self.stateExtractor = SwiftUIStateExtractor(configuration: configuration.stateConfig)
        self.errorHandler = SwiftUIErrorHandler(
            configuration: SwiftUIErrorHandlerConfiguration.forHotReload(),
            recovery: DefaultSwiftUIErrorRecovery(logger: logger),
            logger: logger
        )
    }
    
    public func parseFile(at filePath: String) async {
        logger.debug("Parsing SwiftUI file: \(filePath)")
        
        do {
            // Read file content
            let content = try String(contentsOfFile: filePath, encoding: .utf8)
            
            // Parse content
            let result = await parseContent(content, filePath: filePath)
            
            // Notify delegate
            delegate?.parser(self, didParseFile: filePath, result: result)
            
        } catch {
            logger.error("Failed to read SwiftUI file \(filePath): \(error)")
            delegate?.parser(self, didFailWithError: error, filePath: filePath)
        }
    }
    
    public func parseContent(_ content: String, filePath: String) async -> SwiftUIParseResult {
        let startTime = Date()
        
        logger.debug("Starting SwiftUI content parsing for: \(filePath)")
        
        do {
            // Step 1: Tokenization with error handling
            let tokens = try handlePhase(.tokenization, filePath: filePath) {
                let tokens = tokenizer.tokenize(content)
                logger.debug("Tokenized \(tokens.count) tokens")
                return tokens
            }
            
            // Step 2: AST Building with error handling
            let ast = try handlePhase(.astBuilding, filePath: filePath) {
                let ast = try astBuilder.buildAST(from: tokens)
                logger.debug("Built AST with \(ast.children.count) root nodes")
                return ast
            }
            
            // Step 3: State Extraction with error handling
            let stateInfo = try handlePhase(.stateExtraction, filePath: filePath) {
                let stateInfo = stateExtractor.extractState(from: ast)
                logger.debug("Extracted \(stateInfo.stateVariables.count) state variables")
                return stateInfo
            }
            
            // Step 4: JSON Generation with error handling
            let swiftUIJSON = try handlePhase(.jsonGeneration, filePath: filePath) {
                let swiftUIJSON = generateSwiftUIJSONOutput(from: ast, stateInfo: stateInfo)
                logger.debug("Generated JSON with \(swiftUIJSON.views.count) views")
                return swiftUIJSON
            }
            
            let parseTime = Date().timeIntervalSince(startTime)
            logger.debug("Parsing completed in \(String(format: "%.3f", parseTime))s")
            
            return SwiftUIParseResult(
                success: true,
                filePath: filePath,
                content: content,
                tokens: tokens,
                ast: ast,
                stateInfo: stateInfo,
                swiftUIJSON: swiftUIJSON,
                errors: [],
                parseTime: parseTime,
                timestamp: Date()
            )
            
        } catch let error as SwiftUIHotReloadError {
            let parseTime = Date().timeIntervalSince(startTime)
            logger.error("SwiftUI parsing failed for \(filePath): \(error)")
            
            return SwiftUIParseResult(
                success: false,
                filePath: filePath,
                content: content,
                tokens: [],
                ast: nil,
                stateInfo: nil,
                swiftUIJSON: nil,
                errors: [error],
                parseTime: parseTime,
                timestamp: Date()
            )
        } catch {
            let parseTime = Date().timeIntervalSince(startTime)
            logger.error("Parsing failed for \(filePath): \(error)")
            
            // Map generic error to SwiftUI-specific error
            let swiftUIError = SwiftUIHotReloadError.invalidSwiftUICode(error.localizedDescription, filePath: filePath)
            
            return SwiftUIParseResult(
                success: false,
                filePath: filePath,
                content: content,
                tokens: [],
                ast: nil,
                stateInfo: nil,
                swiftUIJSON: nil,
                errors: [swiftUIError],
                parseTime: parseTime,
                timestamp: Date()
            )
        }
    }
    
    public func parseContentForHotReload(_ content: String, filePath: String) async -> SwiftUILayoutJSON? {
        let result = await parseContent(content, filePath: filePath)
        
        guard result.success, let swiftUIJSON = result.swiftUIJSON else {
            return nil
        }
        
        // Convert to hot reload format
        return SwiftUILayoutJSON(
            views: swiftUIJSON.views,
            metadata: LayoutMetadata(
                fileName: URL(fileURLWithPath: filePath).lastPathComponent,
                checksum: generateChecksum(for: content)
            )
        )
    }
    
    private func generateChecksum(for content: String) -> String {
        return content.data(using: .utf8)?.base64EncodedString() ?? UUID().uuidString
    }
    
    private func generateSwiftUIJSONOutput(from ast: SwiftUIASTNode, stateInfo: SwiftUIStateInfo) -> SwiftUIJSONOutput {
        // Convert AST to views using the JSON generator
        let views = ast.children.map { child in
            jsonGenerator.generateViewJSON(from: child, stateInfo: stateInfo)
        }
        
        // Create metadata
        let metadata = SwiftUIJSONMetadata(
            generatedAt: Date(),
            version: "1.0.0",
            nodeCount: countASTNodes(ast)
        )
        
        return SwiftUIJSONOutput(views: views, metadata: metadata)
    }
    
    private func countASTNodes(_ node: SwiftUIASTNode) -> Int {
        return 1 + node.children.reduce(0) { $0 + countASTNodes($1) }
    }
    
    private func handlePhase<T>(_ phase: SwiftUIParsePhase, filePath: String, operation: () throws -> T) throws -> T {
        do {
            return try operation()
        } catch {
            let context = SwiftUIErrorContext(
                filePath: filePath,
                parsePhase: phase
            )
            
            // Use a semaphore to make the async error handler work synchronously
            let semaphore = DispatchSemaphore(value: 0)
            var handlerResult: SwiftUIErrorHandlerResult?
            
            errorHandler.handleError(error, context: context) { result in
                handlerResult = result
                semaphore.signal()
            }
            
            semaphore.wait()
            
            guard let result = handlerResult else {
                throw error
            }
            
            // Handle the error response
            switch result.response {
            case .continueWithRecovery(let fallbackContent):
                logger.info("Recovered from error in \(phase.rawValue) phase using fallback")
                if let fallbackContent = fallbackContent {
                    // For tokenization phase, re-tokenize the fallback content
                    if phase == .tokenization, let tokens = try? tokenizer.tokenize(fallbackContent) as? T {
                        return tokens
                    }
                }
                throw result.mappedError
                
            case .continueWithWarning(let message):
                logger.warning("Continuing with warning in \(phase.rawValue) phase: \(message)")
                throw result.mappedError
                
            case .skipFile(let reason):
                logger.info("Skipping file in \(phase.rawValue) phase: \(reason)")
                throw SwiftUIHotReloadError.invalidSwiftUICode("File skipped: \(reason)", filePath: filePath)
                
            case .reportError(let message):
                logger.error("Reporting error in \(phase.rawValue) phase: \(message)")
                throw result.mappedError
                
            case .abort(let reason):
                logger.error("Aborting parsing in \(phase.rawValue) phase: \(reason)")
                throw SwiftUIHotReloadError.invalidSwiftUICode("Parsing aborted: \(reason)", filePath: filePath)
            }
        }
    }
}

// MARK: - Supporting Types

public struct SwiftUIParseResult {
    public let success: Bool
    public let filePath: String
    public let content: String
    public let tokens: [SwiftUIToken]
    public let ast: SwiftUIASTNode?
    public let stateInfo: SwiftUIStateInfo?
    public let swiftUIJSON: SwiftUIJSONOutput?
    public let errors: [Error]
    public let parseTime: TimeInterval
    public let timestamp: Date
}

public struct SwiftUIParseConfiguration {
    public let tokenizerConfig: SwiftUITokenizerConfiguration
    public let astConfig: SwiftUIASTConfiguration
    public let jsonConfig: SwiftUIJSONConfiguration
    public let stateConfig: SwiftUIStateConfiguration
    public let optimizeForHotReload: Bool
    
    public init(
        tokenizerConfig: SwiftUITokenizerConfiguration = SwiftUITokenizerConfiguration(),
        astConfig: SwiftUIASTConfiguration = SwiftUIASTConfiguration(),
        jsonConfig: SwiftUIJSONConfiguration = SwiftUIJSONConfiguration(),
        stateConfig: SwiftUIStateConfiguration = SwiftUIStateConfiguration(),
        optimizeForHotReload: Bool = true
    ) {
        self.tokenizerConfig = tokenizerConfig
        self.astConfig = astConfig
        self.jsonConfig = jsonConfig
        self.stateConfig = stateConfig
        self.optimizeForHotReload = optimizeForHotReload
    }
    
    public static func forHotReload() -> SwiftUIParseConfiguration {
        return SwiftUIParseConfiguration(
            tokenizerConfig: SwiftUITokenizerConfiguration.forHotReload(),
            astConfig: SwiftUIASTConfiguration.forHotReload(),
            jsonConfig: SwiftUIJSONConfiguration.forHotReload(),
            stateConfig: SwiftUIStateConfiguration.forHotReload(),
            optimizeForHotReload: true
        )
    }
}

// MARK: - Core Components

public final class SwiftUITokenizer {
    private let configuration: SwiftUITokenizerConfiguration
    
    public init(configuration: SwiftUITokenizerConfiguration) {
        self.configuration = configuration
    }
    
    public func tokenize(_ content: String) -> [SwiftUIToken] {
        // Simplified tokenizer for hot reload
        // This would be more sophisticated in a full implementation
        var tokens: [SwiftUIToken] = []
        
        let lines = content.components(separatedBy: .newlines)
        for (lineIndex, line) in lines.enumerated() {
            let lineTokens = tokenizeLine(line, lineNumber: lineIndex + 1)
            tokens.append(contentsOf: lineTokens)
        }
        
        return tokens
    }
    
    private func tokenizeLine(_ line: String, lineNumber: Int) -> [SwiftUIToken] {
        var tokens: [SwiftUIToken] = []
        
        // Simple regex-based tokenization for demo
        let patterns: [(SwiftUITokenType, String)] = [
            (.keyword, "\\b(struct|var|let|func|import|@State|@Binding|@ObservedObject)\\b"),
            (.identifier, "\\b[a-zA-Z_][a-zA-Z0-9_]*\\b"),
            (.string, "\"[^\"]*\""),
            (.number, "\\b\\d+(\\.\\d+)?\\b"),
            (.`operator`, "[+\\-*/=<>!&|]{1,2}"),
            (.punctuation, "[{}()\\[\\];:,.]"),
            (.whitespace, "\\s+")
        ]
        
        var position = 0
        let nsString = line as NSString
        
        while position < nsString.length {
            var matched = false
            
            for (tokenType, pattern) in patterns {
                let regex = try! NSRegularExpression(pattern: pattern)
                let range = NSRange(location: position, length: nsString.length - position)
                
                if let match = regex.firstMatch(in: line, range: range), match.range.location == position {
                    let tokenValue = nsString.substring(with: match.range)
                    
                    let token = SwiftUIToken(
                        type: tokenType,
                        value: tokenValue,
                        line: lineNumber,
                        column: position + 1,
                        range: NSRange(location: position, length: match.range.length)
                    )
                    
                    if tokenType != .whitespace || configuration.includeWhitespace {
                        tokens.append(token)
                    }
                    
                    position = match.range.location + match.range.length
                    matched = true
                    break
                }
            }
            
            if !matched {
                position += 1 // Skip unrecognized character
            }
        }
        
        return tokens
    }
}

public struct SwiftUIToken {
    public let type: SwiftUITokenType
    public let value: String
    public let line: Int
    public let column: Int
    public let range: NSRange
}

public enum SwiftUITokenType {
    case keyword
    case identifier
    case string
    case number
    case `operator`
    case punctuation
    case whitespace
    case comment
    case unknown
}

public struct SwiftUITokenizerConfiguration {
    public let includeWhitespace: Bool
    public let includeComments: Bool
    
    public init(includeWhitespace: Bool = false, includeComments: Bool = false) {
        self.includeWhitespace = includeWhitespace
        self.includeComments = includeComments
    }
    
    public static func forHotReload() -> SwiftUITokenizerConfiguration {
        return SwiftUITokenizerConfiguration(includeWhitespace: false, includeComments: false)
    }
}

// Placeholder structures for other components - these would be implemented fully
public struct SwiftUIASTNode {
    public let type: String
    public let value: String?
    public let children: [SwiftUIASTNode]
    public let attributes: [String: String]
    
    public init(type: String, value: String? = nil, children: [SwiftUIASTNode] = [], attributes: [String: String] = [:]) {
        self.type = type
        self.value = value
        self.children = children
        self.attributes = attributes
    }
}

public struct SwiftUIASTConfiguration {
    public let enableOptimizations: Bool
    
    public init(enableOptimizations: Bool = true) {
        self.enableOptimizations = enableOptimizations
    }
    
    public static func forHotReload() -> SwiftUIASTConfiguration {
        return SwiftUIASTConfiguration(enableOptimizations: true)
    }
}

public final class SwiftUIASTBuilder {
    private let configuration: SwiftUIASTConfiguration
    
    public init(configuration: SwiftUIASTConfiguration) {
        self.configuration = configuration
    }
    
    public func buildAST(from tokens: [SwiftUIToken]) throws -> SwiftUIASTNode {
        // Simplified AST building for demo
        // This would parse SwiftUI structures in a full implementation
        
        let structTokens = tokens.filter { $0.type == .keyword && $0.value == "struct" }
        let children = structTokens.map { token in
            SwiftUIASTNode(
                type: "struct",
                value: token.value,
                attributes: ["line": "\(token.line)"]
            )
        }
        
        return SwiftUIASTNode(
            type: "root",
            children: children
        )
    }
}

public struct SwiftUIStateInfo {
    public let stateVariables: [SwiftUIStateVariable]
    public let bindings: [SwiftUIBinding]
    public let observedObjects: [SwiftUIObservedObject]
    
    public init(stateVariables: [SwiftUIStateVariable] = [], bindings: [SwiftUIBinding] = [], observedObjects: [SwiftUIObservedObject] = []) {
        self.stateVariables = stateVariables
        self.bindings = bindings
        self.observedObjects = observedObjects
    }
}

public struct SwiftUIStateVariable {
    public let name: String
    public let type: String
    public let defaultValue: String?
    public let line: Int
}

public struct SwiftUIBinding {
    public let name: String
    public let type: String
    public let line: Int
}

public struct SwiftUIObservedObject {
    public let name: String
    public let type: String
    public let line: Int
}

public struct SwiftUIStateConfiguration {
    public let extractStateVariables: Bool
    public let extractBindings: Bool
    
    public init(extractStateVariables: Bool = true, extractBindings: Bool = true) {
        self.extractStateVariables = extractStateVariables
        self.extractBindings = extractBindings
    }
    
    public static func forHotReload() -> SwiftUIStateConfiguration {
        return SwiftUIStateConfiguration(extractStateVariables: true, extractBindings: true)
    }
}

public final class SwiftUIStateExtractor {
    private let configuration: SwiftUIStateConfiguration
    
    public init(configuration: SwiftUIStateConfiguration) {
        self.configuration = configuration
    }
    
    public func extractState(from ast: SwiftUIASTNode) -> SwiftUIStateInfo {
        var stateVariables: [SwiftUIStateVariable] = []
        var bindings: [SwiftUIBinding] = []
        var observedObjects: [SwiftUIObservedObject] = []
        
        // Extract state from the AST recursively
        extractStateFromNode(ast, stateVariables: &stateVariables, bindings: &bindings, observedObjects: &observedObjects)
        
        return SwiftUIStateInfo(
            stateVariables: stateVariables,
            bindings: bindings,
            observedObjects: observedObjects
        )
    }
    
    private func extractStateFromNode(
        _ node: SwiftUIASTNode,
        stateVariables: inout [SwiftUIStateVariable],
        bindings: inout [SwiftUIBinding],
        observedObjects: inout [SwiftUIObservedObject]
    ) {
        // Look for property wrapper attributes in the node
        if let propertyWrapper = extractPropertyWrapperInfo(from: node) {
            switch propertyWrapper.wrapperType {
            case "@State":
                if configuration.extractStateVariables {
                    let stateVar = SwiftUIStateVariable(
                        name: propertyWrapper.propertyName,
                        type: propertyWrapper.propertyType ?? "Unknown",
                        defaultValue: propertyWrapper.defaultValue,
                        line: extractLineNumber(from: node)
                    )
                    stateVariables.append(stateVar)
                }
                
            case "@Binding":
                if configuration.extractBindings {
                    let binding = SwiftUIBinding(
                        name: propertyWrapper.propertyName,
                        type: propertyWrapper.propertyType ?? "Unknown",
                        line: extractLineNumber(from: node)
                    )
                    bindings.append(binding)
                }
                
            case "@ObservedObject", "@StateObject":
                let observedObject = SwiftUIObservedObject(
                    name: propertyWrapper.propertyName,
                    type: propertyWrapper.propertyType ?? "Unknown",
                    line: extractLineNumber(from: node)
                )
                observedObjects.append(observedObject)
                
            default:
                break
            }
        }
        
        // Recursively process child nodes
        for child in node.children {
            extractStateFromNode(child, stateVariables: &stateVariables, bindings: &bindings, observedObjects: &observedObjects)
        }
    }
    
    private func extractPropertyWrapperInfo(from node: SwiftUIASTNode) -> PropertyWrapperInfo? {
        // Look for property wrapper patterns in node attributes
        for (key, _) in node.attributes {
            if key.hasPrefix("@") {
                // Extract property name and type from the node
                let propertyName = extractPropertyName(from: node) ?? "unknown"
                let propertyType = extractPropertyType(from: node)
                let defaultValue = extractDefaultValue(from: node)
                
                return PropertyWrapperInfo(
                    wrapperType: key,
                    propertyName: propertyName,
                    propertyType: propertyType,
                    defaultValue: defaultValue
                )
            }
        }
        
        // Also check node value for property wrapper patterns
        if let nodeValue = node.value, nodeValue.contains("@") {
            if let wrapperMatch = extractPropertyWrapperFromString(nodeValue) {
                return wrapperMatch
            }
        }
        
        return nil
    }
    
    private func extractPropertyWrapperFromString(_ content: String) -> PropertyWrapperInfo? {
        // Simplified regex-based extraction for common SwiftUI property wrappers
        let patterns = [
            ("@State", #"@State\s+(?:private\s+)?var\s+(\w+)\s*:\s*([^=\s]+)(?:\s*=\s*([^;\n]+))?"#),
            ("@Binding", #"@Binding\s+(?:private\s+)?var\s+(\w+)\s*:\s*([^;\n]+)"#),
            ("@ObservedObject", #"@ObservedObject\s+(?:private\s+)?var\s+(\w+)\s*:\s*([^=\s]+)(?:\s*=\s*([^;\n]+))?"#),
            ("@StateObject", #"@StateObject\s+(?:private\s+)?var\s+(\w+)\s*:\s*([^=\s]+)(?:\s*=\s*([^;\n]+))?"#),
            ("@EnvironmentObject", #"@EnvironmentObject\s+(?:private\s+)?var\s+(\w+)\s*:\s*([^;\n]+)"#)
        ]
        
        for (wrapperType, pattern) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)) {
                
                let propertyName = extractGroup(from: content, match: match, groupIndex: 1) ?? "unknown"
                let propertyType = extractGroup(from: content, match: match, groupIndex: 2)
                let defaultValue = extractGroup(from: content, match: match, groupIndex: 3)
                
                return PropertyWrapperInfo(
                    wrapperType: wrapperType,
                    propertyName: propertyName,
                    propertyType: propertyType,
                    defaultValue: defaultValue
                )
            }
        }
        
        return nil
    }
    
    private func extractGroup(from content: String, match: NSTextCheckingResult, groupIndex: Int) -> String? {
        guard groupIndex < match.numberOfRanges,
              match.range(at: groupIndex).location != NSNotFound else {
            return nil
        }
        
        let range = match.range(at: groupIndex)
        let startIndex = content.index(content.startIndex, offsetBy: range.location)
        let endIndex = content.index(startIndex, offsetBy: range.length)
        
        return String(content[startIndex..<endIndex]).trimmingCharacters(in: .whitespaces)
    }
    
    private func extractPropertyName(from node: SwiftUIASTNode) -> String? {
        // Try to extract property name from node attributes
        if let name = node.attributes["name"] ?? node.attributes["identifier"] {
            return name
        }
        
        // Fallback to extracting from node value
        if let value = node.value {
            // Simple extraction - look for identifier patterns
            let words = value.components(separatedBy: .whitespaces)
            for (index, word) in words.enumerated() {
                if word == "var" && index + 1 < words.count {
                    return words[index + 1].components(separatedBy: ":").first
                }
            }
        }
        
        return nil
    }
    
    private func extractPropertyType(from node: SwiftUIASTNode) -> String? {
        // Try to extract type from node attributes
        if let type = node.attributes["type"] {
            return type
        }
        
        // Extract from value string if available
        if let value = node.value, value.contains(":") {
            let components = value.components(separatedBy: ":")
            if components.count > 1 {
                let typeSection = components[1].components(separatedBy: "=").first ?? components[1]
                return typeSection.trimmingCharacters(in: .whitespaces)
            }
        }
        
        return nil
    }
    
    private func extractDefaultValue(from node: SwiftUIASTNode) -> String? {
        // Try to extract default value from node attributes
        if let defaultVal = node.attributes["defaultValue"] ?? node.attributes["initialValue"] {
            return defaultVal
        }
        
        // Extract from value string if available
        if let value = node.value, value.contains("=") {
            let components = value.components(separatedBy: "=")
            if components.count > 1 {
                return components[1].trimmingCharacters(in: .whitespaces)
            }
        }
        
        return nil
    }
    
    private func extractLineNumber(from node: SwiftUIASTNode) -> Int {
        // Try to extract line number from node attributes
        if let lineStr = node.attributes["line"], let line = Int(lineStr) {
            return line
        }
        return 1 // Default line number
    }
}

// Supporting structure for property wrapper information
private struct PropertyWrapperInfo {
    let wrapperType: String
    let propertyName: String
    let propertyType: String?
    let defaultValue: String?
}

public struct SwiftUIJSONOutput {
    public let views: [SwiftUIViewJSON]
    public let metadata: SwiftUIJSONMetadata
    
    public init(views: [SwiftUIViewJSON], metadata: SwiftUIJSONMetadata) {
        self.views = views
        self.metadata = metadata
    }
}

public struct SwiftUIJSONMetadata {
    public let generatedAt: Date
    public let version: String
    public let nodeCount: Int
    
    public init(generatedAt: Date = Date(), version: String = "1.0.0", nodeCount: Int = 0) {
        self.generatedAt = generatedAt
        self.version = version
        self.nodeCount = nodeCount
    }
}

public struct SwiftUIJSONConfiguration {
    public let includeMetadata: Bool
    public let minimizeOutput: Bool
    
    public init(includeMetadata: Bool = true, minimizeOutput: Bool = false) {
        self.includeMetadata = includeMetadata
        self.minimizeOutput = minimizeOutput
    }
    
    public static func forHotReload() -> SwiftUIJSONConfiguration {
        return SwiftUIJSONConfiguration(includeMetadata: true, minimizeOutput: true)
    }
}

