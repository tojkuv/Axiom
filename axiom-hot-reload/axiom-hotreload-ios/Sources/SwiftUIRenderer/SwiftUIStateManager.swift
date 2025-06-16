import SwiftUI
import Combine
import HotReloadProtocol

@MainActor
public final class SwiftUIStateManager: ObservableObject {
    
    // Published state storage
    @Published private var stringStates: [String: String] = [:]
    @Published private var boolStates: [String: Bool] = [:]
    @Published private var intStates: [String: Int] = [:]
    @Published private var doubleStates: [String: Double] = [:]
    @Published private var arrayStates: [String: [AnyCodable]] = [:]
    @Published private var dictionaryStates: [String: [String: AnyCodable]] = [:]
    
    private var cancellables = Set<AnyCancellable>()
    private let configuration: SwiftUIStateConfiguration
    
    // State change callbacks
    private var stateChangeCallbacks: [String: (Any) -> Void] = [:]
    
    public init(configuration: SwiftUIStateConfiguration = SwiftUIStateConfiguration()) {
        self.configuration = configuration
        setupStateObservation()
    }
    
    // MARK: - State Management
    
    public func setState(key: String, value: StateValue) {
        switch value {
        case .string(let stringValue):
            stringStates[key] = stringValue
        case .int(let intValue):
            intStates[key] = intValue
        case .double(let doubleValue):
            doubleStates[key] = doubleValue
        case .bool(let boolValue):
            boolStates[key] = boolValue
        case .array(let arrayValue):
            arrayStates[key] = arrayValue.map { AnyCodable($0) }
        case .dictionary(let dictValue):
            dictionaryStates[key] = dictValue.mapValues { AnyCodable($0) }
        case .nullValue:
            clearState(for: key)
        }
        
        // Notify callback if registered
        if let callback = stateChangeCallbacks[key] {
            callback(getStateValue(for: key) ?? "")
        }
    }
    
    public func updateState(_ stateData: [String: AnyCodable], preserveExisting: Bool = true) {
        for (key, value) in stateData {
            if !preserveExisting || getStateValue(for: key) == nil {
                setStateFromAnyCodable(key: key, value: value)
            }
        }
    }
    
    public func getStateValue(for key: String) -> Any? {
        if let value = stringStates[key] { return value }
        if let value = boolStates[key] { return value }
        if let value = intStates[key] { return value }
        if let value = doubleStates[key] { return value }
        if let value = arrayStates[key] { return value }
        if let value = dictionaryStates[key] { return value }
        return nil
    }
    
    public func clearState(for key: String) {
        stringStates.removeValue(forKey: key)
        boolStates.removeValue(forKey: key)
        intStates.removeValue(forKey: key)
        doubleStates.removeValue(forKey: key)
        arrayStates.removeValue(forKey: key)
        dictionaryStates.removeValue(forKey: key)
        stateChangeCallbacks.removeValue(forKey: key)
    }
    
    public func clearAllState() {
        stringStates.removeAll()
        boolStates.removeAll()
        intStates.removeAll()
        doubleStates.removeAll()
        arrayStates.removeAll()
        dictionaryStates.removeAll()
        stateChangeCallbacks.removeAll()
    }
    
    public func getAllState() -> [String: AnyCodable] {
        var allState: [String: AnyCodable] = [:]
        
        for (key, value) in stringStates {
            allState[key] = AnyCodable(value)
        }
        for (key, value) in boolStates {
            allState[key] = AnyCodable(value)
        }
        for (key, value) in intStates {
            allState[key] = AnyCodable(value)
        }
        for (key, value) in doubleStates {
            allState[key] = AnyCodable(value)
        }
        for (key, value) in arrayStates {
            allState[key] = AnyCodable(value)
        }
        for (key, value) in dictionaryStates {
            allState[key] = AnyCodable(value)
        }
        
        return allState
    }
    
    // MARK: - Binding Creation
    
