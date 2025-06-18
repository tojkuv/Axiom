import Foundation
import SwiftUI
import AxiomCore
import AxiomArchitecture

@MainActor
public final class StudioOrchestrator: ObservableObject {
    @Published public private(set) var applicationState: StudioApplicationState
    @Published public private(set) var isInitialized: Bool = false
    @Published public private(set) var initializationError: Error?
    
    // Clients
    public let personalInfoClient: PersonalInfoClient
    public let healthLocationClient: HealthLocationClient
    public let contentProcessorClient: ContentProcessorClient
    public let mediaHubClient: MediaHubClient
    public let performanceClient: PerformanceClient
    
    // Capabilities
    public let storageCapability: LocalFileStorageCapability
    public let keychainCapability: KeychainStorageCapability
    public let userDefaultsCapability: UserDefaultsCapability
    public let eventKitCapability: EventKitCapability
    public let contactsCapability: ContactsCapability
    public let locationCapability: LocationServicesCapability
    public let healthKitCapability: HealthKitCapability
    
    // Navigation
    public let navigationService: StudioNavigationService
    
    // State observation tasks
    private var observationTasks: [Task<Void, Never>] = []
    
    public init() throws {
        // Initialize capabilities
        self.storageCapability = try LocalFileStorageCapability()
        self.keychainCapability = KeychainStorageCapability()
        self.userDefaultsCapability = UserDefaultsCapability()
        self.eventKitCapability = EventKitCapability()
        self.contactsCapability = ContactsCapability()
        self.locationCapability = LocationServicesCapability()
        self.healthKitCapability = HealthKitCapability()
        
        // Initialize clients
        self.personalInfoClient = PersonalInfoClient(storageCapability: storageCapability)
        self.healthLocationClient = HealthLocationClient(storageCapability: storageCapability)
        self.contentProcessorClient = ContentProcessorClient(storageCapability: storageCapability)
        self.mediaHubClient = MediaHubClient(storageCapability: storageCapability)
        self.performanceClient = PerformanceClient(storageCapability: storageCapability)
        
        // Initialize navigation
        self.navigationService = StudioNavigationService()
        
        // Initialize application state
        self.applicationState = StudioApplicationState()
        
        // Set up state observation
        setupStateObservation()
    }
    
    deinit {
        // Cancel all observation tasks
        observationTasks.forEach { $0.cancel() }
    }
    
    // MARK: - Initialization
    
    public func initialize() async {
        do {
            try await initializeCapabilities()
            try await loadInitialState()
            try await startPerformanceMonitoring()
            
            await MainActor.run {
                isInitialized = true
                initializationError = nil
            }
        } catch {
            await MainActor.run {
                isInitialized = false
                initializationError = error
            }
        }
    }
    
    private func initializeCapabilities() async throws {
        // Initialize storage capabilities first
        try await storageCapability.activate()
        try await userDefaultsCapability.activate()
        
        // Initialize system capabilities (these may require permissions)
        do {
            try await eventKitCapability.activate()
        } catch {
            print("EventKit capability failed to activate: \(error)")
        }
        
        do {
            try await contactsCapability.activate()
        } catch {
            print("Contacts capability failed to activate: \(error)")
        }
        
        do {
            try await locationCapability.activate()
        } catch {
            print("Location capability failed to activate: \(error)")
        }
        
        do {
            try await healthKitCapability.activate()
        } catch {
            print("HealthKit capability failed to activate: \(error)")
        }
    }
    
    private func loadInitialState() async throws {
        // Load data from storage
        try await personalInfoClient.process(.loadTasks)
        try await personalInfoClient.process(.loadCalendarEvents)
        try await personalInfoClient.process(.loadContacts)
        
        try await healthLocationClient.process(.loadHealthMetrics)
        try await healthLocationClient.process(.loadLocationData)
        try await healthLocationClient.process(.loadMovementPatterns)
        
        try await contentProcessorClient.process(.loadMLModels)
        
        try await mediaHubClient.process(.loadDocuments)
        try await mediaHubClient.process(.loadPhotos)
        try await mediaHubClient.process(.loadAudioFiles)
    }
    
    private func startPerformanceMonitoring() async throws {
        try await performanceClient.process(.startMonitoring)
    }
    
    // MARK: - State Observation
    
    private func setupStateObservation() {
        // Observe PersonalInfo state
        observationTasks.append(
            Task {
                for await state in await personalInfoClient.stateStream {
                    await updatePersonalInfoState(state)
                }
            }
        )
        
        // Observe HealthLocation state
        observationTasks.append(
            Task {
                for await state in await healthLocationClient.stateStream {
                    await updateHealthLocationState(state)
                }
            }
        )
        
        // Observe ContentProcessor state
        observationTasks.append(
            Task {
                for await state in await contentProcessorClient.stateStream {
                    await updateContentProcessorState(state)
                }
            }
        )
        
        // Observe MediaHub state
        observationTasks.append(
            Task {
                for await state in await mediaHubClient.stateStream {
                    await updateMediaHubState(state)
                }
            }
        )
        
        // Observe Performance state
        observationTasks.append(
            Task {
                for await state in await performanceClient.stateStream {
                    await updatePerformanceState(state)
                }
            }
        )
    }
    
