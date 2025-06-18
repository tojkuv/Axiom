# AxiomEndpoints Framework Enhancement Plan

## Executive Summary

This plan outlines the implementation of 9 critical improvements to the AxiomEndpoints framework to reduce developer friction, enhance Aspire integration, and modernize the API development experience. The improvements are structured across 3 phases over 12-16 weeks, with comprehensive testing at each stage.

## Implementation Phases

### Phase 1: Foundation (Weeks 1-6)
**Goal**: Eliminate boilerplate and complete source generation
- Suggestion 1: Complete Source Generation Pipeline
- Suggestion 2: Reduce Endpoint Boilerplate  
- Suggestion 3: Auto-Query Parameter Binding

### Phase 2: Integration (Weeks 7-10)
**Goal**: Deep Aspire integration and cross-service communication
- Suggestion 4: Deep Aspire Integration
- Suggestion 5: Cross-Service Type Safety
- Suggestion 6: Configuration-Driven Features

### Phase 3: Enhancement (Weeks 11-16)
**Goal**: Modern web API features and performance
- Suggestion 7: Fluent Endpoint Configuration
- Suggestion 8: Built-in Validation & Error Handling
- Suggestion 9: Performance Optimizations

---

## Phase 1: Foundation (Weeks 1-6)

### Suggestion 1: Complete Source Generation Pipeline

#### Technical Specification
**Enhance Existing Generators**:
- `EndpointRegistrationGenerator.cs` - Auto-discover and register endpoints
- `RouteTemplateGenerator.cs` - Generate route templates from attributes
- `GrpcServiceGenerator.cs` - Generate gRPC service definitions

**New Generators**:
- `OpenApiGenerator.cs` - Generate OpenAPI specs from endpoint metadata
- `TypedClientGenerator.cs` - Generate strongly-typed HTTP clients
- `ValidationGenerator.cs` - Generate validation logic from attributes

#### Implementation Details

**EndpointRegistrationGenerator Enhancement**:
```csharp
// Generated code in EndpointRegistration.cs
public static class GeneratedEndpointRegistration
{
    public static void RegisterEndpoints(this IEndpointRouteBuilder endpoints)
    {
        endpoints.MapAxiom<GetUsersV1Endpoint>("/api/v1/users", HttpMethod.Get);
        endpoints.MapAxiom<CreateUserV1Endpoint>("/api/v1/users", HttpMethod.Post);
        // ... auto-generated for all discovered endpoints
    }
}
```

**OpenApiGenerator**:
```csharp
// Generate OpenAPI metadata from endpoint attributes and return types
[AttributeUsage(AttributeTargets.Class)]
public class OpenApiAttribute : Attribute
{
    public string Summary { get; set; }
    public string Description { get; set; }
    public string[] Tags { get; set; }
}
```

#### Testing Strategy
- **Unit Tests**: Test each generator with sample source code
- **Integration Tests**: Verify generated code compiles and runs correctly
- **Snapshot Tests**: Ensure generator output stability across changes
- **Performance Tests**: Measure compilation time impact

#### Deliverables
- [ ] Enhanced `EndpointRegistrationGenerator` with auto-discovery
- [ ] Complete `RouteTemplateGenerator` implementation
- [ ] New `OpenApiGenerator` with full OpenAPI 3.0 support
- [ ] `TypedClientGenerator` for cross-service communication
- [ ] Comprehensive test suite (90%+ coverage)
- [ ] Documentation and examples

---

### Suggestion 2: Reduce Endpoint Boilerplate

#### Technical Specification
**Attribute-Based Endpoint Definition**:
```csharp
// Current boilerplate (15+ lines)
public class GetUserByIdV1Endpoint : IRouteAxiom<Routes.V1.Users.ById, ApiResponse<UserResponse>>
{
    public static HttpMethod HttpMethod => HttpMethod.Get;
    private readonly AppDbContext _context;
    
    public GetUserByIdV1Endpoint(AppDbContext context) => _context = context;
    
    public async Task<Result<ApiResponse<UserResponse>>> HandleAsync(Routes.V1.Users.ById route, CancellationToken cancellationToken)
    {
        // Implementation...
    }
}

// Target minimal syntax (3-5 lines)
[Get("/api/v1/users/{id:guid}")]
[OpenApi("Get user by ID", "Returns a user by their unique identifier")]
public static async Task<Result<ApiResponse<UserResponse>>> GetUserById(
    Guid id, 
    AppDbContext context,
    CancellationToken cancellationToken = default)
{
    var user = await context.Users.FindAsync(id, cancellationToken);
    return user is not null 
        ? Result.Success(ApiResponse.Success(user.ToResponse()))
        : Result.NotFound("User not found");
}
```

**Source Generator Implementation**:
- Detect methods with HTTP attribute decorations
- Generate endpoint classes implementing `IRouteAxiom<,>`
- Handle dependency injection automatically
- Generate route classes for complex parameters

#### Implementation Details

**HTTP Method Attributes**:
```csharp
[AttributeUsage(AttributeTargets.Method)]
public class HttpMethodAttribute : Attribute
{
    public string Template { get; }
    public string Name { get; set; }
    public string[] Tags { get; set; }
    
    protected HttpMethodAttribute(string template) => Template = template;
}

public class GetAttribute : HttpMethodAttribute
{
    public GetAttribute(string template) : base(template) { }
}

public class PostAttribute : HttpMethodAttribute
{
    public PostAttribute(string template) : base(template) { }
}
// ... Put, Delete, Patch
```

