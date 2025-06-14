import Foundation
import Darwin.Mach

@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
public actor DeviceInfoMonitor {
    public static let current = DeviceInfoMonitor()
    
    public var model: String {
        deviceModel
    }
    
    public var processorSpeed: Double {
        cpuFrequency
    }
    
    public var memorySize: Int64 {
        totalSystemMemory
    }
    
    public var currentMemoryPressure: Double {
        get async {
            await memoryPressure
        }
    }
    
    public var thermalState: ProcessInfo.ThermalState {
        ProcessInfo.processInfo.thermalState
    }
    
    public var platformCapabilities: PlatformCapabilities {
        capabilities
    }
    
    // MARK: - Private Implementation
    
    private let deviceModel: String
    private let cpuFrequency: Double
    private let totalSystemMemory: Int64
    private let capabilities: PlatformCapabilities
    
    private init() {
        // Initialize device model
        self.deviceModel = Self.detectDeviceModel()
        
        // Initialize CPU frequency
        self.cpuFrequency = Self.detectCPUFrequency()
        
        // Initialize total system memory
        self.totalSystemMemory = Self.detectTotalMemory()
        
        // Initialize platform capabilities
        self.capabilities = Self.detectPlatformCapabilities()
    }
    
    private var memoryPressure: Double {
        get async {
            Self.getCurrentMemoryPressure()
        }
    }
    
    // MARK: - Detection Methods
    
    private static func detectDeviceModel() -> String {
        #if os(iOS)
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier.isEmpty ? "Unknown iOS Device" : identifier
        #elseif os(macOS)
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier.isEmpty ? "Unknown Mac" : identifier
        #elseif os(watchOS)
        return "Apple Watch"
        #elseif os(tvOS)
        return "Apple TV"
        #elseif os(visionOS)
        return "Apple Vision Pro"
        #else
        return "Unknown Platform"
        #endif
    }
    
    private static func detectCPUFrequency() -> Double {
        #if os(macOS) || os(iOS)
        var size = MemoryLayout<UInt64>.size
        var frequency: UInt64 = 0
        
        let result = sysctlbyname("hw.cpufrequency_max", &frequency, &size, nil, 0)
        if result == 0 {
            return Double(frequency) / 1_000_000_000.0 // Convert Hz to GHz
        }
        
        // Fallback: try to get base frequency
        let baseResult = sysctlbyname("hw.cpufrequency", &frequency, &size, nil, 0)
        if baseResult == 0 {
            return Double(frequency) / 1_000_000_000.0
        }
        
        // Estimate based on device model if sysctls fail
        return estimateCPUFrequency()
        #else
        return estimateCPUFrequency()
        #endif
    }
    
    private static func detectTotalMemory() -> Int64 {
        #if os(macOS) || os(iOS)
        var size = MemoryLayout<UInt64>.size
        var memsize: UInt64 = 0
        
        let result = sysctlbyname("hw.memsize", &memsize, &size, nil, 0)
        if result == 0 {
            return Int64(memsize)
        }
        #endif
        
        // Fallback using ProcessInfo
        let processInfo = ProcessInfo.processInfo
        return Int64(processInfo.physicalMemory)
    }
    
    private static func getCurrentMemoryPressure() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let totalMemory = detectTotalMemory()
            if totalMemory > 0 {
                return Double(info.resident_size) / Double(totalMemory)
            }
        }
        
        return 0.0
    }
    
    private static func detectPlatformCapabilities() -> PlatformCapabilities {
        #if os(iOS)
        return PlatformCapabilities(
            supportsBackgroundProcessing: true,
            supportsMultiWindow: UIDevice.current.userInterfaceIdiom == .pad,
            supportsExternalDisplay: true,
            supportsCamera: UIImagePickerController.isSourceTypeAvailable(.camera),
            supportsLocation: true,
            supportsPushNotifications: true,
            supportsAppExtensions: true,
            supportsWidgets: true,
            maxConcurrentOperations: ProcessInfo.processInfo.activeProcessorCount
        )
        #elseif os(macOS)
        return PlatformCapabilities(
            supportsBackgroundProcessing: true,
            supportsMultiWindow: true,
            supportsExternalDisplay: true,
            supportsCamera: true,
            supportsLocation: true,
            supportsPushNotifications: true,
            supportsAppExtensions: true,
            supportsWidgets: true,
            maxConcurrentOperations: ProcessInfo.processInfo.activeProcessorCount
        )
        #elseif os(watchOS)
        return PlatformCapabilities(
            supportsBackgroundProcessing: false,
            supportsMultiWindow: false,
            supportsExternalDisplay: false,
            supportsCamera: false,
            supportsLocation: true,
            supportsPushNotifications: true,
            supportsAppExtensions: false,
            supportsWidgets: true,
            maxConcurrentOperations: 2
        )
        #elseif os(tvOS)
        return PlatformCapabilities(
            supportsBackgroundProcessing: true,
            supportsMultiWindow: false,
            supportsExternalDisplay: true,
            supportsCamera: false,
            supportsLocation: false,
            supportsPushNotifications: true,
            supportsAppExtensions: false,
            supportsWidgets: false,
            maxConcurrentOperations: ProcessInfo.processInfo.activeProcessorCount
        )
        #elseif os(visionOS)
        return PlatformCapabilities(
            supportsBackgroundProcessing: true,
            supportsMultiWindow: true,
            supportsExternalDisplay: false,
            supportsCamera: false, // No traditional camera
            supportsLocation: false, // Limited location services
            supportsPushNotifications: true,
            supportsAppExtensions: true,
            supportsWidgets: false, // No widget support
            maxConcurrentOperations: ProcessInfo.processInfo.activeProcessorCount,
            supportsSpatialComputing: true, // visionOS-specific
            supportsHandTracking: true,     // visionOS-specific  
            supportsEyeTracking: true       // visionOS-specific
        )
        #else
        return PlatformCapabilities(
            supportsBackgroundProcessing: false,
            supportsMultiWindow: false,
            supportsExternalDisplay: false,
            supportsCamera: false,
            supportsLocation: false,
            supportsPushNotifications: false,
            supportsAppExtensions: false,
            supportsWidgets: false,
            maxConcurrentOperations: 1
        )
        #endif
    }
    
    private static func estimateCPUFrequency() -> Double {
        #if os(iOS)
        // Rough estimates based on known device capabilities
        return 2.4 // Modern iOS devices typically run at ~2.4GHz
        #elseif os(macOS)
        // Mac systems vary widely, use conservative estimate
        return 2.8
        #elseif os(visionOS)
        // Apple Vision Pro uses M2 chip
        return 3.2 // M2 chip runs at ~3.2GHz
        #else
        return 1.0 // Conservative fallback
        #endif
    }
}

