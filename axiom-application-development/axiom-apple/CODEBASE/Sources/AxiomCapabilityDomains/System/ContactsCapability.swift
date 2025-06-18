import Foundation
import AxiomCapabilities
import AxiomCore
@preconcurrency import Contacts

// MARK: - Contacts Configuration

/// Configuration for Contacts capability
public struct ContactsConfiguration: AxiomCapabilityConfiguration {
    public let keysToFetch: [CNKeyDescriptor]
    public let requestTimeout: TimeInterval
    public let enableAutomaticSyncing: Bool
    public let sortOrder: CNContactSortOrder
    public let unifyResults: Bool
    
    public init(
        keysToFetch: [CNKeyDescriptor] = ContactsConfiguration.defaultKeys,
        requestTimeout: TimeInterval = 30.0,
        enableAutomaticSyncing: Bool = true,
        sortOrder: CNContactSortOrder = .userDefault,
        unifyResults: Bool = true
    ) {
        self.keysToFetch = keysToFetch
        self.requestTimeout = requestTimeout
        self.enableAutomaticSyncing = enableAutomaticSyncing
        self.sortOrder = sortOrder
        self.unifyResults = unifyResults
    }
    
    public var isValid: Bool {
        return requestTimeout > 0 && !keysToFetch.isEmpty
    }
    
    public func merged(with other: ContactsConfiguration) -> ContactsConfiguration {
        // Combine keys from both configurations
        let combinedKeys = Set(keysToFetch.map { $0.description }).union(Set(other.keysToFetch.map { $0.description }))
        let mergedKeys = Array(combinedKeys).compactMap { keyName -> CNKeyDescriptor? in
            // Find the actual CNKeyDescriptor for each unique key name
            return keysToFetch.first { $0.description == keyName } ?? other.keysToFetch.first { $0.description == keyName }
        }
        
        return ContactsConfiguration(
            keysToFetch: mergedKeys,
            requestTimeout: other.requestTimeout,
            enableAutomaticSyncing: other.enableAutomaticSyncing,
            sortOrder: other.sortOrder,
            unifyResults: other.unifyResults
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> ContactsConfiguration {
        var adjustedTimeout = requestTimeout
        var adjustedSyncing = enableAutomaticSyncing
        
        if environment.isLowPowerMode {
            adjustedTimeout *= 1.5
            adjustedSyncing = false // Disable automatic syncing to save battery
        }
        
        if environment.isDebug {
            adjustedTimeout *= 2.0
        }
        
        return ContactsConfiguration(
            keysToFetch: keysToFetch,
            requestTimeout: adjustedTimeout,
            enableAutomaticSyncing: adjustedSyncing,
            sortOrder: sortOrder,
            unifyResults: unifyResults
        )
    }
    
    // Default keys to fetch
    public static let defaultKeys: [CNKeyDescriptor] = [
        CNContactIdentifierKey as CNKeyDescriptor,
        CNContactGivenNameKey as CNKeyDescriptor,
        CNContactFamilyNameKey as CNKeyDescriptor,
        CNContactEmailAddressesKey as CNKeyDescriptor,
        CNContactPhoneNumbersKey as CNKeyDescriptor
    ]
    
    // Extended keys for more complete contact information
    public static let extendedKeys: [CNKeyDescriptor] = defaultKeys + [
        CNContactOrganizationNameKey as CNKeyDescriptor,
        CNContactJobTitleKey as CNKeyDescriptor,
        CNContactPostalAddressesKey as CNKeyDescriptor,
        CNContactBirthdayKey as CNKeyDescriptor,
        CNContactNoteKey as CNKeyDescriptor,
        CNContactImageDataKey as CNKeyDescriptor,
        CNContactUrlAddressesKey as CNKeyDescriptor,
        CNContactSocialProfilesKey as CNKeyDescriptor
    ]
    
    // Configuration presets
    public static let basic = ContactsConfiguration(
        keysToFetch: defaultKeys
    )
    
    public static let detailed = ContactsConfiguration(
        keysToFetch: extendedKeys
    )
}

// MARK: - ContactsConfiguration Codable Implementation

extension ContactsConfiguration: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // For CNKeyDescriptor and CNContactSortOrder that don't conform to Codable, use defaults
        self.keysToFetch = ContactsConfiguration.defaultKeys  // Use default keys
        self.sortOrder = .userDefault  // Use default sort order
        
        self.requestTimeout = try container.decode(TimeInterval.self, forKey: .requestTimeout)
        self.enableAutomaticSyncing = try container.decode(Bool.self, forKey: .enableAutomaticSyncing)
        self.unifyResults = try container.decode(Bool.self, forKey: .unifyResults)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode simple types only - complex Apple framework types would need specific handling
        try container.encode(requestTimeout, forKey: .requestTimeout)
        try container.encode(enableAutomaticSyncing, forKey: .enableAutomaticSyncing)
        try container.encode(unifyResults, forKey: .unifyResults)
    }
    