**Generated Endpoint Class**:
```csharp
// Generated by MinimalEndpointGenerator
public class GetUserById_Generated : IRouteAxiom<GetUserById_Route, ApiResponse<UserResponse>>
{
    public static HttpMethod HttpMethod => HttpMethod.Get;
    private readonly AppDbContext _context;
    
    public GetUserById_Generated(AppDbContext context) => _context = context;
    
    public async Task<Result<ApiResponse<UserResponse>>> HandleAsync(
        GetUserById_Route route, 
        CancellationToken cancellationToken)
    {
        return await UserEndpoints.GetUserById(route.Id, _context, cancellationToken);
    }
}
```

#### Testing Strategy
- **Unit Tests**: Test attribute detection and code generation
- **Integration Tests**: Verify generated endpoints work with ASP.NET Core
- **Regression Tests**: Ensure existing endpoint patterns still work
- **Performance Tests**: Compare minimal vs traditional endpoint performance

#### Deliverables
- [ ] HTTP method attributes (`GetAttribute`, `PostAttribute`, etc.)
- [ ] `MinimalEndpointGenerator` source generator
- [ ] Route parameter binding generator
- [ ] Migration guide from traditional to minimal syntax
- [ ] Comprehensive test coverage
- [ ] Performance benchmarks

---

### Suggestion 3: Auto-Query Parameter Binding

#### Technical Specification
**Problem**: Current manual query parameter extraction
```csharp
// Current: 30+ lines of manual extraction in SearchUsersV1Endpoint
var searchTerm = context.Request.Query["searchTerm"].FirstOrDefault() ?? string.Empty;
var pageNumber = int.TryParse(context.Request.Query["pageNumber"].FirstOrDefault(), out var page) ? page : 1;
// ... continues for each parameter
```

**Solution**: Automatic binding from method signatures
```csharp
[Get("/api/v1/users")]
public static async Task<Result<PagedResponse<UserResponse>>> SearchUsers(
    [FromQuery] string searchTerm = "",
    [FromQuery] int pageNumber = 1,
    [FromQuery] int pageSize = 10,
    [FromQuery] UserSortBy sortBy = UserSortBy.Name,
    [FromQuery] SortDirection sortDirection = SortDirection.Ascending,
    AppDbContext context,
    CancellationToken cancellationToken = default)
{
    // Direct parameter usage - no manual extraction needed
}

// Or with complex query objects
[Get("/api/v1/users")]
public static async Task<Result<PagedResponse<UserResponse>>> SearchUsers(
    [FromQuery] UserSearchQuery query,
    AppDbContext context,
    CancellationToken cancellationToken = default)
{
    // query.SearchTerm, query.PageNumber, etc. automatically bound
}
```

#### Implementation Details

**Query Parameter Binding Attributes**:
```csharp
[AttributeUsage(AttributeTargets.Parameter)]
public class FromQueryAttribute : Attribute
{
    public string Name { get; set; }
    public object DefaultValue { get; set; }
    public bool Required { get; set; } = false;
}

[AttributeUsage(AttributeTargets.Parameter)]
public class FromRouteAttribute : Attribute
{
    public string Name { get; set; }
}

[AttributeUsage(AttributeTargets.Parameter)]
public class FromBodyAttribute : Attribute { }
```

**Generated Binding Code**:
```csharp
// Generated in the endpoint wrapper
public async Task<Result<PagedResponse<UserResponse>>> HandleAsync(
    SearchUsers_Route route, 
    CancellationToken cancellationToken)
{
    var context = _httpContextAccessor.HttpContext;
    
    // Generated parameter extraction
    var searchTerm = context.Request.Query["searchTerm"].FirstOrDefault() ?? "";
    var pageNumber = ParseInt32(context.Request.Query["pageNumber"].FirstOrDefault(), 1);
    var pageSize = ParseInt32(context.Request.Query["pageSize"].FirstOrDefault(), 10);
    var sortBy = ParseEnum<UserSortBy>(context.Request.Query["sortBy"].FirstOrDefault(), UserSortBy.Name);
    var sortDirection = ParseEnum<SortDirection>(context.Request.Query["sortDirection"].FirstOrDefault(), SortDirection.Ascending);
    
    return await UserEndpoints.SearchUsers(searchTerm, pageNumber, pageSize, sortBy, sortDirection, _context, cancellationToken);
}
```

**Complex Query Object Support**:
```csharp
public class UserSearchQuery
{
    public string SearchTerm { get; set; } = "";
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 10;
    public UserSortBy SortBy { get; set; } = UserSortBy.Name;
    public SortDirection SortDirection { get; set; } = SortDirection.Ascending;
    
    [FromQuery("roles")]
    public List<string> UserRoles { get; set; } = new();
    
    [FromQuery("createdAfter")]
    public DateTime? CreatedAfter { get; set; }
}
```

#### Testing Strategy
- **Unit Tests**: Test parameter binding generation for various types
- **Integration Tests**: Verify query parameter extraction works correctly
- **Edge Case Tests**: Test null values, invalid formats, missing parameters
- **Performance Tests**: Compare auto-binding vs manual extraction performance

#### Deliverables
- [ ] Parameter binding attributes
- [ ] `QueryParameterBindingGenerator` source generator
- [ ] Support for primitive types, enums, collections, and complex objects
- [ ] Validation integration for bound parameters
- [ ] Comprehensive test suite
- [ ] Documentation with examples