// MARK: - Platform Capabilities

public struct PlatformCapabilities: Sendable {
    public let supportsBackgroundProcessing: Bool
    public let supportsMultiWindow: Bool
    public let supportsExternalDisplay: Bool
    public let supportsCamera: Bool
    public let supportsLocation: Bool
    public let supportsPushNotifications: Bool
    public let supportsAppExtensions: Bool
    public let supportsWidgets: Bool
    public let maxConcurrentOperations: Int
    
    // visionOS-specific capabilities
    public let supportsSpatialComputing: Bool
    public let supportsHandTracking: Bool
    public let supportsEyeTracking: Bool
    
    public init(
        supportsBackgroundProcessing: Bool,
        supportsMultiWindow: Bool,
        supportsExternalDisplay: Bool,
        supportsCamera: Bool,
        supportsLocation: Bool,
        supportsPushNotifications: Bool,
        supportsAppExtensions: Bool,
        supportsWidgets: Bool,
        maxConcurrentOperations: Int,
        supportsSpatialComputing: Bool = false,
        supportsHandTracking: Bool = false,
        supportsEyeTracking: Bool = false
    ) {
        self.supportsBackgroundProcessing = supportsBackgroundProcessing
        self.supportsMultiWindow = supportsMultiWindow
        self.supportsExternalDisplay = supportsExternalDisplay
        self.supportsCamera = supportsCamera
        self.supportsLocation = supportsLocation
        self.supportsPushNotifications = supportsPushNotifications
        self.supportsAppExtensions = supportsAppExtensions
        self.supportsWidgets = supportsWidgets
        self.maxConcurrentOperations = maxConcurrentOperations
        self.supportsSpatialComputing = supportsSpatialComputing
        self.supportsHandTracking = supportsHandTracking
        self.supportsEyeTracking = supportsEyeTracking
    }
}

// MARK: - UIKit Integration

#if canImport(UIKit)
import UIKit

extension DeviceInfo {
    public var batteryLevel: Float {
        get async {
            await MainActor.run {
                UIDevice.current.isBatteryMonitoringEnabled = true
                return UIDevice.current.batteryLevel
            }
        }
    }
    
    public var isLowPowerMode: Bool {
        ProcessInfo.processInfo.isLowPowerModeEnabled
    }
}
#else
extension DeviceInfo {
    public var batteryLevel: Float {
        get async {
            1.0 // Default for non-iOS platforms
        }
    }
    
    public var isLowPowerMode: Bool {
        false // Default for non-iOS platforms
    }
}
#endif