    private enum CodingKeys: String, CodingKey {
        case requestTimeout
        case enableAutomaticSyncing
        case unifyResults
    }
}

// MARK: - Contacts Data Types

/// Authorization status for Contacts
public enum ContactsAuthorizationStatus: Sendable, Codable {
    case notDetermined
    case restricted
    case denied
    case authorized
    
    public init(from status: CNAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .restricted:
            self = .restricted
        case .denied:
            self = .denied
        case .authorized:
            self = .authorized
        @unknown default:
            self = .notDetermined
        }
    }
}

/// Contact wrapper for safe passing across actor boundaries
public struct ContactData: Sendable, Codable {
    public let identifier: String
    public let givenName: String
    public let familyName: String
    public let organizationName: String
    public let jobTitle: String
    public let emailAddresses: [EmailAddress]
    public let phoneNumbers: [PhoneNumber]
    public let postalAddresses: [PostalAddress]
    public let birthday: DateComponents?
    public let note: String
    public let hasImageData: Bool
    public let urlAddresses: [URLAddress]
    public let socialProfiles: [SocialProfile]
    
    public struct EmailAddress: Sendable, Codable {
        public let label: String?
        public let value: String
        
        public init(label: String?, value: String) {
            self.label = label
            self.value = value
        }
    }
    
    public struct PhoneNumber: Sendable, Codable {
        public let label: String?
        public let value: String
        
        public init(label: String?, value: String) {
            self.label = label
            self.value = value
        }
    }
    
    public struct PostalAddress: Sendable, Codable {
        public let label: String?
        public let street: String
        public let city: String
        public let state: String
        public let postalCode: String
        public let country: String
        
        public init(label: String?, street: String, city: String, state: String, postalCode: String, country: String) {
            self.label = label
            self.street = street
            self.city = city
            self.state = state
            self.postalCode = postalCode
            self.country = country
        }
    }
    
    public struct URLAddress: Sendable, Codable {
        public let label: String?
        public let value: String
        
        public init(label: String?, value: String) {
            self.label = label
            self.value = value
        }
    }
    
    public struct SocialProfile: Sendable, Codable {
        public let label: String?
        public let service: String
        public let username: String
        
        public init(label: String?, service: String, username: String) {
            self.label = label
            self.service = service
            self.username = username
        }
    }
    
    public init(from contact: CNContact) {
        self.identifier = contact.identifier
        self.givenName = contact.givenName
        self.familyName = contact.familyName
        self.organizationName = contact.organizationName
        self.jobTitle = contact.jobTitle
        
        self.emailAddresses = contact.emailAddresses.map { labeledValue in
            EmailAddress(
                label: labeledValue.label,
                value: labeledValue.value as String
            )
        }
        
        self.phoneNumbers = contact.phoneNumbers.map { labeledValue in
            PhoneNumber(
                label: labeledValue.label,
                value: labeledValue.value.stringValue
            )
        }
        
        self.postalAddresses = contact.postalAddresses.map { labeledValue in
            let address = labeledValue.value
            return PostalAddress(
                label: labeledValue.label,
                street: address.street,
                city: address.city,
                state: address.state,
                postalCode: address.postalCode,
                country: address.country
            )
        }
        
        self.birthday = contact.birthday
        self.note = contact.note
        self.hasImageData = contact.imageData != nil
        
        self.urlAddresses = contact.urlAddresses.map { labeledValue in
            URLAddress(
                label: labeledValue.label,
                value: labeledValue.value as String
            )
        }
        
        self.socialProfiles = contact.socialProfiles.map { labeledValue in
            let profile = labeledValue.value
            return SocialProfile(
                label: labeledValue.label,
                service: profile.service,
                username: profile.username
            )
        }
    }
    