---

## Phase 2: Integration (Weeks 7-10)

### Suggestion 4: Deep Aspire Integration

#### Technical Specification
**Enhanced AppHost Integration**:
```csharp
// Current minimal integration
var builder = DistributedApplication.CreateBuilder(args);
builder.AddProject<Projects.UserApi>("users");

// Target enhanced integration
var builder = DistributedApplication.CreateBuilder(args);
builder.AddAxiomService<Projects.UserApi>("users")
    .WithHealthChecks()
    .WithDistributedTracing()
    .WithServiceDiscovery()
    .WithMetrics()
    .WithConfiguration(config => config
        .AddRateLimit(100, TimeSpan.FromMinutes(1))
        .AddResponseCaching(TimeSpan.FromMinutes(5))
        .AddAuthentication("ApiKey"));
```

#### Implementation Details

**AspireBuilderExtensions Enhancement**:
```csharp
public static class AspireBuilderExtensions
{
    public static IResourceBuilder<ProjectResource> AddAxiomService<TProject>(
        this IDistributedApplicationBuilder builder,
        string name)
        where TProject : IProjectMetadata, new()
    {
        var project = builder.AddProject<TProject>(name);
        
        // Auto-configure AxiomEndpoints specific features
        project.WithEnvironment("AXIOM_TELEMETRY_ENABLED", "true")
               .WithEnvironment("AXIOM_HEALTH_CHECKS_ENABLED", "true")
               .WithEnvironment("AXIOM_METRICS_ENABLED", "true");
               
        return project;
    }
    
    public static IResourceBuilder<ProjectResource> WithAxiomConfiguration(
        this IResourceBuilder<ProjectResource> builder,
        Action<AxiomConfigurationBuilder> configure)
    {
        var config = new AxiomConfigurationBuilder();
        configure(config);
        
        // Apply configuration as environment variables
        foreach (var setting in config.Build())
        {
            builder.WithEnvironment(setting.Key, setting.Value);
        }
        
        return builder;
    }
}

public class AxiomConfigurationBuilder
{
    private readonly Dictionary<string, string> _settings = new();
    
    public AxiomConfigurationBuilder AddRateLimit(int requests, TimeSpan window)
    {
        _settings["AXIOM_RATE_LIMIT_REQUESTS"] = requests.ToString();
        _settings["AXIOM_RATE_LIMIT_WINDOW"] = window.ToString();
        return this;
    }
    
    public AxiomConfigurationBuilder AddResponseCaching(TimeSpan defaultTtl)
    {
        _settings["AXIOM_RESPONSE_CACHE_TTL"] = defaultTtl.ToString();
        return this;
    }
    
    public Dictionary<string, string> Build() => _settings;
}
```

**Auto Health Checks**:
```csharp
// Generated health check registration
public static class GeneratedHealthChecks
{
    public static IServiceCollection AddAxiomHealthChecks(this IServiceCollection services)
    {
        services.AddHealthChecks()
            .AddCheck<DatabaseHealthCheck>("database")
            .AddCheck<EndpointHealthCheck>("endpoints")
            .AddCheck<DependencyHealthCheck>("dependencies");
            
        return services;
    }
}
```

#### Testing Strategy
- **Integration Tests**: Test Aspire integration with real distributed application
- **Unit Tests**: Test configuration builders and extension methods
- **End-to-End Tests**: Verify health checks, telemetry, and service discovery
- **Load Tests**: Test performance under Aspire orchestration

#### Deliverables
- [ ] Enhanced `AspireBuilderExtensions` with fluent configuration
- [ ] Auto-generated health checks for AxiomEndpoints
- [ ] Telemetry integration with OpenTelemetry
- [ ] Service discovery integration
- [ ] Configuration management integration
- [ ] Documentation and examples

---

### Suggestion 5: Cross-Service Type Safety

#### Technical Specification
**Generated Typed Clients**:
```csharp
// Auto-generated from UserApi endpoints
public interface IUserApiClient
{
    Task<Result<ApiResponse<UserResponse>>> GetUserById(Guid id, CancellationToken cancellationToken = default);
    Task<Result<PagedResponse<UserResponse>>> SearchUsers(UserSearchQuery query, CancellationToken cancellationToken = default);
    Task<Result<ApiResponse<UserResponse>>> CreateUser(CreateUserRequest request, CancellationToken cancellationToken = default);
}

public class UserApiClient : IUserApiClient
{
    private readonly HttpClient _httpClient;
    private readonly IServiceDiscovery _serviceDiscovery;
    
    public UserApiClient(HttpClient httpClient, IServiceDiscovery serviceDiscovery)
    {
        _httpClient = httpClient;
        _serviceDiscovery = serviceDiscovery;
    }
    
    public async Task<Result<ApiResponse<UserResponse>>> GetUserById(Guid id, CancellationToken cancellationToken = default)
    {
        var serviceUrl = await _serviceDiscovery.ResolveAsync("users", cancellationToken);
        var response = await _httpClient.GetAsync($"{serviceUrl}/api/v1/users/{id}", cancellationToken);
        
        if (response.IsSuccessStatusCode)
        {
            var content = await response.Content.ReadAsStringAsync(cancellationToken);
            var result = JsonSerializer.Deserialize<ApiResponse<UserResponse>>(content);
            return Result.Success(result);
        }
        
        return Result.Failure($"Request failed with status {response.StatusCode}");
    }
}
```

