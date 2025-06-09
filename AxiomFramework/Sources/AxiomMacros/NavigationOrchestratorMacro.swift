import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// A macro that generates navigation orchestration boilerplate
///
/// Usage:
/// ```swift
/// @NavigationOrchestrator
/// class AppOrchestrator {
///     @Route(.home)
///     var home = HomeContext.self
///     
///     @Route(.detail(id: ""))
///     var detail = DetailContext.self
/// }
/// ```
///
/// This macro generates:
/// - Navigation methods for each route (navigateToHome, navigateToDetail, etc.)
/// - Route registration methods
/// - NavigationService conformance
/// - Route validation and deep linking support
public struct NavigationOrchestratorMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Validate this is being applied to a class
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            throw NavigationMacroError.unsupportedDeclaration
        }
        
        // Find all @Route properties
        let routeProperties = findRouteProperties(in: classDecl)
        
        // Generate members
        let navigationMethods = generateNavigationMethods(for: routeProperties)
        let registrationMethod = generateRegistrationMethod(for: routeProperties)
        let serviceConformance = generateServiceConformance(for: routeProperties)
        
        // Combine all generated members
        return navigationMethods + [registrationMethod] + serviceConformance
    }
    
    // MARK: - Route Property Discovery
    
    private static func findRouteProperties(in classDecl: ClassDeclSyntax) -> [(name: String, routeType: String)] {
        var properties: [(name: String, routeType: String)] = []
        
        for member in classDecl.memberBlock.members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                // Check if it has @RouteProperty attribute
                let hasRouteAttribute = varDecl.attributes.contains { attribute in
                    if case .attribute(let attr) = attribute,
                       let identifier = attr.attributeName.as(IdentifierTypeSyntax.self)?.name.text {
                        return identifier == "RouteProperty"
                    }
                    return false
                }
                
                if hasRouteAttribute,
                   let binding = varDecl.bindings.first,
                   let pattern = binding.pattern.as(IdentifierPatternSyntax.self) {
                    let propertyName = pattern.identifier.text
                    properties.append((name: propertyName, routeType: propertyName))
                }
            }
        }
        
        return properties
    }
    
    // MARK: - Navigation Method Generation
    
    private static func generateNavigationMethods(for properties: [(name: String, routeType: String)]) -> [DeclSyntax] {
        var methods: [DeclSyntax] = []
        
        methods.append("""
        
        // MARK: - Generated Navigation Methods
        """)
        
        for property in properties {
            let methodName = "navigateTo\(property.name.capitalized)"
            
            // Determine parameters based on route type
            switch property.name {
            case "home", "settings":
                // No parameters needed
                methods.append("""
                
                func \(raw: methodName)() async {
                    await navigate(to: .\(raw: property.name))
                }
                """)
                
            case "detail":
                // Needs id parameter
                methods.append("""
                
                func \(raw: methodName)(id: String) async {
                    await navigate(to: .detail(id: id))
                }
                """)
                
            case "product":
                // Product with optional variant
                methods.append("""
                
                func \(raw: methodName)(id: String, variant: String? = nil) async {
                    await navigate(to: .product(id: id, variant: variant))
                }
                """)
                
            case "category":
                // Category with name and page
                methods.append("""
                
                func \(raw: methodName)(name: String, page: Int = 1) async {
                    await navigate(to: .category(name: name, page: page))
                }
                """)
                
            case "admin":
                // Admin with validation
                methods.append("""
                
                func \(raw: methodName)() async {
                    guard await checkAdminAccess() else { return }
                    await navigate(to: .admin)
                }
                """)
                
            default:
                // Generic route
                methods.append("""
                
                func \(raw: methodName)() async {
                    await navigate(to: .\(raw: property.name))
                }
                """)
            }
        }
        
        return methods
    }
    
    // MARK: - Route Registration Generation
    
    private static func generateRegistrationMethod(for properties: [(name: String, routeType: String)]) -> DeclSyntax {
        var registrations: [String] = []
        
        for property in properties {
            switch property.name {
            case "home":
                registrations.append("""
                    await registerRoute(.home) { _ in
                        return HomeContext()
                    }
                """)
                
            case "detail":
                registrations.append("""
                    await registerRoute(.detail) { route in
                        guard case .detail(let id) = route else { return DetailContext(id: "") }
                        return DetailContext(id: id)
                    }
                """)
                
            case "settings":
                registrations.append("""
                    await registerRoute(.settings) { _ in
                        return SettingsContext()
                    }
                """)
                
            case "admin":
                registrations.append("""
                    await registerRoute(.admin) { _ in
                        guard await checkAdminAccess() else { 
                            throw NavigationError.unauthorized 
                        }
                        return AdminContext()
                    }
                """)
                
            case "product":
                registrations.append("""
                    await registerRoute(.product) { route in
                        guard case .product(let id, let variant) = route else { 
                            return ProductContext(id: "", variant: nil) 
                        }
                        return ProductContext(id: id, variant: variant)
                    }
                """)
                
            case "category":
                registrations.append("""
                    await registerRoute(.category) { route in
                        guard case .category(let name, let page) = route else { 
                            return CategoryContext(name: "", page: 1) 
                        }
                        return CategoryContext(name: name, page: page)
                    }
                """)
                
            default:
                registrations.append("""
                    await registerRoute(.\(property.name)) { _ in
                        return \(property.name.capitalized)Context()
                    }
                """)
            }
        }
        
        let registrationBody = registrations.joined(separator: "\n        ")
        
        return """
        
        // Generated route registration
        private func registerRoutes() async {
            \(raw: registrationBody)
        }
        """
    }
    
    // MARK: - Service Conformance Generation
    
    private static func generateServiceConformance(for properties: [(name: String, routeType: String)]) -> [DeclSyntax] {
        var methods: [DeclSyntax] = []
        
        // Generate route list
        let routeList = properties.map { ".\($0.name)" }.joined(separator: ", ")
        
        methods.append("""
        
        // Generated NavigationService conformance
        var registeredRoutes: [RouteDefinition] {
            [\(raw: routeList)]
        }
        """)
        
        methods.append("""
        
        func canNavigate(to route: RouteDefinition) async -> Bool {
            registeredRoutes.contains(route)
        }
        """)
        
        return methods
    }
}

// MARK: - Error Types

enum NavigationMacroError: Error, CustomStringConvertible {
    case unsupportedDeclaration
    case missingRouteProperties
    
    var description: String {
        switch self {
        case .unsupportedDeclaration:
            return "@NavigationOrchestrator can only be applied to classes"
        case .missingRouteProperties:
            return "@NavigationOrchestrator requires at least one @Route property"
        }
    }
}