    @MainActor
    private func updatePersonalInfoState(_ state: PersonalInfoState) {
        applicationState = StudioApplicationState(
            personalInfo: state,
            healthLocation: applicationState.healthLocation,
            contentProcessor: applicationState.contentProcessor,
            mediaHub: applicationState.mediaHub,
            performance: applicationState.performance,
            navigation: applicationState.navigation
        )
    }
    
    @MainActor
    private func updateHealthLocationState(_ state: HealthLocationState) {
        applicationState = StudioApplicationState(
            personalInfo: applicationState.personalInfo,
            healthLocation: state,
            contentProcessor: applicationState.contentProcessor,
            mediaHub: applicationState.mediaHub,
            performance: applicationState.performance,
            navigation: applicationState.navigation
        )
    }
    
    @MainActor
    private func updateContentProcessorState(_ state: ContentProcessorState) {
        applicationState = StudioApplicationState(
            personalInfo: applicationState.personalInfo,
            healthLocation: applicationState.healthLocation,
            contentProcessor: state,
            mediaHub: applicationState.mediaHub,
            performance: applicationState.performance,
            navigation: applicationState.navigation
        )
    }
    
    @MainActor
    private func updateMediaHubState(_ state: MediaHubState) {
        applicationState = StudioApplicationState(
            personalInfo: applicationState.personalInfo,
            healthLocation: applicationState.healthLocation,
            contentProcessor: applicationState.contentProcessor,
            mediaHub: state,
            performance: applicationState.performance,
            navigation: applicationState.navigation
        )
    }
    
    @MainActor
    private func updatePerformanceState(_ state: PerformanceState) {
        applicationState = StudioApplicationState(
            personalInfo: applicationState.personalInfo,
            healthLocation: applicationState.healthLocation,
            contentProcessor: applicationState.contentProcessor,
            mediaHub: applicationState.mediaHub,
            performance: state,
            navigation: applicationState.navigation
        )
    }
    
    // MARK: - Action Processing
    
    public func processAction(_ action: StudioAction) async throws {
        switch action {
        case .personalInfo(let personalInfoAction):
            try await personalInfoClient.process(personalInfoAction)
            
        case .healthLocation(let healthLocationAction):
            try await healthLocationClient.process(healthLocationAction)
            
        case .contentProcessor(let contentProcessorAction):
            try await contentProcessorClient.process(contentProcessorAction)
            
        case .mediaHub(let mediaHubAction):
            try await mediaHubClient.process(mediaHubAction)
            
        case .performance(let performanceAction):
            try await performanceClient.process(performanceAction)
            
        case .navigation(let navigationAction):
            await processNavigationAction(navigationAction)
        }
    }
    
    @MainActor
    private func processNavigationAction(_ action: NavigationAction) {
        switch action {
        case .navigate(let route):
            navigationService.navigate(to: route)
            
        case .goBack:
            _ = navigationService.goBack()
            
        case .setDeepLinkingContext(let context):
            navigationService.setDeepLinkingContext(context)
            
        case .clearDeepLinkingContext:
            navigationService.clearDeepLinkingContext()
            
        case .recordTransition:
            // This is handled automatically by the navigation service
            break
        }
        
        // Update navigation state in application state
        let navigationState = navigationService.saveNavigationState()
        applicationState = StudioApplicationState(
            personalInfo: applicationState.personalInfo,
            healthLocation: applicationState.healthLocation,
            contentProcessor: applicationState.contentProcessor,
            mediaHub: applicationState.mediaHub,
            performance: applicationState.performance,
            navigation: navigationState
        )
    }
    
    // MARK: - Convenience Methods
    
    public func createTask(_ task: StudioTask) async throws {
        try await processAction(.personalInfo(.createTask(task)))
    }
    
    public func updateTask(_ task: StudioTask) async throws {
        try await processAction(.personalInfo(.updateTask(task)))
    }
    
    public func deleteTask(_ taskId: UUID) async throws {
        try await processAction(.personalInfo(.deleteTask(taskId)))
    }
    
    public func addHealthMetric(_ metric: HealthMetric) async throws {
        try await processAction(.healthLocation(.addHealthMetric(metric)))
    }
    
    public func processText(_ text: String, analysisType: TextAnalysisType) async throws {
        try await processAction(.contentProcessor(.processText(text, analysisType)))
    }
    
    public func importDocument(from url: URL) async throws {
        try await processAction(.mediaHub(.importDocument(url)))
    }
    
    public func navigate(to route: StudioRoute) async throws {
        try await processAction(.navigation(.navigate(route)))
    }
    
    // MARK: - State Queries
    
    public func getCurrentTasks() async -> [StudioTask] {
        return await personalInfoClient.getCurrentState().tasks
    }
    
    public func getCurrentContacts() async -> [Contact] {
        return await personalInfoClient.getCurrentState().contacts
    }
    
    public func getSystemHealthSummary() async -> SystemHealthSummary {
        return await performanceClient.getSystemHealthSummary()
    }
    
    // MARK: - Cleanup
    
    public func shutdown() async {
        // Cancel observation tasks
        observationTasks.forEach { $0.cancel() }
        observationTasks.removeAll()
        
        // Deactivate capabilities
        try? await storageCapability.deactivate()
        try? await eventKitCapability.deactivate()
        try? await contactsCapability.deactivate()
        try? await locationCapability.deactivate()
        try? await healthKitCapability.deactivate()
        
        // Stop performance monitoring
        try? await performanceClient.process(.stopMonitoring)
    }
}