using NBomber.CSharp;
using AxiomEndpointsExample.Tests.Integration;
using Microsoft.Extensions.DependencyInjection;
using AxiomEndpointsExample.Api;
using System.Text.Json;
using System.Net.Http.Headers;

namespace AxiomEndpointsExample.Tests.Performance;

/// <summary>
/// Performance tests demonstrating the new Axiom performance optimization features:
/// - Caching improvements
/// - Compression benefits  
/// - Object pooling efficiency
/// - Performance monitoring
/// </summary>
[TestClass]
public class ApiPerformanceTests : ApiIntegrationTestBase
{
    private const int TestDurationSeconds = 10;

    protected override async Task SeedTestDataAsync()
    {
        var users = DataBuilder.CreateUsers(100);
        var posts = new List<Post>();
        
        for (int i = 0; i < 20; i++)
        {
            for (int j = 0; j < 3; j++)
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
        var scenario = Scenario.Create("health_endpoint_load", async context =>
        {
            try
            {
                var response = await Client.GetAsync("/health");
                return response.IsSuccessStatusCode ? Response.Ok() : Response.Fail();
            }
            catch (Exception ex)
            {
                return Response.Fail();
            }
        })
        .WithLoadSimulations(
            Simulation.KeepConstant(copies: 10, during: TimeSpan.FromSeconds(TestDurationSeconds))
        )
        .WithWarmUpDuration(TimeSpan.FromSeconds(2));

        NBomberRunner
            .RegisterScenarios(scenario)
            .Run();
    }

    [TestMethod]
    public async Task CachedEndpoints_PerformanceBenefit()
    {
        // Test demonstrates caching performance improvements
        var user = DbContext.Users.First();
        
        var scenario = Scenario.Create("cached_user_stats", async context =>
        {
            try
            {
                var response = await Client.GetAsync($"/v1/users/{user.Id}/stats");
                return response.IsSuccessStatusCode ? Response.Ok() : Response.Fail();
            }
            catch (Exception ex)
            {
                return Response.Fail();
            }
        })
        .WithLoadSimulations(
            Simulation.KeepConstant(copies: 5, during: TimeSpan.FromSeconds(TestDurationSeconds))
        )
        .WithWarmUpDuration(TimeSpan.FromSeconds(2));

        NBomberRunner
            .RegisterScenarios(scenario)
            .Run();
    }

    [TestMethod] 
    public async Task CompressionEfficiency_LargeReports()
    {
        // Test demonstrates compression benefits for large responses
        var scenario = Scenario.Create("large_report_compression", async context =>
        {
            try
            {
                // Add compression headers
                using var client = CreateClientWithCompression();
                var response = await client.GetAsync("/v1/reports/large?type=performance");
                
                return response.IsSuccessStatusCode ? Response.Ok() : Response.Fail();
            }
            catch (Exception ex)
            {
                return Response.Fail();
            }
        })
        .WithLoadSimulations(
            Simulation.KeepConstant(copies: 2, during: TimeSpan.FromSeconds(TestDurationSeconds))
        )
        .WithWarmUpDuration(TimeSpan.FromSeconds(2));

        var stats = NBomberRunner
            .RegisterScenarios(scenario)
            .Run();
        
        Assert.IsTrue(stats.AllOkCount > 0, "Should have successful requests");
    }

    [TestMethod]
    public async Task ObjectPooling_MemoryEfficiency()
    {
        // Test demonstrates object pooling benefits for memory allocation
        var user = DbContext.Users.First();
        
        var scenario = Scenario.Create("object_pooled_reports", async context =>
        {
            try
            {
                var response = await Client.GetAsync($"/v1/reports/user/{user.Id}");
                return response.IsSuccessStatusCode ? Response.Ok() : Response.Fail();
            }
            catch (Exception ex)
            {
                return Response.Fail();
            }
        })
        .WithLoadSimulations(
            Simulation.KeepConstant(copies: 3, during: TimeSpan.FromSeconds(TestDurationSeconds))
        )
        .WithWarmUpDuration(TimeSpan.FromSeconds(2));

        var stats = NBomberRunner
            .RegisterScenarios(scenario)
            .Run();
        
        Assert.IsTrue(stats.AllOkCount > 0, "Should have successful requests");
    }

    [TestMethod]
    public async Task PerformanceMonitoring_SlowEndpointDetection()
    {
        // Test demonstrates performance monitoring for slow endpoints
        var scenario = Scenario.Create("slow_endpoint_monitoring", async context =>
        {
            try
            {
                var response = await Client.GetAsync("/v1/test/slow?delayMs=200");
                return response.IsSuccessStatusCode ? Response.Ok() : Response.Fail();
            }
            catch (Exception ex)
            {
                return Response.Fail();
            }
        })
        .WithLoadSimulations(
            Simulation.KeepConstant(copies: 2, during: TimeSpan.FromSeconds(TestDurationSeconds))
        )
        .WithWarmUpDuration(TimeSpan.FromSeconds(2));

        var stats = NBomberRunner
            .RegisterScenarios(scenario)
            .Run();
        
        Assert.IsTrue(stats.AllOkCount > 0, "Should have successful requests");
    }

    [TestMethod]
    public async Task CacheStressTest_MemoryManagement()
    {
        // Test demonstrates cache performance under stress
        var scenario = Scenario.Create("cache_stress_test", async context =>
        {
            try
            {
                var response = await Client.GetAsync("/v1/test/cache-stress?iterations=10");
                return response.IsSuccessStatusCode ? Response.Ok() : Response.Fail();
            }
            catch (Exception ex)
            {
                return Response.Fail();
            }
        })
        .WithLoadSimulations(
            Simulation.KeepConstant(copies: 1, during: TimeSpan.FromSeconds(TestDurationSeconds))
        )
        .WithWarmUpDuration(TimeSpan.FromSeconds(2));

        var stats = NBomberRunner
            .RegisterScenarios(scenario)
            .Run();
        
        Assert.IsTrue(stats.AllOkCount > 0, "Should have successful requests");
    }

    [TestMethod]
    public async Task PerformanceMetrics_Collection()
    {
        // First, generate some traffic to collect metrics
        for (int i = 0; i < 5; i++)
        {
            await Client.GetAsync("/health");
            await Client.GetAsync("/v1/users/active");
        }

        // Now test the metrics endpoint
        var scenario = Scenario.Create("performance_metrics", async context =>
        {
            try
            {
                var response = await Client.GetAsync("/v1/metrics/performance");
                return response.IsSuccessStatusCode ? Response.Ok() : Response.Fail();
            }
            catch (Exception ex)
            {
                return Response.Fail();
            }
        })
        .WithLoadSimulations(
            Simulation.KeepConstant(copies: 1, during: TimeSpan.FromSeconds(5))
        )
        .WithWarmUpDuration(TimeSpan.FromSeconds(1));

        var stats = NBomberRunner
            .RegisterScenarios(scenario)
            .Run();
        
        Assert.IsTrue(stats.AllOkCount > 0, "Should have successful requests");
    }

    [TestMethod]
    public async Task StressTest_AllPerformanceFeatures()
    {
        var scenario = Scenario.Create("performance_stress_test", async context =>
        {
            var endpoints = new[]
            {
                "/health",
                "/v1/users/active",
                "/v1/posts/recent?limit=5"
            };

            var endpoint = endpoints[context.InvocationNumber % endpoints.Length];
            
            try
            {
                var response = await Client.GetAsync(endpoint);
                return response.IsSuccessStatusCode ? Response.Ok() : Response.Fail();
            }
            catch (Exception ex)
            {
                return Response.Fail();
            }
        })
        .WithLoadSimulations(
            Simulation.KeepConstant(copies: 5, during: TimeSpan.FromSeconds(TestDurationSeconds))
        )
        .WithWarmUpDuration(TimeSpan.FromSeconds(2));

        NBomberRunner
            .RegisterScenarios(scenario)
            .Run();
    }

    private HttpClient CreateClientWithCompression()
    {
        var client = Factory.CreateClient();
        client.DefaultRequestHeaders.AcceptEncoding.Clear();
        client.DefaultRequestHeaders.AcceptEncoding.Add(new StringWithQualityHeaderValue("gzip"));
        client.DefaultRequestHeaders.AcceptEncoding.Add(new StringWithQualityHeaderValue("br"));
        client.DefaultRequestHeaders.AcceptEncoding.Add(new StringWithQualityHeaderValue("deflate"));
        return client;
    }
}