    public func getStringBinding(for key: String, defaultValue: String = "") -> Binding<String> {
        // Ensure the key exists in stringStates
        if stringStates[key] == nil {
            stringStates[key] = defaultValue
        }
        
        return Binding<String>(
            get: {
                return self.stringStates[key] ?? defaultValue
            },
            set: { newValue in
                self.stringStates[key] = newValue
                self.notifyStateChange(key: key, value: newValue)
            }
        )
    }
    
    public func getBooleanBinding(for key: String, defaultValue: Bool = false) -> Binding<Bool> {
        // Ensure the key exists in boolStates
        if boolStates[key] == nil {
            boolStates[key] = defaultValue
        }
        
        return Binding<Bool>(
            get: {
                return self.boolStates[key] ?? defaultValue
            },
            set: { newValue in
                self.boolStates[key] = newValue
                self.notifyStateChange(key: key, value: newValue)
            }
        )
    }
    
    public func getIntBinding(for key: String, defaultValue: Int = 0) -> Binding<Int> {
        // Ensure the key exists in intStates
        if intStates[key] == nil {
            intStates[key] = defaultValue
        }
        
        return Binding<Int>(
            get: {
                return self.intStates[key] ?? defaultValue
            },
            set: { newValue in
                self.intStates[key] = newValue
                self.notifyStateChange(key: key, value: newValue)
            }
        )
    }
    
    public func getDoubleBinding(for key: String, defaultValue: Double = 0.0) -> Binding<Double> {
        // Ensure the key exists in doubleStates
        if doubleStates[key] == nil {
            doubleStates[key] = defaultValue
        }
        
        return Binding<Double>(
            get: {
                return self.doubleStates[key] ?? defaultValue
            },
            set: { newValue in
                self.doubleStates[key] = newValue
                self.notifyStateChange(key: key, value: newValue)
            }
        )
    }
    
    public func getArrayBinding<T>(for key: String, type: T.Type, defaultValue: [T] = []) -> Binding<[T]> {
        return Binding<[T]>(
            get: {
                guard let arrayState = self.arrayStates[key] else {
                    return defaultValue
                }
                return arrayState.compactMap { $0.value as? T }
            },
            set: { newValue in
                self.arrayStates[key] = newValue.map { AnyCodable($0) }
                self.notifyStateChange(key: key, value: newValue)
            }
        )
    }
    
    // MARK: - State Change Observation
    
    public func onStateChange(for key: String, callback: @escaping (Any) -> Void) {
        stateChangeCallbacks[key] = callback
    }
    
    public func removeStateChangeCallback(for key: String) {
        stateChangeCallbacks.removeValue(forKey: key)
    }
    
    private func notifyStateChange(key: String, value: Any) {
        if let callback = stateChangeCallbacks[key] {
            callback(value)
        }
        
        // Notify hot reload system if enabled
        if configuration.enableHotReloadSync {
            notifyHotReloadSystem(key: key, value: value)
        }
    }
    
    private func setupStateObservation() {
        // Observe state changes for debugging
        if configuration.enableStateLogging {
            // String states
            $stringStates
                .sink { states in
                    print("🔄 String states changed: \(states)")
                }
                .store(in: &cancellables)
            
            // Bool states
            $boolStates
                .sink { states in
                    print("🔄 Bool states changed: \(states)")
                }
                .store(in: &cancellables)
            
            // Int states
            $intStates
                .sink { states in
                    print("🔄 Int states changed: \(states)")
                }
                .store(in: &cancellables)
            
            // Double states
            $doubleStates
                .sink { states in
                    print("🔄 Double states changed: \(states)")
                }
                .store(in: &cancellables)
        }
    }
    
    // MARK: - State Persistence
    
