using NBomber.Contracts;
using NBomber.CSharp;
using AxiomEndpointsExample.Tests.Integration;
using Microsoft.Extensions.DependencyInjection;
using AxiomEndpointsExample.Api;
using System.Text.Json;

namespace AxiomEndpointsExample.Tests.Performance;

/// <summary>
/// Performance tests for API endpoints using NBomber
/// </summary>
[TestClass]
public class ApiPerformanceTests : ApiIntegrationTestBase
{
    private const int WarmupDurationSeconds = 10;
    private const int TestDurationSeconds = 30;

    protected override async Task SeedTestDataAsync()
    {
        // Create a substantial dataset for performance testing
        var users = DataBuilder.CreateUsers(1000);
        var posts = new List<Post>();
        
        // Add posts for first 100 users
        for (int i = 0; i < 100; i++)
        {
            for (int j = 0; j < 5; j++)
            {
                posts.Add(DataBuilder.CreatePost(users[i]));
            }
        }
        
        DbContext.Users.AddRange(users);
        DbContext.Posts.AddRange(posts);
        await DbContext.SaveChangesAsync();
    }

    [TestMethod]
    public async Task HealthEndpoint_LoadTest()
    {
        // Arrange
        var scenario = Scenario.Create("health_endpoint_load", async context =>
        {
            try
            {
                var response = await Client.GetAsync("/health");
                return response.IsSuccessStatusCode ? Response.Ok() : Response.Fail();
            }
            catch (Exception ex)
            {
                return Response.Fail(ex.Message);
            }
        })
        .WithLoadSimulations(
            Simulation.InjectPerSec(rate: 100, during: TimeSpan.FromSeconds(WarmupDurationSeconds)),
            Simulation.InjectPerSec(rate: 500, during: TimeSpan.FromSeconds(TestDurationSeconds)),
            Simulation.InjectPerSec(rate: 1000, during: TimeSpan.FromSeconds(TestDurationSeconds))
        );

        // Act
        var stats = NBomberRunner
            .RegisterScenarios(scenario)
            .Run();

        // Assert
        var scenarioStats = stats.AllScenarios.First();
        
        Assert.IsTrue(scenarioStats.Ok.Request.Count > 0, "Should have successful requests");
        Assert.IsTrue(scenarioStats.Ok.Request.Mean < 50, $"Mean response time should be < 50ms, actual: {scenarioStats.Ok.Request.Mean}ms");
        Assert.IsTrue(scenarioStats.Fail.Request.Count == 0, $"Should have no failed requests, actual: {scenarioStats.Fail.Request.Count}");
    }

    [TestMethod]
    public async Task GetUsersEndpoint_LoadTest()
    {
        // Arrange
        var scenario = Scenario.Create("get_users_load", async context =>
        {
            try
            {
                var response = await Client.GetAsync("/v1/users");
                if (!response.IsSuccessStatusCode)
                    return Response.Fail($"HTTP {response.StatusCode}");

                var content = await response.Content.ReadAsStringAsync();
                var result = JsonSerializer.Deserialize<PagedResponse<UserDto>>(content, JsonOptions);
                
                return result?.Data?.Any() == true ? Response.Ok() : Response.Fail("No data returned");
            }
            catch (Exception ex)
            {
                return Response.Fail(ex.Message);
            }
        })
        .WithLoadSimulations(
            Simulation.InjectPerSec(rate: 50, during: TimeSpan.FromSeconds(WarmupDurationSeconds)),
            Simulation.InjectPerSec(rate: 200, during: TimeSpan.FromSeconds(TestDurationSeconds)),
            Simulation.InjectPerSec(rate: 500, during: TimeSpan.FromSeconds(TestDurationSeconds))
        );

        // Act
        var stats = NBomberRunner
            .RegisterScenarios(scenario)
            .Run();

        // Assert
        var scenarioStats = stats.AllScenarios.First();
        
        Assert.IsTrue(scenarioStats.Ok.Request.Count > 0, "Should have successful requests");
        Assert.IsTrue(scenarioStats.Ok.Request.Mean < 200, $"Mean response time should be < 200ms, actual: {scenarioStats.Ok.Request.Mean}ms");
        Assert.IsTrue(scenarioStats.Ok.Request.Percentile95 < 500, $"95th percentile should be < 500ms, actual: {scenarioStats.Ok.Request.Percentile95}ms");
        Assert.IsTrue(scenarioStats.Fail.Request.Count < scenarioStats.Ok.Request.Count * 0.01, "Error rate should be < 1%");
    }

