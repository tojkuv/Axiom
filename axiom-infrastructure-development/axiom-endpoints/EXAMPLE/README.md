# AxiomEndpoints Example - Comprehensive Testing Suite

This directory contains the comprehensive testing implementation for the AxiomEndpointsExample, serving as the primary validation suite for the AxiomEndpoints package in production environments.

## Quick Start

### Running All Tests
```bash
# Run the complete test suite
./run-tests.sh

# Run with code coverage
./run-tests.sh --coverage

# Run with Docker containers for dependencies
./run-tests.sh --docker
```

### Running Specific Test Categories
```bash
# Unit tests only (fast, no dependencies)
./run-tests.sh --unit

# Integration tests only (requires database/Redis)
./run-tests.sh --integration --docker

# Performance tests only
./run-tests.sh --performance --verbose

# Multiple categories
./run-tests.sh --unit --integration --coverage
```

### Visual Studio / IDE
```bash
# Build and test from IDE
dotnet build AxiomEndpointsExample.Tests/
dotnet test AxiomEndpointsExample.Tests/ --filter "TestCategory=Unit"
```

## Test Architecture

### Test Categories

#### 🔧 Unit Tests (`/Unit/`)
- **Purpose**: Test individual components in isolation
- **Speed**: Very fast (< 30 seconds total)
- **Dependencies**: None (in-memory databases, mocks)
- **Coverage**: Individual endpoints, services, models
- **Example**: `HealthEndpointTests.cs`, `GetUsersV1EndpointTests.cs`

#### 🔗 Integration Tests (`/Integration/`)
- **Purpose**: Test complete request/response cycles
- **Speed**: Moderate (1-5 minutes)
- **Dependencies**: PostgreSQL, Redis
- **Coverage**: HTTP API, database operations, service interactions
- **Example**: `UserEndpointsIntegrationTests.cs`

#### ⚡ Performance Tests (`/Performance/`)
- **Purpose**: Load testing and performance validation
- **Speed**: Slow (5-15 minutes)
- **Dependencies**: Full infrastructure
- **Coverage**: Throughput, response times, resource usage
- **Example**: `ApiPerformanceTests.cs`

#### 🔒 Security Tests (Planned)
- **Purpose**: Security vulnerability scanning
- **Coverage**: Input validation, authentication, authorization

### Infrastructure

#### Test Base Classes
- **`TestBase`**: Common setup, utilities, AutoFixture configuration
- **`DatabaseTestBase`**: Entity Framework setup, test data management
- **`ApiIntegrationTestBase`**: WebApplicationFactory, HTTP client setup

#### Test Data Management
- **`TestDataBuilder`**: Fluent API for creating test entities
- **`UserBuilder`**, **`PostBuilder`**, **`CommentBuilder`**: Specific entity builders
- **Automatic cleanup**: Database reset between tests

#### Configuration
- **`test-config.json`**: Centralized test configuration
- **Environment variables**: Runtime configuration override
- **Docker support**: Containerized dependencies

## Test Quality Standards

### Code Coverage Targets
- **Unit Tests**: ≥ 90% line coverage
- **Integration Tests**: ≥ 80% functional coverage
- **Critical Paths**: 100% coverage required

### Performance Benchmarks
| Endpoint | Mean Response Time | 95th Percentile | Throughput |
|----------|-------------------|-----------------|------------|
| GET /health | < 50ms | < 100ms | > 1,000 req/s |
| GET /v1/users | < 200ms | < 500ms | > 500 req/s |
| GET /v1/users/{id} | < 100ms | < 250ms | > 800 req/s |
| GET /v1/users/search | < 300ms | < 750ms | > 200 req/s |

### Quality Gates
- **Test Success Rate**: > 95%
- **Error Rate**: < 1%
- **Build Time**: < 15 minutes
- **Zero Critical Vulnerabilities**

## Usage Examples

### Local Development

#### Quick Feedback Loop
```bash
# Fast unit tests during development
./run-tests.sh --unit

# Test specific functionality
dotnet test --filter "FullyQualifiedName~HealthEndpoint"
```

#### Pre-commit Validation
```bash
# Full validation before committing
./run-tests.sh --all --coverage
```

#### Performance Testing
```bash
# Load test specific endpoints
./run-tests.sh --performance --verbose

# Custom load test scenarios
dotnet test --filter "TestCategory=Performance&TestCategory=LoadTest"
```

### CI/CD Pipeline

#### GitHub Actions
```yaml
# Automated testing on pull requests
- name: Run Comprehensive Tests
  run: ./run-tests.sh --all --coverage --docker
```

#### Quality Gates
```bash
# Enforce quality standards
./run-tests.sh --all --coverage
if [ $? -ne 0 ]; then
  echo "Quality gates failed"
  exit 1
fi
```

### Production Validation

#### Smoke Tests
```bash
# Quick production health check
./run-tests.sh --unit --integration
```

#### Full Validation
```bash
# Complete production readiness validation
./run-tests.sh --all --coverage --performance
```

## Test Data Management

### Entity Creation
```csharp
// Using TestDataBuilder
var user = DataBuilder.CreateUser(builder =>
    builder.WithEmail("test@example.com")
           .WithName("Test User")
           .WithStatus(UserStatus.Active));

var users = DataBuilder.CreateUsers(100); // Bulk creation
```

