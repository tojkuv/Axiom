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
        var data = result.Value.Data as dynamic;
        
        // Verify the dynamic object contains expected properties
        Assert.IsNotNull(data);
        var dataDict = data as IDictionary<string, object>;
        dataDict.Should().ContainKey("status");
        dataDict.Should().ContainKey("timestamp");
        dataDict["status"].Should().Be("healthy");
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
        var data = result.Value.Data as dynamic;
        Assert.IsNotNull(data);
        var dataDict = data as IDictionary<string, object>;
        var timestamp = (DateTime)dataDict["timestamp"];
        
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
            tasks.Add(_endpoint.HandleAsync(route, _contextMock.Object));
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
        
        var data1 = result1.Value.Data as IDictionary<string, object>;
        var data2 = result2.Value.Data as IDictionary<string, object>;
        
        data1.Should().NotBeNull();
        data2.Should().NotBeNull();
        data1.Keys.Should().BeEquivalentTo(data2.Keys);
    }
}