    public func saveStateToDisk(fileName: String = "hotreload_state.json") {
        guard configuration.enableStatePersistence else { return }
        
        let allState = getAllState()
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(allState)
            
            if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = documentsDirectory.appendingPathComponent(fileName)
                try data.write(to: fileURL)
                
                if configuration.enableStateLogging {
                    print("💾 State saved to: \(fileURL.path)")
                }
            }
        } catch {
            print("❌ Failed to save state: \(error)")
        }
    }
    
    public func loadStateFromDisk(fileName: String = "hotreload_state.json") {
        guard configuration.enableStatePersistence else { return }
        
        do {
            if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = documentsDirectory.appendingPathComponent(fileName)
                let data = try Data(contentsOf: fileURL)
                
                let decoder = JSONDecoder()
                let savedState = try decoder.decode([String: AnyCodable].self, from: data)
                
                updateState(savedState, preserveExisting: false)
                
                if configuration.enableStateLogging {
                    print("📂 State loaded from: \(fileURL.path)")
                }
            }
        } catch {
            if configuration.enableStateLogging {
                print("⚠️ Failed to load state (this is normal on first run): \(error)")
            }
        }
    }
    
    // MARK: - State Snapshot and Restoration
    
    public func createStateSnapshot() -> StateSnapshot {
        return StateSnapshot(
            stringStates: stringStates,
            boolStates: boolStates,
            intStates: intStates,
            doubleStates: doubleStates,
            arrayStates: arrayStates,
            dictionaryStates: dictionaryStates,
            timestamp: Date()
        )
    }
    
    public func restoreFromSnapshot(_ snapshot: StateSnapshot) {
        stringStates = snapshot.stringStates
        boolStates = snapshot.boolStates
        intStates = snapshot.intStates
        doubleStates = snapshot.doubleStates
        arrayStates = snapshot.arrayStates
        dictionaryStates = snapshot.dictionaryStates
        
        if configuration.enableStateLogging {
            print("🔄 State restored from snapshot (created at: \(snapshot.timestamp))")
        }
    }
    
    // MARK: - Private Helpers
    
    private func setStateFromAnyCodable(key: String, value: AnyCodable) {
        switch value.value {
        case let stringValue as String:
            stringStates[key] = stringValue
        case let boolValue as Bool:
            boolStates[key] = boolValue
        case let intValue as Int:
            intStates[key] = intValue
        case let doubleValue as Double:
            doubleStates[key] = doubleValue
        case let floatValue as Float:
            doubleStates[key] = Double(floatValue)
        case let arrayValue as [Any]:
            arrayStates[key] = arrayValue.map { AnyCodable($0) }
        case let dictValue as [String: Any]:
            dictionaryStates[key] = dictValue.mapValues { AnyCodable($0) }
        default:
            // Try to convert to string as fallback
            stringStates[key] = String(describing: value.value)
        }
    }
    
    private func notifyHotReloadSystem(key: String, value: Any) {
        // This would send state changes back to the hot reload server
        // Implementation would depend on the connection manager
        Task {
            do {
                let stateData = [key: AnyCodable(value)]
                // Would call connection manager's sendStateSync method
                print("📤 Would sync state to server: \(key) = \(value)")
            } catch {
                print("❌ Failed to sync state to server: \(error)")
            }
        }
    }
}

// MARK: - Supporting Types

public struct StateSnapshot {
    public let stringStates: [String: String]
    public let boolStates: [String: Bool]
    public let intStates: [String: Int]
    public let doubleStates: [String: Double]
    public let arrayStates: [String: [AnyCodable]]
    public let dictionaryStates: [String: [String: AnyCodable]]
    public let timestamp: Date
    
    public var stateCount: Int {
        return stringStates.count + boolStates.count + intStates.count + 
               doubleStates.count + arrayStates.count + dictionaryStates.count
    }
}

public struct SwiftUIStateConfiguration {
    public let enableStateLogging: Bool
    public let enableStatePersistence: Bool
    public let enableHotReloadSync: Bool
    public let enableAutoSave: Bool
    public let autoSaveInterval: TimeInterval
    public let maxStateHistory: Int
    
