import Foundation
import LocalAuthentication
import Security
import AxiomCore
import AxiomCapabilities

// MARK: - Biometric Capability Configuration

/// Configuration for Biometric capability
public struct BiometricCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableTouchID: Bool
    public let enableFaceID: Bool
    public let enableOpticID: Bool
    public let enablePasscodeAuthentication: Bool
    public let enableWatchAuthentication: Bool
    public let requireBiometricOnly: Bool
    public let authenticationPolicy: AuthenticationPolicy
    public let fallbackTitle: String?
    public let cancelTitle: String?
    public let reasonPrompt: String
    public let invalidationTimeout: TimeInterval
    public let maxAuthenticationAttempts: Int
    public let lockoutDuration: TimeInterval
    public let enableAuthenticationHistory: Bool
    public let maxHistoryCount: Int
    public let enableSecurityValidation: Bool
    public let requireRecentAuthentication: Bool
    public let recentAuthenticationThreshold: TimeInterval
    public let enableBiometricChangeDetection: Bool
    public let invalidateOnBiometricChange: Bool
    public let enableApplicationPasswordSupport: Bool
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let securityLevel: SecurityLevel
    public let authenticationPromptStyle: PromptStyle
    
    public enum AuthenticationPolicy: String, Codable, CaseIterable, Sendable {
        case deviceOwnerAuthenticationWithBiometrics = "deviceOwnerAuthenticationWithBiometrics"
        case deviceOwnerAuthentication = "deviceOwnerAuthentication"
        case biometryAny = "biometryAny"
        case biometryCurrentSet = "biometryCurrentSet"
    }
    
    public enum SecurityLevel: String, Codable, CaseIterable, Sendable {
        case standard = "standard"
        case high = "high"
        case maximum = "maximum"
    }
    
    public enum PromptStyle: String, Codable, CaseIterable, Sendable {
        case `default` = "default"
        case compact = "compact"
        case detailed = "detailed"
    }
    
    public init(
        enableTouchID: Bool = true,
        enableFaceID: Bool = true,
        enableOpticID: Bool = true,
        enablePasscodeAuthentication: Bool = true,
        enableWatchAuthentication: Bool = false,
        requireBiometricOnly: Bool = false,
        authenticationPolicy: AuthenticationPolicy = .deviceOwnerAuthenticationWithBiometrics,
        fallbackTitle: String? = nil,
        cancelTitle: String? = nil,
        reasonPrompt: String = "Please authenticate to continue",
        invalidationTimeout: TimeInterval = 300.0, // 5 minutes
        maxAuthenticationAttempts: Int = 3,
        lockoutDuration: TimeInterval = 300.0, // 5 minutes
        enableAuthenticationHistory: Bool = true,
        maxHistoryCount: Int = 100,
        enableSecurityValidation: Bool = true,
        requireRecentAuthentication: Bool = false,
        recentAuthenticationThreshold: TimeInterval = 300.0, // 5 minutes
        enableBiometricChangeDetection: Bool = true,
        invalidateOnBiometricChange: Bool = true,
        enableApplicationPasswordSupport: Bool = false,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        securityLevel: SecurityLevel = .standard,
        authenticationPromptStyle: PromptStyle = .default
    ) {
        self.enableTouchID = enableTouchID
        self.enableFaceID = enableFaceID
        self.enableOpticID = enableOpticID
        self.enablePasscodeAuthentication = enablePasscodeAuthentication
        self.enableWatchAuthentication = enableWatchAuthentication
        self.requireBiometricOnly = requireBiometricOnly
        self.authenticationPolicy = authenticationPolicy
        self.fallbackTitle = fallbackTitle
        self.cancelTitle = cancelTitle
        self.reasonPrompt = reasonPrompt
        self.invalidationTimeout = invalidationTimeout
        self.maxAuthenticationAttempts = maxAuthenticationAttempts
        self.lockoutDuration = lockoutDuration
        self.enableAuthenticationHistory = enableAuthenticationHistory
        self.maxHistoryCount = maxHistoryCount
        self.enableSecurityValidation = enableSecurityValidation
        self.requireRecentAuthentication = requireRecentAuthentication
        self.recentAuthenticationThreshold = recentAuthenticationThreshold
        self.enableBiometricChangeDetection = enableBiometricChangeDetection
        self.invalidateOnBiometricChange = invalidateOnBiometricChange
        self.enableApplicationPasswordSupport = enableApplicationPasswordSupport
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.securityLevel = securityLevel
        self.authenticationPromptStyle = authenticationPromptStyle
    }
    
    public var isValid: Bool {
        !reasonPrompt.isEmpty &&
        invalidationTimeout > 0 &&
        maxAuthenticationAttempts > 0 &&
        lockoutDuration > 0 &&
        maxHistoryCount > 0 &&
        recentAuthenticationThreshold > 0
    }
    
    public func merged(with other: BiometricCapabilityConfiguration) -> BiometricCapabilityConfiguration {
        BiometricCapabilityConfiguration(
            enableTouchID: other.enableTouchID,
            enableFaceID: other.enableFaceID,
            enableOpticID: other.enableOpticID,
            enablePasscodeAuthentication: other.enablePasscodeAuthentication,
            enableWatchAuthentication: other.enableWatchAuthentication,
            requireBiometricOnly: other.requireBiometricOnly,
            authenticationPolicy: other.authenticationPolicy,
            fallbackTitle: other.fallbackTitle ?? fallbackTitle,
            cancelTitle: other.cancelTitle ?? cancelTitle,
            reasonPrompt: other.reasonPrompt,
            invalidationTimeout: other.invalidationTimeout,
            maxAuthenticationAttempts: other.maxAuthenticationAttempts,
            lockoutDuration: other.lockoutDuration,
            enableAuthenticationHistory: other.enableAuthenticationHistory,
            maxHistoryCount: other.maxHistoryCount,
            enableSecurityValidation: other.enableSecurityValidation,
            requireRecentAuthentication: other.requireRecentAuthentication,
            recentAuthenticationThreshold: other.recentAuthenticationThreshold,
            enableBiometricChangeDetection: other.enableBiometricChangeDetection,
            invalidateOnBiometricChange: other.invalidateOnBiometricChange,
            enableApplicationPasswordSupport: other.enableApplicationPasswordSupport,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            securityLevel: other.securityLevel,
            authenticationPromptStyle: other.authenticationPromptStyle
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> BiometricCapabilityConfiguration {
        var adjustedLogging = enableLogging
        var adjustedSecurity = securityLevel
        var adjustedTimeout = invalidationTimeout
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        if environment.isLowPowerMode {
            adjustedTimeout = min(invalidationTimeout, 120.0) // 2 minutes max
        }
        
        return BiometricCapabilityConfiguration(
            enableTouchID: enableTouchID,
            enableFaceID: enableFaceID,
            enableOpticID: enableOpticID,
            enablePasscodeAuthentication: enablePasscodeAuthentication,
            enableWatchAuthentication: enableWatchAuthentication,
            requireBiometricOnly: requireBiometricOnly,
            authenticationPolicy: authenticationPolicy,
            fallbackTitle: fallbackTitle,
            cancelTitle: cancelTitle,
            reasonPrompt: reasonPrompt,
            invalidationTimeout: adjustedTimeout,
            maxAuthenticationAttempts: maxAuthenticationAttempts,
            lockoutDuration: lockoutDuration,
            enableAuthenticationHistory: enableAuthenticationHistory,
            maxHistoryCount: maxHistoryCount,
            enableSecurityValidation: enableSecurityValidation,
            requireRecentAuthentication: requireRecentAuthentication,
            recentAuthenticationThreshold: recentAuthenticationThreshold,
            enableBiometricChangeDetection: enableBiometricChangeDetection,
            invalidateOnBiometricChange: invalidateOnBiometricChange,
            enableApplicationPasswordSupport: enableApplicationPasswordSupport,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            securityLevel: adjustedSecurity,
            authenticationPromptStyle: authenticationPromptStyle
        )
    }
}

// MARK: - Biometric Types

/// Biometric authentication type
public enum BiometricType: String, Codable, CaseIterable, Sendable {
    case none = "none"
    case touchID = "touchID"
    case faceID = "faceID"
    case opticID = "opticID"
}

/// Biometric authentication status
public enum BiometricAuthenticationStatus: String, Codable, CaseIterable, Sendable {
    case notAvailable = "notAvailable"
    case notEnrolled = "notEnrolled"
    case available = "available"
    case lockedOut = "lockedOut"
    case biometryNotSet = "biometryNotSet"
}

/// Authentication result
public struct AuthenticationResult: Sendable {
    public let success: Bool
    public let biometricType: BiometricType
    public let authenticationMethod: AuthenticationMethod
    public let timestamp: Date
    public let duration: TimeInterval
    public let error: AuthenticationError?
    public let context: AuthenticationContext?
    
    public enum AuthenticationMethod: String, Codable, CaseIterable, Sendable {
        case biometric = "biometric"
        case passcode = "passcode"
        case applicationPassword = "applicationPassword"
        case watch = "watch"
    }
    
    public init(
        success: Bool,
        biometricType: BiometricType,
        authenticationMethod: AuthenticationMethod,
        timestamp: Date = Date(),
        duration: TimeInterval,
        error: AuthenticationError? = nil,
        context: AuthenticationContext? = nil
    ) {
        self.success = success
        self.biometricType = biometricType
        self.authenticationMethod = authenticationMethod
        self.timestamp = timestamp
        self.duration = duration
        self.error = error
        self.context = context
    }
}

/// Authentication context for managing authentication sessions
public struct AuthenticationContext: Sendable {
    public let sessionId: String
    public let createdAt: Date
    public let expiresAt: Date
    public let biometricType: BiometricType
    public let policy: BiometricCapabilityConfiguration.AuthenticationPolicy
    public let isValid: Bool
    
    public init(
        sessionId: String = UUID().uuidString,
        createdAt: Date = Date(),
        validityDuration: TimeInterval = 300.0,
        biometricType: BiometricType,
        policy: BiometricCapabilityConfiguration.AuthenticationPolicy
    ) {
        self.sessionId = sessionId
        self.createdAt = createdAt
        self.expiresAt = createdAt.addingTimeInterval(validityDuration)
        self.biometricType = biometricType
        self.policy = policy
        self.isValid = Date() < expiresAt
    }
    
    public var hasExpired: Bool {
        Date() >= expiresAt
    }
    
    public var remainingTime: TimeInterval {
        max(0, expiresAt.timeIntervalSinceNow)
    }
}

/// Biometric enrollment information
public struct BiometricEnrollmentInfo: Sendable {
    public let type: BiometricType
    public let isEnrolled: Bool
    public let enrollmentCount: Int
    public let lastModified: Date?
    public let isEnabled: Bool
    
    public init(
        type: BiometricType,
        isEnrolled: Bool,
        enrollmentCount: Int = 0,
        lastModified: Date? = nil,
        isEnabled: Bool = true
    ) {
        self.type = type
        self.isEnrolled = isEnrolled
        self.enrollmentCount = enrollmentCount
        self.lastModified = lastModified
        self.isEnabled = isEnabled
    }
}

/// Authentication request parameters
public struct AuthenticationRequest: Sendable {
    public let reason: String
    public let fallbackTitle: String?
    public let cancelTitle: String?
    public let policy: BiometricCapabilityConfiguration.AuthenticationPolicy
    public let allowFallback: Bool
    public let invalidateOnBiometricChange: Bool
    
    public init(
        reason: String,
        fallbackTitle: String? = nil,
        cancelTitle: String? = nil,
        policy: BiometricCapabilityConfiguration.AuthenticationPolicy = .deviceOwnerAuthenticationWithBiometrics,
        allowFallback: Bool = true,
        invalidateOnBiometricChange: Bool = true
    ) {
        self.reason = reason
        self.fallbackTitle = fallbackTitle
        self.cancelTitle = cancelTitle
        self.policy = policy
        self.allowFallback = allowFallback
        self.invalidateOnBiometricChange = invalidateOnBiometricChange
    }
}

/// Biometric security validation result
public struct SecurityValidationResult: Sendable {
    public let isValid: Bool
    public let securityLevel: BiometricCapabilityConfiguration.SecurityLevel
    public let validations: [SecurityCheck]
    public let warnings: [SecurityWarning]
    public let timestamp: Date
    
    public struct SecurityCheck: Sendable {
        public let name: String
        public let passed: Bool
        public let description: String
        
        public init(name: String, passed: Bool, description: String) {
            self.name = name
            self.passed = passed
            self.description = description
        }
    }
    
    public struct SecurityWarning: Sendable {
        public let type: WarningType
        public let message: String
        public let severity: Severity
        
        public enum WarningType: String, Codable, CaseIterable, Sendable {
            case jailbreak = "jailbreak"
            case debugger = "debugger"
            case emulator = "emulator"
            case biometricChange = "biometricChange"
        }
        
        public enum Severity: String, Codable, CaseIterable, Sendable {
            case low = "low"
            case medium = "medium"
            case high = "high"
            case critical = "critical"
        }
        
        public init(type: WarningType, message: String, severity: Severity) {
            self.type = type
            self.message = message
            self.severity = severity
        }
    }
    
    public init(
        isValid: Bool,
        securityLevel: BiometricCapabilityConfiguration.SecurityLevel,
        validations: [SecurityCheck] = [],
        warnings: [SecurityWarning] = [],
        timestamp: Date = Date()
    ) {
        self.isValid = isValid
        self.securityLevel = securityLevel
        self.validations = validations
        self.warnings = warnings
        self.timestamp = timestamp
    }
}

/// Biometric metrics
public struct BiometricMetrics: Sendable {
    public let totalAuthenticationAttempts: Int
    public let successfulAuthentications: Int
    public let failedAuthentications: Int
    public let biometricAuthentications: Int
    public let passcodeAuthentications: Int
    public let averageAuthenticationTime: TimeInterval
    public let lockoutEvents: Int
    public let securityViolations: Int
    public let biometricChangeDetections: Int
    public let sessionCount: Int
    public let errorCount: Int
    
    public init(
        totalAuthenticationAttempts: Int = 0,
        successfulAuthentications: Int = 0,
        failedAuthentications: Int = 0,
        biometricAuthentications: Int = 0,
        passcodeAuthentications: Int = 0,
        averageAuthenticationTime: TimeInterval = 0,
        lockoutEvents: Int = 0,
        securityViolations: Int = 0,
        biometricChangeDetections: Int = 0,
        sessionCount: Int = 0,
        errorCount: Int = 0
    ) {
        self.totalAuthenticationAttempts = totalAuthenticationAttempts
        self.successfulAuthentications = successfulAuthentications
        self.failedAuthentications = failedAuthentications
        self.biometricAuthentications = biometricAuthentications
        self.passcodeAuthentications = passcodeAuthentications
        self.averageAuthenticationTime = averageAuthenticationTime
        self.lockoutEvents = lockoutEvents
        self.securityViolations = securityViolations
        self.biometricChangeDetections = biometricChangeDetections
        self.sessionCount = sessionCount
        self.errorCount = errorCount
    }
    
    public var successRate: Double {
        guard totalAuthenticationAttempts > 0 else { return 0.0 }
        return Double(successfulAuthentications) / Double(totalAuthenticationAttempts)
    }
    
    public var biometricUsageRate: Double {
        guard successfulAuthentications > 0 else { return 0.0 }
        return Double(biometricAuthentications) / Double(successfulAuthentications)
    }
}

// MARK: - Biometric Resource

/// Biometric resource management
public actor BiometricCapabilityResource: AxiomCapabilityResource {
    private let configuration: BiometricCapabilityConfiguration
    private var authenticationContext: LAContext?
    private var currentSession: AuthenticationContext?
    private var authenticationHistory: [AuthenticationResult] = []
    private var failedAttempts: Int = 0
    private var lockoutUntil: Date?
    private var metrics: BiometricMetrics = BiometricMetrics()
    private var authenticationTimes: [TimeInterval] = []
    private var lastBiometricState: Data?
    
    public init(configuration: BiometricCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 5_000_000, // 5MB for authentication context and history
            cpu: 5.0, // 5% CPU for authentication operations
            bandwidth: 0, // No network bandwidth
            storage: configuration.maxHistoryCount * 1000 // 1KB per authentication record
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let historySize = authenticationHistory.count * 500
            
            return ResourceUsage(
                memory: historySize + (currentSession != nil ? 1000 : 0),
                cpu: authenticationContext != nil ? 2.0 : 0.1,
                bandwidth: 0,
                storage: historySize
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        await getBiometricAuthenticationStatus() == .available
    }
    
    public func release() async {
        authenticationContext?.invalidate()
        authenticationContext = nil
        currentSession = nil
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        authenticationContext = LAContext()
        
        // Configure authentication context
        if let context = authenticationContext {
            if let fallbackTitle = configuration.fallbackTitle {
                context.localizedFallbackTitle = fallbackTitle
            }
            if let cancelTitle = configuration.cancelTitle {
                context.localizedCancelTitle = cancelTitle
            }
            
            // Enable biometric change detection if configured
            if configuration.enableBiometricChangeDetection {
                context.touchIDAuthenticationAllowableReuseDuration = configuration.invalidationTimeout
            }
        }
        
        // Store initial biometric state for change detection
        if configuration.enableBiometricChangeDetection {
            lastBiometricState = await getBiometricState()
        }
        
        await updateMetrics(sessionStarted: true)
    }
    
    internal func updateConfiguration(_ configuration: BiometricCapabilityConfiguration) async throws {
        if await isAvailable() {
            await release()
            try await allocate()
        }
    }
    
    // MARK: - Biometric Availability
    
    public func getAvailableBiometricTypes() async -> [BiometricType] {
        var types: [BiometricType] = []
        
        guard let context = authenticationContext else { return types }
        
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        if canEvaluate {
            switch context.biometryType {
            case .touchID:
                if configuration.enableTouchID {
                    types.append(.touchID)
                }
            case .faceID:
                if configuration.enableFaceID {
                    types.append(.faceID)
                }
            case .opticID:
                if configuration.enableOpticID {
                    types.append(.opticID)
                }
            case .none:
                break
            @unknown default:
                break
            }
        }
        
        return types
    }
    
    public func getBiometricAuthenticationStatus() async -> BiometricAuthenticationStatus {
        guard let context = authenticationContext else {
            return .notAvailable
        }
        
        var error: NSError?
        let policy = mapAuthenticationPolicy(configuration.authenticationPolicy)
        let canEvaluate = context.canEvaluatePolicy(policy, error: &error)
        
        if canEvaluate {
            return .available
        } else if let error = error {
            switch error.code {
            case LAError.biometryNotAvailable.rawValue:
                return .notAvailable
            case LAError.biometryNotEnrolled.rawValue:
                return .notEnrolled
            case LAError.biometryLockout.rawValue:
                return .lockedOut
            case LAError.passcodeNotSet.rawValue:
                return .biometryNotSet
            default:
                return .notAvailable
            }
        }
        
        return .notAvailable
    }
    
    public func getBiometricEnrollmentInfo() async -> [BiometricEnrollmentInfo] {
        let availableTypes = await getAvailableBiometricTypes()
        
        return availableTypes.map { type in
            BiometricEnrollmentInfo(
                type: type,
                isEnrolled: true, // If it's available, it's enrolled
                enrollmentCount: 1, // Simplified for this implementation
                isEnabled: true
            )
        }
    }
    
    // MARK: - Authentication
    
    public func authenticate(request: AuthenticationRequest) async throws -> AuthenticationResult {
        // Check if locked out
        if await isLockedOut() {
            throw BiometricError.lockedOut
        }
        
        // Check if too many failed attempts
        if failedAttempts >= configuration.maxAuthenticationAttempts {
            await lockout()
            throw BiometricError.tooManyFailedAttempts
        }
        
        // Perform security validation if enabled
        if configuration.enableSecurityValidation {
            let validation = await performSecurityValidation()
            if !validation.isValid {
                await updateMetrics(securityViolation: true)
                throw BiometricError.securityValidationFailed(validation.warnings.map { $0.message })
            }
        }
        
        let startTime = Date()
        
        guard let context = authenticationContext else {
            throw BiometricError.authenticationContextNotAvailable
        }
        
        // Check for biometric changes if enabled
        if configuration.enableBiometricChangeDetection {
            let currentState = await getBiometricState()
            if let lastState = lastBiometricState, currentState != lastState {
                if configuration.invalidateOnBiometricChange {
                    await invalidateCurrentSession()
                    await updateMetrics(biometricChange: true)
                    throw BiometricError.biometricDataChanged
                }
            }
            lastBiometricState = currentState
        }
        
        let policy = mapAuthenticationPolicy(request.policy)
        
        do {
            let success = try await withCheckedThrowingContinuation { continuation in
                context.evaluatePolicy(policy, localizedReason: request.reason) { success, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: success)
                    }
                }
            }
            
            let duration = Date().timeIntervalSince(startTime)
            let biometricType = mapBiometryType(context.biometryType)
            
            let result = AuthenticationResult(
                success: success,
                biometricType: biometricType,
                authenticationMethod: biometricType == .none ? .passcode : .biometric,
                duration: duration
            )
            
            if success {
                // Reset failed attempts on successful authentication
                failedAttempts = 0
                lockoutUntil = nil
                
                // Create new authentication session
                currentSession = AuthenticationContext(
                    validityDuration: configuration.invalidationTimeout,
                    biometricType: biometricType,
                    policy: request.policy
                )
                
                await updateMetrics(
                    authenticationAttempt: true,
                    success: true,
                    biometric: biometricType != .none,
                    duration: duration
                )
            } else {
                failedAttempts += 1
                await updateMetrics(
                    authenticationAttempt: true,
                    success: false,
                    duration: duration
                )
            }
            
            // Add to history
            await addToAuthenticationHistory(result)
            
            return result
            
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            
            failedAttempts += 1
            
            let biometricError = mapLAError(error)
            let result = AuthenticationResult(
                success: false,
                biometricType: mapBiometryType(context.biometryType),
                authenticationMethod: .biometric,
                duration: duration,
                error: biometricError
            )
            
            await updateMetrics(
                authenticationAttempt: true,
                success: false,
                duration: duration,
                error: true
            )
            
            await addToAuthenticationHistory(result)
            
            throw biometricError
        }
    }
    
    public func authenticateWithApplicationPassword(_ password: String) async throws -> AuthenticationResult {
        guard configuration.enableApplicationPasswordSupport else {
            throw BiometricError.applicationPasswordNotSupported
        }
        
        // Check if locked out
        if await isLockedOut() {
            throw BiometricError.lockedOut
        }
        
        let startTime = Date()
        
        // Simplified password validation (in real implementation, this would be more secure)
        let success = !password.isEmpty && password.count >= 6
        
        let duration = Date().timeIntervalSince(startTime)
        
        let result = AuthenticationResult(
            success: success,
            biometricType: .none,
            authenticationMethod: .applicationPassword,
            duration: duration
        )
        
        if success {
            failedAttempts = 0
            lockoutUntil = nil
            
            currentSession = AuthenticationContext(
                validityDuration: configuration.invalidationTimeout,
                biometricType: .none,
                policy: configuration.authenticationPolicy
            )
        } else {
            failedAttempts += 1
        }
        
        await updateMetrics(
            authenticationAttempt: true,
            success: success,
            biometric: false,
            duration: duration
        )
        
        await addToAuthenticationHistory(result)
        
        if success {
            return result
        } else {
            throw BiometricError.applicationPasswordIncorrect
        }
    }
    
    public func getCurrentSession() -> AuthenticationContext? {
        guard let session = currentSession, !session.hasExpired else {
            currentSession = nil
            return nil
        }
        return session
    }
    
    public func invalidateCurrentSession() async {
        currentSession = nil
        authenticationContext?.invalidate()
        
        // Create new context
        authenticationContext = LAContext()
        
        if let context = authenticationContext {
            if let fallbackTitle = configuration.fallbackTitle {
                context.localizedFallbackTitle = fallbackTitle
            }
            if let cancelTitle = configuration.cancelTitle {
                context.localizedCancelTitle = cancelTitle
            }
        }
    }
    
    public func isAuthenticated() -> Bool {
        guard let session = currentSession else { return false }
        return !session.hasExpired
    }
    
    public func requireRecentAuthentication() async throws {
        guard configuration.requireRecentAuthentication else { return }
        
        guard let session = currentSession else {
            throw BiometricError.authenticationRequired
        }
        
        let timeSinceAuth = Date().timeIntervalSince(session.createdAt)
        if timeSinceAuth > configuration.recentAuthenticationThreshold {
            throw BiometricError.recentAuthenticationRequired
        }
    }
    
    // MARK: - Security Validation
    
    public func performSecurityValidation() async -> SecurityValidationResult {
        var validations: [SecurityValidationResult.SecurityCheck] = []
        var warnings: [SecurityValidationResult.SecurityWarning] = []
        
        // Check for jailbreak/root detection
        let jailbreakCheck = performJailbreakDetection()
        validations.append(SecurityValidationResult.SecurityCheck(
            name: "jailbreak_detection",
            passed: !jailbreakCheck,
            description: "Device jailbreak/root detection"
        ))
        
        if jailbreakCheck {
            warnings.append(SecurityValidationResult.SecurityWarning(
                type: .jailbreak,
                message: "Device appears to be jailbroken/rooted",
                severity: .high
            ))
        }
        
        // Check for debugger detection
        let debuggerCheck = performDebuggerDetection()
        validations.append(SecurityValidationResult.SecurityCheck(
            name: "debugger_detection",
            passed: !debuggerCheck,
            description: "Debugger attachment detection"
        ))
        
        if debuggerCheck {
            warnings.append(SecurityValidationResult.SecurityWarning(
                type: .debugger,
                message: "Debugger detected",
                severity: .medium
            ))
        }
        
        // Check for emulator detection
        let emulatorCheck = performEmulatorDetection()
        validations.append(SecurityValidationResult.SecurityCheck(
            name: "emulator_detection",
            passed: !emulatorCheck,
            description: "Emulator/simulator detection"
        ))
        
        if emulatorCheck {
            warnings.append(SecurityValidationResult.SecurityWarning(
                type: .emulator,
                message: "Running on emulator/simulator",
                severity: .low
            ))
        }
        
        let isValid = validations.allSatisfy { $0.passed } || warnings.allSatisfy { $0.severity != .critical }
        
        return SecurityValidationResult(
            isValid: isValid,
            securityLevel: configuration.securityLevel,
            validations: validations,
            warnings: warnings
        )
    }
    
    // MARK: - History and Metrics
    
    public func getAuthenticationHistory() -> [AuthenticationResult] {
        authenticationHistory
    }
    
    public func clearAuthenticationHistory() {
        authenticationHistory.removeAll()
    }
    
    public func getMetrics() -> BiometricMetrics {
        metrics
    }
    
    // MARK: - Private Implementation
    
    private func mapAuthenticationPolicy(_ policy: BiometricCapabilityConfiguration.AuthenticationPolicy) -> LAPolicy {
        switch policy {
        case .deviceOwnerAuthenticationWithBiometrics:
            return .deviceOwnerAuthenticationWithBiometrics
        case .deviceOwnerAuthentication:
            return .deviceOwnerAuthentication
        case .biometryAny:
            return .deviceOwnerAuthenticationWithBiometrics
        case .biometryCurrentSet:
            return .deviceOwnerAuthenticationWithBiometrics
        }
    }
    
    private func mapBiometryType(_ type: LABiometryType) -> BiometricType {
        switch type {
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        case .opticID:
            return .opticID
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }
    
    private func mapLAError(_ error: Error) -> BiometricError {
        guard let laError = error as? LAError else {
            return .unknown(error.localizedDescription)
        }
        
        switch laError.code {
        case .authenticationFailed:
            return .authenticationFailed
        case .userCancel:
            return .userCancel
        case .userFallback:
            return .userFallback
        case .systemCancel:
            return .systemCancel
        case .passcodeNotSet:
            return .passcodeNotSet
        case .biometryNotAvailable:
            return .biometryNotAvailable
        case .biometryNotEnrolled:
            return .biometryNotEnrolled
        case .biometryLockout:
            return .biometryLockout
        case .appCancel:
            return .appCancel
        case .invalidContext:
            return .invalidContext
        case .notInteractive:
            return .notInteractive
        default:
            return .unknown(laError.localizedDescription)
        }
    }
    
    private func getBiometricState() async -> Data? {
        guard let context = authenticationContext else { return nil }
        
        // This would typically return a hash of the enrolled biometric data
        // For this implementation, we'll return a simple identifier
        return "\(context.biometryType.rawValue)_\(Date().timeIntervalSince1970)".data(using: .utf8)
    }
    
    private func isLockedOut() async -> Bool {
        guard let lockoutUntil = lockoutUntil else { return false }
        return Date() < lockoutUntil
    }
    
    private func lockout() async {
        lockoutUntil = Date().addingTimeInterval(configuration.lockoutDuration)
        await updateMetrics(lockout: true)
    }
    
    private func addToAuthenticationHistory(_ result: AuthenticationResult) async {
        guard configuration.enableAuthenticationHistory else { return }
        
        authenticationHistory.append(result)
        
        // Maintain history size limit
        if authenticationHistory.count > configuration.maxHistoryCount {
            authenticationHistory.removeFirst()
        }
    }
    
    private func performJailbreakDetection() -> Bool {
        // Simplified jailbreak detection
        // In a real implementation, this would be more comprehensive
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt"
        ]
        
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        return false
    }
    
    private func performDebuggerDetection() -> Bool {
        // Simplified debugger detection
        // In a real implementation, this would check for debugger attachment
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    private func performEmulatorDetection() -> Bool {
        // Check if running on simulator
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    private func updateMetrics(
        authenticationAttempt: Bool = false,
        success: Bool = false,
        biometric: Bool = false,
        duration: TimeInterval = 0,
        lockout: Bool = false,
        securityViolation: Bool = false,
        biometricChange: Bool = false,
        sessionStarted: Bool = false,
        error: Bool = false
    ) async {
        
        if authenticationAttempt {
            authenticationTimes.append(duration)
            let avgTime = authenticationTimes.reduce(0, +) / Double(authenticationTimes.count)
            
            metrics = BiometricMetrics(
                totalAuthenticationAttempts: metrics.totalAuthenticationAttempts + 1,
                successfulAuthentications: success ? metrics.successfulAuthentications + 1 : metrics.successfulAuthentications,
                failedAuthentications: success ? metrics.failedAuthentications : metrics.failedAuthentications + 1,
                biometricAuthentications: (success && biometric) ? metrics.biometricAuthentications + 1 : metrics.biometricAuthentications,
                passcodeAuthentications: (success && !biometric) ? metrics.passcodeAuthentications + 1 : metrics.passcodeAuthentications,
                averageAuthenticationTime: avgTime,
                lockoutEvents: metrics.lockoutEvents,
                securityViolations: metrics.securityViolations,
                biometricChangeDetections: metrics.biometricChangeDetections,
                sessionCount: metrics.sessionCount,
                errorCount: error ? metrics.errorCount + 1 : metrics.errorCount
            )
        }
        
        if lockout {
            metrics = BiometricMetrics(
                totalAuthenticationAttempts: metrics.totalAuthenticationAttempts,
                successfulAuthentications: metrics.successfulAuthentications,
                failedAuthentications: metrics.failedAuthentications,
                biometricAuthentications: metrics.biometricAuthentications,
                passcodeAuthentications: metrics.passcodeAuthentications,
                averageAuthenticationTime: metrics.averageAuthenticationTime,
                lockoutEvents: metrics.lockoutEvents + 1,
                securityViolations: metrics.securityViolations,
                biometricChangeDetections: metrics.biometricChangeDetections,
                sessionCount: metrics.sessionCount,
                errorCount: metrics.errorCount
            )
        }
        
        if securityViolation {
            metrics = BiometricMetrics(
                totalAuthenticationAttempts: metrics.totalAuthenticationAttempts,
                successfulAuthentications: metrics.successfulAuthentications,
                failedAuthentications: metrics.failedAuthentications,
                biometricAuthentications: metrics.biometricAuthentications,
                passcodeAuthentications: metrics.passcodeAuthentications,
                averageAuthenticationTime: metrics.averageAuthenticationTime,
                lockoutEvents: metrics.lockoutEvents,
                securityViolations: metrics.securityViolations + 1,
                biometricChangeDetections: metrics.biometricChangeDetections,
                sessionCount: metrics.sessionCount,
                errorCount: metrics.errorCount
            )
        }
        
        if biometricChange {
            metrics = BiometricMetrics(
                totalAuthenticationAttempts: metrics.totalAuthenticationAttempts,
                successfulAuthentications: metrics.successfulAuthentications,
                failedAuthentications: metrics.failedAuthentications,
                biometricAuthentications: metrics.biometricAuthentications,
                passcodeAuthentications: metrics.passcodeAuthentications,
                averageAuthenticationTime: metrics.averageAuthenticationTime,
                lockoutEvents: metrics.lockoutEvents,
                securityViolations: metrics.securityViolations,
                biometricChangeDetections: metrics.biometricChangeDetections + 1,
                sessionCount: metrics.sessionCount,
                errorCount: metrics.errorCount
            )
        }
        
        if sessionStarted {
            metrics = BiometricMetrics(
                totalAuthenticationAttempts: metrics.totalAuthenticationAttempts,
                successfulAuthentications: metrics.successfulAuthentications,
                failedAuthentications: metrics.failedAuthentications,
                biometricAuthentications: metrics.biometricAuthentications,
                passcodeAuthentications: metrics.passcodeAuthentications,
                averageAuthenticationTime: metrics.averageAuthenticationTime,
                lockoutEvents: metrics.lockoutEvents,
                securityViolations: metrics.securityViolations,
                biometricChangeDetections: metrics.biometricChangeDetections,
                sessionCount: metrics.sessionCount + 1,
                errorCount: metrics.errorCount
            )
        }
    }
}

// MARK: - Biometric Capability Implementation

/// Biometric capability providing Touch ID/Face ID authentication
public actor BiometricCapability: DomainCapability {
    public typealias ConfigurationType = BiometricCapabilityConfiguration
    public typealias ResourceType = BiometricCapabilityResource
    
    private var _configuration: BiometricCapabilityConfiguration
    private var _resources: BiometricCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(5)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "biometric-capability" }
    
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
    
    public var configuration: BiometricCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: BiometricCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: BiometricCapabilityConfiguration = BiometricCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = BiometricCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: BiometricCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Biometric configuration")
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
        let availableTypes = await _resources.getAvailableBiometricTypes()
        return !availableTypes.isEmpty
    }
    
    public func requestPermission() async throws {
        // Biometric authentication doesn't require explicit permission request
        // The permission is requested when first attempting authentication
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Biometric Operations
    
    /// Get available biometric types
    public func getAvailableBiometricTypes() async -> [BiometricType] {
        await _resources.getAvailableBiometricTypes()
    }
    
    /// Get biometric authentication status
    public func getBiometricAuthenticationStatus() async -> BiometricAuthenticationStatus {
        await _resources.getBiometricAuthenticationStatus()
    }
    
    /// Get biometric enrollment information
    public func getBiometricEnrollmentInfo() async -> [BiometricEnrollmentInfo] {
        await _resources.getBiometricEnrollmentInfo()
    }
    
    /// Authenticate with biometrics or passcode
    public func authenticate(request: AuthenticationRequest? = nil) async throws -> AuthenticationResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Biometric capability not available")
        }
        
        let authRequest = request ?? AuthenticationRequest(
            reason: _configuration.reasonPrompt,
            fallbackTitle: _configuration.fallbackTitle,
            cancelTitle: _configuration.cancelTitle,
            policy: _configuration.authenticationPolicy
        )
        
        return try await _resources.authenticate(request: authRequest)
    }
    
    /// Authenticate with application password
    public func authenticateWithApplicationPassword(_ password: String) async throws -> AuthenticationResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Biometric capability not available")
        }
        
        return try await _resources.authenticateWithApplicationPassword(password)
    }
    
    /// Get current authentication session
    public func getCurrentSession() async -> AuthenticationContext? {
        await _resources.getCurrentSession()
    }
    
    /// Invalidate current authentication session
    public func invalidateCurrentSession() async {
        await _resources.invalidateCurrentSession()
    }
    
    /// Check if currently authenticated
    public func isAuthenticated() async -> Bool {
        await _resources.isAuthenticated()
    }
    
    /// Require recent authentication
    public func requireRecentAuthentication() async throws {
        try await _resources.requireRecentAuthentication()
    }
    
    /// Perform security validation
    public func performSecurityValidation() async -> SecurityValidationResult {
        await _resources.performSecurityValidation()
    }
    
    /// Get authentication history
    public func getAuthenticationHistory() async -> [AuthenticationResult] {
        await _resources.getAuthenticationHistory()
    }
    
    /// Clear authentication history
    public func clearAuthenticationHistory() async {
        await _resources.clearAuthenticationHistory()
    }
    
    /// Get biometric metrics
    public func getMetrics() async -> BiometricMetrics {
        await _resources.getMetrics()
    }
    
    // MARK: - Convenience Methods
    
    /// Quick authentication with default settings
    public func quickAuthenticate() async throws -> AuthenticationResult {
        let request = AuthenticationRequest(reason: _configuration.reasonPrompt)
        return try await authenticate(request: request)
    }
    
    /// Authenticate with custom reason
    public func authenticate(reason: String) async throws -> AuthenticationResult {
        let request = AuthenticationRequest(reason: reason)
        return try await authenticate(request: request)
    }
    
    /// Check if biometric authentication is ready
    public func isBiometricAuthenticationReady() async -> Bool {
        let status = await getBiometricAuthenticationStatus()
        return status == .available
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Biometric specific errors
public enum BiometricError: Error, LocalizedError {
    case authenticationContextNotAvailable
    case authenticationFailed
    case userCancel
    case userFallback
    case systemCancel
    case passcodeNotSet
    case biometryNotAvailable
    case biometryNotEnrolled
    case biometryLockout
    case appCancel
    case invalidContext
    case notInteractive
    case lockedOut
    case tooManyFailedAttempts
    case authenticationRequired
    case recentAuthenticationRequired
    case securityValidationFailed([String])
    case biometricDataChanged
    case applicationPasswordNotSupported
    case applicationPasswordIncorrect
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .authenticationContextNotAvailable:
            return "Authentication context not available"
        case .authenticationFailed:
            return "Authentication failed"
        case .userCancel:
            return "User cancelled authentication"
        case .userFallback:
            return "User chose fallback authentication method"
        case .systemCancel:
            return "System cancelled authentication"
        case .passcodeNotSet:
            return "Passcode not set on device"
        case .biometryNotAvailable:
            return "Biometry not available"
        case .biometryNotEnrolled:
            return "No biometric data enrolled"
        case .biometryLockout:
            return "Biometry locked out due to too many failed attempts"
        case .appCancel:
            return "Application cancelled authentication"
        case .invalidContext:
            return "Invalid authentication context"
        case .notInteractive:
            return "Authentication not interactive"
        case .lockedOut:
            return "Authentication locked out temporarily"
        case .tooManyFailedAttempts:
            return "Too many failed authentication attempts"
        case .authenticationRequired:
            return "Authentication required"
        case .recentAuthenticationRequired:
            return "Recent authentication required"
        case .securityValidationFailed(let reasons):
            return "Security validation failed: \(reasons.joined(separator: ", "))"
        case .biometricDataChanged:
            return "Biometric data has changed"
        case .applicationPasswordNotSupported:
            return "Application password authentication not supported"
        case .applicationPasswordIncorrect:
            return "Application password is incorrect"
        case .unknown(let message):
            return "Unknown biometric error: \(message)"
        }
    }
}