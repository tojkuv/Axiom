import Foundation
import PassKit

// MARK: - Payment Processing Capabilities

/// Payment capability configuration
public struct PaymentCapabilityConfiguration: CapabilityConfiguration, Codable {
    public let merchantId: String
    // MVP: Removing non-Codable types
    // public let supportedNetworks: [PKPaymentNetwork]
    // public let merchantCapabilities: PKMerchantCapability
    public let countryCode: String
    public let currencyCode: String
    public let sandboxMode: Bool
    public let applePayEnabled: Bool
    
    public init(
        merchantId: String,
        // supportedNetworks: [PKPaymentNetwork] = [.visa, .masterCard, .amex],
        // merchantCapabilities: PKMerchantCapability = [.capability3DS],
        countryCode: String = "US",
        currencyCode: String = "USD",
        sandboxMode: Bool = true,
        applePayEnabled: Bool = true
    ) {
        self.merchantId = merchantId
        // self.supportedNetworks = supportedNetworks
        // self.merchantCapabilities = merchantCapabilities
        self.countryCode = countryCode
        self.currencyCode = currencyCode
        self.sandboxMode = sandboxMode
        self.applePayEnabled = applePayEnabled
    }
    
    public var isValid: Bool {
        !merchantId.isEmpty && !countryCode.isEmpty && !currencyCode.isEmpty
    }
    
    public func merged(with other: PaymentCapabilityConfiguration) -> PaymentCapabilityConfiguration {
        PaymentCapabilityConfiguration(
            merchantId: other.merchantId.isEmpty ? merchantId : other.merchantId,
            // supportedNetworks: other.supportedNetworks.isEmpty ? supportedNetworks : other.supportedNetworks,
            // merchantCapabilities: other.merchantCapabilities,
            countryCode: other.countryCode.isEmpty ? countryCode : other.countryCode,
            currencyCode: other.currencyCode.isEmpty ? currencyCode : other.currencyCode,
            sandboxMode: other.sandboxMode,
            applePayEnabled: other.applePayEnabled
        )
    }
    
    public func adjusted(for environment: CapabilityEnvironment) -> PaymentCapabilityConfiguration {
        PaymentCapabilityConfiguration(
            merchantId: merchantId,
            // supportedNetworks: supportedNetworks,
            // merchantCapabilities: merchantCapabilities,
            countryCode: countryCode,
            currencyCode: currencyCode,
            sandboxMode: environment.isDebug,
            applePayEnabled: applePayEnabled
        )
    }
}

/// Payment resource management
public actor PaymentCapabilityResource: CapabilityResource {
    private var paymentController: PKPaymentAuthorizationController?
    private let configuration: PaymentCapabilityConfiguration
    
    public init(configuration: PaymentCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            ResourceUsage(memory: 5_000_000) // 5MB for payment UI
        }
    }
    
    public let maxUsage = ResourceUsage(memory: 20_000_000) // 20MB max
    
    public func isAvailable() async -> Bool {
        // MVP: Using default supported networks
        let defaultNetworks: [PKPaymentNetwork] = [.visa, .masterCard, .amex]
        return PKPaymentAuthorizationController.canMakePayments(usingNetworks: defaultNetworks)
    }
    
    public func allocate() async throws {
        guard await isAvailable() else {
            throw CapabilityError.notAvailable("Apple Pay not available")
        }
    }
    
    public func release() async {
        paymentController = nil
    }
}

/// Payment capability implementation
public actor PaymentCapability: ExtendedCapability {
    private var _configuration: PaymentCapabilityConfiguration
    private var _resources: PaymentCapabilityResource
    private var _environment: CapabilityEnvironment
    private var _state: CapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(30)
    
    public init(
        configuration: PaymentCapabilityConfiguration,
        environment: CapabilityEnvironment = CapabilityEnvironment(isDebug: true)
    ) {
        self._configuration = configuration
        self._resources = PaymentCapabilityResource(configuration: configuration)
        self._environment = environment
    }
    
    // MARK: - DomainCapability Protocol
    
    public var configuration: PaymentCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: PaymentCapabilityResource {
        get async { _resources }
    }
    
    public var environment: CapabilityEnvironment {
        get async { _environment }
    }
    
    public func updateConfiguration(_ configuration: PaymentCapabilityConfiguration) async throws {
        _configuration = configuration.adjusted(for: _environment)
        _resources = PaymentCapabilityResource(configuration: _configuration)
    }
    
    public func handleEnvironmentChange(_ environment: CapabilityEnvironment) async {
        _environment = environment
        let adjustedConfig = _configuration.adjusted(for: environment)
        try? await updateConfiguration(adjustedConfig)
    }
    
    // MARK: - ExtendedCapability Protocol
    
    public var state: CapabilityState {
        get async { _state }
    }
    
    public var stateStream: AsyncStream<CapabilityState> {
        get async {
            AsyncStream { continuation in
                continuation.yield(_state)
                continuation.finish()
            }
        }
    }
    
    public func isSupported() async -> Bool {
        PKPaymentAuthorizationController.canMakePayments()
    }
    
    public func requestPermission() async throws {
        // Payment capabilities use system authorization
    }
    
    public var activationTimeout: Duration {
        get async { _activationTimeout }
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Capability Protocol
    
    public var isAvailable: Bool {
        get async { _state == .available }
    }
    
    public func activate() async throws {
        guard await isSupported() else {
            _state = .unavailable
            throw CapabilityError.notAvailable("Apple Pay not supported")
        }
        
        try await _resources.allocate()
        _state = .available
    }
    
    public func deactivate() async {
        await _resources.release()
        _state = .unavailable
    }
    
    // MARK: - Payment-Specific Methods
    
    public func processPayment(
        amount: Decimal,
        description: String,
        shippingType: PKShippingType = .shipping
    ) async throws -> PaymentResult {
        guard _state == .available else {
            throw CapabilityError.notAvailable("Payment capability not available")
        }
        
        let request = PKPaymentRequest()
        request.merchantIdentifier = _configuration.merchantId
        // MVP: Using default values
        request.supportedNetworks = [.visa, .masterCard, .amex]
        request.merchantCapabilities = [.capability3DS]
        request.countryCode = _configuration.countryCode
        request.currencyCode = _configuration.currencyCode
        request.shippingType = shippingType
        
        let summaryItem = PKPaymentSummaryItem(
            label: description,
            amount: NSDecimalNumber(decimal: amount)
        )
        request.paymentSummaryItems = [summaryItem]
        
        // In real implementation, present payment authorization controller
        // For now, simulate processing
        try await Task.sleep(for: .seconds(2))
        
        return PaymentResult(
            status: .success,
            transactionId: UUID().uuidString,
            amount: amount,
            currency: _configuration.currencyCode
        )
    }
    
    public func validateMerchant() async throws -> Bool {
        // Validate merchant configuration
        return _configuration.isValid
    }
}

/// Payment processing result
public struct PaymentResult: Codable, Sendable {
    public enum Status: String, Codable {
        case success
        case failed
        case cancelled
        case pending
    }
    
    public let status: Status
    public let transactionId: String
    public let amount: Decimal
    public let currency: String
    public let timestamp = Date()
    
    public init(status: Status, transactionId: String, amount: Decimal, currency: String) {
        self.status = status
        self.transactionId = transactionId
        self.amount = amount
        self.currency = currency
    }
}