    [TestMethod]
    public async Task GetUserByIdEndpoint_LoadTest()
    {
        // Arrange
        var userIds = DbContext.Users.Take(100).Select(u => u.Id).ToList();
        var random = new Random();

        var scenario = Scenario.Create("get_user_by_id_load", async context =>
        {
            try
            {
                var userId = userIds[random.Next(userIds.Count)];
                var response = await Client.GetAsync($"/v1/users/{userId}");
                
                if (!response.IsSuccessStatusCode)
                    return Response.Fail($"HTTP {response.StatusCode}");

                var content = await response.Content.ReadAsStringAsync();
                var result = JsonSerializer.Deserialize<ApiResponse<UserDto>>(content, JsonOptions);
                
                return result?.Data != null ? Response.Ok() : Response.Fail("No data returned");
            }
            catch (Exception ex)
            {
                return Response.Fail(ex.Message);
            }
        })
        .WithLoadSimulations(
            Simulation.InjectPerSec(rate: 100, during: TimeSpan.FromSeconds(WarmupDurationSeconds)),
            Simulation.InjectPerSec(rate: 300, during: TimeSpan.FromSeconds(TestDurationSeconds)),
            Simulation.InjectPerSec(rate: 600, during: TimeSpan.FromSeconds(TestDurationSeconds))
        );

        // Act
        var stats = NBomberRunner
            .RegisterScenarios(scenario)
            .Run();

        // Assert
        var scenarioStats = stats.AllScenarios.First();
        
        Assert.IsTrue(scenarioStats.Ok.Request.Count > 0, "Should have successful requests");
        Assert.IsTrue(scenarioStats.Ok.Request.Mean < 100, $"Mean response time should be < 100ms, actual: {scenarioStats.Ok.Request.Mean}ms");
        Assert.IsTrue(scenarioStats.Ok.Request.Percentile95 < 250, $"95th percentile should be < 250ms, actual: {scenarioStats.Ok.Request.Percentile95}ms");
        Assert.IsTrue(scenarioStats.Fail.Request.Count < scenarioStats.Ok.Request.Count * 0.01, "Error rate should be < 1%");
    }

    [TestMethod]
    public async Task SearchUsersEndpoint_LoadTest()
    {
        // Arrange
        var searchTerms = new[] { "User", "test", "example", "1", "2" };
        var random = new Random();

        var scenario = Scenario.Create("search_users_load", async context =>
        {
            try
            {
                var searchTerm = searchTerms[random.Next(searchTerms.Length)];
                var response = await Client.GetAsync($"/v1/users/search?search={Uri.EscapeDataString(searchTerm)}");
                
                if (!response.IsSuccessStatusCode)
                    return Response.Fail($"HTTP {response.StatusCode}");

                var content = await response.Content.ReadAsStringAsync();
                var result = JsonSerializer.Deserialize<PagedResponse<UserDto>>(content, JsonOptions);
                
                return result != null ? Response.Ok() : Response.Fail("No data returned");
            }
            catch (Exception ex)
            {
                return Response.Fail(ex.Message);
            }
        })
        .WithLoadSimulations(
            Simulation.InjectPerSec(rate: 30, during: TimeSpan.FromSeconds(WarmupDurationSeconds)),
            Simulation.InjectPerSec(rate: 100, during: TimeSpan.FromSeconds(TestDurationSeconds)),
            Simulation.InjectPerSec(rate: 200, during: TimeSpan.FromSeconds(TestDurationSeconds))
        );

        // Act
        var stats = NBomberRunner
            .RegisterScenarios(scenario)
            .Run();

        // Assert
        var scenarioStats = stats.AllScenarios.First();
        
        Assert.IsTrue(scenarioStats.Ok.Request.Count > 0, "Should have successful requests");
        Assert.IsTrue(scenarioStats.Ok.Request.Mean < 300, $"Mean response time should be < 300ms, actual: {scenarioStats.Ok.Request.Mean}ms");
        Assert.IsTrue(scenarioStats.Ok.Request.Percentile95 < 750, $"95th percentile should be < 750ms, actual: {scenarioStats.Ok.Request.Percentile95}ms");
        Assert.IsTrue(scenarioStats.Fail.Request.Count < scenarioStats.Ok.Request.Count * 0.02, "Error rate should be < 2%");
    }

