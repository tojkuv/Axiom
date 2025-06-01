import Foundation

// MARK: - Shared Test Infrastructure

/// Weak reference wrapper for observer management across all tests
struct WeakObserver {
    weak var observer: AnyObject?
    
    init(_ observer: AnyObject) {
        self.observer = observer
    }
}

/// Memory tracking utility for test performance monitoring
struct MemoryTracker {
    static func currentUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int(info.resident_size) : 0
    }
}