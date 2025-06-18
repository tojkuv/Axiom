import Foundation
import Security
import CommonCrypto
import AxiomCore
import AxiomCapabilities

// MARK: - Certificate Pinning Capability Configuration

/// Configuration for Certificate Pinning capability
public struct CertificatePinningCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let pinningMode: PinningMode
    public let pinnedCertificates: [PinnedCertificate]
    public let pinnedPublicKeys: [PinnedPublicKey]
    public let allowInvalidCertificates: Bool
    public let allowInvalidHostnames: Bool
    public let enableCertificateTransparency: Bool
    public let enableOCSPStapling: Bool
    public let trustedCABundle: [Data]?
    public let validationMode: ValidationMode
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableFailureReporting: Bool
    public let maxCertificateChainLength: Int
    public let enableRevocationChecking: Bool
    public let enableHostnameValidation: Bool
    public let customValidators: [String]
    public let emergencyPins: [EmergencyPin]
    
    public enum PinningMode: String, Codable, CaseIterable {
        case certificate = "certificate"      // Pin entire certificates
        case publicKey = "public-key"        // Pin public keys only
        case subjectKeyIdentifier = "ski"    // Pin Subject Key Identifier
        case certificateChain = "chain"      // Pin certificate chain
        case hybrid = "hybrid"               // Use multiple pinning methods
    }
    
    public enum ValidationMode: String, Codable, CaseIterable {
        case strict = "strict"               // Fail if any pin doesn't match
        case anyPin = "any-pin"             // Pass if any pin matches
        case backup = "backup"               // Allow backup pins on failure
        case graceful = "graceful"           // Warn but don't fail
    }
    
    public init(
        pinningMode: PinningMode = .publicKey,
        pinnedCertificates: [PinnedCertificate] = [],
        pinnedPublicKeys: [PinnedPublicKey] = [],
        allowInvalidCertificates: Bool = false,
        allowInvalidHostnames: Bool = false,
        enableCertificateTransparency: Bool = true,
        enableOCSPStapling: Bool = true,
        trustedCABundle: [Data]? = nil,
        validationMode: ValidationMode = .strict,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableFailureReporting: Bool = true,
        maxCertificateChainLength: Int = 10,
        enableRevocationChecking: Bool = true,
        enableHostnameValidation: Bool = true,
        customValidators: [String] = [],
        emergencyPins: [EmergencyPin] = []
    ) {
        self.pinningMode = pinningMode
        self.pinnedCertificates = pinnedCertificates
        self.pinnedPublicKeys = pinnedPublicKeys
        self.allowInvalidCertificates = allowInvalidCertificates
        self.allowInvalidHostnames = allowInvalidHostnames
        self.enableCertificateTransparency = enableCertificateTransparency
        self.enableOCSPStapling = enableOCSPStapling
        self.trustedCABundle = trustedCABundle
        self.validationMode = validationMode
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableFailureReporting = enableFailureReporting
        self.maxCertificateChainLength = maxCertificateChainLength
        self.enableRevocationChecking = enableRevocationChecking
        self.enableHostnameValidation = enableHostnameValidation
        self.customValidators = customValidators
        self.emergencyPins = emergencyPins
    }
    
    public var isValid: Bool {
        maxCertificateChainLength > 0 && 
        (pinnedCertificates.allSatisfy { $0.isValid } && 
         pinnedPublicKeys.allSatisfy { $0.isValid })
    }
    
    public func merged(with other: CertificatePinningCapabilityConfiguration) -> CertificatePinningCapabilityConfiguration {
        CertificatePinningCapabilityConfiguration(
            pinningMode: other.pinningMode,
            pinnedCertificates: other.pinnedCertificates.isEmpty ? pinnedCertificates : other.pinnedCertificates,
            pinnedPublicKeys: other.pinnedPublicKeys.isEmpty ? pinnedPublicKeys : other.pinnedPublicKeys,
            allowInvalidCertificates: other.allowInvalidCertificates,
            allowInvalidHostnames: other.allowInvalidHostnames,
            enableCertificateTransparency: other.enableCertificateTransparency,
            enableOCSPStapling: other.enableOCSPStapling,
            trustedCABundle: other.trustedCABundle ?? trustedCABundle,
            validationMode: other.validationMode,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableFailureReporting: other.enableFailureReporting,
            maxCertificateChainLength: other.maxCertificateChainLength,
            enableRevocationChecking: other.enableRevocationChecking,
            enableHostnameValidation: other.enableHostnameValidation,
            customValidators: other.customValidators.isEmpty ? customValidators : other.customValidators,
            emergencyPins: other.emergencyPins.isEmpty ? emergencyPins : other.emergencyPins
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> CertificatePinningCapabilityConfiguration {
        var adjustedLogging = enableLogging
        var adjustedValidationMode = validationMode
        var adjustedRevocationChecking = enableRevocationChecking
        
        if environment.isLowPowerMode {
            adjustedRevocationChecking = false // Skip expensive revocation checks
        }
        
        if environment.isDebug {
            adjustedLogging = true
            adjustedValidationMode = .graceful // Be more permissive in debug
        }
        
        return CertificatePinningCapabilityConfiguration(
            pinningMode: pinningMode,
            pinnedCertificates: pinnedCertificates,
            pinnedPublicKeys: pinnedPublicKeys,
            allowInvalidCertificates: allowInvalidCertificates,
            allowInvalidHostnames: allowInvalidHostnames,
            enableCertificateTransparency: enableCertificateTransparency,
            enableOCSPStapling: enableOCSPStapling,
            trustedCABundle: trustedCABundle,
            validationMode: adjustedValidationMode,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableFailureReporting: enableFailureReporting,
            maxCertificateChainLength: maxCertificateChainLength,
            enableRevocationChecking: adjustedRevocationChecking,
            enableHostnameValidation: enableHostnameValidation,
            customValidators: customValidators,
            emergencyPins: emergencyPins
        )
    }
}

// MARK: - Certificate Pinning Types

/// Pinned certificate configuration
public struct PinnedCertificate: Sendable, Codable {
    public let hostname: String
    public let certificateData: Data
    public let certificateHash: String
    public let validFrom: Date
    public let validTo: Date
    public let issuer: String
    public let subject: String
    public let isBackup: Bool
    public let pinType: PinType
    
    public enum PinType: String, Codable, CaseIterable {
        case leaf = "leaf"           // Pin leaf certificate
        case intermediate = "intermediate"  // Pin intermediate CA
        case root = "root"          // Pin root CA
        case any = "any"           // Pin any certificate in chain
    }
    
    public init(
        hostname: String,
        certificateData: Data,
        certificateHash: String,
        validFrom: Date,
        validTo: Date,
        issuer: String,
        subject: String,
        isBackup: Bool = false,
        pinType: PinType = .leaf
    ) {
        self.hostname = hostname
        self.certificateData = certificateData
        self.certificateHash = certificateHash
        self.validFrom = validFrom
        self.validTo = validTo
        self.issuer = issuer
        self.subject = subject
        self.isBackup = isBackup
        self.pinType = pinType
    }
    
    public var isValid: Bool {
        !hostname.isEmpty && 
        !certificateData.isEmpty && 
        !certificateHash.isEmpty &&
        validFrom < validTo &&
        Date() >= validFrom &&
        Date() <= validTo
    }
    
    public var isExpired: Bool {
        Date() > validTo
    }
    
    public var isNotYetValid: Bool {
        Date() < validFrom
    }
}

/// Pinned public key configuration
public struct PinnedPublicKey: Sendable, Codable {
    public let hostname: String
    public let publicKeyHash: String
    public let algorithm: Algorithm
    public let keySize: Int
    public let isBackup: Bool
    public let pinType: PinnedCertificate.PinType
    
    public enum Algorithm: String, Codable, CaseIterable {
        case rsa = "rsa"
        case ecdsa = "ecdsa"
        case ed25519 = "ed25519"
        case dsa = "dsa"
    }
    
    public init(
        hostname: String,
        publicKeyHash: String,
        algorithm: Algorithm,
        keySize: Int,
        isBackup: Bool = false,
        pinType: PinnedCertificate.PinType = .leaf
    ) {
        self.hostname = hostname
        self.publicKeyHash = publicKeyHash
        self.algorithm = algorithm
        self.keySize = keySize
        self.isBackup = isBackup
        self.pinType = pinType
    }
    
    public var isValid: Bool {
        !hostname.isEmpty && 
        !publicKeyHash.isEmpty && 
        keySize > 0
    }
}

/// Emergency pin for backup validation
public struct EmergencyPin: Sendable, Codable {
    public let hostname: String
    public let pinHash: String
    public let validUntil: Date
    public let reason: String
    public let isActive: Bool
    
    public init(
        hostname: String,
        pinHash: String,
        validUntil: Date,
        reason: String,
        isActive: Bool = true
    ) {
        self.hostname = hostname
        self.pinHash = pinHash
        self.validUntil = validUntil
        self.reason = reason
        self.isActive = isActive
    }
    
    public var isValid: Bool {
        !hostname.isEmpty && 
        !pinHash.isEmpty && 
        Date() <= validUntil && 
        isActive
    }
}

/// Certificate validation result
public struct CertificateValidationResult: Sendable {
    public let isValid: Bool
    public let hostname: String
    public let validationTime: Date
    public let validationDuration: TimeInterval
    public let certificateChain: [CertificateInfo]
    public let pinnedMatches: [PinMatch]
    public let errors: [CertificateValidationError]
    public let warnings: [String]
    public let validationMethod: String
    public let trustScore: Double
    
    public init(
        isValid: Bool,
        hostname: String,
        validationTime: Date = Date(),
        validationDuration: TimeInterval,
        certificateChain: [CertificateInfo],
        pinnedMatches: [PinMatch] = [],
        errors: [CertificateValidationError] = [],
        warnings: [String] = [],
        validationMethod: String,
        trustScore: Double = 0.0
    ) {
        self.isValid = isValid
        self.hostname = hostname
        self.validationTime = validationTime
        self.validationDuration = validationDuration
        self.certificateChain = certificateChain
        self.pinnedMatches = pinnedMatches
        self.errors = errors
        self.warnings = warnings
        self.validationMethod = validationMethod
        self.trustScore = trustScore
    }
}

/// Certificate information
public struct CertificateInfo: Sendable {
    public let subject: String
    public let issuer: String
    public let serialNumber: String
    public let validFrom: Date
    public let validTo: Date
    public let publicKeyAlgorithm: String
    public let publicKeySize: Int
    public let signatureAlgorithm: String
    public let fingerprint: String
    public let subjectKeyIdentifier: String?
    public let authorityKeyIdentifier: String?
    public let keyUsage: [String]
    public let extendedKeyUsage: [String]
    public let subjectAlternativeNames: [String]
    
    public init(
        subject: String,
        issuer: String,
        serialNumber: String,
        validFrom: Date,
        validTo: Date,
        publicKeyAlgorithm: String,
        publicKeySize: Int,
        signatureAlgorithm: String,
        fingerprint: String,
        subjectKeyIdentifier: String? = nil,
        authorityKeyIdentifier: String? = nil,
        keyUsage: [String] = [],
        extendedKeyUsage: [String] = [],
        subjectAlternativeNames: [String] = []
    ) {
        self.subject = subject
        self.issuer = issuer
        self.serialNumber = serialNumber
        self.validFrom = validFrom
        self.validTo = validTo
        self.publicKeyAlgorithm = publicKeyAlgorithm
        self.publicKeySize = publicKeySize
        self.signatureAlgorithm = signatureAlgorithm
        self.fingerprint = fingerprint
        self.subjectKeyIdentifier = subjectKeyIdentifier
        self.authorityKeyIdentifier = authorityKeyIdentifier
        self.keyUsage = keyUsage
        self.extendedKeyUsage = extendedKeyUsage
        self.subjectAlternativeNames = subjectAlternativeNames
    }
    
    public var isExpired: Bool {
        Date() > validTo
    }
    
    public var isNotYetValid: Bool {
        Date() < validFrom
    }
    
    public var daysUntilExpiry: Int {
        let interval = validTo.timeIntervalSinceNow
        return max(0, Int(interval / 86400)) // 86400 seconds in a day
    }
}

/// Pin match information
public struct PinMatch: Sendable {
    public let pinType: String
    public let matchedHash: String
    public let certificatePosition: Int
    public let isBackupPin: Bool
    public let isEmergencyPin: Bool
    
    public init(
        pinType: String,
        matchedHash: String,
        certificatePosition: Int,
        isBackupPin: Bool = false,
        isEmergencyPin: Bool = false
    ) {
        self.pinType = pinType
        self.matchedHash = matchedHash
        self.certificatePosition = certificatePosition
        self.isBackupPin = isBackupPin
        self.isEmergencyPin = isEmergencyPin
    }
}

/// Certificate validation error
public enum CertificateValidationError: Error, Sendable, LocalizedError {
    case noPinsConfigured(String)
    case pinMismatch(String, [String])
    case certificateExpired(String, Date)
    case certificateNotYetValid(String, Date)
    case invalidCertificateChain(String)
    case hostnameValidationFailed(String, String)
    case revocationCheckFailed(String, String)
    case invalidSignature(String)
    case untrustedRootCertificate(String)
    case certificateChainTooLong(Int, Int)
    case malformedCertificate(String)
    case unsupportedAlgorithm(String)
    case customValidationFailed(String, String)
    
    public var errorDescription: String? {
        switch self {
        case .noPinsConfigured(let hostname):
            return "No certificate pins configured for hostname: \(hostname)"
        case .pinMismatch(let hostname, let expected):
            return "Certificate pin mismatch for \(hostname). Expected: \(expected.joined(separator: ", "))"
        case .certificateExpired(let subject, let expiry):
            return "Certificate expired: \(subject) (expired: \(expiry))"
        case .certificateNotYetValid(let subject, let validFrom):
            return "Certificate not yet valid: \(subject) (valid from: \(validFrom))"
        case .invalidCertificateChain(let reason):
            return "Invalid certificate chain: \(reason)"
        case .hostnameValidationFailed(let hostname, let subject):
            return "Hostname validation failed: \(hostname) does not match \(subject)"
        case .revocationCheckFailed(let subject, let reason):
            return "Revocation check failed for \(subject): \(reason)"
        case .invalidSignature(let subject):
            return "Invalid certificate signature: \(subject)"
        case .untrustedRootCertificate(let subject):
            return "Untrusted root certificate: \(subject)"
        case .certificateChainTooLong(let length, let max):
            return "Certificate chain too long: \(length) (max: \(max))"
        case .malformedCertificate(let reason):
            return "Malformed certificate: \(reason)"
        case .unsupportedAlgorithm(let algorithm):
            return "Unsupported algorithm: \(algorithm)"
        case .customValidationFailed(let validator, let reason):
            return "Custom validation failed (\(validator)): \(reason)"
        }
    }
}

/// Certificate pinning metrics
public struct CertificatePinningMetrics: Sendable {
    public let totalValidations: Int
    public let successfulValidations: Int
    public let failedValidations: Int
    public let pinMatches: Int
    public let pinMismatches: Int
    public let averageValidationTime: TimeInterval
    public let validationsByHostname: [String: Int]
    public let errorsByType: [String: Int]
    public let emergencyPinUsage: Int
    public let backupPinUsage: Int
    public let certificateExpiryWarnings: Int
    
    public init(
        totalValidations: Int = 0,
        successfulValidations: Int = 0,
        failedValidations: Int = 0,
        pinMatches: Int = 0,
        pinMismatches: Int = 0,
        averageValidationTime: TimeInterval = 0,
        validationsByHostname: [String: Int] = [:],
        errorsByType: [String: Int] = [:],
        emergencyPinUsage: Int = 0,
        backupPinUsage: Int = 0,
        certificateExpiryWarnings: Int = 0
    ) {
        self.totalValidations = totalValidations
        self.successfulValidations = successfulValidations
        self.failedValidations = failedValidations
        self.pinMatches = pinMatches
        self.pinMismatches = pinMismatches
        self.averageValidationTime = averageValidationTime
        self.validationsByHostname = validationsByHostname
        self.errorsByType = errorsByType
        self.emergencyPinUsage = emergencyPinUsage
        self.backupPinUsage = backupPinUsage
        self.certificateExpiryWarnings = certificateExpiryWarnings
    }
    
    public var successRate: Double {
        totalValidations > 0 ? Double(successfulValidations) / Double(totalValidations) : 0
    }
    
    public var pinMatchRate: Double {
        let totalPinChecks = pinMatches + pinMismatches
        return totalPinChecks > 0 ? Double(pinMatches) / Double(totalPinChecks) : 0
    }
}

// MARK: - Certificate Pinning Resource

/// Certificate pinning resource management
public actor CertificatePinningCapabilityResource: AxiomCapabilityResource {
    private let configuration: CertificatePinningCapabilityConfiguration
    private var pinnedCertificatesIndex: [String: [PinnedCertificate]] = [:]
    private var pinnedPublicKeysIndex: [String: [PinnedPublicKey]] = [:]
    private var emergencyPinsIndex: [String: [EmergencyPin]] = [:]
    private var metrics: CertificatePinningMetrics = CertificatePinningMetrics()
    private var validationCache: [String: (result: CertificateValidationResult, timestamp: Date)] = [:]
    
    public init(configuration: CertificatePinningCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: configuration.pinnedCertificates.count * 50_000 + configuration.pinnedPublicKeys.count * 10_000,
            cpu: 3.0, // Certificate validation can be CPU intensive
            bandwidth: 0,
            storage: configuration.pinnedCertificates.count * 20_000
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let cacheMemory = validationCache.count * 5_000
            return ResourceUsage(
                memory: pinnedCertificatesIndex.values.flatMap { $0 }.count * 25_000 + cacheMemory,
                cpu: 1.0,
                bandwidth: 0,
                storage: pinnedCertificatesIndex.values.flatMap { $0 }.count * 10_000
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        !pinnedCertificatesIndex.isEmpty || !pinnedPublicKeysIndex.isEmpty
    }
    
    public func release() async {
        pinnedCertificatesIndex.removeAll()
        pinnedPublicKeysIndex.removeAll()
        emergencyPinsIndex.removeAll()
        validationCache.removeAll()
        metrics = CertificatePinningMetrics()
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Index pinned certificates by hostname
        await indexPinnedCertificates()
        
        // Index pinned public keys by hostname
        await indexPinnedPublicKeys()
        
        // Index emergency pins by hostname
        await indexEmergencyPins()
        
        // Validate configuration
        try await validateConfiguration()
    }
    
    internal func updateConfiguration(_ configuration: CertificatePinningCapabilityConfiguration) async throws {
        // Clear existing indexes
        pinnedCertificatesIndex.removeAll()
        pinnedPublicKeysIndex.removeAll()
        emergencyPinsIndex.removeAll()
        
        // Rebuild indexes
        try await allocate()
    }
    
    // MARK: - Certificate Validation
    
    public func validateServerTrust(
        _ serverTrust: SecTrust,
        hostname: String
    ) async throws -> CertificateValidationResult {
        
        let startTime = Date()
        var errors: [CertificateValidationError] = []
        var warnings: [String] = []
        var pinnedMatches: [PinMatch] = []
        
        // Extract certificate chain
        let certificateChain = extractCertificateChain(from: serverTrust)
        
        // Basic certificate chain validation
        if certificateChain.isEmpty {
            errors.append(.invalidCertificateChain("Empty certificate chain"))
        }
        
        if certificateChain.count > configuration.maxCertificateChainLength {
            errors.append(.certificateChainTooLong(certificateChain.count, configuration.maxCertificateChainLength))
        }
        
        // Check certificate expiry
        for cert in certificateChain {
            if cert.isExpired {
                errors.append(.certificateExpired(cert.subject, cert.validTo))
            } else if cert.isNotYetValid {
                errors.append(.certificateNotYetValid(cert.subject, cert.validFrom))
            } else if cert.daysUntilExpiry <= 30 {
                warnings.append("Certificate \(cert.subject) expires in \(cert.daysUntilExpiry) days")
            }
        }
        
        // Hostname validation
        if configuration.enableHostnameValidation && !configuration.allowInvalidHostnames {
            let hostnameValid = await validateHostname(hostname, against: certificateChain)
            if !hostnameValid {
                errors.append(.hostnameValidationFailed(hostname, certificateChain.first?.subject ?? "unknown"))
            }
        }
        
        // Certificate pinning validation
        let pinningResult = await validateCertificatePinning(hostname: hostname, certificateChain: certificateChain)
        errors.append(contentsOf: pinningResult.errors)
        pinnedMatches.append(contentsOf: pinningResult.matches)
        
        // Revocation checking
        if configuration.enableRevocationChecking {
            let revocationErrors = await checkRevocationStatus(certificateChain)
            errors.append(contentsOf: revocationErrors)
        }
        
        // Custom validation
        for validatorName in configuration.customValidators {
            let customResult = await performCustomValidation(validatorName, serverTrust: serverTrust, hostname: hostname)
            if let error = customResult {
                errors.append(.customValidationFailed(validatorName, error))
            }
        }
        
        // Determine overall validity based on validation mode
        let isValid = await determineValidationResult(errors: errors, pinnedMatches: pinnedMatches)
        
        let validationDuration = Date().timeIntervalSince(startTime)
        let trustScore = calculateTrustScore(certificateChain: certificateChain, pinnedMatches: pinnedMatches, errors: errors)
        
        let result = CertificateValidationResult(
            isValid: isValid,
            hostname: hostname,
            validationDuration: validationDuration,
            certificateChain: certificateChain,
            pinnedMatches: pinnedMatches,
            errors: errors,
            warnings: warnings,
            validationMethod: configuration.pinningMode.rawValue,
            trustScore: trustScore
        )
        
        // Update metrics
        if configuration.enableMetrics {
            await updateValidationMetrics(result: result, hostname: hostname)
        }
        
        // Log result
        if configuration.enableLogging {
            await logValidationResult(result)
        }
        
        return result
    }
    
    // MARK: - Pin Management
    
    public func addPinnedCertificate(_ certificate: PinnedCertificate) async {
        var certificates = pinnedCertificatesIndex[certificate.hostname] ?? []
        certificates.append(certificate)
        pinnedCertificatesIndex[certificate.hostname] = certificates
    }
    
    public func addPinnedPublicKey(_ publicKey: PinnedPublicKey) async {
        var keys = pinnedPublicKeysIndex[publicKey.hostname] ?? []
        keys.append(publicKey)
        pinnedPublicKeysIndex[publicKey.hostname] = keys
    }
    
    public func addEmergencyPin(_ pin: EmergencyPin) async {
        var pins = emergencyPinsIndex[pin.hostname] ?? []
        pins.append(pin)
        emergencyPinsIndex[pin.hostname] = pins
    }
    
    public func removePinnedCertificate(hostname: String, certificateHash: String) async {
        var certificates = pinnedCertificatesIndex[hostname] ?? []
        certificates.removeAll { $0.certificateHash == certificateHash }
        if certificates.isEmpty {
            pinnedCertificatesIndex.removeValue(forKey: hostname)
        } else {
            pinnedCertificatesIndex[hostname] = certificates
        }
    }
    
    public func getPinnedCertificates(for hostname: String) async -> [PinnedCertificate] {
        pinnedCertificatesIndex[hostname] ?? []
    }
    
    public func getPinnedPublicKeys(for hostname: String) async -> [PinnedPublicKey] {
        pinnedPublicKeysIndex[hostname] ?? []
    }
    
    public func getEmergencyPins(for hostname: String) async -> [EmergencyPin] {
        emergencyPinsIndex[hostname]?.filter { $0.isValid } ?? []
    }
    
    // MARK: - Metrics and Reporting
    
    public func getMetrics() async -> CertificatePinningMetrics {
        metrics
    }
    
    public func clearMetrics() async {
        metrics = CertificatePinningMetrics()
    }
    
    public func getValidationCache() async -> [String: CertificateValidationResult] {
        validationCache.mapValues { $0.result }
    }
    
    public func clearValidationCache() async {
        validationCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func indexPinnedCertificates() async {
        for certificate in configuration.pinnedCertificates {
            var certificates = pinnedCertificatesIndex[certificate.hostname] ?? []
            certificates.append(certificate)
            pinnedCertificatesIndex[certificate.hostname] = certificates
        }
    }
    
    private func indexPinnedPublicKeys() async {
        for publicKey in configuration.pinnedPublicKeys {
            var keys = pinnedPublicKeysIndex[publicKey.hostname] ?? []
            keys.append(publicKey)
            pinnedPublicKeysIndex[publicKey.hostname] = keys
        }
    }
    
    private func indexEmergencyPins() async {
        for pin in configuration.emergencyPins {
            var pins = emergencyPinsIndex[pin.hostname] ?? []
            pins.append(pin)
            emergencyPinsIndex[pin.hostname] = pins
        }
    }
    
    private func validateConfiguration() async throws {
        // Validate that we have pins configured
        if pinnedCertificatesIndex.isEmpty && pinnedPublicKeysIndex.isEmpty {
            throw CertificateValidationError.noPinsConfigured("global")
        }
        
        // Validate certificate dates
        for (_, certificates) in pinnedCertificatesIndex {
            for certificate in certificates {
                if !certificate.isValid {
                    throw CertificateValidationError.certificateExpired(certificate.subject, certificate.validTo)
                }
            }
        }
    }
    
    private func extractCertificateChain(from serverTrust: SecTrust) -> [CertificateInfo] {
        var certificateChain: [CertificateInfo] = []
        
        let certificateCount = SecTrustGetCertificateCount(serverTrust)
        
        for i in 0..<certificateCount {
            if let certificate = SecTrustGetCertificateAtIndex(serverTrust, i) {
                let certificateInfo = extractCertificateInfo(from: certificate)
                certificateChain.append(certificateInfo)
            }
        }
        
        return certificateChain
    }
    
    private func extractCertificateInfo(from certificate: SecCertificate) -> CertificateInfo {
        // Extract certificate information using Security framework
        // This is a simplified implementation - real implementation would use
        // SecCertificateCopyValues and other Security framework APIs
        
        let subject = getCertificateSubject(certificate) ?? "Unknown"
        let issuer = getCertificateIssuer(certificate) ?? "Unknown"
        let serialNumber = getCertificateSerialNumber(certificate) ?? "Unknown"
        let (validFrom, validTo) = getCertificateValidityPeriod(certificate)
        let fingerprint = getCertificateFingerprint(certificate) ?? "Unknown"
        
        return CertificateInfo(
            subject: subject,
            issuer: issuer,
            serialNumber: serialNumber,
            validFrom: validFrom,
            validTo: validTo,
            publicKeyAlgorithm: "RSA", // Simplified
            publicKeySize: 2048, // Simplified
            signatureAlgorithm: "SHA256withRSA", // Simplified
            fingerprint: fingerprint
        )
    }
    
    private func getCertificateSubject(_ certificate: SecCertificate) -> String? {
        var commonName: CFString?
        let status = SecCertificateCopyCommonName(certificate, &commonName)
        
        if status == errSecSuccess, let name = commonName {
            return name as String
        }
        
        return nil
    }
    
    private func getCertificateIssuer(_ certificate: SecCertificate) -> String? {
        // Simplified implementation
        return "CA Issuer"
    }
    
    private func getCertificateSerialNumber(_ certificate: SecCertificate) -> String? {
        // Simplified implementation
        return "123456789"
    }
    
    private func getCertificateValidityPeriod(_ certificate: SecCertificate) -> (Date, Date) {
        // Simplified implementation - would use SecCertificateNotValidBefore/After
        let now = Date()
        return (now.addingTimeInterval(-86400 * 365), now.addingTimeInterval(86400 * 365))
    }
    
    private func getCertificateFingerprint(_ certificate: SecCertificate) -> String? {
        let data = SecCertificateCopyData(certificate)
        let certificateData = CFDataGetBytePtr(data)
        let certificateLength = CFDataGetLength(data)
        
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256(certificateData, CC_LONG(certificateLength), &hash)
        
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    private func validateHostname(_ hostname: String, against certificateChain: [CertificateInfo]) async -> Bool {
        guard let leafCertificate = certificateChain.first else { return false }
        
        // Check if hostname matches subject or any SAN
        if leafCertificate.subject.contains(hostname) {
            return true
        }
        
        for san in leafCertificate.subjectAlternativeNames {
            if matchesHostname(hostname, pattern: san) {
                return true
            }
        }
        
        return false
    }
    
    private func matchesHostname(_ hostname: String, pattern: String) -> Bool {
        // Simplified hostname matching - real implementation would handle wildcards
        return hostname.lowercased() == pattern.lowercased()
    }
    
    private func validateCertificatePinning(
        hostname: String,
        certificateChain: [CertificateInfo]
    ) async -> (errors: [CertificateValidationError], matches: [PinMatch]) {
        
        var errors: [CertificateValidationError] = []
        var matches: [PinMatch] = []
        
        let pinnedCertificates = pinnedCertificatesIndex[hostname] ?? []
        let pinnedPublicKeys = pinnedPublicKeysIndex[hostname] ?? []
        let emergencyPins = emergencyPinsIndex[hostname]?.filter { $0.isValid } ?? []
        
        // Check if we have any pins configured for this hostname
        if pinnedCertificates.isEmpty && pinnedPublicKeys.isEmpty {
            errors.append(.noPinsConfigured(hostname))
            return (errors, matches)
        }
        
        var hasMatch = false
        
        // Check certificate pins
        for (index, certificateInfo) in certificateChain.enumerated() {
            for pinnedCert in pinnedCertificates {
                if certificateInfo.fingerprint == pinnedCert.certificateHash {
                    matches.append(PinMatch(
                        pinType: "certificate",
                        matchedHash: pinnedCert.certificateHash,
                        certificatePosition: index,
                        isBackupPin: pinnedCert.isBackup
                    ))
                    hasMatch = true
                }
            }
        }
        
        // Check public key pins
        for (index, certificateInfo) in certificateChain.enumerated() {
            for pinnedKey in pinnedPublicKeys {
                // In real implementation, we would extract and compare public keys
                let publicKeyHash = calculatePublicKeyHash(from: certificateInfo)
                if publicKeyHash == pinnedKey.publicKeyHash {
                    matches.append(PinMatch(
                        pinType: "public-key",
                        matchedHash: pinnedKey.publicKeyHash,
                        certificatePosition: index,
                        isBackupPin: pinnedKey.isBackup
                    ))
                    hasMatch = true
                }
            }
        }
        
        // Check emergency pins if no regular pins matched
        if !hasMatch && !emergencyPins.isEmpty {
            for (index, certificateInfo) in certificateChain.enumerated() {
                for emergencyPin in emergencyPins {
                    if certificateInfo.fingerprint == emergencyPin.pinHash {
                        matches.append(PinMatch(
                            pinType: "emergency",
                            matchedHash: emergencyPin.pinHash,
                            certificatePosition: index,
                            isEmergencyPin: true
                        ))
                        hasMatch = true
                    }
                }
            }
        }
        
        // Add error if no pins matched
        if !hasMatch {
            let expectedHashes = pinnedCertificates.map { $0.certificateHash } + pinnedPublicKeys.map { $0.publicKeyHash }
            errors.append(.pinMismatch(hostname, expectedHashes))
        }
        
        return (errors, matches)
    }
    
    private func calculatePublicKeyHash(from certificateInfo: CertificateInfo) -> String {
        // Simplified implementation - would extract actual public key and hash it
        return "simplified-public-key-hash"
    }
    
    private func checkRevocationStatus(_ certificateChain: [CertificateInfo]) async -> [CertificateValidationError] {
        var errors: [CertificateValidationError] = []
        
        // Simplified implementation - would check OCSP/CRL
        // In real implementation, this would make network requests to check revocation status
        
        return errors
    }
    
    private func performCustomValidation(
        _ validatorName: String,
        serverTrust: SecTrust,
        hostname: String
    ) async -> String? {
        // Placeholder for custom validation logic
        // In real implementation, this would call registered custom validators
        return nil
    }
    
    private func determineValidationResult(
        errors: [CertificateValidationError],
        pinnedMatches: [PinMatch]
    ) async -> Bool {
        
        switch configuration.validationMode {
        case .strict:
            return errors.isEmpty && !pinnedMatches.isEmpty
        case .anyPin:
            return !pinnedMatches.isEmpty
        case .backup:
            return !pinnedMatches.isEmpty || pinnedMatches.contains { $0.isBackupPin }
        case .graceful:
            return true // Always pass in graceful mode, but log issues
        }
    }
    
    private func calculateTrustScore(
        certificateChain: [CertificateInfo],
        pinnedMatches: [PinMatch],
        errors: [CertificateValidationError]
    ) -> Double {
        var score = 0.0
        
        // Base score for valid certificate chain
        if !certificateChain.isEmpty {
            score += 30.0
        }
        
        // Score for pin matches
        if !pinnedMatches.isEmpty {
            score += 50.0
        }
        
        // Score for certificate validity
        let validCertificates = certificateChain.filter { !$0.isExpired && !$0.isNotYetValid }
        if !validCertificates.isEmpty {
            score += 20.0
        }
        
        // Penalty for errors
        score -= Double(errors.count) * 10.0
        
        return max(0.0, min(100.0, score))
    }
    
    private func updateValidationMetrics(result: CertificateValidationResult, hostname: String) async {
        var newValidationsByHostname = metrics.validationsByHostname
        var newErrorsByType = metrics.errorsByType
        
        newValidationsByHostname[hostname, default: 0] += 1
        
        for error in result.errors {
            let errorType = String(describing: type(of: error))
            newErrorsByType[errorType, default: 0] += 1
        }
        
        let totalValidations = metrics.totalValidations + 1
        let successfulValidations = metrics.successfulValidations + (result.isValid ? 1 : 0)
        let failedValidations = metrics.failedValidations + (result.isValid ? 0 : 1)
        let pinMatches = metrics.pinMatches + result.pinnedMatches.count
        let pinMismatches = metrics.pinMismatches + (result.pinnedMatches.isEmpty ? 1 : 0)
        
        let newAverageTime = ((metrics.averageValidationTime * Double(metrics.totalValidations)) + result.validationDuration) / Double(totalValidations)
        
        let emergencyPinUsage = metrics.emergencyPinUsage + result.pinnedMatches.filter { $0.isEmergencyPin }.count
        let backupPinUsage = metrics.backupPinUsage + result.pinnedMatches.filter { $0.isBackupPin }.count
        
        metrics = CertificatePinningMetrics(
            totalValidations: totalValidations,
            successfulValidations: successfulValidations,
            failedValidations: failedValidations,
            pinMatches: pinMatches,
            pinMismatches: pinMismatches,
            averageValidationTime: newAverageTime,
            validationsByHostname: newValidationsByHostname,
            errorsByType: newErrorsByType,
            emergencyPinUsage: emergencyPinUsage,
            backupPinUsage: backupPinUsage,
            certificateExpiryWarnings: metrics.certificateExpiryWarnings + result.warnings.count
        )
    }
    
    private func logValidationResult(_ result: CertificateValidationResult) async {
        let status = result.isValid ? "✅ VALID" : "❌ INVALID"
        let pinInfo = result.pinnedMatches.isEmpty ? "" : " (pins: \(result.pinnedMatches.count))"
        
        print("[CertificatePinning] \(status): \(result.hostname)\(pinInfo)")
        
        if !result.errors.isEmpty {
            for error in result.errors {
                print("[CertificatePinning] ⚠️ ERROR: \(error.localizedDescription)")
            }
        }
        
        if !result.warnings.isEmpty {
            for warning in result.warnings {
                print("[CertificatePinning] ⚠️ WARNING: \(warning)")
            }
        }
    }
}

// MARK: - Certificate Pinning Capability Implementation

/// Certificate Pinning capability providing SSL/TLS certificate validation and pinning
public actor CertificatePinningCapability: DomainCapability {
    public typealias ConfigurationType = CertificatePinningCapabilityConfiguration
    public typealias ResourceType = CertificatePinningCapabilityResource
    
    private var _configuration: CertificatePinningCapabilityConfiguration
    private var _resources: CertificatePinningCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(5)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "certificate-pinning-capability" }
    
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
    
    public var configuration: CertificatePinningCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: CertificatePinningCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: CertificatePinningCapabilityConfiguration,
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = CertificatePinningCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: CertificatePinningCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Certificate Pinning configuration")
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
        // Certificate pinning is supported on all platforms
        true
    }
    
    public func requestPermission() async throws {
        // Certificate pinning doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Certificate Pinning Operations
    
    /// Validate server trust with certificate pinning
    public func validateServerTrust(
        _ serverTrust: SecTrust,
        hostname: String
    ) async throws -> CertificateValidationResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Certificate Pinning capability not available")
        }
        
        return try await _resources.validateServerTrust(serverTrust, hostname: hostname)
    }
    
    /// Add a pinned certificate
    public func addPinnedCertificate(_ certificate: PinnedCertificate) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Certificate Pinning capability not available")
        }
        
        await _resources.addPinnedCertificate(certificate)
    }
    
    /// Add a pinned public key
    public func addPinnedPublicKey(_ publicKey: PinnedPublicKey) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Certificate Pinning capability not available")
        }
        
        await _resources.addPinnedPublicKey(publicKey)
    }
    
    /// Add an emergency pin
    public func addEmergencyPin(_ pin: EmergencyPin) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Certificate Pinning capability not available")
        }
        
        await _resources.addEmergencyPin(pin)
    }
    
    /// Remove a pinned certificate
    public func removePinnedCertificate(hostname: String, certificateHash: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Certificate Pinning capability not available")
        }
        
        await _resources.removePinnedCertificate(hostname: hostname, certificateHash: certificateHash)
    }
    
    /// Get pinned certificates for hostname
    public func getPinnedCertificates(for hostname: String) async throws -> [PinnedCertificate] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Certificate Pinning capability not available")
        }
        
        return await _resources.getPinnedCertificates(for: hostname)
    }
    
    /// Get pinned public keys for hostname
    public func getPinnedPublicKeys(for hostname: String) async throws -> [PinnedPublicKey] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Certificate Pinning capability not available")
        }
        
        return await _resources.getPinnedPublicKeys(for: hostname)
    }
    
    /// Get emergency pins for hostname
    public func getEmergencyPins(for hostname: String) async throws -> [EmergencyPin] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Certificate Pinning capability not available")
        }
        
        return await _resources.getEmergencyPins(for: hostname)
    }
    
    /// Get validation metrics
    public func getMetrics() async throws -> CertificatePinningMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Certificate Pinning capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Certificate Pinning capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    /// Clear validation cache
    public func clearValidationCache() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Certificate Pinning capability not available")
        }
        
        await _resources.clearValidationCache()
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}