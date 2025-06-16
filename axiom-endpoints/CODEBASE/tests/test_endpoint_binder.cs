// Quick test for EndpointBinder
using System;
using System.Text.Json;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Primitives;
using AxiomEndpoints.AspNetCore;

// Test EndpointBinder functionality
Console.WriteLine("=== EndpointBinder Test ===");

// Create a simple test request type
public record TestRequest(int Id, string Name);

// Create a mock HttpContext
var httpContext = new DefaultHttpContext();

// Test 1: Route parameter binding
httpContext.Request.RouteValues["Id"] = "123";
httpContext.Request.RouteValues["Name"] = "TestUser";

var result1 = EndpointBinder.BindFromRoute(httpContext, typeof(TestRequest));
Console.WriteLine($"Route binding result: {result1}");

// Test 2: Query parameter binding for simple types
httpContext.Request.Query = new QueryCollection(new Dictionary<string, StringValues>
{
    ["id"] = "456"
});

var result2 = EndpointBinder.BindQueryParameter<int>(httpContext, "id");
Console.WriteLine($"Query parameter binding: {result2}");

// Test 3: Multiple query parameters
httpContext.Request.Query = new QueryCollection(new Dictionary<string, StringValues>
{
    ["tags"] = new StringValues(new[] { "tag1", "tag2", "tag3" })
});

var result3 = EndpointBinder.BindQueryParameters<string>(httpContext, "tags").ToList();
Console.WriteLine($"Multiple query parameters: [{string.Join(", ", result3)}]");

Console.WriteLine("✅ EndpointBinder basic tests completed");