//! Unit tests for naming convention utilities

use axiom_universal_client_generator::utils::naming::*;

#[test]
fn test_proto_to_swift_type_name() {
    assert_eq!(to_swift_type_name("UserService"), "UserService");
    assert_eq!(to_swift_type_name("user_service"), "UserService");
    assert_eq!(to_swift_type_name("API_KEY"), "ApiKey");
    assert_eq!(to_swift_type_name("HTTPResponse"), "HttpResponse");
    assert_eq!(to_swift_type_name("XMLDocument"), "XmlDocument");
    assert_eq!(to_swift_type_name("URLSession"), "UrlSession");
    assert_eq!(to_swift_type_name("task_manager_service"), "TaskManagerService");
}

#[test]
fn test_proto_to_swift_property_name() {
    assert_eq!(to_swift_property_name("user_id"), "userId");
    assert_eq!(to_swift_property_name("is_completed"), "isCompleted");
    assert_eq!(to_swift_property_name("created_at"), "createdAt");
    assert_eq!(to_swift_property_name("task_count"), "taskCount");
    assert_eq!(to_swift_property_name("api_key"), "apiKey");
    assert_eq!(to_swift_property_name("UUID"), "uuid");
    assert_eq!(to_swift_property_name("URL"), "url");
    assert_eq!(to_swift_property_name("HTTP_STATUS"), "httpStatus");
    assert_eq!(to_swift_property_name("first_name"), "firstName");
    assert_eq!(to_swift_property_name("last_name"), "lastName");
}

#[test]
fn test_proto_to_swift_method_name() {
    assert_eq!(to_swift_method_name("CreateTask"), "createTask");
    assert_eq!(to_swift_method_name("GetUserProfile"), "getUserProfile");
    assert_eq!(to_swift_method_name("ListAllTasks"), "listAllTasks");
    assert_eq!(to_swift_method_name("UpdateUser"), "updateUser");
    assert_eq!(to_swift_method_name("DeleteTask"), "deleteTask");
    assert_eq!(to_swift_method_name("SearchUsers"), "searchUsers");
    assert_eq!(to_swift_method_name("GetHTTPStatus"), "getHttpStatus");
    assert_eq!(to_swift_method_name("ValidateAPIKey"), "validateApiKey");
}

#[test]
fn test_proto_to_swift_enum_case() {
    assert_eq!(to_swift_enum_case("CreateTask"), "createTask");
    assert_eq!(to_swift_enum_case("DELETE_USER"), "deleteUser");
    assert_eq!(to_swift_enum_case("LIST_ALL"), "listAll");
    assert_eq!(to_swift_enum_case("GetUserProfile"), "getUserProfile");
    assert_eq!(to_swift_enum_case("VALIDATE_API_KEY"), "validateApiKey");
}

#[test]
fn test_proto_to_swift_constant_name() {
    assert_eq!(to_swift_constant_name("default_timeout"), "defaultTimeout");
    assert_eq!(to_swift_constant_name("MAX_RETRY_COUNT"), "maxRetryCount");
    assert_eq!(to_swift_constant_name("api_base_url"), "apiBaseUrl");
    assert_eq!(to_swift_constant_name("HTTP_TIMEOUT"), "httpTimeout");
}

#[test]
fn test_swift_actor_name_generation() {
    assert_eq!(to_swift_actor_name("TaskService"), "TaskClient");
    assert_eq!(to_swift_actor_name("UserService"), "UserClient");
    assert_eq!(to_swift_actor_name("PaymentService"), "PaymentClient");
    assert_eq!(to_swift_actor_name("NotificationService"), "NotificationClient");
    
    // Test with custom suffix
    assert_eq!(to_swift_actor_name_with_suffix("TaskService", "Manager"), "TaskManager");
    assert_eq!(to_swift_actor_name_with_suffix("UserService", "Actor"), "UserActor");
}

#[test]
fn test_swift_state_name_generation() {
    assert_eq!(to_swift_state_name("TaskService"), "TaskState");
    assert_eq!(to_swift_state_name("UserService"), "UserState");
    assert_eq!(to_swift_state_name("PaymentService"), "PaymentState");
    
    // Test with message names
    assert_eq!(to_swift_state_name("Task"), "TaskState");
    assert_eq!(to_swift_state_name("User"), "UserState");
}

#[test]
fn test_swift_action_name_generation() {
    assert_eq!(to_swift_action_name("TaskService"), "TaskAction");
    assert_eq!(to_swift_action_name("UserService"), "UserAction");
    assert_eq!(to_swift_action_name("PaymentService"), "PaymentAction");
}