    public init(
        identifier: String = UUID().uuidString,
        givenName: String = "",
        familyName: String = "",
        organizationName: String = "",
        jobTitle: String = "",
        emailAddresses: [EmailAddress] = [],
        phoneNumbers: [PhoneNumber] = [],
        postalAddresses: [PostalAddress] = [],
        birthday: DateComponents? = nil,
        note: String = "",
        hasImageData: Bool = false,
        urlAddresses: [URLAddress] = [],
        socialProfiles: [SocialProfile] = []
    ) {
        self.identifier = identifier
        self.givenName = givenName
        self.familyName = familyName
        self.organizationName = organizationName
        self.jobTitle = jobTitle
        self.emailAddresses = emailAddresses
        self.phoneNumbers = phoneNumbers
        self.postalAddresses = postalAddresses
        self.birthday = birthday
        self.note = note
        self.hasImageData = hasImageData
        self.urlAddresses = urlAddresses
        self.socialProfiles = socialProfiles
    }
    
    /// Full name computed property
    public var fullName: String {
        let components = [givenName, familyName].filter { !$0.isEmpty }
        return components.joined(separator: " ")
    }
    
    /// Primary email address
    public var primaryEmail: String? {
        return emailAddresses.first?.value
    }
    
    /// Primary phone number
    public var primaryPhone: String? {
        return phoneNumbers.first?.value
    }
}

// MARK: - Contacts Resource

