import Foundation
import Contacts
import AxiomCore
import AxiomCapabilities

// MARK: - Contacts Sendable Conformance
// Contacts framework types don't conform to Sendable by default
extension CNContact: @unchecked Sendable {}
extension CNMutableContact: @unchecked Sendable {}

public actor ContactsCapability: AxiomCapability {
    public let id = UUID()
    public let name = "Contacts"
    public let version = "1.0.0"
    
    private let contactStore = CNContactStore()
    private var authorizationStatus: CNAuthorizationStatus = .notDetermined
    
    public init() {}
    
    public func activate() async throws {
        authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        
        if authorizationStatus == .notDetermined {
            try await requestAccess()
        } else if authorizationStatus != .authorized {
            throw ContactsError.accessDenied
        }
    }
    
    public func deactivate() async {
        // Contacts framework doesn't require explicit deactivation
    }
    
    public var isAvailable: Bool {
        return authorizationStatus == .authorized
    }
    
    private func requestAccess() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            contactStore.requestAccess(for: .contacts) { [weak self] granted, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if granted {
                    Task { [weak self] in
                        await self?.updateAuthorizationStatus(.authorized)
                    }
                    continuation.resume()
                } else {
                    Task { [weak self] in
                        await self?.updateAuthorizationStatus(.denied)
                    }
                    continuation.resume(throwing: ContactsError.accessDenied)
                }
            }
        }
    }
    
    // MARK: - Contact Fetching
    
    public func getAllContacts() async throws -> [CNContact] {
        guard isAvailable else {
            throw ContactsError.accessDenied
        }
        
        let keys = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactMiddleNameKey,
            CNContactOrganizationNameKey,
            CNContactJobTitleKey,
            CNContactPhoneNumbersKey,
            CNContactEmailAddressesKey,
            CNContactPostalAddressesKey,
            CNContactBirthdayKey,
            CNContactNoteKey,
            CNContactImageDataKey,
            CNContactIdentifierKey
        ] as [CNKeyDescriptor]
        
        let request = CNContactFetchRequest(keysToFetch: keys)
        var contacts: [CNContact] = []
        
        try contactStore.enumerateContacts(with: request) { contact, _ in
            contacts.append(contact)
        }
        
        return contacts
    }
    
    public func getContact(withIdentifier identifier: String) async throws -> CNContact? {
        guard isAvailable else {
            throw ContactsError.accessDenied
        }
        
        let keys = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactMiddleNameKey,
            CNContactOrganizationNameKey,
            CNContactJobTitleKey,
            CNContactPhoneNumbersKey,
            CNContactEmailAddressesKey,
            CNContactPostalAddressesKey,
            CNContactBirthdayKey,
            CNContactNoteKey,
            CNContactImageDataKey,
            CNContactIdentifierKey
        ] as [CNKeyDescriptor]
        
        do {
            return try contactStore.unifiedContact(withIdentifier: identifier, keysToFetch: keys)
        } catch {
            return nil
        }
    }
    
    public func searchContacts(matching name: String) async throws -> [CNContact] {
        guard isAvailable else {
            throw ContactsError.accessDenied
        }
        
        let keys = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactMiddleNameKey,
            CNContactOrganizationNameKey,
            CNContactJobTitleKey,
            CNContactPhoneNumbersKey,
            CNContactEmailAddressesKey,
            CNContactPostalAddressesKey,
            CNContactBirthdayKey,
            CNContactNoteKey,
            CNContactImageDataKey,
            CNContactIdentifierKey
        ] as [CNKeyDescriptor]
        
        let predicate = CNContact.predicateForContacts(matchingName: name)
        return try contactStore.unifiedContacts(matching: predicate, keysToFetch: keys)
    }
    
    // MARK: - Contact Modification
    
    public func createContact(_ contact: CNMutableContact) async throws -> CNContact {
        guard isAvailable else {
            throw ContactsError.accessDenied
        }
        
        let request = CNSaveRequest()
        request.add(contact, toContainerWithIdentifier: nil)
        
        do {
            try contactStore.execute(request)
            return contact
        } catch {
            throw ContactsError.saveFailed(error)
        }
    }
    
    public func updateContact(_ contact: CNMutableContact) async throws {
        guard isAvailable else {
            throw ContactsError.accessDenied
        }
        
        let request = CNSaveRequest()
        request.update(contact)
        
        do {
            try contactStore.execute(request)
        } catch {
            throw ContactsError.saveFailed(error)
        }
    }
    
    public func deleteContact(_ contact: CNMutableContact) async throws {
        guard isAvailable else {
            throw ContactsError.accessDenied
        }
        
        let request = CNSaveRequest()
        request.delete(contact)
        
        do {
            try contactStore.execute(request)
        } catch {
            throw ContactsError.deleteFailed(error)
        }
    }
    
    // MARK: - Conversion Methods
    
    public func convertToContact(_ cnContact: CNContact) -> Contact {
        let phoneNumbers = cnContact.phoneNumbers.map { phoneNumber in
            PhoneNumber(
                value: phoneNumber.value.stringValue,
                label: CNLabeledValue<CNPhoneNumber>.localizedString(forLabel: phoneNumber.label ?? "")
            )
        }
        
        let emailAddresses = cnContact.emailAddresses.map { emailAddress in
            EmailAddress(
                value: emailAddress.value as String,
                label: CNLabeledValue<NSString>.localizedString(forLabel: emailAddress.label ?? "")
            )
        }
        
        let postalAddresses = cnContact.postalAddresses.map { postalAddress in
            let address = postalAddress.value
            return PostalAddress(
                street: address.street,
                city: address.city,
                state: address.state,
                postalCode: address.postalCode,
                country: address.country,
                label: CNLabeledValue<CNPostalAddress>.localizedString(forLabel: postalAddress.label ?? "")
            )
        }
        
        return Contact(
            identifier: cnContact.identifier,
            givenName: cnContact.givenName,
            familyName: cnContact.familyName,
            middleName: cnContact.middleName.isEmpty ? nil : cnContact.middleName,
            organizationName: cnContact.organizationName.isEmpty ? nil : cnContact.organizationName,
            jobTitle: cnContact.jobTitle.isEmpty ? nil : cnContact.jobTitle,
            phoneNumbers: phoneNumbers,
            emailAddresses: emailAddresses,
            postalAddresses: postalAddresses,
            birthday: cnContact.birthday,
            note: cnContact.note.isEmpty ? nil : cnContact.note,
            imageData: cnContact.imageData
        )
    }
    
    public func convertToCNContact(_ contact: Contact) -> CNMutableContact {
        let cnContact = CNMutableContact()
        
        cnContact.givenName = contact.givenName
        cnContact.familyName = contact.familyName
        cnContact.middleName = contact.middleName ?? ""
        cnContact.organizationName = contact.organizationName ?? ""
        cnContact.jobTitle = contact.jobTitle ?? ""
        cnContact.note = contact.note ?? ""
        
        if let birthday = contact.birthday {
            cnContact.birthday = birthday
        }
        
        if let imageData = contact.imageData {
            cnContact.imageData = imageData
        }
        
        // Phone numbers
        let cnPhoneNumbers = contact.phoneNumbers.map { phoneNumber in
            CNLabeledValue(
                label: phoneNumber.label,
                value: CNPhoneNumber(stringValue: phoneNumber.value)
            )
        }
        cnContact.phoneNumbers = cnPhoneNumbers
        
        // Email addresses
        let cnEmailAddresses = contact.emailAddresses.map { emailAddress in
            CNLabeledValue(
                label: emailAddress.label,
                value: emailAddress.value as NSString
            )
        }
        cnContact.emailAddresses = cnEmailAddresses
        
        // Postal addresses
        let cnPostalAddresses = contact.postalAddresses.map { postalAddress in
            let cnPostalAddress = CNMutablePostalAddress()
            cnPostalAddress.street = postalAddress.street ?? ""
            cnPostalAddress.city = postalAddress.city ?? ""
            cnPostalAddress.state = postalAddress.state ?? ""
            cnPostalAddress.postalCode = postalAddress.postalCode ?? ""
            cnPostalAddress.country = postalAddress.country ?? ""
            
            return CNLabeledValue(
                label: postalAddress.label,
                value: cnPostalAddress
            )
        }
        cnContact.postalAddresses = cnPostalAddresses.map { labeledValue in
            CNLabeledValue(label: labeledValue.label, value: labeledValue.value.copy() as! CNPostalAddress)
        }
        
        return cnContact
    }
    
    // MARK: - Batch Operations
    
    public func getAllContactsAsContacts() async throws -> [Contact] {
        let cnContacts = try await getAllContacts()
        return cnContacts.map { convertToContact($0) }
    }
    
    public func searchContactsAsContacts(matching name: String) async throws -> [Contact] {
        let cnContacts = try await searchContacts(matching: name)
        return cnContacts.map { convertToContact($0) }
    }
    
    public func createContactFromContact(_ contact: Contact) async throws -> Contact {
        let cnContact = convertToCNContact(contact)
        let savedContact = try await createContact(cnContact)
        return convertToContact(savedContact)
    }
    
    // MARK: - Advanced Search
    
    public func getContactsWithEmailAddress(_ emailAddress: String) async throws -> [Contact] {
        guard isAvailable else {
            throw ContactsError.accessDenied
        }
        
        let keys = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactMiddleNameKey,
            CNContactOrganizationNameKey,
            CNContactJobTitleKey,
            CNContactPhoneNumbersKey,
            CNContactEmailAddressesKey,
            CNContactPostalAddressesKey,
            CNContactBirthdayKey,
            CNContactNoteKey,
            CNContactImageDataKey,
            CNContactIdentifierKey
        ] as [CNKeyDescriptor]
        
        let predicate = CNContact.predicateForContacts(matchingEmailAddress: emailAddress)
        let cnContacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: keys)
        return cnContacts.map { convertToContact($0) }
    }
    
    public func getContactsWithPhoneNumber(_ phoneNumber: String) async throws -> [Contact] {
        guard isAvailable else {
            throw ContactsError.accessDenied
        }
        
        let keys = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactMiddleNameKey,
            CNContactOrganizationNameKey,
            CNContactJobTitleKey,
            CNContactPhoneNumbersKey,
            CNContactEmailAddressesKey,
            CNContactPostalAddressesKey,
            CNContactBirthdayKey,
            CNContactNoteKey,
            CNContactImageDataKey,
            CNContactIdentifierKey
        ] as [CNKeyDescriptor]
        
        let phoneNumberToSearch = CNPhoneNumber(stringValue: phoneNumber)
        let predicate = CNContact.predicateForContacts(matching: phoneNumberToSearch)
        let cnContacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: keys)
        return cnContacts.map { convertToContact($0) }
    }
    
    public func getContactsInGroup(_ group: CNGroup) async throws -> [Contact] {
        guard isAvailable else {
            throw ContactsError.accessDenied
        }
        
        let keys = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactMiddleNameKey,
            CNContactOrganizationNameKey,
            CNContactJobTitleKey,
            CNContactPhoneNumbersKey,
            CNContactEmailAddressesKey,
            CNContactPostalAddressesKey,
            CNContactBirthdayKey,
            CNContactNoteKey,
            CNContactImageDataKey,
            CNContactIdentifierKey
        ] as [CNKeyDescriptor]
        
        let predicate = CNContact.predicateForContactsInGroup(withIdentifier: group.identifier)
        let cnContacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: keys)
        return cnContacts.map { convertToContact($0) }
    }
    
    // MARK: - Groups
    
    public func getAllGroups() async throws -> [CNGroup] {
        guard isAvailable else {
            throw ContactsError.accessDenied
        }
        
        let predicate = CNGroup.predicateForGroups(withIdentifiers: [])
        return try contactStore.groups(matching: predicate)
    }
    
    public func createGroup(name: String) async throws -> CNGroup {
        guard isAvailable else {
            throw ContactsError.accessDenied
        }
        
        let group = CNMutableGroup()
        group.name = name
        
        let request = CNSaveRequest()
        request.add(group, toContainerWithIdentifier: nil)
        
        do {
            try contactStore.execute(request)
            return group
        } catch {
            throw ContactsError.saveFailed(error)
        }
    }
    
    // MARK: - Statistics
    
    public func getContactCount() async throws -> Int {
        let contacts = try await getAllContacts()
        return contacts.count
    }
    
    public func getContactsWithBirthdays() async throws -> [Contact] {
        let allContacts = try await getAllContactsAsContacts()
        return allContacts.filter { $0.birthday != nil }
    }
    
    public func getContactsWithImages() async throws -> [Contact] {
        let allContacts = try await getAllContactsAsContacts()
        return allContacts.filter { $0.imageData != nil }
    }
    
    // MARK: - Helper Methods
    
    private func updateAuthorizationStatus(_ status: CNAuthorizationStatus) {
        authorizationStatus = status
    }
}

public enum ContactsError: Error, LocalizedError {
    case accessDenied
    case contactNotFound
    case groupNotFound
    case saveFailed(Error)
    case deleteFailed(Error)
    case searchFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Access to contacts was denied"
        case .contactNotFound:
            return "Contact not found"
        case .groupNotFound:
            return "Contact group not found"
        case .saveFailed(let error):
            return "Failed to save contact: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete contact: \(error.localizedDescription)"
        case .searchFailed(let error):
            return "Failed to search contacts: \(error.localizedDescription)"
        }
    }
}