#[test]
fn test_sanitize_swift_identifier() {
    assert_eq!(sanitize_swift_identifier("valid_name"), "valid_name");
    assert_eq!(sanitize_swift_identifier("123invalid"), "_123invalid");
    assert_eq!(sanitize_swift_identifier("class"), "`class`"); // Swift keyword
    assert_eq!(sanitize_swift_identifier("struct"), "`struct`"); // Swift keyword
    assert_eq!(sanitize_swift_identifier("var"), "`var`"); // Swift keyword
    assert_eq!(sanitize_swift_identifier("let"), "`let`"); // Swift keyword
    assert_eq!(sanitize_swift_identifier("func"), "`func`"); // Swift keyword
    assert_eq!(sanitize_swift_identifier("import"), "`import`"); // Swift keyword
    assert_eq!(sanitize_swift_identifier("protocol"), "`protocol`"); // Swift keyword
    assert_eq!(sanitize_swift_identifier("extension"), "`extension`"); // Swift keyword
    assert_eq!(sanitize_swift_identifier("enum"), "`enum`"); // Swift keyword
    assert_eq!(sanitize_swift_identifier("typealias"), "`typealias`"); // Swift keyword
    assert_eq!(sanitize_swift_identifier("actor"), "`actor`"); // Swift keyword
    assert_eq!(sanitize_swift_identifier("async"), "`async`"); // Swift keyword
    assert_eq!(sanitize_swift_identifier("await"), "`await`"); // Swift keyword
}

#[test]
fn test_is_swift_keyword() {
    assert!(is_swift_keyword("class"));
    assert!(is_swift_keyword("struct"));
    assert!(is_swift_keyword("enum"));
    assert!(is_swift_keyword("protocol"));
    assert!(is_swift_keyword("var"));
    assert!(is_swift_keyword("let"));
    assert!(is_swift_keyword("func"));
    assert!(is_swift_keyword("import"));
    assert!(is_swift_keyword("extension"));
    assert!(is_swift_keyword("typealias"));
    assert!(is_swift_keyword("actor"));
    assert!(is_swift_keyword("async"));
    assert!(is_swift_keyword("await"));
    assert!(is_swift_keyword("throws"));
    assert!(is_swift_keyword("rethrows"));
    assert!(is_swift_keyword("try"));
    assert!(is_swift_keyword("catch"));
    assert!(is_swift_keyword("defer"));
    assert!(is_swift_keyword("guard"));
    assert!(is_swift_keyword("if"));
    assert!(is_swift_keyword("else"));
    assert!(is_swift_keyword("switch"));
    assert!(is_swift_keyword("case"));
    assert!(is_swift_keyword("default"));
    assert!(is_swift_keyword("for"));
    assert!(is_swift_keyword("while"));
    assert!(is_swift_keyword("repeat"));
    assert!(is_swift_keyword("break"));
    assert!(is_swift_keyword("continue"));
    assert!(is_swift_keyword("return"));
    assert!(is_swift_keyword("public"));
    assert!(is_swift_keyword("private"));
    assert!(is_swift_keyword("internal"));
    assert!(is_swift_keyword("fileprivate"));
    assert!(is_swift_keyword("open"));
    assert!(is_swift_keyword("static"));
    assert!(is_swift_keyword("final"));
    assert!(is_swift_keyword("lazy"));
    assert!(is_swift_keyword("weak"));
    assert!(is_swift_keyword("unowned"));
    assert!(is_swift_keyword("mutating"));
    assert!(is_swift_keyword("nonmutating"));
    assert!(is_swift_keyword("override"));
    assert!(is_swift_keyword("required"));
    assert!(is_swift_keyword("convenience"));
    assert!(is_swift_keyword("dynamic"));
    assert!(is_swift_keyword("optional"));
    assert!(is_swift_keyword("indirect"));
    assert!(is_swift_keyword("inout"));
    
    // Test non-keywords
    assert!(!is_swift_keyword("validName"));
    assert!(!is_swift_keyword("userId"));
    assert!(!is_swift_keyword("TaskClient"));
    assert!(!is_swift_keyword("customProperty"));
}

#[test]
fn test_package_name_validation() {
    assert!(is_valid_swift_package_name("TaskManager"));
    assert!(is_valid_swift_package_name("UserService"));
    assert!(is_valid_swift_package_name("AxiomCore"));
    assert!(is_valid_swift_package_name("MyFramework123"));
    
    // Invalid package names
    assert!(!is_valid_swift_package_name("123InvalidStart"));
    assert!(!is_valid_swift_package_name("Invalid-Name"));
    assert!(!is_valid_swift_package_name("Invalid.Name"));
    assert!(!is_valid_swift_package_name(""));
    assert!(!is_valid_swift_package_name("class")); // Swift keyword
}

