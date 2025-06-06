import Foundation

// GREEN Phase: DeepLinkNavigationController implementation for End-to-End tests

actor DeepLinkNavigationController {
    private var navigationHistory: [DeepLinkEntry] = []
    private var currentRoute: AppRoute?
    
    init() {
        // Initialize with no current route
    }
    
    func handleDeepLink(_ url: URL) async -> DeepLinkResult {
        let startTime = Date()
        
        // Parse URL into route
        guard let route = AppRoute(url: url) else {
            let processingTime = Date().timeIntervalSince(startTime) * 1000
            return DeepLinkResult(
                success: false,
                route: nil,
                processingTime: processingTime,
                error: DeepLinkError.invalidURL
            )
        }
        
        // Validate route
        let validationResult = validateRoute(route)
        if !validationResult.isValid {
            let processingTime = Date().timeIntervalSince(startTime) * 1000
            return DeepLinkResult(
                success: false,
                route: route,
                processingTime: processingTime,
                error: validationResult.error
            )
        }
        
        // Store current route
        currentRoute = route
        
        // Record in history
        let entry = DeepLinkEntry(
            url: url,
            route: route,
            timestamp: Date(),
            success: true
        )
        navigationHistory.append(entry)
        
        // Simulate navigation processing
        try? await _Concurrency.Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        let processingTime = Date().timeIntervalSince(startTime) * 1000
        
        return DeepLinkResult(
            success: true,
            route: route,
            processingTime: processingTime,
            error: nil
        )
    }
    
    func getCurrentRoute() async -> AppRoute? {
        return currentRoute
    }
    
    func getNavigationHistory() async -> [DeepLinkEntry] {
        return navigationHistory
    }
    
    private func validateRoute(_ route: AppRoute) -> (isValid: Bool, error: DeepLinkError?) {
        switch route {
        case .taskDetail(let taskId):
            // Validate task ID format
            guard !taskId.isEmpty else {
                return (false, .missingParameter("taskId"))
            }
            
        case .taskEdit(let taskId):
            // Task edit can have nil taskId for new task
            if let taskId = taskId, taskId.isEmpty {
                return (false, .invalidParameter("taskId"))
            }
            
        case .categoryEdit(let categoryId):
            // Category edit can have nil categoryId for new category
            if let categoryId = categoryId, categoryId.isEmpty {
                return (false, .invalidParameter("categoryId"))
            }
            
        default:
            // Other routes don't need validation
            break
        }
        
        return (true, nil)
    }
}

// MARK: - Supporting Types

enum AppRoute: Equatable {
    case taskList
    case taskDetail(taskId: String)
    case taskEdit(taskId: String?)
    case categoryList
    case categoryEdit(categoryId: String?)
    case settings
    case profile
    case login
    
    // Deep link URL parsing
    init?(url: URL) {
        guard let scheme = url.scheme else { return nil }
        
        // Handle custom scheme: task://
        if scheme == "task" {
            guard let host = url.host else { return nil }
            
            switch host {
            case "taskId":
                let taskId = url.pathComponents.dropFirst().first ?? ""
                self = .taskDetail(taskId: taskId)
                
            case "edit":
                let taskId = url.pathComponents.dropFirst().first
                self = .taskEdit(taskId: taskId)
                
            case "list":
                self = .taskList
                
            default:
                return nil
            }
            
        // Handle custom scheme: category://
        } else if scheme == "category" {
            guard let host = url.host else { return nil }
            
            switch host {
            case "list":
                self = .categoryList
                
            case "edit":
                let categoryId = url.pathComponents.dropFirst().first
                self = .categoryEdit(categoryId: categoryId)
                
            default:
                return nil
            }
            
        // Handle universal links: https://myapp.com/
        } else if scheme == "https", url.host == "myapp.com" {
            let path = url.path
            
            if path.hasPrefix("/task/") {
                let taskId = String(path.dropFirst("/task/".count))
                self = .taskDetail(taskId: taskId)
            } else if path == "/tasks" {
                self = .taskList
            } else if path.hasPrefix("/category/edit/") {
                let categoryId = String(path.dropFirst("/category/edit/".count))
                self = .categoryEdit(categoryId: categoryId)
            } else if path == "/categories" {
                self = .categoryList
            } else if path == "/settings" {
                self = .settings
            } else if path == "/profile" {
                self = .profile
            } else if path == "/login" {
                self = .login
            } else {
                return nil
            }
            
        // Handle app-specific scheme: myapp://
        } else if scheme == "myapp" {
            guard let host = url.host else { return nil }
            
            switch host {
            case "settings":
                self = .settings
            case "profile":
                self = .profile
            case "login":
                self = .login
            default:
                return nil
            }
            
        } else {
            return nil
        }
    }
}

struct DeepLinkResult {
    let success: Bool
    let route: AppRoute?
    let processingTime: Double // milliseconds
    let error: DeepLinkError?
}

struct DeepLinkEntry {
    let url: URL
    let route: AppRoute
    let timestamp: Date
    let success: Bool
}

enum DeepLinkError: Error, Equatable {
    case invalidURL
    case unsupportedScheme
    case missingParameter(String)
    case invalidParameter(String)
    case routeNotFound
    case navigationFailed
}