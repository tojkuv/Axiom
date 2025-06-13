import XCTest
import SwiftSyntaxMacrosTestSupport
@testable import Axiom

/// Tests for navigation macro expansion
final class NavigationMacroTests: XCTestCase {
    
    // MARK: - NavigationOrchestrator Macro Tests
    
    func testNavigationOrchestratorMacroGeneratesNavigationMethods() throws {
        // This should fail - NavigationOrchestratorMacro doesn't exist yet
        assertMacroExpansion(
            """
            @NavigationOrchestrator
            class AppOrchestrator {
                @RouteProperty(.home)
                var home = HomeContext.self
                
                @RouteProperty(.detail)
                var detail = DetailContext.self
            }
            """,
            expandedSource: """
            class AppOrchestrator {
                @RouteProperty(.home)
                var home = HomeContext.self
                
                @RouteProperty(.detail)
                var detail = DetailContext.self
                
                // Generated navigation methods
                func navigateToHome() async {
                    await navigate(to: .home)
                }
                
                func navigateToDetail(id: String) async {
                    await navigate(to: .detail(id: id))
                }
                
                // Generated route registration
                private func registerRoutes() async {
                    await registerRoute(.home) { _ in
                        return HomeContext()
                    }
                    await registerRoute(.detail) { route in
                        guard case .detail(let id) = route else { return DetailContext(id: "") }
                        return DetailContext(id: id)
                    }
                }
                
                // Generated NavigationService conformance
                var registeredRoutes: [RouteDefinition] {
                    [.home, .detail]
                }
                
                func canNavigate(to route: RouteDefinition) async -> Bool {
                    registeredRoutes.contains(route)
                }
            }
            """,
            macros: ["NavigationOrchestrator": NavigationOrchestratorMacro.self]
        )
    }
    
    func testNavigationOrchestratorWithCustomValidation() throws {
        assertMacroExpansion(
            """
            @NavigationOrchestrator
            class SecureOrchestrator {
                @RouteProperty(.admin, validation: { await checkAdminAccess() })
                var admin = AdminContext.self
            }
            """,
            expandedSource: """
            class SecureOrchestrator {
                @RouteProperty(.admin, validation: { await checkAdminAccess() })
                var admin = AdminContext.self
                
                // Generated with validation
                func navigateToAdmin() async {
                    guard await checkAdminAccess() else { return }
                    await navigate(to: .admin)
                }
                
                private func registerRoutes() async {
                    await registerRoute(.admin) { _ in
                        guard await checkAdminAccess() else { 
                            throw NavigationError.unauthorized 
                        }
                        return AdminContext()
                    }
                }
            }
            """,
            macros: ["NavigationOrchestrator": NavigationOrchestratorMacro.self]
        )
    }
    
    func testNavigationOrchestratorHandlesParameters() throws {
        assertMacroExpansion(
            """
            @NavigationOrchestrator
            class ProductOrchestrator {
                @RouteProperty(.product)
                var product = ProductContext.self
                
                @RouteProperty(.category)
                var category = CategoryContext.self
            }
            """,
            expandedSource: """
            class ProductOrchestrator {
                @RouteProperty(.product)
                var product = ProductContext.self
                
                @RouteProperty(.category)
                var category = CategoryContext.self
                
                // Generated with parameter extraction
                func navigateToProduct(id: String, variant: String? = nil) async {
                    await navigate(to: .product(id: id, variant: variant))
                }
                
                func navigateToCategory(name: String, page: Int = 1) async {
                    await navigate(to: .category(name: name, page: page))
                }
                
                private func registerRoutes() async {
                    await registerRoute(.product) { route in
                        guard case .product(let id, let variant) = route else { 
                            return ProductContext(id: "", variant: nil) 
                        }
                        return ProductContext(id: id, variant: variant)
                    }
                    
                    await registerRoute(.category) { route in
                        guard case .category(let name, let page) = route else { 
                            return CategoryContext(name: "", page: 1) 
                        }
                        return CategoryContext(name: name, page: page)
                    }
                }
            }
            """,
            macros: ["NavigationOrchestrator": NavigationOrchestratorMacro.self]
        )
    }
}