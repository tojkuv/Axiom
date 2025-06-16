#if canImport(UIKit)
@preconcurrency import UIKit
#endif
#if canImport(AppKit)
@preconcurrency import AppKit
#endif
import Foundation
import AxiomCore


public actor StateStorage<S: AxiomState & Codable> {
    private let state: S
    private let memoryLimit: Int
    private var partitionCache: [String: (data: Any, lastAccessed: CFAbsoluteTime)] = [:]
    private var memoryPressureObserver: (any NSObjectProtocol)?
    private var isUnderMemoryPressure = false
    private var totalMemoryUsage: Int
    
    public init(state: S, memoryLimit: Int = 100_000_000) {
        self.state = state
        self.memoryLimit = memoryLimit
        self.totalMemoryUsage = Self.estimateMemoryUsage(of: state)
        
        Task {
            await setupMemoryPressureMonitoring()
        }
    }
    
    private func setupMemoryPressureMonitoring() async {
        #if canImport(UIKit) && !os(watchOS)
        // Get the notification name from MainActor context, then assign to actor property
        let notificationName = await MainActor.run {
            UIApplication.didReceiveMemoryWarningNotification
        }
        
        self.memoryPressureObserver = NotificationCenter.default.addObserver(
            forName: notificationName,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.handleMemoryPressure()
            }
        }
        #elseif canImport(AppKit)
        // macOS doesn't have a direct equivalent to iOS memory warnings
        // Use a simplified approach for now
        #endif
    }
    
    private func handleMemoryPressure() async {
        isUnderMemoryPressure = true
        
        let _ = partitionCache.count // Track cache size for potential logging
        let freedBytes = await clearCache()
        
        await FrameworkEventBus.shared.post(.memoryPressure(freedBytes: freedBytes))
        
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        isUnderMemoryPressure = false
        
        await FrameworkEventBus.shared.post(.platformLifecycle(.didReceiveMemoryWarning))
    }
    
    @discardableResult
    public func clearCache() async -> Int {
        let beforeMemory = totalMemoryUsage
        partitionCache.removeAll()
        
        let currentMemory = Self.estimateMemoryUsage(of: state)
        totalMemoryUsage = currentMemory
        
        return max(0, beforeMemory - currentMemory)
    }
    
    public func cachePartition<T>(_ data: T, forKey key: String) async {
        guard !isUnderMemoryPressure else { return }
        
        partitionCache[key] = (data: data, lastAccessed: CFAbsoluteTimeGetCurrent())
        
        if partitionCache.count > 100 {
            await evictOldestCacheEntries()
        }
        
        if totalMemoryUsage > memoryLimit {
            await handleMemoryPressure()
        }
    }
    
    public func getCachedPartition<T>(forKey key: String, as type: T.Type) async -> T? {
        guard let cached = partitionCache[key] else { return nil }
        
        partitionCache[key] = (data: cached.data, lastAccessed: CFAbsoluteTimeGetCurrent())
        
        return cached.data as? T
    }
    
    private func evictOldestCacheEntries() async {
        guard partitionCache.count > 50 else { return }
        
        let sortedByAccess = partitionCache.sorted { $0.value.lastAccessed < $1.value.lastAccessed }
        let toRemove = Array(sortedByAccess.prefix(partitionCache.count - 50))
        
        for (key, _) in toRemove {
            partitionCache.removeValue(forKey: key)
        }
    }
    
    public var memoryUsage: Int {
        totalMemoryUsage
    }
    
    public var cacheSize: Int {
        partitionCache.count
    }
    
    public func getState() -> S {
        state
    }
    
    private static func estimateMemoryUsage(of state: S) -> Int {
        do {
            let data = try JSONEncoder().encode(state)
            return data.count * 2
        } catch {
            return MemoryLayout<S>.size
        }
    }
    
    deinit {
        if let observer = memoryPressureObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

public extension StateStorage {
    static func createWithPlatformDefaults(state: S) -> StateStorage<S> {
        #if os(watchOS)
        return StateStorage(state: state, memoryLimit: 50_000_000) // 50MB for watchOS
        #elseif os(iOS)
        return StateStorage(state: state, memoryLimit: 200_000_000) // 200MB for iOS
        #elseif os(macOS)
        return StateStorage(state: state, memoryLimit: 500_000_000) // 500MB for macOS
        #elseif os(tvOS)
        return StateStorage(state: state, memoryLimit: 300_000_000) // 300MB for tvOS
        #else
        return StateStorage(state: state, memoryLimit: 100_000_000) // 100MB default
        #endif
    }
}

public struct SystemMetrics {
    public static func getDetailedMemoryUsage() async -> MemoryUsageInfo {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        let resident = result == KERN_SUCCESS ? Int(info.resident_size) : 0
        let virtual = result == KERN_SUCCESS ? Int(info.virtual_size) : 0
        
        let physicalMemory = Int(ProcessInfo.processInfo.physicalMemory)
        let available = physicalMemory - resident
        
        return MemoryUsageInfo(
            resident: resident,
            virtual: virtual,
            available: available,
            total: physicalMemory
        )
    }
}

public struct MemoryUsageInfo: Sendable {
    public let resident: Int
    public let virtual: Int
    public let available: Int
    public let total: Int
    
    public var usagePercentage: Double {
        guard total > 0 else { return 0 }
        return Double(resident) / Double(total)
    }
    
    public init(resident: Int, virtual: Int, available: Int, total: Int) {
        self.resident = resident
        self.virtual = virtual
        self.available = available
        self.total = total
    }
}