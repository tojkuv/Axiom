using AxiomEndpoints.Core;
using AxiomEndpointsExample.Api;
using AxiomEndpointsExample.Tests.Infrastructure;
using FluentAssertions;
using Moq;

namespace AxiomEndpointsExample.Tests.Unit.Endpoints;

/// <summary>
/// Unit tests for GetUsersV1Endpoint
/// </summary>
[TestClass]
public class GetUsersV1EndpointTests : DatabaseTestBase
{
    private GetUsersV1Endpoint _endpoint = null!;
    private Mock<IContext> _contextMock = null!;

    protected override async Task AdditionalSetupAsync()
    {
        await base.AdditionalSetupAsync();
        
        _endpoint = new GetUsersV1Endpoint(DbContext);
        _contextMock = new Mock<IContext>();
    }

    protected override async Task SeedTestDataAsync()
    {
        // Create test users
        var users = DataBuilder.CreateUsers(25, builder => builder.WithStatus(UserStatus.Active));
        
        // Add some inactive users
        users.AddRange(DataBuilder.CreateUsers(5, builder => builder.WithStatus(UserStatus.Inactive)));
        
        DbContext.Users.AddRange(users);
        await DbContext.SaveChangesAsync();
    }

    [TestMethod]
    public async Task HandleAsync_ShouldReturnSuccessResult()
    {
        // Arrange
        var route = new Routes.V1.Users.Index();

        // Act
        var result = await _endpoint.HandleAsync(route, _contextMock.Object);

        // Assert
        result.IsSuccess.Should().BeTrue();
        result.Value.Should().NotBeNull();
    }

    [TestMethod]
    public async Task HandleAsync_ShouldReturnPagedResults()
    {
        // Arrange
        var route = new Routes.V1.Users.Index();

        // Act
        var result = await _endpoint.HandleAsync(route, _contextMock.Object);

        // Assert
        var response = result.Value;
        response.Data.Should().NotBeNull();
        response.Data.Should().HaveCountLessOrEqualTo(20); // Default page size
        response.Page.Should().Be(1);
        response.Limit.Should().Be(20);
        response.TotalCount.Should().BeGreaterThan(0);
    }

    [TestMethod]
    public async Task HandleAsync_ShouldReturnOnlyActiveUsers()
    {
        // Arrange
        var route = new Routes.V1.Users.Index();

        // Act
        var result = await _endpoint.HandleAsync(route, _contextMock.Object);

        // Assert
        var response = result.Value;
        response.Data.Should().AllSatisfy(user => 
            user.Status.Should().Be(UserStatus.Active));
    }

    [TestMethod]
    public async Task HandleAsync_ShouldIncludePostsCount()
    {
        // Arrange
        var user = DataBuilder.CreateUser();
        var posts = new List<Post>
        {
            DataBuilder.CreatePost(user),
            DataBuilder.CreatePost(user),
            DataBuilder.CreatePost(user)
        };
        
        DbContext.Users.Add(user);
        DbContext.Posts.AddRange(posts);
        await DbContext.SaveChangesAsync();

        var route = new Routes.V1.Users.Index();

        // Act
        var result = await _endpoint.HandleAsync(route, _contextMock.Object);

        // Assert
        var userDto = result.Value.Data.FirstOrDefault(u => u.Id == user.Id);
        userDto.Should().NotBeNull();
        userDto!.PostsCount.Should().Be(3);
    }

    [TestMethod]
    public async Task HandleAsync_ShouldMapUserPropertiesCorrectly()
    {
        // Arrange
        var testUser = DataBuilder.CreateUser(builder => 
            builder.WithEmail("test@example.com")
                   .WithName("Test User")
                   .WithBio("Test bio"));
        
        await SaveEntityAsync(testUser);

        var route = new Routes.V1.Users.Index();

        // Act
        var result = await _endpoint.HandleAsync(route, _contextMock.Object);

        // Assert
        var userDto = result.Value.Data.FirstOrDefault(u => u.Id == testUser.Id);
        userDto.Should().NotBeNull();
        userDto!.Id.Should().Be(testUser.Id);
        userDto.Email.Should().Be(testUser.Email);
        userDto.Name.Should().Be(testUser.Name);
        userDto.Bio.Should().Be(testUser.Bio);
        userDto.CreatedAt.Should().Be(testUser.CreatedAt);
        userDto.Status.Should().Be(testUser.Status);
    }

