#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif
import Foundation

public protocol LifecycleObserver: AnyObject, Sendable {
    func didEnterBackground() async
    func willEnterForeground() async
    func willTerminate() async
    func didReceiveMemoryWarning() async
}

public struct WeakLifecycleObserver {
    public weak var observer: (any LifecycleObserver)?
    
    public init(_ observer: any LifecycleObserver) {
        self.observer = observer
    }
}

public actor CleanupCoordinator {
    private var cleanupTasks: [() async -> Void] = []
    
    public func addCleanupTask(_ task: @escaping () async -> Void) {
        cleanupTasks.append(task)
    }
    
    public func executeCleanup() async {
        for task in cleanupTasks {
            await task()
        }
    }
    
    public func removeAllCleanupTasks() {
        cleanupTasks.removeAll()
    }
}

public actor PlatformLifecycleCoordinator {
    private let cleanupCoordinator: CleanupCoordinator
    private var stateStorages: [any StateStorageProtocol] = []
    private var backgroundTaskID: BackgroundTaskIdentifier = .invalid
    private var lifecycleObservers: [WeakLifecycleObserver] = []
    
    public init() {
        self.cleanupCoordinator = CleanupCoordinator()
        
        Task {
            await setupPlatformLifecycleObservers()
        }
    }
    
    private func setupPlatformLifecycleObservers() async {
        #if canImport(UIKit) && !os(watchOS)
        await MainActor.run {
            NotificationCenter.default.addObserver(
                forName: UIApplication.didEnterBackgroundNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task {
                    await self?.handleAppDidEnterBackground()
                }
            }
            
            NotificationCenter.default.addObserver(
                forName: UIApplication.willEnterForegroundNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task {
                    await self?.handleAppWillEnterForeground()
                }
            }
            
            NotificationCenter.default.addObserver(
                forName: UIApplication.willTerminateNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task {
                    await self?.handleAppWillTerminate()
                }
            }
        }
        #elseif canImport(AppKit)
        await MainActor.run {
            NotificationCenter.default.addObserver(
                forName: NSApplication.didHideNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task {
                    await self?.handleAppDidEnterBackground()
                }
            }
            
            NotificationCenter.default.addObserver(
                forName: NSApplication.didUnhideNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task {
                    await self?.handleAppWillEnterForeground()
                }
            }
            
            NotificationCenter.default.addObserver(
                forName: NSApplication.willTerminateNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task {
                    await self?.handleAppWillTerminate()
                }
            }
        }
        #endif
    }
    
    private func handleAppDidEnterBackground() async {
        #if canImport(UIKit) && !os(watchOS)
        backgroundTaskID = await MainActor.run {
            UIApplication.shared.beginBackgroundTask {
                Task {
                    await self.forceCleanupCompletion()
                }
            }
        }
        #endif
        
        await coordinateBackgroundTransition()
        await notifyLifecycleObservers { observer in
            await observer.didEnterBackground()
        }
        
        await FrameworkEventBus.shared.post(.platformLifecycle(.didEnterBackground))
    }
    
    private func handleAppWillEnterForeground() async {
        await coordinateForegroundTransition()
        await notifyLifecycleObservers { observer in
            await observer.willEnterForeground()
        }
        
        #if canImport(UIKit) && !os(watchOS)
        if backgroundTaskID != .invalid {
            await MainActor.run {
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                backgroundTaskID = .invalid
            }
        }
        #endif
        
        await FrameworkEventBus.shared.post(.platformLifecycle(.willEnterForeground))
    }
    
    private func handleAppWillTerminate() async {
        await notifyLifecycleObservers { observer in
            await observer.willTerminate()
        }
        
        await cleanupCoordinator.executeCleanup()
        await FrameworkEventBus.shared.post(.platformLifecycle(.willTerminate))
    }
    
    private func coordinateBackgroundTransition() async {
        await cleanupCoordinator.executeCleanup()
        
        for storage in stateStorages {
            _ = await storage.clearCache()
        }
        
        await suspendNonCriticalOperations()
        
        await FrameworkEventBus.shared.post(.resourceCleanup(resourceType: "background_transition"))
    }
    
    private func coordinateForegroundTransition() async {
        await resumeOperations()
        
        for storage in stateStorages {
            await storage.refreshIfNeeded()
        }
    }
    
    private func suspendNonCriticalOperations() async {
        // Suspend operations that can be paused during background state
    }
    
    private func resumeOperations() async {
        // Resume operations when returning to foreground
    }
    
    private func forceCleanupCompletion() async {
        await cleanupCoordinator.executeCleanup()
        
        #if canImport(UIKit) && !os(watchOS)
        if backgroundTaskID != .invalid {
            await MainActor.run {
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                backgroundTaskID = .invalid
            }
        }
        #endif
    }
    
    private func notifyLifecycleObservers(_ action: (any LifecycleObserver) async -> Void) async {
        let activeObservers = lifecycleObservers.compactMap { $0.observer }
        
        for observer in activeObservers {
            await action(observer)
        }
        
        lifecycleObservers.removeAll { $0.observer == nil }
    }
    
    public func addStateStorage(_ storage: any StateStorageProtocol) {
        stateStorages.append(storage)
    }
    
    public func removeStateStorage(_ storage: any StateStorageProtocol) async {
        let storageId = await storage.identifier
        var indicesToRemove: [Int] = []
        
        for (index, existingStorage) in stateStorages.enumerated() {
            let existingId = await existingStorage.identifier
            if existingId == storageId {
                indicesToRemove.append(index)
            }
        }
        
        // Remove in reverse order to maintain correct indices
        for index in indicesToRemove.reversed() {
            stateStorages.remove(at: index)
        }
    }
    
    public func addLifecycleObserver(_ observer: any LifecycleObserver) {
        lifecycleObservers.append(WeakLifecycleObserver(observer))
    }
    
    public func removeLifecycleObserver(_ observer: any LifecycleObserver) {
        lifecycleObservers.removeAll { $0.observer === observer }
    }
    
    public func addCleanupTask(_ task: @escaping @Sendable () async -> Void) async {
        await cleanupCoordinator.addCleanupTask(task)
    }
}

public protocol StateStorageProtocol: Actor {
    var identifier: String { get }
    func clearCache() async -> Int
    func refreshIfNeeded() async
}

extension Axiom.StateStorage: StateStorageProtocol {
    public var identifier: String {
        "\(S.self)_\(ObjectIdentifier(self).hashValue)"
    }
    
    public func refreshIfNeeded() async {
        // Refresh state if needed when returning to foreground
    }
}

#if canImport(UIKit)
public typealias BackgroundTaskIdentifier = UIBackgroundTaskIdentifier
#else
public struct BackgroundTaskIdentifier: Equatable, Sendable {
    public static let invalid = BackgroundTaskIdentifier()
    private init() {}
}
#endif