**Service Discovery Integration**:
```csharp
// Registration in consuming service
services.AddAxiomClient<IUserApiClient>("users")
    .WithCircuitBreaker(handledEventsAllowedBeforeBreaking: 3)
    .WithRetry(retryCount: 3)
    .WithTimeout(TimeSpan.FromSeconds(30));
```

#### Implementation Details

**Client Generation Pipeline**:
1. **Endpoint Discovery**: Scan assemblies for AxiomEndpoint classes
2. **Interface Generation**: Generate client interfaces from endpoint signatures
3. **Implementation Generation**: Generate HttpClient-based implementations
4. **Service Registration**: Generate DI registration extensions

**Generated Client Registration**:
```csharp
public static class GeneratedClientRegistration
{
    public static IServiceCollection AddAxiomClients(this IServiceCollection services)
    {
        services.AddHttpClient<IUserApiClient, UserApiClient>();
        services.AddHttpClient<IOrderApiClient, OrderApiClient>();
        // ... auto-generated for all discovered APIs
        
        return services;
    }
}
```

#### Testing Strategy
- **Unit Tests**: Test client generation logic
- **Integration Tests**: Test generated clients against real services
- **Contract Tests**: Verify client-server compatibility
- **Resilience Tests**: Test circuit breaker, retry, and timeout policies

#### Deliverables
- [ ] `TypedClientGenerator` for HTTP clients
- [ ] Service discovery integration
- [ ] Resilience patterns (circuit breaker, retry, timeout)
- [ ] Client registration extensions
- [ ] Comprehensive test suite
- [ ] Documentation and examples

---

### Suggestion 6: Configuration-Driven Features

#### Technical Specification
**Configuration Schema**:
```json
{
  "AxiomEndpoints": {
    "RateLimit": {
      "GlobalEnabled": true,
      "DefaultRequestsPerMinute": 100,
      "DefaultWindow": "00:01:00",
      "Endpoints": {
        "/api/v1/users": {
          "RequestsPerMinute": 200,
          "Window": "00:01:00"
        }
      }
    },
    "Caching": {
      "GlobalEnabled": true,
      "DefaultTtl": "00:05:00",
      "Endpoints": {
        "/api/v1/users/{id}": {
          "Ttl": "00:10:00",
          "VaryByHeader": ["Authorization"]
        }
      }
    },
    "Authentication": {
      "DefaultScheme": "ApiKey",
      "ApiKey": {
        "HeaderName": "X-API-Key",
        "QueryParameterName": "api_key"
      },
      "Endpoints": {
        "/api/v1/admin/*": {
          "RequiredRoles": ["Admin"],
          "RequiredScopes": ["admin:read", "admin:write"]
        }
      }
    },
    "Validation": {
      "GlobalEnabled": true,
      "ReturnValidationDetails": true,
      "Endpoints": {
        "/api/v1/users": {
          "CustomValidators": ["UserCreateValidator"]
        }
      }
    },
    "Telemetry": {
      "TracingEnabled": true,
      "MetricsEnabled": true,
      "LoggingEnabled": true,
      "SamplingRatio": 0.1
    }
  }
}
```

#### Implementation Details

**Configuration Classes**:
```csharp
public class AxiomEndpointsOptions
{
    public RateLimitOptions RateLimit { get; set; } = new();
    public CachingOptions Caching { get; set; } = new();
    public AuthenticationOptions Authentication { get; set; } = new();
    public ValidationOptions Validation { get; set; } = new();
    public TelemetryOptions Telemetry { get; set; } = new();
}

public class RateLimitOptions
{
    public bool GlobalEnabled { get; set; } = true;
    public int DefaultRequestsPerMinute { get; set; } = 100;
    public TimeSpan DefaultWindow { get; set; } = TimeSpan.FromMinutes(1);
    public Dictionary<string, EndpointRateLimitOptions> Endpoints { get; set; } = new();
}

public class EndpointRateLimitOptions
{
    public int RequestsPerMinute { get; set; }
    public TimeSpan Window { get; set; }
    public string[] ExemptRoles { get; set; } = Array.Empty<string>();
}
```

**Configuration-Driven Middleware**:
```csharp
public class ConfigurationDrivenMiddleware
{
    private readonly RequestDelegate _next;
    private readonly IOptionsMonitor<AxiomEndpointsOptions> _options;
    
    public ConfigurationDrivenMiddleware(RequestDelegate next, IOptionsMonitor<AxiomEndpointsOptions> options)
    {
        _next = next;
        _options = options;
    }
    
    public async Task InvokeAsync(HttpContext context)
    {
        var options = _options.CurrentValue;
        var endpoint = context.GetEndpoint();
        var route = context.Request.Path.Value;
        
        // Apply rate limiting if configured
        if (options.RateLimit.GlobalEnabled && ShouldApplyRateLimit(route, options.RateLimit))
        {
            if (!await CheckRateLimit(context, route, options.RateLimit))
            {
                context.Response.StatusCode = 429;
                return;
            }
        }
        
        // Apply caching if configured
        if (options.Caching.GlobalEnabled && ShouldApplyCache(route, options.Caching))
        {
            if (await TryServeFromCache(context, route, options.Caching))
                return;
        }
        
        await _next(context);
        
        // Cache response if configured
        if (options.Caching.GlobalEnabled && ShouldCacheResponse(context, route, options.Caching))
        {
            await CacheResponse(context, route, options.Caching);
        }
    }
}
```