#[test]
fn test_file_name_generation() {
    assert_eq!(to_swift_file_name("TaskService", "Service"), "TaskService.swift");
    assert_eq!(to_swift_file_name("UserClient", "Client"), "UserClient.swift");
    assert_eq!(to_swift_file_name("TaskState", "State"), "TaskState.swift");
    assert_eq!(to_swift_file_name("TaskAction", "Action"), "TaskAction.swift");
    assert_eq!(to_swift_file_name("TaskModels", "Models"), "TaskModels.swift");
    
    // Test file names for tests
    assert_eq!(to_swift_test_file_name("TaskClient"), "TaskClientTests.swift");
    assert_eq!(to_swift_test_file_name("UserService"), "UserServiceTests.swift");
}

#[test]
fn test_directory_name_generation() {
    assert_eq!(to_swift_directory_name("TaskManager"), "TaskManager");
    assert_eq!(to_swift_directory_name("user_service"), "UserService");
    assert_eq!(to_swift_directory_name("API_CLIENT"), "ApiClient");
}

#[test]
fn test_namespace_handling() {
    assert_eq!(extract_namespace("com.example.task"), "com.example");
    assert_eq!(extract_namespace("task"), "");
    assert_eq!(extract_namespace("com.example.v1.task"), "com.example.v1");
    
    assert_eq!(to_swift_module_name("com.example.task"), "Task");
    assert_eq!(to_swift_module_name("task"), "Task");
    assert_eq!(to_swift_module_name("com.example.v1.user_service"), "UserService");
}

#[test]
fn test_acronym_handling() {
    assert_eq!(handle_acronyms("HTTPSConnection"), "HttpsConnection");
    assert_eq!(handle_acronyms("XMLDocument"), "XmlDocument");
    assert_eq!(handle_acronyms("URLSession"), "UrlSession");
    assert_eq!(handle_acronyms("APIKey"), "ApiKey");
    assert_eq!(handle_acronyms("SQLDatabase"), "SqlDatabase");
    assert_eq!(handle_acronyms("UIView"), "UiView");
    assert_eq!(handle_acronyms("JSONData"), "JsonData");
    
    // Should preserve single letters and known abbreviations
    assert_eq!(handle_acronyms("HTTPSClient"), "HttpsClient");
    assert_eq!(handle_acronyms("iOSApp"), "IosApp");
}

#[test]
fn test_version_suffix_handling() {
    assert_eq!(remove_version_suffix("TaskServiceV1"), "TaskService");
    assert_eq!(remove_version_suffix("UserServiceV2"), "UserService");
    assert_eq!(remove_version_suffix("APIv3"), "Api");
    assert_eq!(remove_version_suffix("ServiceVersion"), "ServiceVersion"); // Not a version suffix
    assert_eq!(remove_version_suffix("TaskService"), "TaskService"); // No version suffix
}

#[test]
fn test_pluralization() {
    assert_eq!(to_singular("tasks"), "task");
    assert_eq!(to_singular("users"), "user");
    assert_eq!(to_singular("categories"), "category");
    assert_eq!(to_singular("children"), "child");
    assert_eq!(to_singular("people"), "person");
    assert_eq!(to_singular("data"), "data"); // Uncountable
    
    assert_eq!(to_plural("task"), "tasks");
    assert_eq!(to_plural("user"), "users");
    assert_eq!(to_plural("category"), "categories");
    assert_eq!(to_plural("child"), "children");
    assert_eq!(to_plural("person"), "people");
}

#[test]
fn test_edge_cases() {
    // Empty strings
    assert_eq!(to_swift_type_name(""), "");
    assert_eq!(to_swift_property_name(""), "");
    
    // Single characters
    assert_eq!(to_swift_type_name("a"), "A");
    assert_eq!(to_swift_property_name("A"), "a");
    
    // Numbers only
    assert_eq!(sanitize_swift_identifier("123"), "_123");
    
    // Special characters
    assert_eq!(to_swift_type_name("task-service"), "TaskService");
    assert_eq!(to_swift_type_name("task.service"), "TaskService");
    assert_eq!(to_swift_type_name("task_service_v1"), "TaskServiceV1");
    
    // Unicode handling
    assert_eq!(to_swift_type_name("café"), "Café");
    assert_eq!(to_swift_property_name("naïve"), "naïve");
}