### Database Operations
```csharp
// In DatabaseTestBase
await SaveEntityAsync(user);
await AssertEntityExistsAsync<User>(u => u.Email == "test@example.com");
await ClearDatabaseAsync();
```

### Test Isolation
```csharp
[TestMethod]
public async Task MyTest()
{
    // Each test gets fresh database
    // Automatic cleanup after test
}
```

## Performance Testing

### NBomber Load Testing
```csharp
var scenario = Scenario.Create("load_test", async context =>
{
    var response = await httpClient.GetAsync("/v1/users");
    return response.IsSuccessStatusCode ? Response.Ok() : Response.Fail();
})
.WithLoadSimulations(
    Simulation.InjectPerSec(rate: 100, during: TimeSpan.FromSeconds(30))
);
```

### Custom Performance Metrics
```csharp
[TestMethod]
public async Task ResponseTime_ShouldMeetTarget()
{
    await AssertCompletesWithinAsync(TimeSpan.FromMilliseconds(100), async () =>
    {
        await endpoint.HandleAsync(route, context);
    });
}
```

## Troubleshooting

### Common Issues

#### Database Connection Errors
```bash
# Check PostgreSQL is running
docker ps | grep postgres

# Reset database
./run-tests.sh --clean --docker
```

#### Redis Connection Errors
```bash
# Check Redis is running
docker ps | grep redis

# Verify connection
redis-cli -h localhost -p 6379 ping
```

#### Performance Test Failures
```bash
# Run with verbose logging
./run-tests.sh --performance --verbose

# Check system resources
htop
docker stats
```

#### Build Errors
```bash
# Clean and rebuild
./run-tests.sh --clean
dotnet clean
dotnet restore
dotnet build
```

### Test Debugging

#### IDE Debugging
1. Set breakpoints in test code
2. Right-click test → Debug Test
3. Step through test execution

#### Console Debugging
```bash
# Verbose output
./run-tests.sh --unit --verbose

# Specific test with detailed logs
dotnet test --logger "console;verbosity=detailed" --filter "FullyQualifiedName~MyTest"
```

#### Test Data Inspection
```csharp
// Add diagnostic output in tests
Console.WriteLine($"User: {JsonSerializer.Serialize(user)}");
DbContext.ChangeTracker.DebugView.LongView; // EF debugging
```

## Advanced Usage

### Custom Test Configuration
```json
// test-config.json
{
  "TestConfiguration": {
    "Performance": {
      "TestDuration": "00:01:00",
      "ThroughputTargets": {
        "CustomEndpoint": 500
      }
    }
  }
}
```

### Test Categories and Tagging
```csharp
[TestMethod]
[TestCategory("Fast")]
[TestCategory("Database")]
public async Task MyTest() { }
```

### Parallel Test Execution
```bash
# Enable parallel execution
./run-tests.sh --parallel

# Control parallelism
dotnet test --parallel --max-parallel-threads 4
```

### Custom Test Filters
```bash
# Run specific categories
dotnet test --filter "TestCategory=Integration&TestCategory=API"

# Run by method name pattern
dotnet test --filter "FullyQualifiedName~User"

# Run by class name
dotnet test --filter "ClassName~EndpointTests"
```

## Reporting and Metrics

### Test Reports
- **HTML Report**: `TestResults/test-report.html`
- **TRX Files**: `TestResults/*/TestResults.trx`
- **Coverage Reports**: `TestResults/*/coverage.cobertura.xml`

### CI/CD Integration
- **GitHub Actions**: `.github/workflows/comprehensive-tests.yml`
- **Quality Gates**: Automated validation of test metrics
- **Artifact Upload**: Test results and reports

### Performance Metrics
- **NBomber Reports**: Detailed load testing results
- **Response Time Distributions**: Percentile analysis
- **Throughput Measurements**: Requests per second

## Contributing

### Adding New Tests

#### Unit Test Example
```csharp
[TestClass]
public class NewEndpointTests : TestBase
{
    [TestMethod]
    public async Task NewEndpoint_ShouldReturnExpectedResult()
    {
        // Arrange
        var endpoint = new NewEndpoint();
        var route = new Routes.NewRoute();
        
        // Act
        var result = await endpoint.HandleAsync(route, mockContext.Object);
        
        // Assert
        result.IsSuccess.Should().BeTrue();
    }
}
```

#### Integration Test Example
```csharp
[TestClass]
public class NewIntegrationTests : ApiIntegrationTestBase
{
    [TestMethod]
    public async Task NewEndpoint_IntegrationTest()
    {
        // Act
        var response = await GetAsync<ExpectedType>("/new-endpoint");
        
        // Assert
        response.Should().NotBeNull();
    }
}
```

### Test Guidelines
1. **Naming**: Use descriptive test names indicating scenario and expectation
2. **Arrange-Act-Assert**: Follow the AAA pattern consistently
3. **Isolation**: Each test should be independent and idempotent
4. **Speed**: Keep unit tests fast (< 100ms each)
5. **Reliability**: Tests should be deterministic and not flaky

## Conclusion

This comprehensive testing suite ensures the AxiomEndpointsExample demonstrates production-ready quality and serves as a reliable reference implementation for the AxiomEndpoints package. The multi-layered testing approach provides confidence in both individual components and the complete system integration.