#### Testing Strategy
- **Unit Tests**: Test configuration parsing and validation
- **Integration Tests**: Test configuration-driven behavior
- **Configuration Tests**: Test various configuration scenarios
- **Performance Tests**: Measure configuration lookup performance

#### Deliverables
- [ ] Configuration schema and classes
- [ ] Configuration-driven middleware pipeline
- [ ] Hot-reload support for configuration changes
- [ ] Configuration validation and error handling
- [ ] Documentation and examples
- [ ] JSON schema for IDE support

---

## Phase 3: Enhancement (Weeks 11-16)

### Suggestion 7: Fluent Endpoint Configuration

#### Technical Specification
**Fluent Configuration API**:
```csharp
// In Program.cs or extension method
app.MapAxiomEndpoints(endpoints =>
{
    endpoints.MapEndpoint<GetUsersEndpoint>()
        .RequiresAuthorization("admin")
        .WithRateLimit(200, TimeSpan.FromMinutes(1))
        .WithResponseCache(TimeSpan.FromMinutes(10))
        .WithTags("Users", "V1")
        .ProducesApiVersion("1.0")
        .WithName("GetUsers");
        
    endpoints.MapEndpoint<CreateUserEndpoint>()
        .RequiresAuthorization()
        .WithValidation<CreateUserValidator>()
        .WithCircuitBreaker(handledEventsAllowedBeforeBreaking: 3)
        .WithRetry(maxRetryAttempts: 3)
        .WithTags("Users", "V1")
        .AcceptsJson<CreateUserRequest>()
        .ProducesJson<ApiResponse<UserResponse>>();
});

// Or with method chaining for groups
app.MapAxiomEndpoints(endpoints =>
{
    endpoints.MapGroup("/api/v1/users")
        .RequiresAuthorization()
        .WithTags("Users", "V1")
        .ProducesApiVersion("1.0")
        .WithRateLimit(100, TimeSpan.FromMinutes(1))
        .MapEndpoints(group =>
        {
            group.MapEndpoint<GetUsersEndpoint>();
            group.MapEndpoint<GetUserByIdEndpoint>();
            group.MapEndpoint<CreateUserEndpoint>()
                .RequiresAuthorization("admin");
            group.MapEndpoint<UpdateUserEndpoint>()
                .RequiresAuthorization("admin");
            group.MapEndpoint<DeleteUserEndpoint>()
                .RequiresAuthorization("admin");
        });
});
```

#### Implementation Details

**Fluent Builder Classes**:
```csharp
public class AxiomEndpointBuilder
{
    private readonly IEndpointRouteBuilder _endpoints;
    private readonly List<Action<RouteHandlerBuilder>> _configurations = new();
    
    public AxiomEndpointBuilder(IEndpointRouteBuilder endpoints)
    {
        _endpoints = endpoints;
    }
    
    public AxiomEndpointBuilder<T> MapEndpoint<T>() where T : class, IAxiom
    {
        return new AxiomEndpointBuilder<T>(_endpoints, _configurations);
    }
    
    public AxiomGroupBuilder MapGroup(string prefix)
    {
        return new AxiomGroupBuilder(_endpoints.MapGroup(prefix), _configurations);
    }
}

public class AxiomEndpointBuilder<T> where T : class, IAxiom
{
    private readonly IEndpointRouteBuilder _endpoints;
    private readonly List<Action<RouteHandlerBuilder>> _configurations;
    
    public AxiomEndpointBuilder<T> RequiresAuthorization(params string[] roles)
    {
        _configurations.Add(builder => builder.RequireAuthorization(roles));
        return this;
    }
    
    public AxiomEndpointBuilder<T> WithRateLimit(int requests, TimeSpan window)
    {
        _configurations.Add(builder => builder.WithMetadata(new RateLimitMetadata(requests, window)));
        return this;
    }
    
    public AxiomEndpointBuilder<T> WithResponseCache(TimeSpan ttl)
    {
        _configurations.Add(builder => builder.WithMetadata(new CacheMetadata(ttl)));
        return this;
    }
    
    public AxiomEndpointBuilder<T> WithTags(params string[] tags)
    {
        _configurations.Add(builder => builder.WithTags(tags));
        return this;
    }
    
    public void Build()
    {
        var route = GetRouteTemplate<T>();
        var method = GetHttpMethod<T>();
        var handler = CreateHandler<T>();
        
        var routeBuilder = _endpoints.MapMethods(route, new[] { method.Method }, handler);
        
        foreach (var config in _configurations)
        {
            config(routeBuilder);
        }
    }
}
```

**Metadata Classes**:
```csharp
public class RateLimitMetadata
{
    public int Requests { get; }
    public TimeSpan Window { get; }
    
    public RateLimitMetadata(int requests, TimeSpan window)
    {
        Requests = requests;
        Window = window;
    }
}

public class CacheMetadata
{
    public TimeSpan Ttl { get; }
    public string[] VaryByHeaders { get; }
    
    public CacheMetadata(TimeSpan ttl, params string[] varyByHeaders)
    {
        Ttl = ttl;
        VaryByHeaders = varyByHeaders;
    }
}
```

#### Testing Strategy
- **Unit Tests**: Test fluent builder methods and configuration
- **Integration Tests**: Test that fluent configuration affects endpoint behavior
- **API Tests**: Verify that configured endpoints behave as expected
- **Documentation Tests**: Ensure all fluent methods are documented

