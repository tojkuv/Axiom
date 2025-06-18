import Foundation
import UIKit
import CoreGraphics
import AxiomCore
import AxiomCapabilities

// MARK: - Keyboard Input Capability Configuration

/// Configuration for Keyboard Input capability
public struct KeyboardInputCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableKeyboardInput: Bool
    public let enableShortcutRecognition: Bool
    public let enableTextInputProcessing: Bool
    public let enableHardwareKeyboard: Bool
    public let enableVirtualKeyboard: Bool
    public let enableInputMethodSupport: Bool
    public let maxConcurrentInputs: Int
    public let inputTimeout: TimeInterval
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableCaching: Bool
    public let cacheSize: Int
    public let keyboardLayout: KeyboardLayout
    public let inputMode: InputMode
    public let repeatDelay: TimeInterval
    public let repeatInterval: TimeInterval
    public let enableKeyPreview: Bool
    public let enableAutocorrection: Bool
    public let enableSpellChecking: Bool
    public let enablePredictiveText: Bool
    public let textContentType: TextContentType
    
    public enum KeyboardLayout: String, Codable, CaseIterable {
        case qwerty = "qwerty"
        case qwertz = "qwertz"
        case azerty = "azerty"
        case dvorak = "dvorak"
        case colemak = "colemak"
        case automatic = "automatic"
    }
    
    public enum InputMode: String, Codable, CaseIterable {
        case text = "text"
        case numeric = "numeric"
        case email = "email"
        case url = "url"
        case phone = "phone"
        case secure = "secure"
        case search = "search"
        case twitter = "twitter"
    }
    
    public enum TextContentType: String, Codable, CaseIterable {
        case none = "none"
        case username = "username"
        case password = "password"
        case newPassword = "newPassword"
        case oneTimeCode = "oneTimeCode"
        case emailAddress = "emailAddress"
        case telephoneNumber = "telephoneNumber"
        case creditCardNumber = "creditCardNumber"
        case addressCity = "addressCity"
        case addressState = "addressState"
        case addressCityAndState = "addressCityAndState"
        case fullStreetAddress = "fullStreetAddress"
        case countryName = "countryName"
        case postalCode = "postalCode"
        case organizationName = "organizationName"
        case givenName = "givenName"
        case familyName = "familyName"
        case namePrefix = "namePrefix"
        case nameSuffix = "nameSuffix"
        case nickname = "nickname"
        case jobTitle = "jobTitle"
        case location = "location"
    }
    
    public init(
        enableKeyboardInput: Bool = true,
        enableShortcutRecognition: Bool = true,
        enableTextInputProcessing: Bool = true,
        enableHardwareKeyboard: Bool = true,
        enableVirtualKeyboard: Bool = true,
        enableInputMethodSupport: Bool = true,
        maxConcurrentInputs: Int = 10,
        inputTimeout: TimeInterval = 30.0,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableCaching: Bool = true,
        cacheSize: Int = 500,
        keyboardLayout: KeyboardLayout = .automatic,
        inputMode: InputMode = .text,
        repeatDelay: TimeInterval = 0.5,
        repeatInterval: TimeInterval = 0.1,
        enableKeyPreview: Bool = true,
        enableAutocorrection: Bool = true,
        enableSpellChecking: Bool = true,
        enablePredictiveText: Bool = true,
        textContentType: TextContentType = .none
    ) {
        self.enableKeyboardInput = enableKeyboardInput
        self.enableShortcutRecognition = enableShortcutRecognition
        self.enableTextInputProcessing = enableTextInputProcessing
        self.enableHardwareKeyboard = enableHardwareKeyboard
        self.enableVirtualKeyboard = enableVirtualKeyboard
        self.enableInputMethodSupport = enableInputMethodSupport
        self.maxConcurrentInputs = maxConcurrentInputs
        self.inputTimeout = inputTimeout
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableCaching = enableCaching
        self.cacheSize = cacheSize
        self.keyboardLayout = keyboardLayout
        self.inputMode = inputMode
        self.repeatDelay = repeatDelay
        self.repeatInterval = repeatInterval
        self.enableKeyPreview = enableKeyPreview
        self.enableAutocorrection = enableAutocorrection
        self.enableSpellChecking = enableSpellChecking
        self.enablePredictiveText = enablePredictiveText
        self.textContentType = textContentType
    }
    
    public var isValid: Bool {
        maxConcurrentInputs > 0 &&
        inputTimeout > 0 &&
        repeatDelay >= 0 &&
        repeatInterval > 0 &&
        cacheSize >= 0
    }
    
    public func merged(with other: KeyboardInputCapabilityConfiguration) -> KeyboardInputCapabilityConfiguration {
        KeyboardInputCapabilityConfiguration(
            enableKeyboardInput: other.enableKeyboardInput,
            enableShortcutRecognition: other.enableShortcutRecognition,
            enableTextInputProcessing: other.enableTextInputProcessing,
            enableHardwareKeyboard: other.enableHardwareKeyboard,
            enableVirtualKeyboard: other.enableVirtualKeyboard,
            enableInputMethodSupport: other.enableInputMethodSupport,
            maxConcurrentInputs: other.maxConcurrentInputs,
            inputTimeout: other.inputTimeout,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableCaching: other.enableCaching,
            cacheSize: other.cacheSize,
            keyboardLayout: other.keyboardLayout,
            inputMode: other.inputMode,
            repeatDelay: other.repeatDelay,
            repeatInterval: other.repeatInterval,
            enableKeyPreview: other.enableKeyPreview,
            enableAutocorrection: other.enableAutocorrection,
            enableSpellChecking: other.enableSpellChecking,
            enablePredictiveText: other.enablePredictiveText,
            textContentType: other.textContentType
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> KeyboardInputCapabilityConfiguration {
        var adjustedTimeout = inputTimeout
        var adjustedLogging = enableLogging
        var adjustedConcurrentInputs = maxConcurrentInputs
        var adjustedCacheSize = cacheSize
        var adjustedPredictiveText = enablePredictiveText
        var adjustedAutocorrection = enableAutocorrection
        
        if environment.isLowPowerMode {
            adjustedTimeout = min(inputTimeout, 15.0)
            adjustedConcurrentInputs = min(maxConcurrentInputs, 3)
            adjustedCacheSize = min(cacheSize, 100)
            adjustedPredictiveText = false
            adjustedAutocorrection = false
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return KeyboardInputCapabilityConfiguration(
            enableKeyboardInput: enableKeyboardInput,
            enableShortcutRecognition: enableShortcutRecognition,
            enableTextInputProcessing: enableTextInputProcessing,
            enableHardwareKeyboard: enableHardwareKeyboard,
            enableVirtualKeyboard: enableVirtualKeyboard,
            enableInputMethodSupport: enableInputMethodSupport,
            maxConcurrentInputs: adjustedConcurrentInputs,
            inputTimeout: adjustedTimeout,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableCaching: enableCaching,
            cacheSize: adjustedCacheSize,
            keyboardLayout: keyboardLayout,
            inputMode: inputMode,
            repeatDelay: repeatDelay,
            repeatInterval: repeatInterval,
            enableKeyPreview: enableKeyPreview,
            enableAutocorrection: adjustedAutocorrection,
            enableSpellChecking: enableSpellChecking,
            enablePredictiveText: adjustedPredictiveText,
            textContentType: textContentType
        )
    }
}

// MARK: - Keyboard Input Types

/// Keyboard input event
public struct KeyboardInputEvent: Sendable, Identifiable {
    public let id: UUID
    public let keyData: KeyData
    public let timestamp: Date
    public let metadata: [String: String]
    
    public struct KeyData: Sendable {
        public let keys: [KeyInput]
        public let eventType: KeyEventType
        public let modifiers: KeyModifiers
        public let inputSource: InputSource
        public let text: String?
        public let textRange: NSRange?
        public let replacement: String?
        public let markedText: String?
        public let selectedTextRange: NSRange?
        
        public struct KeyInput: Sendable, Identifiable {
            public let id: UUID
            public let key: String
            public let keyCode: Int
            public let virtualKeyCode: Int?
            public let unicodeScalar: Unicode.Scalar?
            public let isRepeat: Bool
            public let timestamp: TimeInterval
            public let pressure: Float
            public let stage: KeyStage
            
            public enum KeyStage: String, Sendable, CaseIterable {
                case down = "down"
                case up = "up"
                case repeat = "repeat"
            }
            
            public init(
                key: String,
                keyCode: Int,
                virtualKeyCode: Int? = nil,
                unicodeScalar: Unicode.Scalar? = nil,
                isRepeat: Bool = false,
                timestamp: TimeInterval = 0,
                pressure: Float = 1.0,
                stage: KeyStage = .down
            ) {
                self.id = UUID()
                self.key = key
                self.keyCode = keyCode
                self.virtualKeyCode = virtualKeyCode
                self.unicodeScalar = unicodeScalar
                self.isRepeat = isRepeat
                self.timestamp = timestamp
                self.pressure = pressure
                self.stage = stage
            }
        }
        
        public struct KeyModifiers: OptionSet, Sendable {
            public let rawValue: UInt
            
            public init(rawValue: UInt) {
                self.rawValue = rawValue
            }
            
            public static let command = KeyModifiers(rawValue: 1 << 0)
            public static let shift = KeyModifiers(rawValue: 1 << 1)
            public static let control = KeyModifiers(rawValue: 1 << 2)
            public static let option = KeyModifiers(rawValue: 1 << 3)
            public static let capsLock = KeyModifiers(rawValue: 1 << 4)
            public static let numericPad = KeyModifiers(rawValue: 1 << 5)
            public static let help = KeyModifiers(rawValue: 1 << 6)
            public static let function = KeyModifiers(rawValue: 1 << 7)
        }
        
        public enum InputSource: String, Sendable, CaseIterable {
            case hardware = "hardware"
            case virtual = "virtual"
            case external = "external"
            case dictation = "dictation"
            case handwriting = "handwriting"
            case voice = "voice"
        }
        
        public enum KeyEventType: String, Sendable, CaseIterable {
            case keyDown = "keyDown"
            case keyUp = "keyUp"
            case textInput = "textInput"
            case textChange = "textChange"
            case textSelection = "textSelection"
            case shortcut = "shortcut"
            case composition = "composition"
            case autocomplete = "autocomplete"
        }
        
        public init(
            keys: [KeyInput],
            eventType: KeyEventType,
            modifiers: KeyModifiers = [],
            inputSource: InputSource = .hardware,
            text: String? = nil,
            textRange: NSRange? = nil,
            replacement: String? = nil,
            markedText: String? = nil,
            selectedTextRange: NSRange? = nil
        ) {
            self.keys = keys
            self.eventType = eventType
            self.modifiers = modifiers
            self.inputSource = inputSource
            self.text = text
            self.textRange = textRange
            self.replacement = replacement
            self.markedText = markedText
            self.selectedTextRange = selectedTextRange
        }
    }
    
    public init(keyData: KeyData, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.keyData = keyData
        self.timestamp = Date()
        self.metadata = metadata
    }
}

/// Keyboard input result
public struct KeyboardInputResult: Sendable, Identifiable {
    public let id: UUID
    public let eventId: UUID
    public let processedKeys: [ProcessedKey]
    public let recognizedShortcuts: [RecognizedShortcut]
    public let textProcessing: TextProcessingResult
    public let inputMetrics: InputMetrics
    public let processingTime: TimeInterval
    public let success: Bool
    public let error: KeyboardInputError?
    public let timestamp: Date
    public let metadata: [String: String]
    
    public struct ProcessedKey: Sendable {
        public let originalKey: KeyboardInputEvent.KeyData.KeyInput
        public let normalizedKey: String
        public let keyCode: Int
        public let character: String?
        public let isSpecialKey: Bool
        public let keyFunction: KeyFunction
        public let inputMode: KeyboardInputCapabilityConfiguration.InputMode
        public let layout: KeyboardInputCapabilityConfiguration.KeyboardLayout
        
        public enum KeyFunction: String, Sendable, CaseIterable {
            case character = "character"
            case backspace = "backspace"
            case delete = "delete"
            case enter = "enter"
            case tab = "tab"
            case space = "space"
            case escape = "escape"
            case arrow = "arrow"
            case function = "function"
            case modifier = "modifier"
            case media = "media"
            case system = "system"
        }
        
        public init(
            originalKey: KeyboardInputEvent.KeyData.KeyInput,
            normalizedKey: String,
            keyCode: Int,
            character: String? = nil,
            isSpecialKey: Bool = false,
            keyFunction: KeyFunction = .character,
            inputMode: KeyboardInputCapabilityConfiguration.InputMode = .text,
            layout: KeyboardInputCapabilityConfiguration.KeyboardLayout = .qwerty
        ) {
            self.originalKey = originalKey
            self.normalizedKey = normalizedKey
            self.keyCode = keyCode
            self.character = character
            self.isSpecialKey = isSpecialKey
            self.keyFunction = keyFunction
            self.inputMode = inputMode
            self.layout = layout
        }
    }
    
    public struct RecognizedShortcut: Sendable {
        public let shortcut: String
        public let keys: [String]
        public let modifiers: KeyboardInputEvent.KeyData.KeyModifiers
        public let action: String
        public let context: String
        public let confidence: Float
        
        public init(
            shortcut: String,
            keys: [String],
            modifiers: KeyboardInputEvent.KeyData.KeyModifiers,
            action: String,
            context: String = "global",
            confidence: Float = 1.0
        ) {
            self.shortcut = shortcut
            self.keys = keys
            self.modifiers = modifiers
            self.action = action
            self.context = context
            self.confidence = confidence
        }
    }
    
    public struct TextProcessingResult: Sendable {
        public let originalText: String?
        public let processedText: String?
        public let autocorrectedText: String?
        public let suggestions: [String]
        public let predictiveText: [String]
        public let spellCheckResults: [SpellCheckResult]
        public let languageDetection: String?
        public let inputMethod: String?
        
        public struct SpellCheckResult: Sendable {
            public let range: NSRange
            public let misspelledWord: String
            public let suggestions: [String]
            public let confidence: Float
            
            public init(range: NSRange, misspelledWord: String, suggestions: [String], confidence: Float) {
                self.range = range
                self.misspelledWord = misspelledWord
                self.suggestions = suggestions
                self.confidence = confidence
            }
        }
        
        public init(
            originalText: String? = nil,
            processedText: String? = nil,
            autocorrectedText: String? = nil,
            suggestions: [String] = [],
            predictiveText: [String] = [],
            spellCheckResults: [SpellCheckResult] = [],
            languageDetection: String? = nil,
            inputMethod: String? = nil
        ) {
            self.originalText = originalText
            self.processedText = processedText
            self.autocorrectedText = autocorrectedText
            self.suggestions = suggestions
            self.predictiveText = predictiveText
            self.spellCheckResults = spellCheckResults
            self.languageDetection = languageDetection
            self.inputMethod = inputMethod
        }
    }
    
    public struct InputMetrics: Sendable {
        public let totalKeys: Int
        public let charactersPerSecond: Double
        public let wordsPerMinute: Double
        public let accuracy: Double
        public let autocorrectionRate: Double
        public let shortcutsUsed: Int
        public let inputLatency: TimeInterval
        public let processingLatency: TimeInterval
        
        public init(
            totalKeys: Int,
            charactersPerSecond: Double,
            wordsPerMinute: Double,
            accuracy: Double,
            autocorrectionRate: Double,
            shortcutsUsed: Int,
            inputLatency: TimeInterval,
            processingLatency: TimeInterval
        ) {
            self.totalKeys = totalKeys
            self.charactersPerSecond = charactersPerSecond
            self.wordsPerMinute = wordsPerMinute
            self.accuracy = accuracy
            self.autocorrectionRate = autocorrectionRate
            self.shortcutsUsed = shortcutsUsed
            self.inputLatency = inputLatency
            self.processingLatency = processingLatency
        }
    }
    
    public init(
        eventId: UUID,
        processedKeys: [ProcessedKey],
        recognizedShortcuts: [RecognizedShortcut],
        textProcessing: TextProcessingResult,
        inputMetrics: InputMetrics,
        processingTime: TimeInterval,
        success: Bool,
        error: KeyboardInputError? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.eventId = eventId
        self.processedKeys = processedKeys
        self.recognizedShortcuts = recognizedShortcuts
        self.textProcessing = textProcessing
        self.inputMetrics = inputMetrics
        self.processingTime = processingTime
        self.success = success
        self.error = error
        self.timestamp = Date()
        self.metadata = metadata
    }
    
    public var keyCount: Int {
        processedKeys.count
    }
    
    public var shortcutCount: Int {
        recognizedShortcuts.count
    }
    
    public var averageConfidence: Float {
        guard !recognizedShortcuts.isEmpty else { return 0.0 }
        return recognizedShortcuts.reduce(0) { $0 + $1.confidence } / Float(recognizedShortcuts.count)
    }
}

/// Keyboard input metrics
public struct KeyboardInputMetrics: Sendable {
    public let totalEvents: Int
    public let successfulEvents: Int
    public let failedEvents: Int
    public let averageProcessingTime: TimeInterval
    public let eventsByType: [String: Int]
    public let shortcutsByAction: [String: Int]
    public let inputBySource: [String: Int]
    public let errorsByType: [String: Int]
    public let averageLatency: TimeInterval
    public let averageKeysPerEvent: Double
    public let averageShortcutsPerEvent: Double
    public let throughputPerSecond: Double
    public let performanceStats: PerformanceStats
    
    public struct PerformanceStats: Sendable {
        public let bestProcessingTime: TimeInterval
        public let worstProcessingTime: TimeInterval
        public let averageCharactersPerSecond: Double
        public let averageWordsPerMinute: Double
        public let averageInputAccuracy: Double
        public let averageAutocorrectionRate: Double
        public let totalShortcutsUsed: Int
        public let averageInputLatency: TimeInterval
        
        public init(
            bestProcessingTime: TimeInterval = 0,
            worstProcessingTime: TimeInterval = 0,
            averageCharactersPerSecond: Double = 0,
            averageWordsPerMinute: Double = 0,
            averageInputAccuracy: Double = 0,
            averageAutocorrectionRate: Double = 0,
            totalShortcutsUsed: Int = 0,
            averageInputLatency: TimeInterval = 0
        ) {
            self.bestProcessingTime = bestProcessingTime
            self.worstProcessingTime = worstProcessingTime
            self.averageCharactersPerSecond = averageCharactersPerSecond
            self.averageWordsPerMinute = averageWordsPerMinute
            self.averageInputAccuracy = averageInputAccuracy
            self.averageAutocorrectionRate = averageAutocorrectionRate
            self.totalShortcutsUsed = totalShortcutsUsed
            self.averageInputLatency = averageInputLatency
        }
    }
    
    public init(
        totalEvents: Int = 0,
        successfulEvents: Int = 0,
        failedEvents: Int = 0,
        averageProcessingTime: TimeInterval = 0,
        eventsByType: [String: Int] = [:],
        shortcutsByAction: [String: Int] = [:],
        inputBySource: [String: Int] = [:],
        errorsByType: [String: Int] = [:],
        averageLatency: TimeInterval = 0,
        averageKeysPerEvent: Double = 0,
        averageShortcutsPerEvent: Double = 0,
        throughputPerSecond: Double = 0,
        performanceStats: PerformanceStats = PerformanceStats()
    ) {
        self.totalEvents = totalEvents
        self.successfulEvents = successfulEvents
        self.failedEvents = failedEvents
        self.averageProcessingTime = averageProcessingTime
        self.eventsByType = eventsByType
        self.shortcutsByAction = shortcutsByAction
        self.inputBySource = inputBySource
        self.errorsByType = errorsByType
        self.averageLatency = averageLatency
        self.averageKeysPerEvent = averageKeysPerEvent
        self.averageShortcutsPerEvent = averageShortcutsPerEvent
        self.throughputPerSecond = averageProcessingTime > 0 ? Double(totalEvents) / averageProcessingTime : 0
        self.performanceStats = performanceStats
    }
    
    public var successRate: Double {
        totalEvents > 0 ? Double(successfulEvents) / Double(totalEvents) : 0
    }
}

// MARK: - Keyboard Input Resource

/// Keyboard input resource management
@available(iOS 13.0, macOS 10.15, *)
public actor KeyboardInputCapabilityResource: AxiomCapabilityResource {
    private let configuration: KeyboardInputCapabilityConfiguration
    private var activeEvents: [UUID: KeyboardInputEvent] = [:]
    private var eventHistory: [KeyboardInputResult] = [:]
    private var resultCache: [String: KeyboardInputResult] = [:]
    private var keyProcessor: KeyProcessor = KeyProcessor()
    private var shortcutRecognizer: ShortcutRecognizer = ShortcutRecognizer()
    private var textProcessor: TextProcessor = TextProcessor()
    private var inputTracker: InputTracker = InputTracker()
    private var metrics: KeyboardInputMetrics = KeyboardInputMetrics()
    private var resultStreamContinuation: AsyncStream<KeyboardInputResult>.Continuation?
    
    // Helper classes for keyboard input processing
    private class KeyProcessor {
        func processKeys(
            _ keys: [KeyboardInputEvent.KeyData.KeyInput],
            configuration: KeyboardInputCapabilityConfiguration
        ) -> [KeyboardInputResult.ProcessedKey] {
            return keys.map { key in
                let normalizedKey = normalizeKey(key.key)
                let character = extractCharacter(from: key)
                let isSpecialKey = determineIfSpecialKey(key)
                let keyFunction = determineKeyFunction(key)
                
                return KeyboardInputResult.ProcessedKey(
                    originalKey: key,
                    normalizedKey: normalizedKey,
                    keyCode: key.keyCode,
                    character: character,
                    isSpecialKey: isSpecialKey,
                    keyFunction: keyFunction,
                    inputMode: configuration.inputMode,
                    layout: configuration.keyboardLayout
                )
            }
        }
        
        private func normalizeKey(_ key: String) -> String {
            return key.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
        
        private func extractCharacter(from key: KeyboardInputEvent.KeyData.KeyInput) -> String? {
            if let scalar = key.unicodeScalar {
                return String(scalar)
            }
            return key.key.count == 1 ? key.key : nil
        }
        
        private func determineIfSpecialKey(_ key: KeyboardInputEvent.KeyData.KeyInput) -> Bool {
            let specialKeys = [
                "Backspace", "Delete", "Enter", "Return", "Tab", "Escape",
                "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight",
                "Home", "End", "PageUp", "PageDown", "Insert",
                "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12"
            ]
            return specialKeys.contains(key.key) || key.key.count > 1
        }
        
        private func determineKeyFunction(_ key: KeyboardInputEvent.KeyData.KeyInput) -> KeyboardInputResult.ProcessedKey.KeyFunction {
            switch key.key.lowercased() {
            case "backspace":
                return .backspace
            case "delete":
                return .delete
            case "enter", "return":
                return .enter
            case "tab":
                return .tab
            case " ", "space":
                return .space
            case "escape":
                return .escape
            case let arrowKey where arrowKey.contains("arrow"):
                return .arrow
            case let functionKey where functionKey.hasPrefix("f") && functionKey.count <= 3:
                return .function
            case let key where ["shift", "command", "control", "option", "alt"].contains(key):
                return .modifier
            default:
                return key.count == 1 ? .character : .system
            }
        }
    }
    
    private class ShortcutRecognizer {
        private let shortcuts: [String: (keys: [String], modifiers: KeyboardInputEvent.KeyData.KeyModifiers, action: String)] = [
            "copy": (["c"], [.command], "copy"),
            "paste": (["v"], [.command], "paste"),
            "cut": (["x"], [.command], "cut"),
            "undo": (["z"], [.command], "undo"),
            "redo": (["z"], [.command, .shift], "redo"),
            "save": (["s"], [.command], "save"),
            "open": (["o"], [.command], "open"),
            "new": (["n"], [.command], "new"),
            "find": (["f"], [.command], "find"),
            "selectAll": (["a"], [.command], "selectAll"),
            "quit": (["q"], [.command], "quit"),
            "close": (["w"], [.command], "close"),
            "minimize": (["m"], [.command], "minimize"),
            "hide": (["h"], [.command], "hide"),
            "print": (["p"], [.command], "print"),
            "refresh": (["r"], [.command], "refresh")
        ]
        
        func recognizeShortcuts(
            from keys: [KeyboardInputEvent.KeyData.KeyInput],
            modifiers: KeyboardInputEvent.KeyData.KeyModifiers
        ) -> [KeyboardInputResult.RecognizedShortcut] {
            var recognizedShortcuts: [KeyboardInputResult.RecognizedShortcut] = []
            
            let keyStrings = keys.map { $0.key.lowercased() }
            
            for (shortcutName, shortcutData) in shortcuts {
                if shortcutData.modifiers == modifiers && keyStrings == shortcutData.keys {
                    let shortcut = KeyboardInputResult.RecognizedShortcut(
                        shortcut: shortcutName,
                        keys: shortcutData.keys,
                        modifiers: shortcutData.modifiers,
                        action: shortcutData.action,
                        context: "global",
                        confidence: 0.95
                    )
                    recognizedShortcuts.append(shortcut)
                }
            }
            
            return recognizedShortcuts
        }
    }
    
    private class TextProcessor {
        func processText(
            _ text: String?,
            configuration: KeyboardInputCapabilityConfiguration
        ) -> KeyboardInputResult.TextProcessingResult {
            var result = KeyboardInputResult.TextProcessingResult(originalText: text)
            
            guard let text = text, !text.isEmpty else { return result }
            
            if configuration.enableAutocorrection {
                result = KeyboardInputResult.TextProcessingResult(
                    originalText: result.originalText,
                    processedText: result.processedText,
                    autocorrectedText: performAutocorrection(text),
                    suggestions: result.suggestions,
                    predictiveText: result.predictiveText,
                    spellCheckResults: result.spellCheckResults,
                    languageDetection: result.languageDetection,
                    inputMethod: result.inputMethod
                )
            }
            
            if configuration.enableSpellChecking {
                let spellCheckResults = performSpellCheck(text)
                result = KeyboardInputResult.TextProcessingResult(
                    originalText: result.originalText,
                    processedText: result.processedText,
                    autocorrectedText: result.autocorrectedText,
                    suggestions: result.suggestions,
                    predictiveText: result.predictiveText,
                    spellCheckResults: spellCheckResults,
                    languageDetection: result.languageDetection,
                    inputMethod: result.inputMethod
                )
            }
            
            if configuration.enablePredictiveText {
                let predictions = generatePredictiveText(text)
                result = KeyboardInputResult.TextProcessingResult(
                    originalText: result.originalText,
                    processedText: result.processedText,
                    autocorrectedText: result.autocorrectedText,
                    suggestions: predictions,
                    predictiveText: predictions,
                    spellCheckResults: result.spellCheckResults,
                    languageDetection: result.languageDetection,
                    inputMethod: result.inputMethod
                )
            }
            
            return result
        }
        
        private func performAutocorrection(_ text: String) -> String {
            let corrections: [String: String] = [
                "teh": "the",
                "adn": "and",
                "recieve": "receive",
                "seperate": "separate",
                "definately": "definitely",
                "occured": "occurred"
            ]
            
            var correctedText = text
            for (typo, correction) in corrections {
                correctedText = correctedText.replacingOccurrences(of: typo, with: correction, options: .caseInsensitive)
            }
            
            return correctedText
        }
        
        private func performSpellCheck(_ text: String) -> [KeyboardInputResult.TextProcessingResult.SpellCheckResult] {
            let words = text.components(separatedBy: .whitespacesAndNewlines)
            var results: [KeyboardInputResult.TextProcessingResult.SpellCheckResult] = []
            
            let misspelledWords = ["misspeled", "wrnog", "incorect"]
            var currentIndex = 0
            
            for word in words {
                if misspelledWords.contains(word.lowercased()) {
                    let range = NSRange(location: currentIndex, length: word.count)
                    let suggestions = getSuggestions(for: word)
                    let result = KeyboardInputResult.TextProcessingResult.SpellCheckResult(
                        range: range,
                        misspelledWord: word,
                        suggestions: suggestions,
                        confidence: 0.9
                    )
                    results.append(result)
                }
                currentIndex += word.count + 1 // +1 for space
            }
            
            return results
        }
        
        private func getSuggestions(for word: String) -> [String] {
            let suggestions: [String: [String]] = [
                "misspeled": ["misspelled", "spelled"],
                "wrnog": ["wrong", "ring"],
                "incorect": ["incorrect", "correct"]
            ]
            
            return suggestions[word.lowercased()] ?? []
        }
        
        private func generatePredictiveText(_ text: String) -> [String] {
            let words = text.components(separatedBy: .whitespacesAndNewlines)
            guard let lastWord = words.last?.lowercased() else { return [] }
            
            let predictions: [String: [String]] = [
                "the": ["quick", "brown", "fox"],
                "hello": ["world", "there", "everyone"],
                "how": ["are", "do", "can"],
                "what": ["is", "are", "time"],
                "when": ["is", "are", "will"],
                "where": ["is", "are", "can"]
            ]
            
            return predictions[lastWord] ?? []
        }
    }
    
    private class InputTracker {
        private var inputHistory: [KeyboardInputEvent.KeyData.KeyInput] = []
        private var sessionStartTime: Date = Date()
        
        func trackInput(_ keys: [KeyboardInputEvent.KeyData.KeyInput]) {
            inputHistory.append(contentsOf: keys)
        }
        
        func calculateMetrics() -> KeyboardInputResult.InputMetrics {
            let totalKeys = inputHistory.count
            let sessionDuration = Date().timeIntervalSince(sessionStartTime)
            
            let charactersPerSecond = sessionDuration > 0 ? Double(totalKeys) / sessionDuration : 0
            let wordsPerMinute = charactersPerSecond * 60 / 5 // Average 5 characters per word
            let accuracy = calculateAccuracy()
            let autocorrectionRate = 0.05 // 5% simplified
            let inputLatency = 0.02 // 20ms average
            let processingLatency = 0.001 // 1ms average
            
            return KeyboardInputResult.InputMetrics(
                totalKeys: totalKeys,
                charactersPerSecond: charactersPerSecond,
                wordsPerMinute: wordsPerMinute,
                accuracy: accuracy,
                autocorrectionRate: autocorrectionRate,
                shortcutsUsed: 0,
                inputLatency: inputLatency,
                processingLatency: processingLatency
            )
        }
        
        private func calculateAccuracy() -> Double {
            // Simplified accuracy calculation
            let backspaceCount = inputHistory.filter { $0.key.lowercased() == "backspace" }.count
            let totalCharacters = inputHistory.filter { $0.key.count == 1 }.count
            
            guard totalCharacters > 0 else { return 1.0 }
            return max(0.0, 1.0 - (Double(backspaceCount) / Double(totalCharacters)))
        }
        
        func reset() {
            inputHistory.removeAll()
            sessionStartTime = Date()
        }
    }
    
    public init(configuration: KeyboardInputCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 100_000_000, // 100MB for keyboard input processing
            cpu: 2.0, // Moderate CPU usage for input processing
            bandwidth: 0,
            storage: 30_000_000 // 30MB for input and result caching
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let eventMemory = activeEvents.count * 5_000_000 // ~5MB per active event
            let cacheMemory = resultCache.count * 25_000 // ~25KB per cached result
            let historyMemory = eventHistory.count * 10_000
            let processingMemory = 20_000_000 // Input processing overhead
            
            return ResourceUsage(
                memory: eventMemory + cacheMemory + historyMemory + processingMemory,
                cpu: activeEvents.isEmpty ? 0.1 : 1.5,
                bandwidth: 0,
                storage: resultCache.count * 12_000
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // Keyboard input is available on iOS 13+
        if #available(iOS 13.0, *) {
            return configuration.enableKeyboardInput
        }
        return false
    }
    
    public func release() async {
        activeEvents.removeAll()
        eventHistory.removeAll()
        resultCache.removeAll()
        inputTracker.reset()
        
        resultStreamContinuation?.finish()
        
        metrics = KeyboardInputMetrics()
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        keyProcessor = KeyProcessor()
        shortcutRecognizer = ShortcutRecognizer()
        textProcessor = TextProcessor()
        inputTracker = InputTracker()
        
        if configuration.enableLogging {
            print("[KeyboardInput] 🚀 Keyboard Input capability initialized")
        }
    }
    
    internal func updateConfiguration(_ configuration: KeyboardInputCapabilityConfiguration) async throws {
        // Update keyboard input configurations
    }
    
    // MARK: - Result Streams
    
    public var resultStream: AsyncStream<KeyboardInputResult> {
        AsyncStream { continuation in
            self.resultStreamContinuation = continuation
        }
    }
    
    // MARK: - Keyboard Input Processing
    
    public func processInput(_ event: KeyboardInputEvent) async throws -> KeyboardInputResult {
        guard configuration.enableKeyboardInput else {
            throw KeyboardInputError.keyboardInputDisabled
        }
        
        let startTime = Date()
        activeEvents[event.id] = event
        
        do {
            // Track input for metrics
            inputTracker.trackInput(event.keyData.keys)
            
            // Process keys
            let processedKeys = keyProcessor.processKeys(event.keyData.keys, configuration: configuration)
            
            // Recognize shortcuts if enabled
            var recognizedShortcuts: [KeyboardInputResult.RecognizedShortcut] = []
            if configuration.enableShortcutRecognition {
                recognizedShortcuts = shortcutRecognizer.recognizeShortcuts(
                    from: event.keyData.keys,
                    modifiers: event.keyData.modifiers
                )
            }
            
            // Process text if enabled
            var textProcessing = KeyboardInputResult.TextProcessingResult()
            if configuration.enableTextInputProcessing {
                textProcessing = textProcessor.processText(event.keyData.text, configuration: configuration)
            }
            
            // Calculate input metrics
            let inputMetrics = inputTracker.calculateMetrics()
            
            let processingTime = Date().timeIntervalSince(startTime)
            let result = KeyboardInputResult(
                eventId: event.id,
                processedKeys: processedKeys,
                recognizedShortcuts: recognizedShortcuts,
                textProcessing: textProcessing,
                inputMetrics: inputMetrics,
                processingTime: processingTime,
                success: true,
                metadata: event.metadata
            )
            
            activeEvents.removeValue(forKey: event.id)
            eventHistory.append(result)
            
            // Cache result if enabled
            if configuration.enableCaching && resultCache.count < configuration.cacheSize {
                let cacheKey = generateCacheKey(for: event)
                resultCache[cacheKey] = result
            }
            
            resultStreamContinuation?.yield(result)
            
            await updateSuccessMetrics(result)
            
            if configuration.enableLogging {
                await logKeyboardEvent(result)
            }
            
            return result
            
        } catch {
            let processingTime = Date().timeIntervalSince(startTime)
            let result = KeyboardInputResult(
                eventId: event.id,
                processedKeys: [],
                recognizedShortcuts: [],
                textProcessing: KeyboardInputResult.TextProcessingResult(),
                inputMetrics: KeyboardInputResult.InputMetrics(
                    totalKeys: 0,
                    charactersPerSecond: 0,
                    wordsPerMinute: 0,
                    accuracy: 0,
                    autocorrectionRate: 0,
                    shortcutsUsed: 0,
                    inputLatency: 0,
                    processingLatency: 0
                ),
                processingTime: processingTime,
                success: false,
                error: error as? KeyboardInputError ?? KeyboardInputError.processingError(error.localizedDescription)
            )
            
            activeEvents.removeValue(forKey: event.id)
            eventHistory.append(result)
            
            resultStreamContinuation?.yield(result)
            
            await updateFailureMetrics(result)
            
            if configuration.enableLogging {
                await logKeyboardEvent(result)
            }
            
            throw error
        }
    }
    
    public func getActiveEvents() async -> [KeyboardInputEvent] {
        return Array(activeEvents.values)
    }
    
    public func getEventHistory(since: Date? = nil) async -> [KeyboardInputResult] {
        if let since = since {
            return eventHistory.filter { $0.timestamp >= since }
        }
        return eventHistory
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> KeyboardInputMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = KeyboardInputMetrics()
        inputTracker.reset()
    }
    
    public func clearCache() async {
        resultCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func generateCacheKey(for event: KeyboardInputEvent) -> String {
        let keyCount = event.keyData.keys.count
        let eventType = event.keyData.eventType.rawValue
        let modifiers = event.keyData.modifiers.rawValue
        let timestamp = Int(event.timestamp.timeIntervalSince1970 * 1000) // Milliseconds
        return "\(keyCount)_\(eventType)_\(modifiers)_\(timestamp)"
    }
    
    private func updateSuccessMetrics(_ result: KeyboardInputResult) async {
        let totalEvents = metrics.totalEvents + 1
        let successfulEvents = metrics.successfulEvents + 1
        
        let newAverageProcessingTime = ((metrics.averageProcessingTime * Double(metrics.totalEvents)) + result.processingTime) / Double(totalEvents)
        
        var eventsByType = metrics.eventsByType
        eventsByType["keyboard", default: 0] += 1
        
        var shortcutsByAction = metrics.shortcutsByAction
        for shortcut in result.recognizedShortcuts {
            shortcutsByAction[shortcut.action, default: 0] += 1
        }
        
        var inputBySource = metrics.inputBySource
        inputBySource["keyboard", default: 0] += 1
        
        let newAverageKeysPerEvent = ((metrics.averageKeysPerEvent * Double(metrics.successfulEvents)) + Double(result.keyCount)) / Double(successfulEvents)
        let newAverageShortcutsPerEvent = ((metrics.averageShortcutsPerEvent * Double(metrics.successfulEvents)) + Double(result.shortcutCount)) / Double(successfulEvents)
        
        // Update performance stats
        var performanceStats = metrics.performanceStats
        let bestTime = metrics.successfulEvents == 0 ? result.processingTime : min(performanceStats.bestProcessingTime, result.processingTime)
        let worstTime = max(performanceStats.worstProcessingTime, result.processingTime)
        let newAverageCPS = ((performanceStats.averageCharactersPerSecond * Double(metrics.successfulEvents)) + result.inputMetrics.charactersPerSecond) / Double(successfulEvents)
        let newAverageWPM = ((performanceStats.averageWordsPerMinute * Double(metrics.successfulEvents)) + result.inputMetrics.wordsPerMinute) / Double(successfulEvents)
        let newAverageAccuracy = ((performanceStats.averageInputAccuracy * Double(metrics.successfulEvents)) + result.inputMetrics.accuracy) / Double(successfulEvents)
        let newAverageAutocorrection = ((performanceStats.averageAutocorrectionRate * Double(metrics.successfulEvents)) + result.inputMetrics.autocorrectionRate) / Double(successfulEvents)
        let totalShortcutsUsed = performanceStats.totalShortcutsUsed + result.inputMetrics.shortcutsUsed
        let newAverageInputLatency = ((performanceStats.averageInputLatency * Double(metrics.successfulEvents)) + result.inputMetrics.inputLatency) / Double(successfulEvents)
        
        performanceStats = KeyboardInputMetrics.PerformanceStats(
            bestProcessingTime: bestTime,
            worstProcessingTime: worstTime,
            averageCharactersPerSecond: newAverageCPS,
            averageWordsPerMinute: newAverageWPM,
            averageInputAccuracy: newAverageAccuracy,
            averageAutocorrectionRate: newAverageAutocorrection,
            totalShortcutsUsed: totalShortcutsUsed,
            averageInputLatency: newAverageInputLatency
        )
        
        metrics = KeyboardInputMetrics(
            totalEvents: totalEvents,
            successfulEvents: successfulEvents,
            failedEvents: metrics.failedEvents,
            averageProcessingTime: newAverageProcessingTime,
            eventsByType: eventsByType,
            shortcutsByAction: shortcutsByAction,
            inputBySource: inputBySource,
            errorsByType: metrics.errorsByType,
            averageLatency: result.inputMetrics.inputLatency,
            averageKeysPerEvent: newAverageKeysPerEvent,
            averageShortcutsPerEvent: newAverageShortcutsPerEvent,
            throughputPerSecond: metrics.throughputPerSecond,
            performanceStats: performanceStats
        )
    }
    
    private func updateFailureMetrics(_ result: KeyboardInputResult) async {
        let totalEvents = metrics.totalEvents + 1
        let failedEvents = metrics.failedEvents + 1
        
        var errorsByType = metrics.errorsByType
        if let error = result.error {
            let errorKey = String(describing: type(of: error))
            errorsByType[errorKey, default: 0] += 1
        }
        
        metrics = KeyboardInputMetrics(
            totalEvents: totalEvents,
            successfulEvents: metrics.successfulEvents,
            failedEvents: failedEvents,
            averageProcessingTime: metrics.averageProcessingTime,
            eventsByType: metrics.eventsByType,
            shortcutsByAction: metrics.shortcutsByAction,
            inputBySource: metrics.inputBySource,
            errorsByType: errorsByType,
            averageLatency: metrics.averageLatency,
            averageKeysPerEvent: metrics.averageKeysPerEvent,
            averageShortcutsPerEvent: metrics.averageShortcutsPerEvent,
            throughputPerSecond: metrics.throughputPerSecond,
            performanceStats: metrics.performanceStats
        )
    }
    
    private func logKeyboardEvent(_ result: KeyboardInputResult) async {
        let statusIcon = result.success ? "✅" : "❌"
        let timeStr = String(format: "%.3f", result.processingTime)
        let keyCount = result.keyCount
        let shortcutCount = result.shortcutCount
        let wpm = String(format: "%.1f", result.inputMetrics.wordsPerMinute)
        let accuracy = String(format: "%.1f", result.inputMetrics.accuracy * 100)
        
        print("[KeyboardInput] \(statusIcon) Input: \(keyCount) keys, \(shortcutCount) shortcuts, \(wpm) WPM, \(accuracy)% accuracy (\(timeStr)s)")
        
        if let error = result.error {
            print("[KeyboardInput] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - Keyboard Input Capability Implementation

/// Keyboard Input capability providing comprehensive keyboard event handling
@available(iOS 13.0, macOS 10.15, *)
public actor KeyboardInputCapability: DomainCapability {
    public typealias ConfigurationType = KeyboardInputCapabilityConfiguration
    public typealias ResourceType = KeyboardInputCapabilityResource
    
    private var _configuration: KeyboardInputCapabilityConfiguration
    private var _resources: KeyboardInputCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(5)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "keyboard-input-capability" }
    
    public var isAvailable: Bool {
        get async { _state == .available }
    }
    
    public var state: AxiomCapabilityState {
        get async { _state }
    }
    
    public var stateStream: AsyncStream<AxiomCapabilityState> {
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                await self?.setStreamContinuation(continuation)
                if let currentState = await self?._state {
                    continuation.yield(currentState)
                }
            }
        }
    }
    
    public var activationTimeout: Duration {
        get async { _activationTimeout }
    }
    
    public var configuration: KeyboardInputCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: KeyboardInputCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: KeyboardInputCapabilityConfiguration = KeyboardInputCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = KeyboardInputCapabilityResource(configuration: self._configuration)
        self._environment = environment
    }
    
    private func setStreamContinuation(_ continuation: AsyncStream<AxiomCapabilityState>.Continuation) {
        self.stateStreamContinuation = continuation
    }
    
    // MARK: - AxiomCapability Protocol
    
    public func activate() async throws {
        await transitionTo(.initializing)
        
        do {
            try await _resources.allocate()
            await transitionTo(.available)
        } catch {
            await transitionTo(.unavailable)
            throw error
        }
    }
    
    public func deactivate() async {
        await transitionTo(.terminating)
        await _resources.release()
        await transitionTo(.unavailable)
        stateStreamContinuation?.finish()
    }
    
    // MARK: - DomainCapability Protocol
    
    public func updateConfiguration(_ configuration: KeyboardInputCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Keyboard Input configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        try await _resources.updateConfiguration(_configuration)
    }
    
    public func handleEnvironmentChange(_ environment: AxiomCapabilityEnvironment) async {
        _environment = environment
        let adjusted = _configuration.adjusted(for: environment)
        try? await updateConfiguration(adjusted)
    }
    
    public func isSupported() async -> Bool {
        // Keyboard input is supported on iOS 13+
        if #available(iOS 13.0, *) {
            return true
        }
        return false
    }
    
    public func requestPermission() async throws {
        // Keyboard input doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Keyboard Input Operations
    
    /// Process keyboard input event
    public func processInput(_ event: KeyboardInputEvent) async throws -> KeyboardInputResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Keyboard Input capability not available")
        }
        
        return try await _resources.processInput(event)
    }
    
    /// Get result stream
    public func getResultStream() async throws -> AsyncStream<KeyboardInputResult> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Keyboard Input capability not available")
        }
        
        return await _resources.resultStream
    }
    
    /// Get active events
    public func getActiveEvents() async throws -> [KeyboardInputEvent] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Keyboard Input capability not available")
        }
        
        return await _resources.getActiveEvents()
    }
    
    /// Get event history
    public func getEventHistory(since: Date? = nil) async throws -> [KeyboardInputResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Keyboard Input capability not available")
        }
        
        return await _resources.getEventHistory(since: since)
    }
    
    /// Get metrics
    public func getMetrics() async throws -> KeyboardInputMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Keyboard Input capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Keyboard Input capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    /// Clear cache
    public func clearCache() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Keyboard Input capability not available")
        }
        
        await _resources.clearCache()
    }
    
    // MARK: - Convenience Methods
    
    /// Create key event from UIKit key input
    public func createKeyEvent(from key: String, keyCode: Int, modifiers: KeyboardInputEvent.KeyData.KeyModifiers = [], eventType: KeyboardInputEvent.KeyData.KeyEventType = .keyDown) -> KeyboardInputEvent {
        let keyInput = KeyboardInputEvent.KeyData.KeyInput(
            key: key,
            keyCode: keyCode,
            stage: eventType == .keyDown ? .down : .up
        )
        
        let keyData = KeyboardInputEvent.KeyData(
            keys: [keyInput],
            eventType: eventType,
            modifiers: modifiers
        )
        
        return KeyboardInputEvent(keyData: keyData)
    }
    
    /// Create text input event
    public func createTextInputEvent(_ text: String, replacement: String? = nil, range: NSRange? = nil) -> KeyboardInputEvent {
        let keyData = KeyboardInputEvent.KeyData(
            keys: [],
            eventType: .textInput,
            text: text,
            textRange: range,
            replacement: replacement
        )
        
        return KeyboardInputEvent(keyData: keyData)
    }
    
    /// Check if keyboard input is active
    public func hasActiveEvents() async throws -> Bool {
        let activeEvents = try await getActiveEvents()
        return !activeEvents.isEmpty
    }
    
    /// Get typing speed
    public func getTypingSpeed() async throws -> (charactersPerSecond: Double, wordsPerMinute: Double) {
        let metrics = try await getMetrics()
        return (
            charactersPerSecond: metrics.performanceStats.averageCharactersPerSecond,
            wordsPerMinute: metrics.performanceStats.averageWordsPerMinute
        )
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Keyboard Input specific errors
public enum KeyboardInputError: Error, LocalizedError {
    case keyboardInputDisabled
    case processingError(String)
    case shortcutRecognitionFailed
    case textProcessingFailed
    case invalidKeyData
    case inputTimeout(UUID)
    case unsupportedInputMode(String)
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .keyboardInputDisabled:
            return "Keyboard input is disabled"
        case .processingError(let reason):
            return "Keyboard processing failed: \(reason)"
        case .shortcutRecognitionFailed:
            return "Shortcut recognition failed"
        case .textProcessingFailed:
            return "Text processing failed"
        case .invalidKeyData:
            return "Invalid key data provided"
        case .inputTimeout(let id):
            return "Input timeout: \(id)"
        case .unsupportedInputMode(let mode):
            return "Unsupported input mode: \(mode)"
        case .configurationError(let reason):
            return "Keyboard input configuration error: \(reason)"
        }
    }
}