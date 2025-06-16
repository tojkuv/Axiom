#if canImport(UIKit)
import AxiomCore
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif
import Foundation

public actor FrameworkEventBus {
    public static let shared = FrameworkEventBus()
    
    private var subscribers: [EventType: [WeakSubscriber]] = [:]
    private var eventHistory: [TimestampedEvent] = []
    private let maxHistorySize = 1000
    
    public enum EventType: Hashable, Sendable {
        case memoryPressure(freedBytes: Int)
        case platformLifecycle(PlatformLifecycleEvent)
        case resourceCleanup(resourceType: String)
        case actorIsolationViolation(violation: String)
        case backgroundTaskExpiring(taskID: String)
        case emergencyMemoryAction(action: String)
    }
    
    public enum PlatformLifecycleEvent: Hashable, Sendable {
        case didEnterBackground
        case willEnterForeground
        case willTerminate
        case didReceiveMemoryWarning
        case significantTimeChange
    }
    
    private init() {}
    
    public func post(_ event: EventType) async {
        let timestampedEvent = TimestampedEvent(
            event: event,
            timestamp: CFAbsoluteTimeGetCurrent()
        )
        eventHistory.append(timestampedEvent)
        
        if eventHistory.count > maxHistorySize {
            eventHistory.removeFirst(eventHistory.count - maxHistorySize)
        }
        
        if let eventSubscribers = subscribers[event] {
            await notifySubscribers(eventSubscribers, of: event)
        }
        
        await cleanupSubscribers(for: event)
    }
    
    public func subscribe(
        to eventType: EventType,
        callback: @escaping @Sendable (EventType) async -> Void
    ) async -> SubscriptionToken {
        let subscriber = WeakSubscriber(callback: callback)
        let token = SubscriptionToken { [weak self] in
            Task { [weak self] in
                await self?.unsubscribe(subscriber, from: eventType)
            }
        }
        
        if subscribers[eventType] == nil {
            subscribers[eventType] = []
        }
        subscribers[eventType]?.append(subscriber)
        
        return token
    }
    
    private func notifySubscribers(_ eventSubscribers: [WeakSubscriber], of event: EventType) async {
        for subscriber in eventSubscribers {
            if let callback = subscriber.callback {
                await callback(event)
            }
        }
    }
    
    private func cleanupSubscribers(for eventType: EventType) async {
        guard var eventSubscribers = subscribers[eventType] else { return }
        
        let beforeCount = eventSubscribers.count
        eventSubscribers.removeAll { $0.callback == nil }
        
        if eventSubscribers.count != beforeCount {
            subscribers[eventType] = eventSubscribers.isEmpty ? nil : eventSubscribers
        }
    }
    
    private func unsubscribe(_ subscriber: WeakSubscriber, from eventType: EventType) async {
        guard var eventSubscribers = subscribers[eventType] else { return }
        
        eventSubscribers.removeAll { $0 === subscriber }
        subscribers[eventType] = eventSubscribers.isEmpty ? nil : eventSubscribers
    }
    
    public func getEventHistory(limit: Int? = nil) async -> [TimestampedEvent] {
        if let limit = limit {
            return Array(eventHistory.suffix(limit))
        }
        return eventHistory
    }
    
    public func clearHistory() async {
        eventHistory.removeAll()
    }
}

public struct TimestampedEvent: Sendable {
    public let event: FrameworkEventBus.EventType
    public let timestamp: CFAbsoluteTime
    
    public init(event: FrameworkEventBus.EventType, timestamp: CFAbsoluteTime) {
        self.event = event
        self.timestamp = timestamp
    }
}

public final class SubscriptionToken: @unchecked Sendable {
    private let unsubscribe: () -> Void
    private var hasUnsubscribed = false
    private let lock = NSLock()
    
    init(unsubscribe: @escaping () -> Void) {
        self.unsubscribe = unsubscribe
    }
    
    public func cancel() {
        lock.lock()
        defer { lock.unlock() }
        
        guard !hasUnsubscribed else { return }
        hasUnsubscribed = true
        unsubscribe()
    }
    
    deinit {
        cancel()
    }
}

private final class WeakSubscriber: @unchecked Sendable {
    private weak var _callback: AnyObject?
    private let _callbackRef: (@Sendable (FrameworkEventBus.EventType) async -> Void)?
    
    var callback: (@Sendable (FrameworkEventBus.EventType) async -> Void)? {
        return _callback != nil ? _callbackRef : nil
    }
    
    init(callback: @escaping @Sendable (FrameworkEventBus.EventType) async -> Void) {
        let holder = CallbackHolder(callback: callback)
        self._callback = holder
        self._callbackRef = callback
    }
}

private final class CallbackHolder {
    let callback: @Sendable (FrameworkEventBus.EventType) async -> Void
    
    init(callback: @escaping @Sendable (FrameworkEventBus.EventType) async -> Void) {
        self.callback = callback
    }
}