#### Deliverables
- [ ] Fluent builder classes for endpoint configuration
- [ ] Group configuration support
- [ ] Metadata classes for various features
- [ ] Extension methods for common scenarios
- [ ] Comprehensive test suite
- [ ] Documentation with examples

---

### Suggestion 8: Built-in Validation & Error Handling

#### Technical Specification
**Automatic Validation**:
```csharp
[Post("/api/v1/users")]
public static async Task<Result<ApiResponse<UserResponse>>> CreateUser(
    [FromBody] CreateUserRequest request,
    [FromServices] IValidator<CreateUserRequest> validator,
    AppDbContext context,
    CancellationToken cancellationToken = default)
{
    // Validation happens automatically before method execution
    // If validation fails, standardized error response is returned
    
    var user = new User
    {
        Name = request.Name,
        Email = request.Email,
        // ...
    };
    
    context.Users.Add(user);
    await context.SaveChangesAsync(cancellationToken);
    
    return Result.Success(ApiResponse.Success(user.ToResponse()));
}

public class CreateUserRequest
{
    [Required]
    [StringLength(100, MinimumLength = 2)]
    public string Name { get; set; } = "";
    
    [Required]
    [EmailAddress]
    public string Email { get; set; } = "";
    
    [Range(18, 120)]
    public int Age { get; set; }
    
    [Phone]
    public string? PhoneNumber { get; set; }
}
```

**Standardized Error Responses**:
```csharp
public class ApiError
{
    public string Type { get; set; } = "";
    public string Title { get; set; } = "";
    public string Detail { get; set; } = "";
    public int Status { get; set; }
    public string Instance { get; set; } = "";
    public Dictionary<string, object> Extensions { get; set; } = new();
}

public class ValidationApiError : ApiError
{
    public Dictionary<string, string[]> Errors { get; set; } = new();
    
    public ValidationApiError(ValidationResult validationResult)
    {
        Type = "validation-error";
        Title = "One or more validation errors occurred.";
        Status = 400;
        
        Errors = validationResult.Errors
            .GroupBy(e => e.PropertyName)
            .ToDictionary(g => g.Key, g => g.Select(e => e.ErrorMessage).ToArray());
    }
}
```

#### Implementation Details

**Automatic Validation Middleware**:
```csharp
public class ValidationMiddleware
{
    private readonly RequestDelegate _next;
    private readonly IServiceProvider _serviceProvider;
    
    public ValidationMiddleware(RequestDelegate next, IServiceProvider serviceProvider)
    {
        _next = next;
        _serviceProvider = serviceProvider;
    }
    
    public async Task InvokeAsync(HttpContext context)
    {
        var endpoint = context.GetEndpoint();
        if (endpoint?.Metadata.GetMetadata<ValidationMetadata>() is ValidationMetadata validationMetadata)
        {
            var validationResult = await ValidateRequest(context, validationMetadata);
            if (!validationResult.IsValid)
            {
                await WriteValidationErrorResponse(context, validationResult);
                return;
            }
        }
        
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            await HandleException(context, ex);
        }
    }
    
    private async Task HandleException(HttpContext context, Exception exception)
    {
        var error = exception switch
        {
            ValidationException validationEx => new ValidationApiError(validationEx.Errors),
            NotFoundException notFoundEx => new ApiError
            {
                Type = "not-found",
                Title = "Resource not found",
                Detail = notFoundEx.Message,
                Status = 404
            },
            // ... other exception types
            _ => new ApiError
            {
                Type = "internal-error",
                Title = "An error occurred while processing your request.",
                Status = 500
            }
        };
        
        context.Response.StatusCode = error.Status;
        context.Response.ContentType = "application/json";
        
        var json = JsonSerializer.Serialize(error, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        });
        
        await context.Response.WriteAsync(json);
    }
}
```

**Generated Validation**:
```csharp
// Generated from CreateUserRequest
public class CreateUserRequestValidator : AbstractValidator<CreateUserRequest>
{
    public CreateUserRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty()
            .Length(2, 100);
            
        RuleFor(x => x.Email)
            .NotEmpty()
            .EmailAddress();
            
        RuleFor(x => x.Age)
            .InclusiveBetween(18, 120);
            
        RuleFor(x => x.PhoneNumber)
            .Matches(@"^\+?[1-9]\d{1,14}$")
            .When(x => !string.IsNullOrEmpty(x.PhoneNumber));
    }
}
```

#### Testing Strategy
- **Unit Tests**: Test validation logic and error handling
- **Integration Tests**: Test validation middleware with various scenarios
- **Edge Case Tests**: Test validation with malformed input
- **Performance Tests**: Measure validation performance impact

#### Deliverables
- [ ] Automatic validation middleware
- [ ] Validation generator from Data Annotations
- [ ] Standardized error response classes
- [ ] Exception handling middleware
- [ ] FluentValidation integration
- [ ] Comprehensive test suite

---

### Suggestion 9: Performance Optimizations

#### Technical Specification
**Response Caching with ETags**:
```csharp
[Get("/api/v1/users/{id:guid}")]
[ResponseCache(Duration = 300)] // 5 minutes
public static async Task<Result<ApiResponse<UserResponse>>> GetUserById(
    Guid id,
    AppDbContext context,
    CancellationToken cancellationToken = default)
{
    var user = await context.Users.FindAsync(id, cancellationToken);
    if (user is null)
        return Result.NotFound("User not found");
    
    var response = ApiResponse.Success(user.ToResponse());
    
    // ETag generated from user's last modified timestamp
    response.ETag = GenerateETag(user.LastModified);
    
    return Result.Success(response);
}
```