/// Resource management for Contacts
public actor ContactsResource: AxiomCapabilityResource {
    private var activeFetches: Set<UUID> = []
    private var _isAvailable: Bool = true
    private let configuration: ContactsConfiguration
    
    public init(configuration: ContactsConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 50_000_000, // 50MB max for contact data
            cpu: 12.0, // 12% CPU max
            bandwidth: 5_000, // 5KB/s for contact sync
            storage: 200_000_000 // 200MB for cached contact data
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let fetchCount = activeFetches.count
            let baseCPU = Double(fetchCount * 4) // 4% CPU per active fetch
            let baseMemory = fetchCount * 5_000_000 // 5MB per fetch
            
            return ResourceUsage(
                memory: baseMemory,
                cpu: baseCPU,
                bandwidth: fetchCount * 1_000, // 1KB/s per fetch
                storage: fetchCount * 20_000_000 // 20MB storage per fetch
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        return _isAvailable
    }
    
    public func release() async {
        activeFetches.removeAll()
    }
    
    public func addFetch(_ fetchId: UUID) async throws {
        guard await isAvailable() else {
            throw AxiomCapabilityError.resourceAllocationFailed("Contacts resources not available")
        }
        activeFetches.insert(fetchId)
    }
    
    public func removeFetch(_ fetchId: UUID) async {
        activeFetches.remove(fetchId)
    }
    
    public func setAvailable(_ available: Bool) async {
        _isAvailable = available
    }
}

// MARK: - Contacts Capability

/// Contacts capability providing access to the device's contact database
public actor ContactsCapability: DomainCapability {
    public typealias ConfigurationType = ContactsConfiguration
    public typealias ResourceType = ContactsResource
    
    private var _configuration: ContactsConfiguration
    private var _resources: ContactsResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .milliseconds(10)
    
    private var contactStore: CNContactStore?
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    private var contactStreamContinuation: AsyncStream<ContactData>.Continuation?
    
    public nonisolated var id: String { "contacts-capability" }
    
    public var isAvailable: Bool {
        get async { _state == .available }
    }
    
    public var state: AxiomCapabilityState {
        get async { _state }
    }
    
    public var stateStream: AsyncStream<AxiomCapabilityState> {
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                await self?.setStateStreamContinuation(continuation)
                if let currentState = await self?._state {
                    continuation.yield(currentState)
                }
            }
        }
    }
    
    public var activationTimeout: Duration {
        get async { _activationTimeout }
    }
    
    public var configuration: ContactsConfiguration {
        get async { _configuration }
    }
    
    public var resources: ContactsResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: ContactsConfiguration = ContactsConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = ContactsResource(configuration: self._configuration)
        self._environment = environment
    }
    
    private func setStateStreamContinuation(_ continuation: AsyncStream<AxiomCapabilityState>.Continuation) {
        self.stateStreamContinuation = continuation
    }
    
    private func setContactStreamContinuation(_ continuation: AsyncStream<ContactData>.Continuation) {
        self.contactStreamContinuation = continuation
    }
    
    // MARK: - DomainCapability Protocol
    
    public func updateConfiguration(_ configuration: ContactsConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Contacts configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
    }
    
    public func handleEnvironmentChange(_ environment: AxiomCapabilityEnvironment) async {
        _environment = environment
        let adjusted = _configuration.adjusted(for: environment)
        try? await updateConfiguration(adjusted)
    }
    
    // MARK: - ExtendedCapability Protocol
    
    public func isSupported() async -> Bool {
        return true // Contacts framework is available on all iOS devices
    }
    
    public func requestPermission() async throws {
        guard let store = contactStore else {
            throw AxiomCapabilityError.unavailable("Contacts store not initialized")
        }
        
        let status = CNContactStore.authorizationStatus(for: .contacts)
        
        if status == .notDetermined {
            let granted = try await store.requestAccess(for: .contacts)
            if !granted {
                throw AxiomCapabilityError.permissionRequired("Contacts access denied")
            }
        } else if status != .authorized {
            throw AxiomCapabilityError.permissionRequired("Contacts access not authorized")
        }
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Capability Protocol
    
    public func activate() async throws {
        guard await _resources.isAvailable() else {
            throw AxiomCapabilityError.initializationFailed("Contacts resources not available")
        }
        
        contactStore = CNContactStore()
        
        try await requestPermission()
        
        await transitionTo(.available)
    }
    
    public func deactivate() async {
        await transitionTo(.unavailable)
        await _resources.release()
        
        contactStore = nil
        stateStreamContinuation?.finish()
        contactStreamContinuation?.finish()
    }
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
    
    // MARK: - Contacts API
    
    /// Fetch all contacts
    public func getAllContacts() async throws -> [ContactData] {
        guard _state == .available else {
            throw AxiomCapabilityError.unavailable("Contacts capability not available")
        }
        
        guard let store = contactStore else {
            throw AxiomCapabilityError.unavailable("Contacts store not initialized")
        }
        
        let fetchId = UUID()
        try await _resources.addFetch(fetchId)
        defer {
            Task {
                await _resources.removeFetch(fetchId)
            }
        }
        
        let request = CNContactFetchRequest(keysToFetch: _configuration.keysToFetch)
        request.sortOrder = _configuration.sortOrder
        request.unifyResults = _configuration.unifyResults
        
        var contacts: [ContactData] = []
        
        try store.enumerateContacts(with: request) { contact, stop in
            let contactData = ContactData(from: contact)
            contacts.append(contactData)
        }
        
        return contacts
    }
    
    /// Fetch contacts matching predicate
    public func getContacts(matching predicate: NSPredicate) async throws -> [ContactData] {
        guard _state == .available else {
            throw AxiomCapabilityError.unavailable("Contacts capability not available")
        }
        
        guard let store = contactStore else {
            throw AxiomCapabilityError.unavailable("Contacts store not initialized")
        }
        
        let fetchId = UUID()
        try await _resources.addFetch(fetchId)
        defer {
            Task {
                await _resources.removeFetch(fetchId)
            }
        }
        
        let cnContacts = try store.unifiedContacts(
            matching: predicate,
            keysToFetch: _configuration.keysToFetch
        )
        
        return cnContacts.map { ContactData(from: $0) }
    }
    
    /// Search contacts by name
    public func searchContacts(byName name: String) async throws -> [ContactData] {
        let predicate = CNContact.predicateForContacts(matchingName: name)
        return try await getContacts(matching: predicate)
    }
    
    /// Search contacts by email
    public func searchContacts(byEmailAddress email: String) async throws -> [ContactData] {
        let predicate = CNContact.predicateForContacts(matchingEmailAddress: email)
        return try await getContacts(matching: predicate)
    }
    
    /// Search contacts by phone number
    public func searchContacts(byPhoneNumber phoneNumber: String) async throws -> [ContactData] {
        let phoneNumberValue = CNPhoneNumber(stringValue: phoneNumber)
        let predicate = CNContact.predicateForContacts(matching: phoneNumberValue)
        return try await getContacts(matching: predicate)
    }
    
    /// Get contact by identifier
    public func getContact(withIdentifier identifier: String) async throws -> ContactData? {
        guard _state == .available else {
            throw AxiomCapabilityError.unavailable("Contacts capability not available")
        }
        
        guard let store = contactStore else {
            throw AxiomCapabilityError.unavailable("Contacts store not initialized")
        }
        
        let fetchId = UUID()
        try await _resources.addFetch(fetchId)
        defer {
            Task {
                await _resources.removeFetch(fetchId)
            }
        }
        
        do {
            let contact = try store.unifiedContact(
                withIdentifier: identifier,
                keysToFetch: _configuration.keysToFetch
            )
            return ContactData(from: contact)
        } catch {
            return nil
        }
    }
    
    /// Create new contact
    public func createContact(
        givenName: String,
        familyName: String,
        emailAddresses: [ContactData.EmailAddress] = [],
        phoneNumbers: [ContactData.PhoneNumber] = [],
        organizationName: String = "",
        jobTitle: String = ""
    ) async throws -> ContactData {
        guard _state == .available else {
            throw AxiomCapabilityError.unavailable("Contacts capability not available")
        }
        
        guard let store = contactStore else {
            throw AxiomCapabilityError.unavailable("Contacts store not initialized")
        }
        
        let contact = CNMutableContact()
        contact.givenName = givenName
        contact.familyName = familyName
        contact.organizationName = organizationName
        contact.jobTitle = jobTitle
        
        // Add email addresses
        contact.emailAddresses = emailAddresses.map { email in
            CNLabeledValue(
                label: email.label,
                value: email.value as NSString
            )
        }
        
        // Add phone numbers
        contact.phoneNumbers = phoneNumbers.map { phone in
            CNLabeledValue(
                label: phone.label,
                value: CNPhoneNumber(stringValue: phone.value)
            )
        }
        
        let saveRequest = CNSaveRequest()
        saveRequest.add(contact, toContainerWithIdentifier: nil)
        
        try store.execute(saveRequest)
        
        let contactData = ContactData(from: contact)
        contactStreamContinuation?.yield(contactData)
        
        return contactData
    }
    
    /// Update existing contact
    public func updateContact(
        withIdentifier identifier: String,
        givenName: String? = nil,
        familyName: String? = nil,
        emailAddresses: [ContactData.EmailAddress]? = nil,
        phoneNumbers: [ContactData.PhoneNumber]? = nil,
        organizationName: String? = nil,
        jobTitle: String? = nil
    ) async throws -> ContactData {
        guard _state == .available else {
            throw AxiomCapabilityError.unavailable("Contacts capability not available")
        }
        
        guard let store = contactStore else {
            throw AxiomCapabilityError.unavailable("Contacts store not initialized")
        }
        
        // Fetch the existing contact
        let contact = try store.unifiedContact(
            withIdentifier: identifier,
            keysToFetch: _configuration.keysToFetch
        ).mutableCopy() as! CNMutableContact
        
        // Update fields if provided
        if let givenName = givenName { contact.givenName = givenName }
        if let familyName = familyName { contact.familyName = familyName }
        if let organizationName = organizationName { contact.organizationName = organizationName }
        if let jobTitle = jobTitle { contact.jobTitle = jobTitle }
        
        if let emailAddresses = emailAddresses {
            contact.emailAddresses = emailAddresses.map { email in
                CNLabeledValue(
                    label: email.label,
                    value: email.value as NSString
                )
            }
        }
        
        if let phoneNumbers = phoneNumbers {
            contact.phoneNumbers = phoneNumbers.map { phone in
                CNLabeledValue(
                    label: phone.label,
                    value: CNPhoneNumber(stringValue: phone.value)
                )
            }
        }
        
        let saveRequest = CNSaveRequest()
        saveRequest.update(contact)
        
        try store.execute(saveRequest)
        
        let contactData = ContactData(from: contact)
        contactStreamContinuation?.yield(contactData)
        
        return contactData
    }
    
    /// Delete contact
    public func deleteContact(withIdentifier identifier: String) async throws {
        guard _state == .available else {
            throw AxiomCapabilityError.unavailable("Contacts capability not available")
        }
        
        guard let store = contactStore else {
            throw AxiomCapabilityError.unavailable("Contacts store not initialized")
        }
        
        // Fetch the contact to delete
        let contact = try store.unifiedContact(
            withIdentifier: identifier,
            keysToFetch: [CNContactIdentifierKey as CNKeyDescriptor]
        ).mutableCopy() as! CNMutableContact
        
        let saveRequest = CNSaveRequest()
        saveRequest.delete(contact)
        
        try store.execute(saveRequest)
    }
    
    /// Get authorization status
    public func getAuthorizationStatus() async -> ContactsAuthorizationStatus {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        return ContactsAuthorizationStatus(from: status)
    }
    
    /// Get contact groups
    public func getContactGroups() async throws -> [CNGroup] {
        guard let store = contactStore else {
            throw AxiomCapabilityError.unavailable("Contacts store not initialized")
        }
        
        return try store.groups(matching: nil)
    }
    
    /// Stream of contact updates (when contacts are created/updated through this capability)
    public var contactUpdatesStream: AsyncStream<ContactData> {
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                await self?.setContactStreamContinuation(continuation)
            }
        }
    }
    
    /// Get contact image data
    public func getContactImage(withIdentifier identifier: String) async throws -> Data? {
        guard _state == .available else {
            throw AxiomCapabilityError.unavailable("Contacts capability not available")
        }
        
        guard let store = contactStore else {
            throw AxiomCapabilityError.unavailable("Contacts store not initialized")
        }
        
        let contact = try store.unifiedContact(
            withIdentifier: identifier,
            keysToFetch: [CNContactImageDataKey as CNKeyDescriptor]
        )
        
        return contact.imageData
    }
}

// MARK: - Registration Extension

extension AxiomCapabilityRegistry {
    /// Register Contacts capability
    public func registerContacts() async throws {
        let capability = ContactsCapability()
        try await register(
            capability,
            requirements: [
                AxiomCapabilityDiscoveryService.Requirement(
                    type: .systemFeature("Contacts"),
                    isMandatory: true
                ),
                AxiomCapabilityDiscoveryService.Requirement(
                    type: .permission("NSContactsUsageDescription"),
                    isMandatory: true
                )
            ],
            category: "contacts",
            metadata: AxiomCapabilityMetadata(
                name: "Contacts",
                description: "Device contacts access and management capability",
                version: "1.0.0",
                documentation: "Provides access to the device's contact database for reading, creating, updating, and deleting contacts",
                supportedPlatforms: ["iOS", "macOS"],
                minimumOSVersion: "14.0",
                tags: ["contacts", "people", "address book"],
                dependencies: ["Contacts"]
            )
        )
    }
}