import Foundation

public struct HealthMetric: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let type: HealthMetricType
    public let value: Double
    public let unit: String
    public let date: Date
    public let source: String?
    public let metadata: [String: String]
    
    public init(
        id: UUID = UUID(),
        type: HealthMetricType,
        value: Double,
        unit: String,
        date: Date,
        source: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.type = type
        self.value = value
        self.unit = unit
        self.date = date
        self.source = source
        self.metadata = metadata
    }
}

public enum HealthMetricType: String, CaseIterable, Codable, Hashable, Sendable {
    case stepCount = "stepCount"
    case heartRate = "heartRate"
    case activeEnergy = "activeEnergy"
    case distanceWalking = "distanceWalking"
    case flightsClimbed = "flightsClimbed"
    case bodyMass = "bodyMass"
    case height = "height"
    case sleepAnalysis = "sleepAnalysis"
    case workoutTime = "workoutTime"
    case mindfulSession = "mindfulSession"
    
    public var displayName: String {
        switch self {
        case .stepCount: return "Step Count"
        case .heartRate: return "Heart Rate"
        case .activeEnergy: return "Active Energy"
        case .distanceWalking: return "Walking Distance"
        case .flightsClimbed: return "Flights Climbed"
        case .bodyMass: return "Body Mass"
        case .height: return "Height"
        case .sleepAnalysis: return "Sleep Analysis"
        case .workoutTime: return "Workout Time"
        case .mindfulSession: return "Mindful Session"
        }
    }
}

public struct LocationData: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let latitude: Double
    public let longitude: Double
    public let altitude: Double?
    public let horizontalAccuracy: Double
    public let verticalAccuracy: Double?
    public let timestamp: Date
    public let speed: Double?
    public let course: Double?
    public let locationName: String?
    public let address: String?
    public let visitType: LocationVisitType?
    
    public init(
        id: UUID = UUID(),
        latitude: Double,
        longitude: Double,
        altitude: Double? = nil,
        horizontalAccuracy: Double,
        verticalAccuracy: Double? = nil,
        timestamp: Date,
        speed: Double? = nil,
        course: Double? = nil,
        locationName: String? = nil,
        address: String? = nil,
        visitType: LocationVisitType? = nil
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
        self.timestamp = timestamp
        self.speed = speed
        self.course = course
        self.locationName = locationName
        self.address = address
        self.visitType = visitType
    }
}

public enum LocationVisitType: String, Codable, Equatable, Hashable, Sendable {
    case home = "home"
    case work = "work"
    case school = "school"
    case gym = "gym"
    case restaurant = "restaurant"
    case store = "store"
    case unknown = "unknown"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

public struct MovementPattern: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let startDate: Date
    public let endDate: Date
    public let activityType: ActivityType
    public let distance: Double?
    public let duration: TimeInterval
    public let locations: [LocationData]
    public let averageSpeed: Double?
    public let calories: Double?
    
    public init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date,
        activityType: ActivityType,
        distance: Double? = nil,
        duration: TimeInterval,
        locations: [LocationData] = [],
        averageSpeed: Double? = nil,
        calories: Double? = nil
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.activityType = activityType
        self.distance = distance
        self.duration = duration
        self.locations = locations
        self.averageSpeed = averageSpeed
        self.calories = calories
    }
}

public enum ActivityType: String, CaseIterable, Codable, Hashable, Sendable {
    case walking = "walking"
    case running = "running"
    case cycling = "cycling"
    case driving = "driving"
    case stationary = "stationary"
    case unknown = "unknown"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}