**Request/Response Compression**:
```csharp
// Automatic compression based on content type and size
public class CompressionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly CompressionOptions _options;
    
    public async Task InvokeAsync(HttpContext context)
    {
        // Compress request body if applicable
        if (ShouldDecompressRequest(context))
        {
            context.Request.Body = DecompressStream(context.Request.Body);
        }
        
        // Wrap response stream for compression
        if (ShouldCompressResponse(context))
        {
            var originalStream = context.Response.Body;
            using var compressionStream = new GZipStream(originalStream, CompressionLevel.Optimal);
            context.Response.Body = compressionStream;
            context.Response.Headers.Add("Content-Encoding", "gzip");
        }
        
        await _next(context);
    }
}
```

**Object Pooling**:
```csharp
public class PooledObjectMiddleware<T> where T : class, new()
{
    private static readonly ObjectPool<T> Pool = new DefaultObjectPool<T>(new DefaultPooledObjectPolicy<T>());
    
    public static T Get() => Pool.Get();
    public static void Return(T obj) => Pool.Return(obj);
}

// Usage in endpoints
[Get("/api/v1/users")]
public static async Task<Result<PagedResponse<UserResponse>>> GetUsers(
    [FromQuery] UserSearchQuery query,
    AppDbContext context,
    CancellationToken cancellationToken = default)
{
    var searchBuilder = PooledObjectMiddleware<StringBuilder>.Get();
    try
    {
        // Use pooled StringBuilder for query building
        var sql = BuildQuery(searchBuilder, query);
        var users = await context.Users.FromSqlRaw(sql).ToListAsync(cancellationToken);
        
        return Result.Success(new PagedResponse<UserResponse>
        {
            Data = users.Select(u => u.ToResponse()).ToList(),
            // ...
        });
    }
    finally
    {
        PooledObjectMiddleware<StringBuilder>.Return(searchBuilder);
    }
}
```

#### Implementation Details

**Performance Monitoring**:
```csharp
public class PerformanceMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<PerformanceMiddleware> _logger;
    private readonly DiagnosticSource _diagnosticSource;
    
    public async Task InvokeAsync(HttpContext context)
    {
        var stopwatch = Stopwatch.StartNew();
        var startTime = DateTimeOffset.UtcNow;
        
        try
        {
            await _next(context);
        }
        finally
        {
            stopwatch.Stop();
            var duration = stopwatch.ElapsedMilliseconds;
            
            // Log slow requests
            if (duration > 1000)
            {
                _logger.LogWarning("Slow request: {Method} {Path} took {Duration}ms",
                    context.Request.Method,
                    context.Request.Path,
                    duration);
            }
            
            // Emit metrics
            _diagnosticSource.Write("AxiomEndpoints.RequestCompleted", new
            {
                HttpContext = context,
                Duration = duration,
                StatusCode = context.Response.StatusCode
            });
            
            // Add performance headers
            context.Response.Headers.Add("X-Response-Time", $"{duration}ms");
        }
    }
}
```

**Memory Optimization**:
```csharp
// Span<T> usage for string operations
public static class StringExtensions
{
    public static bool TryParseGuid(ReadOnlySpan<char> input, out Guid result)
    {
        return Guid.TryParse(input, out result);
    }
    
    public static ReadOnlySpan<char> ExtractBearerToken(ReadOnlySpan<char> authHeader)
    {
        const string bearerPrefix = "Bearer ";
        return authHeader.StartsWith(bearerPrefix.AsSpan(), StringComparison.OrdinalIgnoreCase)
            ? authHeader.Slice(bearerPrefix.Length)
            : ReadOnlySpan<char>.Empty;
    }
}

// ArrayPool usage for collections
public class ArrayPoolMiddleware
{
    private static readonly ArrayPool<byte> BytePool = ArrayPool<byte>.Shared;
    private static readonly ArrayPool<char> CharPool = ArrayPool<char>.Shared;
    
    public static byte[] RentBytes(int minimumLength) => BytePool.Rent(minimumLength);
    public static void ReturnBytes(byte[] array) => BytePool.Return(array);
    
    public static char[] RentChars(int minimumLength) => CharPool.Rent(minimumLength);
    public static void ReturnChars(char[] array) => CharPool.Return(array);
}
```

#### Testing Strategy
- **Performance Tests**: Benchmark before/after performance improvements
- **Load Tests**: Test caching and compression under load
- **Memory Tests**: Verify object pooling reduces allocations
- **Stress Tests**: Test performance under extreme conditions

#### Deliverables
- [ ] Response caching with ETag support
- [ ] Request/response compression middleware
- [ ] Object pooling for common types
- [ ] Performance monitoring and metrics
- [ ] Memory optimization utilities
- [ ] Comprehensive performance test suite

---

## Comprehensive Testing Strategy

### Test Categories

#### 1. Unit Tests (Target: 90%+ Coverage)
- **Source Generators**: Test code generation with various input scenarios
- **Middleware**: Test individual middleware components in isolation
- **Utilities**: Test helper classes and extension methods
- **Configuration**: Test configuration parsing and validation