    [TestMethod]
    public async Task MixedWorkload_LoadTest()
    {
        // Arrange
        var userIds = DbContext.Users.Take(50).Select(u => u.Id).ToList();
        var random = new Random();

        var healthScenario = Scenario.Create("mixed_health", async context =>
        {
            var response = await Client.GetAsync("/health");
            return response.IsSuccessStatusCode ? Response.Ok() : Response.Fail();
        })
        .WithWeight(20)
        .WithLoadSimulations(Simulation.InjectPerSec(rate: 200, during: TimeSpan.FromSeconds(TestDurationSeconds)));

        var usersScenario = Scenario.Create("mixed_users", async context =>
        {
            var response = await Client.GetAsync("/v1/users");
            return response.IsSuccessStatusCode ? Response.Ok() : Response.Fail();
        })
        .WithWeight(40)
        .WithLoadSimulations(Simulation.InjectPerSec(rate: 100, during: TimeSpan.FromSeconds(TestDurationSeconds)));

        var userByIdScenario = Scenario.Create("mixed_user_by_id", async context =>
        {
            var userId = userIds[random.Next(userIds.Count)];
            var response = await Client.GetAsync($"/v1/users/{userId}");
            return response.IsSuccessStatusCode ? Response.Ok() : Response.Fail();
        })
        .WithWeight(30)
        .WithLoadSimulations(Simulation.InjectPerSec(rate: 150, during: TimeSpan.FromSeconds(TestDurationSeconds)));

        var searchScenario = Scenario.Create("mixed_search", async context =>
        {
            var response = await Client.GetAsync("/v1/users/search?search=User");
            return response.IsSuccessStatusCode ? Response.Ok() : Response.Fail();
        })
        .WithWeight(10)
        .WithLoadSimulations(Simulation.InjectPerSec(rate: 50, during: TimeSpan.FromSeconds(TestDurationSeconds)));

        // Act
        var stats = NBomberRunner
            .RegisterScenarios(healthScenario, usersScenario, userByIdScenario, searchScenario)
            .Run();

        // Assert
        Assert.IsTrue(stats.AllScenarios.All(s => s.Ok.Request.Count > 0), "All scenarios should have successful requests");
        Assert.IsTrue(stats.AllScenarios.All(s => s.Fail.Request.Count < s.Ok.Request.Count * 0.05), "Error rate should be < 5% for all scenarios");
        
        // Check individual scenario performance
        var healthStats = stats.AllScenarios.First(s => s.ScenarioName == "mixed_health");
        Assert.IsTrue(healthStats.Ok.Request.Mean < 50, $"Health endpoint mean response time should be < 50ms");

        var usersStats = stats.AllScenarios.First(s => s.ScenarioName == "mixed_users");
        Assert.IsTrue(usersStats.Ok.Request.Mean < 200, $"Users endpoint mean response time should be < 200ms");

        var userByIdStats = stats.AllScenarios.First(s => s.ScenarioName == "mixed_user_by_id");
        Assert.IsTrue(userByIdStats.Ok.Request.Mean < 100, $"User by ID endpoint mean response time should be < 100ms");

        var searchStats = stats.AllScenarios.First(s => s.ScenarioName == "mixed_search");
        Assert.IsTrue(searchStats.Ok.Request.Mean < 300, $"Search endpoint mean response time should be < 300ms");
    }

    [TestMethod]
    public async Task StressTest_GradualLoad()
    {
        // Arrange
        var scenario = Scenario.Create("stress_test", async context =>
        {
            try
            {
                var response = await Client.GetAsync("/v1/users");
                return response.IsSuccessStatusCode ? Response.Ok() : Response.Fail($"HTTP {response.StatusCode}");
            }
            catch (Exception ex)
            {
                return Response.Fail(ex.Message);
            }
        })
        .WithLoadSimulations(
            Simulation.InjectPerSec(rate: 50, during: TimeSpan.FromSeconds(10)),   // Warm up
            Simulation.InjectPerSec(rate: 100, during: TimeSpan.FromSeconds(10)),  // Gradual increase
            Simulation.InjectPerSec(rate: 200, during: TimeSpan.FromSeconds(10)),  
            Simulation.InjectPerSec(rate: 400, during: TimeSpan.FromSeconds(10)),  
            Simulation.InjectPerSec(rate: 800, during: TimeSpan.FromSeconds(10)),  // Peak load
            Simulation.InjectPerSec(rate: 400, during: TimeSpan.FromSeconds(10)),  // Cool down
            Simulation.InjectPerSec(rate: 200, during: TimeSpan.FromSeconds(10)),  
            Simulation.InjectPerSec(rate: 100, during: TimeSpan.FromSeconds(10))   
        );

        // Act
        var stats = NBomberRunner
            .RegisterScenarios(scenario)
            .Run();

        // Assert
        var scenarioStats = stats.AllScenarios.First();
        
        // Should handle the load gracefully
        Assert.IsTrue(scenarioStats.Ok.Request.Count > 0, "Should have successful requests under stress");
        Assert.IsTrue(scenarioStats.Fail.Request.Count < scenarioStats.Ok.Request.Count * 0.1, "Error rate should be < 10% under stress");
        
        // Performance should degrade gracefully
        Assert.IsTrue(scenarioStats.Ok.Request.Percentile99 < 2000, "99th percentile should be < 2s even under stress");
    }
}