import Foundation

public struct Contact: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let identifier: String
    public let givenName: String
    public let familyName: String
    public let middleName: String?
    public let organizationName: String?
    public let jobTitle: String?
    public let phoneNumbers: [PhoneNumber]
    public let emailAddresses: [EmailAddress]
    public let postalAddresses: [PostalAddress]
    public let birthday: DateComponents?
    public let note: String?
    public let imageData: Data?
    public let associatedTaskIds: [UUID]
    public let lastContactDate: Date?
    public let contactFrequency: ContactFrequency?
    
    public init(
        id: UUID = UUID(),
        identifier: String,
        givenName: String,
        familyName: String,
        middleName: String? = nil,
        organizationName: String? = nil,
        jobTitle: String? = nil,
        phoneNumbers: [PhoneNumber] = [],
        emailAddresses: [EmailAddress] = [],
        postalAddresses: [PostalAddress] = [],
        birthday: DateComponents? = nil,
        note: String? = nil,
        imageData: Data? = nil,
        associatedTaskIds: [UUID] = [],
        lastContactDate: Date? = nil,
        contactFrequency: ContactFrequency? = nil
    ) {
        self.id = id
        self.identifier = identifier
        self.givenName = givenName
        self.familyName = familyName
        self.middleName = middleName
        self.organizationName = organizationName
        self.jobTitle = jobTitle
        self.phoneNumbers = phoneNumbers
        self.emailAddresses = emailAddresses
        self.postalAddresses = postalAddresses
        self.birthday = birthday
        self.note = note
        self.imageData = imageData
        self.associatedTaskIds = associatedTaskIds
        self.lastContactDate = lastContactDate
        self.contactFrequency = contactFrequency
    }
    
    public var fullName: String {
        let components = [givenName, middleName, familyName].compactMap { $0 }
        return components.joined(separator: " ")
    }
    
    public var displayName: String {
        if !givenName.isEmpty || !familyName.isEmpty {
            return fullName
        } else if let organization = organizationName, !organization.isEmpty {
            return organization
        } else {
            return "Unknown Contact"
        }
    }
    
    public var initials: String {
        let firstInitial = givenName.first.map(String.init) ?? ""
        let lastInitial = familyName.first.map(String.init) ?? ""
        return (firstInitial + lastInitial).uppercased()
    }
}

public struct PhoneNumber: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let value: String
    public let label: String?
    
    public init(id: UUID = UUID(), value: String, label: String? = nil) {
        self.id = id
        self.value = value
        self.label = label
    }
}

public struct EmailAddress: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let value: String
    public let label: String?
    
    public init(id: UUID = UUID(), value: String, label: String? = nil) {
        self.id = id
        self.value = value
        self.label = label
    }
}

public struct PostalAddress: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let street: String?
    public let city: String?
    public let state: String?
    public let postalCode: String?
    public let country: String?
    public let label: String?
    
    public init(
        id: UUID = UUID(),
        street: String? = nil,
        city: String? = nil,
        state: String? = nil,
        postalCode: String? = nil,
        country: String? = nil,
        label: String? = nil
    ) {
        self.id = id
        self.street = street
        self.city = city
        self.state = state
        self.postalCode = postalCode
        self.country = country
        self.label = label
    }
    
    public var formattedAddress: String {
        let components = [street, city, state, postalCode, country].compactMap { $0 }
        return components.joined(separator: ", ")
    }
}

public enum ContactFrequency: String, CaseIterable, Codable, Hashable, Sendable {
    case daily = "daily"
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case yearly = "yearly"
    case never = "never"
    
    public var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .biweekly: return "Bi-weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .yearly: return "Yearly"
        case .never: return "Never"
        }
    }
    
    public var interval: TimeInterval? {
        switch self {
        case .daily: return 86400
        case .weekly: return 604800
        case .biweekly: return 1209600
        case .monthly: return 2629746
        case .quarterly: return 7889238
        case .yearly: return 31556952
        case .never: return nil
        }
    }
}