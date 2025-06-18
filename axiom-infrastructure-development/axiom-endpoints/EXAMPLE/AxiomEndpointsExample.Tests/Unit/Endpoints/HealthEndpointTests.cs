using AxiomEndpoints.Core;
using AxiomEndpointsExample.Api;
using AxiomEndpointsExample.Tests.Infrastructure;
using FluentAssertions;
using Moq;

namespace AxiomEndpointsExample.Tests.Unit.Endpoints;

/// <summary>
/// Unit tests for HealthEndpoint
/// </summary>
[TestClass]
public class HealthEndpointTests : TestBase
{
    private HealthEndpoint _endpoint = null!;
    private Mock<IContext> _contextMock = null!;

    protected override async Task AdditionalSetupAsync()
    {
        await base.AdditionalSetupAsync();
        
        _endpoint = new HealthEndpoint();
        _contextMock = new Mock<IContext>();
    }

    [TestMethod]
    public async Task HandleAsync_ShouldReturnSuccessResult()
    {
        // Arrange
        var route = new Routes.Health();

        // Act
        var result = await _endpoint.HandleAsync(route, _contextMock.Object);

        // Assert
        result.IsSuccess.Should().BeTrue();
        result.Value.Should().NotBeNull();
    }

    [TestMethod]
    public async Task HandleAsync_ShouldReturnHealthyStatus()
    {
        // Arrange
        var route = new Routes.Health();

        // Act
        var result = await _endpoint.HandleAsync(route, _contextMock.Object);

        // Assert
        result.Value.Data.Should().NotBeNull();
        
        // Use reflection to access anonymous object properties
        var data = result.Value.Data;
        var dataType = data.GetType();
        
        var statusProperty = dataType.GetProperty("status");
        var timestampProperty = dataType.GetProperty("timestamp");
        
        statusProperty.Should().NotBeNull();
        timestampProperty.Should().NotBeNull();
        statusProperty!.GetValue(data).Should().Be("healthy");
    }

    [TestMethod]
    public async Task HandleAsync_ShouldIncludeCurrentTimestamp()
    {
        // Arrange
        var route = new Routes.Health();
        var beforeCall = DateTime.UtcNow;

        // Act
        var result = await _endpoint.HandleAsync(route, _contextMock.Object);
        var afterCall = DateTime.UtcNow;

        // Assert
        // Use reflection to access anonymous object properties
        var data = result.Value.Data;
        var dataType = data.GetType();
        var timestampProperty = dataType.GetProperty("timestamp");
        
        timestampProperty.Should().NotBeNull();
        var timestamp = (DateTime)timestampProperty!.GetValue(data)!;
        
        timestamp.Should().BeOnOrAfter(beforeCall);
        timestamp.Should().BeOnOrBefore(afterCall);
    }

    [TestMethod]
    public async Task HandleAsync_ShouldReturnServiceRunningMessage()
    {
        // Arrange
        var route = new Routes.Health();

        // Act
        var result = await _endpoint.HandleAsync(route, _contextMock.Object);

        // Assert
        result.Value.Message.Should().Be("Service is running");
    }

    [TestMethod]
    public async Task HandleAsync_ShouldCompleteQuickly()
    {
        // Arrange
        var route = new Routes.Health();

        // Act & Assert
        await AssertCompletesWithinAsync(TimeSpan.FromMilliseconds(100), async () =>
        {
            await _endpoint.HandleAsync(route, _contextMock.Object);
        });
    }

    [TestMethod]
    public async Task HandleAsync_WithCancellation_ShouldRespectCancellation()
    {
        // Arrange
        var route = new Routes.Health();
        var cts = new CancellationTokenSource();
        cts.Cancel();
        
        _contextMock.Setup(x => x.CancellationToken).Returns(cts.Token);

        // Act & Assert
        // Note: This endpoint doesn't actually check cancellation, but this demonstrates the test pattern
        var result = await _endpoint.HandleAsync(route, _contextMock.Object);
        result.IsSuccess.Should().BeTrue(); // Health endpoint ignores cancellation
    }

    [TestMethod]
    public async Task HandleAsync_MultipleCallsInParallel_ShouldAllSucceed()
    {
        // Arrange
        var route = new Routes.Health();
        var tasks = new List<Task<Result<ApiResponse<object>>>>();

        // Act
        for (int i = 0; i < 10; i++)
        {
            tasks.Add(_endpoint.HandleAsync(route, _contextMock.Object).AsTask());
        }

        var results = await Task.WhenAll(tasks);

        // Assert
        results.Should().AllSatisfy(result =>
        {
            result.IsSuccess.Should().BeTrue();
            result.Value.Should().NotBeNull();
        });
    }

    [TestMethod]
    public async Task HandleAsync_ShouldReturnConsistentStructure()
    {
        // Arrange
        var route = new Routes.Health();

        // Act
        var result1 = await _endpoint.HandleAsync(route, _contextMock.Object);
        var result2 = await _endpoint.HandleAsync(route, _contextMock.Object);

        // Assert
        result1.Value.GetType().Should().Be(result2.Value.GetType());
        
        // Check that the Data object has the expected properties
        var data1Type = result1.Value.Data.GetType();
        var data2Type = result2.Value.Data.GetType();
        
        data1Type.Should().Be(data2Type);
        
        // Verify the anonymous object has the expected properties
        var properties = data1Type.GetProperties();
        properties.Should().HaveCount(2);
        properties.Should().Contain(p => p.Name == "status");
        properties.Should().Contain(p => p.Name == "timestamp");
    }
}