    public init(
        enableStateLogging: Bool = false,
        enableStatePersistence: Bool = true,
        enableHotReloadSync: Bool = true,
        enableAutoSave: Bool = false,
        autoSaveInterval: TimeInterval = 30.0,
        maxStateHistory: Int = 10
    ) {
        self.enableStateLogging = enableStateLogging
        self.enableStatePersistence = enableStatePersistence
        self.enableHotReloadSync = enableHotReloadSync
        self.enableAutoSave = enableAutoSave
        self.autoSaveInterval = autoSaveInterval
        self.maxStateHistory = maxStateHistory
    }
    
    public static func development() -> SwiftUIStateConfiguration {
        return SwiftUIStateConfiguration(
            enableStateLogging: true,
            enableStatePersistence: true,
            enableHotReloadSync: true,
            enableAutoSave: true,
            autoSaveInterval: 10.0
        )
    }
    
    public static func production() -> SwiftUIStateConfiguration {
        return SwiftUIStateConfiguration(
            enableStateLogging: false,
            enableStatePersistence: false,
            enableHotReloadSync: true,
            enableAutoSave: false
        )
    }
    
    public static func hotReload() -> SwiftUIStateConfiguration {
        return SwiftUIStateConfiguration(
            enableStateLogging: false,
            enableStatePersistence: true,
            enableHotReloadSync: true,
            enableAutoSave: false
        )
    }
}

// MARK: - State Manager Extensions

extension SwiftUIStateManager {
    
    // MARK: - Convenience Methods
    
    public func setString(_ value: String, for key: String) {
        stringStates[key] = value
    }
    
    public func getString(for key: String) -> String? {
        return stringStates[key]
    }
    
    public func setBool(_ value: Bool, for key: String) {
        boolStates[key] = value
    }
    
    public func getBool(for key: String) -> Bool? {
        return boolStates[key]
    }
    
    public func setInt(_ value: Int, for key: String) {
        intStates[key] = value
    }
    
    public func getInt(for key: String) -> Int? {
        return intStates[key]
    }
    
    public func setDouble(_ value: Double, for key: String) {
        doubleStates[key] = value
    }
    
    public func getDouble(for key: String) -> Double? {
        return doubleStates[key]
    }
    
    // MARK: - State Validation
    
    public func validateState() -> [StateValidationIssue] {
        var issues: [StateValidationIssue] = []
        
        // Check for unused state keys
        let allKeys = Set(stringStates.keys)
            .union(boolStates.keys)
            .union(intStates.keys)
            .union(doubleStates.keys)
            .union(arrayStates.keys)
            .union(dictionaryStates.keys)
        
        for key in allKeys {
            if !stateChangeCallbacks.keys.contains(key) {
                issues.append(StateValidationIssue(
                    type: .unusedState,
                    key: key,
                    message: "State key '\(key)' is not being observed"
                ))
            }
        }
        
        return issues
    }
}

public struct StateValidationIssue {
    public enum IssueType {
        case unusedState
        case missingState
        case typeConflict
        case invalidValue
    }
    
    public let type: IssueType
    public let key: String
    public let message: String
}

// MARK: - State Manager Errors

public enum SwiftUIStateManagerError: Error, LocalizedError {
    case invalidStateKey(String)
    case typeConversionFailed(String, String)
    case stateNotFound(String)
    case persistenceFailed(String)
    case validationFailed([StateValidationIssue])
    
    public var errorDescription: String? {
        switch self {
        case .invalidStateKey(let key):
            return "Invalid state key: \(key)"
        case .typeConversionFailed(let key, let details):
            return "Type conversion failed for key '\(key)': \(details)"
        case .stateNotFound(let key):
            return "State not found for key: \(key)"
        case .persistenceFailed(let details):
            return "State persistence failed: \(details)"
        case .validationFailed(let issues):
            return "State validation failed with \(issues.count) issues"
        }
    }
}