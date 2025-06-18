import Foundation
import Intents
import IntentsUI
import AxiomCore
import AxiomCapabilities

// MARK: - Siri Intents Capability Configuration

/// Configuration for Siri Intents capability
public struct SiriIntentsCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableSiriIntents: Bool
    public let enableShortcuts: Bool
    public let enableVoiceShortcuts: Bool
    public let enableSuggestions: Bool
    public let enableParameterRequests: Bool
    public let supportedIntentTypes: Set<String>
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let donationBatchSize: Int
    public let maxDonationsPerHour: Int
    public let enableBackgroundDonation: Bool
    public let contextualSuggestions: Bool
    
    public init(
        enableSiriIntents: Bool = true,
        enableShortcuts: Bool = true,
        enableVoiceShortcuts: Bool = true,
        enableSuggestions: Bool = true,
        enableParameterRequests: Bool = true,
        supportedIntentTypes: Set<String> = [],
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        donationBatchSize: Int = 10,
        maxDonationsPerHour: Int = 100,
        enableBackgroundDonation: Bool = true,
        contextualSuggestions: Bool = true
    ) {
        self.enableSiriIntents = enableSiriIntents
        self.enableShortcuts = enableShortcuts
        self.enableVoiceShortcuts = enableVoiceShortcuts
        self.enableSuggestions = enableSuggestions
        self.enableParameterRequests = enableParameterRequests
        self.supportedIntentTypes = supportedIntentTypes
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.donationBatchSize = donationBatchSize
        self.maxDonationsPerHour = maxDonationsPerHour
        self.enableBackgroundDonation = enableBackgroundDonation
        self.contextualSuggestions = contextualSuggestions
    }
    
    public var isValid: Bool {
        donationBatchSize > 0 && maxDonationsPerHour > 0
    }
    
    public func merged(with other: SiriIntentsCapabilityConfiguration) -> SiriIntentsCapabilityConfiguration {
        SiriIntentsCapabilityConfiguration(
            enableSiriIntents: other.enableSiriIntents,
            enableShortcuts: other.enableShortcuts,
            enableVoiceShortcuts: other.enableVoiceShortcuts,
            enableSuggestions: other.enableSuggestions,
            enableParameterRequests: other.enableParameterRequests,
            supportedIntentTypes: other.supportedIntentTypes,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            donationBatchSize: other.donationBatchSize,
            maxDonationsPerHour: other.maxDonationsPerHour,
            enableBackgroundDonation: other.enableBackgroundDonation,
            contextualSuggestions: other.contextualSuggestions
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> SiriIntentsCapabilityConfiguration {
        var adjustedLogging = enableLogging
        var adjustedBackgroundDonation = enableBackgroundDonation
        var adjustedMaxDonations = maxDonationsPerHour
        
        if environment.isLowPowerMode {
            adjustedBackgroundDonation = false
            adjustedMaxDonations = min(maxDonationsPerHour, 20)
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return SiriIntentsCapabilityConfiguration(
            enableSiriIntents: enableSiriIntents,
            enableShortcuts: enableShortcuts,
            enableVoiceShortcuts: enableVoiceShortcuts,
            enableSuggestions: enableSuggestions,
            enableParameterRequests: enableParameterRequests,
            supportedIntentTypes: supportedIntentTypes,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            donationBatchSize: donationBatchSize,
            maxDonationsPerHour: adjustedMaxDonations,
            enableBackgroundDonation: adjustedBackgroundDonation,
            contextualSuggestions: contextualSuggestions
        )
    }
}

// MARK: - Siri Intent Types

/// Siri intent information
public struct SiriIntent: Sendable, Identifiable, Codable {
    public let id: UUID
    public let intentClass: String
    public let identifier: String?
    public let groupIdentifier: String?
    public let title: String
    public let subtitle: String?
    public let suggestedInvocationPhrase: String?
    public let userInfo: [String: String]
    public let isEligibleForSearch: Bool
    public let isEligibleForPrediction: Bool
    public let isEligibleForWidgets: Bool
    public let creationDate: Date
    public let donationDate: Date?
    public let relevantShortcuts: [RelevantShortcut]
    public let parameters: [IntentParameter]
    
    public struct RelevantShortcut: Sendable, Codable {
        public let shortcutRole: ShortcutRole
        public let relevanceProviders: [RelevanceProvider]
        
        public enum ShortcutRole: String, Sendable, Codable, CaseIterable {
            case action = "action"
            case information = "information"
            case assistance = "assistance"
        }
        
        public struct RelevanceProvider: Sendable, Codable {
            public let type: ProviderType
            public let identifier: String
            public let relevanceScore: Double
            
            public enum ProviderType: String, Sendable, Codable, CaseIterable {
                case location = "location"
                case dateTime = "dateTime"
                case daily = "daily"
                case calendar = "calendar"
            }
            
            public init(type: ProviderType, identifier: String, relevanceScore: Double) {
                self.type = type
                self.identifier = identifier
                self.relevanceScore = max(0.0, min(1.0, relevanceScore))
            }
        }
        
        public init(shortcutRole: ShortcutRole, relevanceProviders: [RelevanceProvider]) {
            self.shortcutRole = shortcutRole
            self.relevanceProviders = relevanceProviders
        }
    }
    
    public struct IntentParameter: Sendable, Codable {
        public let name: String
        public let type: ParameterType
        public let value: String?
        public let isRequired: Bool
        public let displayName: String?
        
        public enum ParameterType: String, Sendable, Codable, CaseIterable {
            case string = "string"
            case number = "number"
            case boolean = "boolean"
            case date = "date"
            case location = "location"
            case person = "person"
            case file = "file"
            case custom = "custom"
        }
        
        public init(name: String, type: ParameterType, value: String? = nil, isRequired: Bool = false, displayName: String? = nil) {
            self.name = name
            self.type = type
            self.value = value
            self.isRequired = isRequired
            self.displayName = displayName
        }
    }
    
    public init(
        intentClass: String,
        identifier: String? = nil,
        groupIdentifier: String? = nil,
        title: String,
        subtitle: String? = nil,
        suggestedInvocationPhrase: String? = nil,
        userInfo: [String: String] = [:],
        isEligibleForSearch: Bool = true,
        isEligibleForPrediction: Bool = true,
        isEligibleForWidgets: Bool = false,
        relevantShortcuts: [RelevantShortcut] = [],
        parameters: [IntentParameter] = []
    ) {
        self.id = UUID()
        self.intentClass = intentClass
        self.identifier = identifier
        self.groupIdentifier = groupIdentifier
        self.title = title
        self.subtitle = subtitle
        self.suggestedInvocationPhrase = suggestedInvocationPhrase
        self.userInfo = userInfo
        self.isEligibleForSearch = isEligibleForSearch
        self.isEligibleForPrediction = isEligibleForPrediction
        self.isEligibleForWidgets = isEligibleForWidgets
        self.creationDate = Date()
        self.donationDate = nil
        self.relevantShortcuts = relevantShortcuts
        self.parameters = parameters
    }
    
    public var age: TimeInterval {
        Date().timeIntervalSince(creationDate)
    }
    
    public var wasDonated: Bool {
        donationDate != nil
    }
}

/// Voice shortcut information
public struct VoiceShortcut: Sendable, Identifiable {
    public let id: UUID
    public let intent: SiriIntent
    public let phrase: String
    public let shortcut: INShortcut?
    public let isEnabled: Bool
    public let creationDate: Date
    public let lastUsed: Date?
    public let usageCount: Int
    
    public init(
        intent: SiriIntent,
        phrase: String,
        shortcut: INShortcut? = nil,
        isEnabled: Bool = true,
        lastUsed: Date? = nil,
        usageCount: Int = 0
    ) {
        self.id = UUID()
        self.intent = intent
        self.phrase = phrase
        self.shortcut = shortcut
        self.isEnabled = isEnabled
        self.creationDate = Date()
        self.lastUsed = lastUsed
        self.usageCount = usageCount
    }
    
    public var isRecentlyUsed: Bool {
        guard let lastUsed = lastUsed else { return false }
        return Date().timeIntervalSince(lastUsed) < 3600 // Within last hour
    }
}

/// Intent execution result
public struct IntentExecutionResult: Sendable {
    public let intent: SiriIntent
    public let success: Bool
    public let response: IntentResponse?
    public let executionTime: TimeInterval
    public let error: SiriIntentsError?
    public let timestamp: Date
    
    public struct IntentResponse: Sendable {
        public let code: ResponseCode
        public let userActivity: [String: String]?
        public let parameters: [String: String]
        
        public enum ResponseCode: String, Sendable, Codable {
            case success = "success"
            case continueInApp = "continueInApp"
            case inProgress = "inProgress"
            case ready = "ready"
            case failure = "failure"
            case failureRequiringAppLaunch = "failureRequiringAppLaunch"
        }
        
        public init(code: ResponseCode, userActivity: [String: String]? = nil, parameters: [String: String] = [:]) {
            self.code = code
            self.userActivity = userActivity
            self.parameters = parameters
        }
    }
    
    public init(
        intent: SiriIntent,
        success: Bool,
        response: IntentResponse? = nil,
        executionTime: TimeInterval,
        error: SiriIntentsError? = nil
    ) {
        self.intent = intent
        self.success = success
        self.response = response
        self.executionTime = executionTime
        self.error = error
        self.timestamp = Date()
    }
}

/// Siri suggestions information
public struct SiriSuggestion: Sendable, Identifiable {
    public let id: UUID
    public let intent: SiriIntent
    public let relevanceScore: Double
    public let suggestionType: SuggestionType
    public let contextualFactors: [ContextualFactor]
    public let timestamp: Date
    public let expirationDate: Date?
    
    public enum SuggestionType: String, Sendable, Codable, CaseIterable {
        case routine = "routine"
        case contextual = "contextual"
        case trending = "trending"
        case prediction = "prediction"
    }
    
    public struct ContextualFactor: Sendable, Codable {
        public let type: FactorType
        public let weight: Double
        public let confidence: Double
        
        public enum FactorType: String, Sendable, Codable, CaseIterable {
            case timeOfDay = "timeOfDay"
            case location = "location"
            case activity = "activity"
            case calendar = "calendar"
            case contacts = "contacts"
            case usage = "usage"
        }
        
        public init(type: FactorType, weight: Double, confidence: Double) {
            self.type = type
            self.weight = max(0.0, min(1.0, weight))
            self.confidence = max(0.0, min(1.0, confidence))
        }
    }
    
    public init(
        intent: SiriIntent,
        relevanceScore: Double,
        suggestionType: SuggestionType,
        contextualFactors: [ContextualFactor] = [],
        expirationDate: Date? = nil
    ) {
        self.id = UUID()
        self.intent = intent
        self.relevanceScore = max(0.0, min(1.0, relevanceScore))
        self.suggestionType = suggestionType
        self.contextualFactors = contextualFactors
        self.timestamp = Date()
        self.expirationDate = expirationDate
    }
    
    public var isExpired: Bool {
        if let expirationDate = expirationDate {
            return Date() > expirationDate
        }
        return false
    }
}

/// Siri Intents metrics
public struct SiriIntentsMetrics: Sendable {
    public let totalIntents: Int
    public let totalDonations: Int
    public let totalExecutions: Int
    public let successfulExecutions: Int
    public let averageExecutionTime: TimeInterval
    public let intentsByType: [String: Int]
    public let voiceShortcuts: Int
    public let suggestionsGenerated: Int
    public let suggestionAcceptanceRate: Double
    public let donationRate: Double
    public let errorsByType: [String: Int]
    
    public init(
        totalIntents: Int = 0,
        totalDonations: Int = 0,
        totalExecutions: Int = 0,
        successfulExecutions: Int = 0,
        averageExecutionTime: TimeInterval = 0,
        intentsByType: [String: Int] = [:],
        voiceShortcuts: Int = 0,
        suggestionsGenerated: Int = 0,
        suggestionAcceptanceRate: Double = 0,
        donationRate: Double = 0,
        errorsByType: [String: Int] = [:]
    ) {
        self.totalIntents = totalIntents
        self.totalDonations = totalDonations
        self.totalExecutions = totalExecutions
        self.successfulExecutions = successfulExecutions
        self.averageExecutionTime = averageExecutionTime
        self.intentsByType = intentsByType
        self.voiceShortcuts = voiceShortcuts
        self.suggestionsGenerated = suggestionsGenerated
        self.suggestionAcceptanceRate = suggestionAcceptanceRate
        self.donationRate = donationRate
        self.errorsByType = errorsByType
    }
    
    public var successRate: Double {
        totalExecutions > 0 ? Double(successfulExecutions) / Double(totalExecutions) : 0
    }
}

// MARK: - Siri Intents Resource

/// Siri Intents resource management
public actor SiriIntentsCapabilityResource: AxiomCapabilityResource {
    private let configuration: SiriIntentsCapabilityConfiguration
    private var registeredIntents: [String: SiriIntent] = [:]
    private var voiceShortcuts: [UUID: VoiceShortcut] = [:]
    private var executionHistory: [IntentExecutionResult] = []
    private var suggestions: [SiriSuggestion] = []
    private var metrics: SiriIntentsMetrics = SiriIntentsMetrics()
    private var intentStreamContinuation: AsyncStream<SiriIntent>.Continuation?
    private var executionStreamContinuation: AsyncStream<IntentExecutionResult>.Continuation?
    private var suggestionStreamContinuation: AsyncStream<SiriSuggestion>.Continuation?
    private var intentHandlers: [String: (SiriIntent) async -> IntentExecutionResult] = [:]
    private var donationQueue: [SiriIntent] = []
    private var donationTimer: Timer?
    private var donationCount: Int = 0
    private var lastDonationReset: Date = Date()
    
    public init(configuration: SiriIntentsCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 10_000_000, // 10MB for intent management
            cpu: 1.5, // Intent processing and Siri integration
            bandwidth: 0,
            storage: 5_000_000 // 5MB for intent history
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let intentMemory = registeredIntents.count * 5_000
            let shortcutMemory = voiceShortcuts.count * 2_000
            let historyMemory = executionHistory.count * 1_000
            let suggestionMemory = suggestions.count * 3_000
            
            return ResourceUsage(
                memory: intentMemory + shortcutMemory + historyMemory + suggestionMemory + 1_000_000,
                cpu: registeredIntents.isEmpty ? 0.1 : 0.5,
                bandwidth: 0,
                storage: executionHistory.count * 500
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // Siri Intents is available on iOS 10+, macOS 10.12+
        return configuration.enableSiriIntents
    }
    
    public func release() async {
        registeredIntents.removeAll()
        voiceShortcuts.removeAll()
        executionHistory.removeAll()
        suggestions.removeAll()
        intentHandlers.removeAll()
        donationQueue.removeAll()
        
        donationTimer?.invalidate()
        donationTimer = nil
        
        intentStreamContinuation?.finish()
        executionStreamContinuation?.finish()
        suggestionStreamContinuation?.finish()
        
        metrics = SiriIntentsMetrics()
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Setup donation timer
        if configuration.enableBackgroundDonation {
            await setupDonationTimer()
        }
        
        // Initialize suggestion engine
        if configuration.enableSuggestions {
            await initializeSuggestionEngine()
        }
    }
    
    internal func updateConfiguration(_ configuration: SiriIntentsCapabilityConfiguration) async throws {
        // Configuration updates for Siri Intents
    }
    
    // MARK: - Intent Streams
    
    public var intentStream: AsyncStream<SiriIntent> {
        AsyncStream { continuation in
            self.intentStreamContinuation = continuation
        }
    }
    
    public var executionStream: AsyncStream<IntentExecutionResult> {
        AsyncStream { continuation in
            self.executionStreamContinuation = continuation
        }
    }
    
    public var suggestionStream: AsyncStream<SiriSuggestion> {
        AsyncStream { continuation in
            self.suggestionStreamContinuation = continuation
        }
    }
    
    // MARK: - Intent Management
    
    public func registerIntent(_ intent: SiriIntent) async throws {
        guard configuration.supportedIntentTypes.isEmpty || 
              configuration.supportedIntentTypes.contains(intent.intentClass) else {
            throw SiriIntentsError.unsupportedIntentType(intent.intentClass)
        }
        
        let intentKey = intent.identifier ?? intent.id.uuidString
        registeredIntents[intentKey] = intent
        
        intentStreamContinuation?.yield(intent)
        
        await updateIntentMetrics(intent)
        
        if configuration.enableLogging {
            await logIntent(intent, action: "Registered")
        }
    }
    
    public func unregisterIntent(_ intentIdentifier: String) async {
        registeredIntents.removeValue(forKey: intentIdentifier)
        
        if configuration.enableLogging {
            print("[SiriIntents] 🗑️ Unregistered intent: \(intentIdentifier)")
        }
    }
    
    public func getRegisteredIntents() async -> [SiriIntent] {
        return Array(registeredIntents.values)
    }
    
    public func getIntent(by identifier: String) async -> SiriIntent? {
        return registeredIntents[identifier]
    }
    
    // MARK: - Intent Donation
    
    public func donateIntent(_ intent: SiriIntent) async throws {
        guard configuration.enableSiriIntents else {
            throw SiriIntentsError.siriIntentsDisabled
        }
        
        // Check donation rate limits
        await checkDonationLimits()
        
        if configuration.enableBackgroundDonation {
            donationQueue.append(intent)
        } else {
            await performDonation(intent)
        }
        
        if configuration.enableLogging {
            await logIntent(intent, action: "Donated")
        }
    }
    
    public func batchDonateIntents(_ intents: [SiriIntent]) async throws {
        for intent in intents {
            try await donateIntent(intent)
        }
    }
    
    // MARK: - Intent Execution
    
    public func registerIntentHandler(for intentClass: String, handler: @escaping (SiriIntent) async -> IntentExecutionResult) async {
        intentHandlers[intentClass] = handler
    }
    
    public func unregisterIntentHandler(for intentClass: String) async {
        intentHandlers.removeValue(forKey: intentClass)
    }
    
    public func executeIntent(_ intent: SiriIntent) async -> IntentExecutionResult {
        let startTime = Date()
        
        guard let handler = intentHandlers[intent.intentClass] else {
            let error = SiriIntentsError.noHandlerRegistered(intent.intentClass)
            let result = IntentExecutionResult(
                intent: intent,
                success: false,
                executionTime: Date().timeIntervalSince(startTime),
                error: error
            )
            
            await updateExecutionMetrics(result)
            return result
        }
        
        let result = await handler(intent)
        executionHistory.append(result)
        await trimExecutionHistory()
        
        executionStreamContinuation?.yield(result)
        
        await updateExecutionMetrics(result)
        
        if configuration.enableLogging {
            await logExecution(result)
        }
        
        return result
    }
    
    public func getExecutionHistory(since: Date? = nil) async -> [IntentExecutionResult] {
        if let since = since {
            return executionHistory.filter { $0.timestamp >= since }
        }
        return executionHistory
    }
    
    // MARK: - Voice Shortcuts
    
    public func createVoiceShortcut(for intent: SiriIntent, phrase: String) async throws -> VoiceShortcut {
        guard configuration.enableVoiceShortcuts else {
            throw SiriIntentsError.voiceShortcutsDisabled
        }
        
        let voiceShortcut = VoiceShortcut(
            intent: intent,
            phrase: phrase
        )
        
        voiceShortcuts[voiceShortcut.id] = voiceShortcut
        
        await updateVoiceShortcutMetrics()
        
        if configuration.enableLogging {
            print("[SiriIntents] 🗣️ Created voice shortcut: \"\(phrase)\" for \(intent.intentClass)")
        }
        
        return voiceShortcut
    }
    
    public func deleteVoiceShortcut(_ shortcutId: UUID) async {
        voiceShortcuts.removeValue(forKey: shortcutId)
        
        await updateVoiceShortcutMetrics()
        
        if configuration.enableLogging {
            print("[SiriIntents] 🗑️ Deleted voice shortcut: \(shortcutId)")
        }
    }
    
    public func getVoiceShortcuts() async -> [VoiceShortcut] {
        return Array(voiceShortcuts.values)
    }
    
    // MARK: - Suggestions
    
    public func generateSuggestions() async -> [SiriSuggestion] {
        guard configuration.enableSuggestions else { return [] }
        
        var newSuggestions: [SiriSuggestion] = []
        
        // Generate suggestions based on usage patterns
        for intent in registeredIntents.values {
            if intent.isEligibleForPrediction {
                let suggestion = await createSuggestionForIntent(intent)
                newSuggestions.append(suggestion)
            }
        }
        
        // Sort by relevance score
        newSuggestions.sort { $0.relevanceScore > $1.relevanceScore }
        
        // Take top suggestions
        let topSuggestions = Array(newSuggestions.prefix(10))
        
        // Add to suggestions list
        suggestions.append(contentsOf: topSuggestions)
        await trimSuggestions()
        
        // Emit suggestions
        for suggestion in topSuggestions {
            suggestionStreamContinuation?.yield(suggestion)
        }
        
        await updateSuggestionMetrics(topSuggestions)
        
        if configuration.enableLogging {
            print("[SiriIntents] 💡 Generated \(topSuggestions.count) suggestions")
        }
        
        return topSuggestions
    }
    
    public func getSuggestions(limit: Int = 10) async -> [SiriSuggestion] {
        // Remove expired suggestions
        suggestions.removeAll { $0.isExpired }
        
        return Array(suggestions.prefix(limit))
    }
    
    public func clearSuggestions() async {
        suggestions.removeAll()
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> SiriIntentsMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = SiriIntentsMetrics()
    }
    
    // MARK: - Private Methods
    
    private func setupDonationTimer() async {
        donationTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.processDonationQueue()
            }
        }
    }
    
    private func initializeSuggestionEngine() async {
        // Initialize suggestion generation
        if configuration.contextualSuggestions {
            await generateSuggestions()
        }
    }
    
    private func checkDonationLimits() async {
        let now = Date()
        
        // Reset counter if an hour has passed
        if now.timeIntervalSince(lastDonationReset) >= 3600 {
            donationCount = 0
            lastDonationReset = now
        }
        
        // Check if we've exceeded the hourly limit
        if donationCount >= configuration.maxDonationsPerHour {
            return // Skip donation due to rate limit
        }
    }
    
    private func performDonation(_ intent: SiriIntent) async {
        // In a real implementation, this would use INInteraction.donate()
        // For now, we'll simulate the donation
        
        donationCount += 1
        
        var updatedIntent = intent
        updatedIntent = SiriIntent(
            intentClass: intent.intentClass,
            identifier: intent.identifier,
            groupIdentifier: intent.groupIdentifier,
            title: intent.title,
            subtitle: intent.subtitle,
            suggestedInvocationPhrase: intent.suggestedInvocationPhrase,
            userInfo: intent.userInfo,
            isEligibleForSearch: intent.isEligibleForSearch,
            isEligibleForPrediction: intent.isEligibleForPrediction,
            isEligibleForWidgets: intent.isEligibleForWidgets,
            relevantShortcuts: intent.relevantShortcuts,
            parameters: intent.parameters
        )
        
        await updateDonationMetrics()
    }
    
    private func processDonationQueue() async {
        let batchSize = min(configuration.donationBatchSize, donationQueue.count)
        guard batchSize > 0 else { return }
        
        let batch = Array(donationQueue.prefix(batchSize))
        donationQueue.removeFirst(batchSize)
        
        for intent in batch {
            await performDonation(intent)
        }
        
        if configuration.enableLogging && !batch.isEmpty {
            print("[SiriIntents] 📦 Processed donation batch: \(batch.count) intents")
        }
    }
    
    private func createSuggestionForIntent(_ intent: SiriIntent) async -> SiriSuggestion {
        // Calculate relevance score based on various factors
        var relevanceScore = 0.5 // Base score
        
        // Time-based relevance
        let hourOfDay = Calendar.current.component(.hour, from: Date())
        if hourOfDay >= 9 && hourOfDay <= 17 {
            relevanceScore += 0.2 // Work hours boost
        }
        
        // Usage-based relevance
        let recentExecutions = executionHistory.filter { 
            $0.intent.intentClass == intent.intentClass &&
            Date().timeIntervalSince($0.timestamp) < 86400 // Last 24 hours
        }
        
        if !recentExecutions.isEmpty {
            relevanceScore += 0.3
        }
        
        // Intent-specific boost
        if intent.isEligibleForPrediction {
            relevanceScore += 0.1
        }
        
        let contextualFactors = [
            SiriSuggestion.ContextualFactor(type: .timeOfDay, weight: 0.3, confidence: 0.8),
            SiriSuggestion.ContextualFactor(type: .usage, weight: 0.4, confidence: 0.9)
        ]
        
        return SiriSuggestion(
            intent: intent,
            relevanceScore: min(1.0, relevanceScore),
            suggestionType: .contextual,
            contextualFactors: contextualFactors,
            expirationDate: Date().addingTimeInterval(3600) // 1 hour
        )
    }
    
    private func updateIntentMetrics(_ intent: SiriIntent) async {
        let totalIntents = metrics.totalIntents + 1
        
        var intentsByType = metrics.intentsByType
        intentsByType[intent.intentClass, default: 0] += 1
        
        metrics = SiriIntentsMetrics(
            totalIntents: totalIntents,
            totalDonations: metrics.totalDonations,
            totalExecutions: metrics.totalExecutions,
            successfulExecutions: metrics.successfulExecutions,
            averageExecutionTime: metrics.averageExecutionTime,
            intentsByType: intentsByType,
            voiceShortcuts: metrics.voiceShortcuts,
            suggestionsGenerated: metrics.suggestionsGenerated,
            suggestionAcceptanceRate: metrics.suggestionAcceptanceRate,
            donationRate: metrics.donationRate,
            errorsByType: metrics.errorsByType
        )
    }
    
    private func updateDonationMetrics() async {
        metrics = SiriIntentsMetrics(
            totalIntents: metrics.totalIntents,
            totalDonations: metrics.totalDonations + 1,
            totalExecutions: metrics.totalExecutions,
            successfulExecutions: metrics.successfulExecutions,
            averageExecutionTime: metrics.averageExecutionTime,
            intentsByType: metrics.intentsByType,
            voiceShortcuts: metrics.voiceShortcuts,
            suggestionsGenerated: metrics.suggestionsGenerated,
            suggestionAcceptanceRate: metrics.suggestionAcceptanceRate,
            donationRate: metrics.totalIntents > 0 ? Double(metrics.totalDonations + 1) / Double(metrics.totalIntents) : 0,
            errorsByType: metrics.errorsByType
        )
    }
    
    private func updateExecutionMetrics(_ result: IntentExecutionResult) async {
        let totalExecutions = metrics.totalExecutions + 1
        let successfulExecutions = metrics.successfulExecutions + (result.success ? 1 : 0)
        
        let newAverageExecutionTime = ((metrics.averageExecutionTime * Double(metrics.totalExecutions)) + result.executionTime) / Double(totalExecutions)
        
        var errorsByType = metrics.errorsByType
        if let error = result.error {
            let errorKey = String(describing: type(of: error))
            errorsByType[errorKey, default: 0] += 1
        }
        
        metrics = SiriIntentsMetrics(
            totalIntents: metrics.totalIntents,
            totalDonations: metrics.totalDonations,
            totalExecutions: totalExecutions,
            successfulExecutions: successfulExecutions,
            averageExecutionTime: newAverageExecutionTime,
            intentsByType: metrics.intentsByType,
            voiceShortcuts: metrics.voiceShortcuts,
            suggestionsGenerated: metrics.suggestionsGenerated,
            suggestionAcceptanceRate: metrics.suggestionAcceptanceRate,
            donationRate: metrics.donationRate,
            errorsByType: errorsByType
        )
    }
    
    private func updateVoiceShortcutMetrics() async {
        metrics = SiriIntentsMetrics(
            totalIntents: metrics.totalIntents,
            totalDonations: metrics.totalDonations,
            totalExecutions: metrics.totalExecutions,
            successfulExecutions: metrics.successfulExecutions,
            averageExecutionTime: metrics.averageExecutionTime,
            intentsByType: metrics.intentsByType,
            voiceShortcuts: voiceShortcuts.count,
            suggestionsGenerated: metrics.suggestionsGenerated,
            suggestionAcceptanceRate: metrics.suggestionAcceptanceRate,
            donationRate: metrics.donationRate,
            errorsByType: metrics.errorsByType
        )
    }
    
    private func updateSuggestionMetrics(_ suggestions: [SiriSuggestion]) async {
        metrics = SiriIntentsMetrics(
            totalIntents: metrics.totalIntents,
            totalDonations: metrics.totalDonations,
            totalExecutions: metrics.totalExecutions,
            successfulExecutions: metrics.successfulExecutions,
            averageExecutionTime: metrics.averageExecutionTime,
            intentsByType: metrics.intentsByType,
            voiceShortcuts: metrics.voiceShortcuts,
            suggestionsGenerated: metrics.suggestionsGenerated + suggestions.count,
            suggestionAcceptanceRate: metrics.suggestionAcceptanceRate,
            donationRate: metrics.donationRate,
            errorsByType: metrics.errorsByType
        )
    }
    
    private func trimExecutionHistory() async {
        if executionHistory.count > 1000 {
            executionHistory = Array(executionHistory.suffix(1000))
        }
        
        // Remove entries older than 30 days
        let monthAgo = Date().addingTimeInterval(-2_592_000)
        executionHistory.removeAll { $0.timestamp < monthAgo }
    }
    
    private func trimSuggestions() async {
        // Remove expired suggestions
        suggestions.removeAll { $0.isExpired }
        
        // Keep only most recent 100 suggestions
        if suggestions.count > 100 {
            suggestions = Array(suggestions.suffix(100))
        }
    }
    
    private func logIntent(_ intent: SiriIntent, action: String) async {
        let eligibilityIcons = [
            intent.isEligibleForSearch ? "🔍" : "",
            intent.isEligibleForPrediction ? "🔮" : "",
            intent.isEligibleForWidgets ? "📱" : ""
        ].filter { !$0.isEmpty }.joined(separator: " ")
        
        print("[SiriIntents] 🎙️ \(action): \(intent.intentClass) - \(intent.title) \(eligibilityIcons)")
    }
    
    private func logExecution(_ result: IntentExecutionResult) async {
        let statusIcon = result.success ? "✅" : "❌"
        let timeStr = String(format: "%.3f", result.executionTime)
        
        print("[SiriIntents] \(statusIcon) Executed: \(result.intent.intentClass) (\(timeStr)s)")
        
        if let error = result.error {
            print("[SiriIntents] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - Siri Intents Capability Implementation

/// Siri Intents capability providing comprehensive Siri integration and shortcuts support
public actor SiriIntentsCapability: DomainCapability {
    public typealias ConfigurationType = SiriIntentsCapabilityConfiguration
    public typealias ResourceType = SiriIntentsCapabilityResource
    
    private var _configuration: SiriIntentsCapabilityConfiguration
    private var _resources: SiriIntentsCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(5)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "siri-intents-capability" }
    
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
    
    public var configuration: SiriIntentsCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: SiriIntentsCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: SiriIntentsCapabilityConfiguration = SiriIntentsCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = SiriIntentsCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: SiriIntentsCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Siri Intents configuration")
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
        // Siri Intents is supported on iOS 10+, macOS 10.12+
        return true
    }
    
    public func requestPermission() async throws {
        // Siri Intents doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Intent Management Operations
    
    /// Register an intent with Siri
    public func registerIntent(_ intent: SiriIntent) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Siri Intents capability not available")
        }
        
        try await _resources.registerIntent(intent)
    }
    
    /// Unregister an intent
    public func unregisterIntent(_ intentIdentifier: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Siri Intents capability not available")
        }
        
        await _resources.unregisterIntent(intentIdentifier)
    }
    
    /// Get intent stream
    public func getIntentStream() async throws -> AsyncStream<SiriIntent> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Siri Intents capability not available")
        }
        
        return await _resources.intentStream
    }
    
    /// Get registered intents
    public func getRegisteredIntents() async throws -> [SiriIntent] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Siri Intents capability not available")
        }
        
        return await _resources.getRegisteredIntents()
    }
    
    /// Get specific intent
    public func getIntent(by identifier: String) async throws -> SiriIntent? {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Siri Intents capability not available")
        }
        
        return await _resources.getIntent(by: identifier)
    }
    
    // MARK: - Intent Donation Operations
    
    /// Donate an intent to Siri
    public func donateIntent(_ intent: SiriIntent) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Siri Intents capability not available")
        }
        
        try await _resources.donateIntent(intent)
    }
    
    /// Batch donate multiple intents
    public func batchDonateIntents(_ intents: [SiriIntent]) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Siri Intents capability not available")
        }
        
        try await _resources.batchDonateIntents(intents)
    }
    
    // MARK: - Intent Execution Operations
    
    /// Register intent handler
    public func registerIntentHandler(for intentClass: String, handler: @escaping (SiriIntent) async -> IntentExecutionResult) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Siri Intents capability not available")
        }
        
        await _resources.registerIntentHandler(for: intentClass, handler: handler)
    }
    
    /// Unregister intent handler
    public func unregisterIntentHandler(for intentClass: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Siri Intents capability not available")
        }
        
        await _resources.unregisterIntentHandler(for: intentClass)
    }
    
    /// Execute an intent
    public func executeIntent(_ intent: SiriIntent) async throws -> IntentExecutionResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Siri Intents capability not available")
        }
        
        return await _resources.executeIntent(intent)
    }
    
    /// Get execution stream
    public func getExecutionStream() async throws -> AsyncStream<IntentExecutionResult> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Siri Intents capability not available")
        }
        
        return await _resources.executionStream
    }
    
    /// Get execution history
    public func getExecutionHistory(since: Date? = nil) async throws -> [IntentExecutionResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Siri Intents capability not available")
        }
        
        return await _resources.getExecutionHistory(since: since)
    }
    
    // MARK: - Voice Shortcuts Operations
    
    /// Create voice shortcut
    public func createVoiceShortcut(for intent: SiriIntent, phrase: String) async throws -> VoiceShortcut {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Siri Intents capability not available")
        }
        
        return try await _resources.createVoiceShortcut(for: intent, phrase: phrase)
    }
    
    /// Delete voice shortcut
    public func deleteVoiceShortcut(_ shortcutId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Siri Intents capability not available")
        }
        
        await _resources.deleteVoiceShortcut(shortcutId)
    }
    
    /// Get voice shortcuts
    public func getVoiceShortcuts() async throws -> [VoiceShortcut] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Siri Intents capability not available")
        }
        
        return await _resources.getVoiceShortcuts()
    }
    
    // MARK: - Suggestions Operations
    
    /// Generate suggestions
    public func generateSuggestions() async throws -> [SiriSuggestion] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Siri Intents capability not available")
        }
        
        return await _resources.generateSuggestions()
    }
    
    /// Get suggestion stream
    public func getSuggestionStream() async throws -> AsyncStream<SiriSuggestion> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Siri Intents capability not available")
        }
        
        return await _resources.suggestionStream
    }
    
    /// Get suggestions
    public func getSuggestions(limit: Int = 10) async throws -> [SiriSuggestion] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Siri Intents capability not available")
        }
        
        return await _resources.getSuggestions(limit: limit)
    }
    
    /// Clear suggestions
    public func clearSuggestions() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Siri Intents capability not available")
        }
        
        await _resources.clearSuggestions()
    }
    
    /// Get Siri Intents metrics
    public func getMetrics() async throws -> SiriIntentsMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Siri Intents capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Siri Intents capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    // MARK: - Convenience Methods
    
    /// Check if Siri Intents is active
    public func isIntentsActive() async throws -> Bool {
        let intents = try await getRegisteredIntents()
        return !intents.isEmpty
    }
    
    /// Get total registered intents count
    public func getRegisteredIntentsCount() async throws -> Int {
        let intents = try await getRegisteredIntents()
        return intents.count
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Siri Intents specific errors
public enum SiriIntentsError: Error, LocalizedError {
    case siriIntentsDisabled
    case voiceShortcutsDisabled
    case unsupportedIntentType(String)
    case noHandlerRegistered(String)
    case intentExecutionFailed(String)
    case donationFailed(String)
    case rateLimitExceeded
    case invalidIntent(String)
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .siriIntentsDisabled:
            return "Siri Intents is disabled"
        case .voiceShortcutsDisabled:
            return "Voice shortcuts are disabled"
        case .unsupportedIntentType(let type):
            return "Unsupported intent type: \(type)"
        case .noHandlerRegistered(let intentClass):
            return "No handler registered for intent: \(intentClass)"
        case .intentExecutionFailed(let reason):
            return "Intent execution failed: \(reason)"
        case .donationFailed(let reason):
            return "Intent donation failed: \(reason)"
        case .rateLimitExceeded:
            return "Intent donation rate limit exceeded"
        case .invalidIntent(let reason):
            return "Invalid intent: \(reason)"
        case .configurationError(let reason):
            return "Siri Intents configuration error: \(reason)"
        }
    }
}