#### 2. Integration Tests
- **Endpoint Registration**: Test auto-discovery and registration
- **Request/Response Flow**: Test complete request processing pipeline
- **Middleware Pipeline**: Test middleware execution order and behavior
- **Database Integration**: Test EF Core integration with real database

#### 3. Performance Tests
- **Benchmarks**: Compare performance before/after optimizations
- **Load Testing**: Test under various load conditions
- **Memory Profiling**: Verify memory usage optimizations
- **Startup Performance**: Measure application startup time

#### 4. End-to-End Tests
- **Aspire Integration**: Test full distributed application scenarios
- **Service Communication**: Test cross-service type safety
- **Configuration Changes**: Test hot-reload and configuration updates
- **Error Scenarios**: Test error handling across service boundaries

#### 5. Contract Tests
- **API Contracts**: Verify client-server compatibility
- **Schema Validation**: Test OpenAPI schema generation accuracy
- **Breaking Changes**: Detect API breaking changes

### Testing Infrastructure

#### Test Projects Structure
```
tests/
├── Unit/
│   ├── AxiomEndpoints.Core.Tests/
│   ├── AxiomEndpoints.SourceGenerators.Tests/
│   ├── AxiomEndpoints.AspNetCore.Tests/
│   └── AxiomEndpoints.Aspire.Tests/
├── Integration/
│   ├── AxiomEndpoints.Integration.Tests/
│   └── AxiomEndpoints.Aspire.Integration.Tests/
├── Performance/
│   ├── AxiomEndpoints.Performance.Tests/
│   └── BenchmarkDotNet.Results/
└── E2E/
    ├── AxiomEndpoints.E2E.Tests/
    └── TestApplications/
```

#### Test Data Management
- **Test Fixtures**: Reusable test data and configurations
- **Database Seeding**: Consistent test data across test runs
- **Mock Services**: Mock external dependencies for reliable testing
- **Test Containers**: Use TestContainers for database integration tests

#### Continuous Testing
- **GitHub Actions**: Automated test execution on PR and merge
- **Code Coverage**: Enforce minimum coverage thresholds
- **Performance Regression**: Detect performance regressions automatically
- **Contract Testing**: Validate API contracts on changes

---

## Timeline and Milestones

### Phase 1: Foundation (Weeks 1-6)
- **Week 1-2**: Complete source generation pipeline
- **Week 3-4**: Implement minimal endpoint syntax
- **Week 5-6**: Auto-query parameter binding and testing

### Phase 2: Integration (Weeks 7-10)
- **Week 7-8**: Deep Aspire integration and service discovery
- **Week 9**: Cross-service type safety implementation
- **Week 10**: Configuration-driven features and testing

### Phase 3: Enhancement (Weeks 11-16)
- **Week 11-12**: Fluent endpoint configuration
- **Week 13-14**: Built-in validation and error handling
- **Week 15-16**: Performance optimizations and final testing

### Key Milestones
- **Week 2**: Source generators producing functional code
- **Week 4**: Minimal endpoint syntax working end-to-end
- **Week 6**: Phase 1 complete with comprehensive tests
- **Week 8**: Aspire integration demonstrable
- **Week 10**: Phase 2 complete with service-to-service communication
- **Week 12**: Fluent API usable for endpoint configuration
- **Week 14**: Automatic validation working across all endpoints
- **Week 16**: All performance optimizations implemented and tested

---

## Risk Assessment

### High Risk
- **Source Generator Complexity**: Advanced code generation may be complex to implement and debug
- **Breaking Changes**: Existing endpoint implementations may need migration
- **Performance Impact**: New features might negatively impact performance

### Medium Risk
- **Aspire Integration**: Deep integration with Aspire may require significant changes
- **Configuration Complexity**: Configuration-driven approach may become too complex
- **Testing Overhead**: Comprehensive testing may significantly extend timeline

### Low Risk
- **Fluent API Design**: Well-established patterns exist for fluent APIs
- **Validation Integration**: Standard validation patterns are well-understood
- **Error Handling**: Standardized error handling is straightforward

### Mitigation Strategies
- **Incremental Implementation**: Implement features incrementally with backward compatibility
- **Extensive Testing**: Comprehensive test coverage to catch regressions early
- **Performance Monitoring**: Continuous performance monitoring to detect issues
- **Community Feedback**: Early feedback from users to validate design decisions

---

## Success Metrics

### Developer Experience
- **Boilerplate Reduction**: Measure lines of code reduction for common scenarios
- **Time to First Endpoint**: Measure time from project creation to first working endpoint
- **Configuration Complexity**: Measure configuration lines vs. functionality delivered

### Performance
- **Request Throughput**: Measure requests per second improvement
- **Response Time**: Measure average response time reduction
- **Memory Usage**: Measure memory allocation reduction
- **Startup Time**: Measure application startup time improvement

### Quality
- **Test Coverage**: Maintain 90%+ code coverage
- **Bug Reports**: Track and minimize post-release bug reports
- **Performance Regressions**: Zero performance regressions
- **Documentation Completeness**: 100% public API documentation

### Adoption
- **Migration Success**: Measure successful migration of existing endpoints
- **Feature Usage**: Track usage of new features vs. old patterns
- **Community Feedback**: Positive feedback from early adopters
- **Issue Resolution**: Fast resolution of reported issues

This comprehensive plan provides a structured approach to implementing the 9 critical improvements to the AxiomEndpoints framework, with emphasis on reducing developer friction while maintaining the framework's strong type safety and performance characteristics.