    [TestMethod]
    public async Task HandleAsync_WithNoUsers_ShouldReturnEmptyList()
    {
        // Arrange
        await ClearDatabaseAsync();
        var route = new Routes.V1.Users.Index();

        // Act
        var result = await _endpoint.HandleAsync(route, _contextMock.Object);

        // Assert
        var response = result.Value;
        response.Data.Should().BeEmpty();
        response.TotalCount.Should().Be(0);
        response.TotalPages.Should().Be(1);
        response.HasNextPage.Should().BeFalse();
        response.HasPreviousPage.Should().BeFalse();
    }

    [TestMethod]
    public async Task HandleAsync_ShouldSetPaginationPropertiesCorrectly()
    {
        // Arrange
        var route = new Routes.V1.Users.Index();

        // Act
        var result = await _endpoint.HandleAsync(route, _contextMock.Object);

        // Assert
        var response = result.Value;
        response.Page.Should().Be(1);
        response.Limit.Should().Be(20);
        response.TotalPages.Should().Be(1); // We have less than 20 users
        response.HasNextPage.Should().BeFalse();
        response.HasPreviousPage.Should().BeFalse();
    }

    [TestMethod]
    public async Task HandleAsync_ShouldLimitResultsTo20()
    {
        // Arrange
        await ClearDatabaseAsync();
        
        // Create 25 users
        var users = DataBuilder.CreateUsers(25);
        DbContext.Users.AddRange(users);
        await DbContext.SaveChangesAsync();

        var route = new Routes.V1.Users.Index();

        // Act
        var result = await _endpoint.HandleAsync(route, _contextMock.Object);

        // Assert
        var response = result.Value;
        response.Data.Should().HaveCount(20);
        response.TotalCount.Should().Be(25);
    }

    [TestMethod]
    public async Task HandleAsync_ShouldCompleteWithinReasonableTime()
    {
        // Arrange
        var route = new Routes.V1.Users.Index();

        // Act & Assert
        await AssertCompletesWithinAsync(TimeSpan.FromMilliseconds(500), async () =>
        {
            await _endpoint.HandleAsync(route, _contextMock.Object);
        });
    }

    [TestMethod]
    public async Task HandleAsync_WithCancellation_ShouldThrowOperationCanceledException()
    {
        // Arrange
        var route = new Routes.V1.Users.Index();
        var cts = new CancellationTokenSource();
        cts.Cancel();
        
        _contextMock.Setup(x => x.CancellationToken).Returns(cts.Token);

        // Act & Assert
        await AssertThrowsAsync<OperationCanceledException>(async () =>
        {
            await _endpoint.HandleAsync(route, _contextMock.Object);
        });
    }

    [TestMethod]
    public async Task HandleAsync_WithDatabaseError_ShouldPropagateException()
    {
        // Arrange
        await DbContext.DisposeAsync(); // Dispose context to simulate database error
        var route = new Routes.V1.Users.Index();

        // Act & Assert
        await AssertThrowsAsync<ObjectDisposedException>(async () =>
        {
            await _endpoint.HandleAsync(route, _contextMock.Object);
        });
    }

    [TestMethod]
    public async Task HandleAsync_ConcurrentRequests_ShouldAllSucceed()
    {
        // Arrange
        var route = new Routes.V1.Users.Index();
        var tasks = new List<Task<Result<PagedResponse<UserDto>>>>();

        // Act
        for (int i = 0; i < 5; i++)
        {
            var endpoint = new GetUsersV1Endpoint(DbContext);
            tasks.Add(endpoint.HandleAsync(route, _contextMock.Object));
        }

        var results = await Task.WhenAll(tasks);

        // Assert
        results.Should().AllSatisfy(result =>
        {
            result.IsSuccess.Should().BeTrue();
            result.Value.Should().NotBeNull();
        });
    }
}