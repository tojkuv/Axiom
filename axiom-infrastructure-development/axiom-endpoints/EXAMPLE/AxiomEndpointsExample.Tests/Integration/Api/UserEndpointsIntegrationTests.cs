using System.Net;
using AxiomEndpointsExample.Api;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;

namespace AxiomEndpointsExample.Tests.Integration.Api;

/// <summary>
/// Integration tests for user-related endpoints
/// </summary>
[TestClass]
public class UserEndpointsIntegrationTests : ApiIntegrationTestBase
{
    protected override async Task SeedTestDataAsync()
    {
        // Create test users with posts - using Factory to ensure same context as web app
        using var scope = Factory.Services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        
        var users = new List<User>();
        
        for (int i = 0; i < 15; i++)
        {
            var user = DataBuilder.CreateUser(builder => 
                builder.WithEmail($"user{i}@example.com")
                       .WithName($"User {i}")
                       .WithStatus(UserStatus.Active));
            
            users.Add(user);
        }
        
        // Add some inactive users
        for (int i = 15; i < 20; i++)
        {
            var user = DataBuilder.CreateUser(builder => 
                builder.WithEmail($"inactive{i}@example.com")
                       .WithName($"Inactive User {i}")
                       .WithStatus(UserStatus.Inactive));
            
            users.Add(user);
        }
        
        // Add a specific test user that GetUserById_WithValidId_ShouldReturnUser will use
        var testUserId = new Guid("A1B2C3D4-E5F6-789A-BCDE-F0123456789A"); // Use a mixed letter/number GUID
        var specificTestUser = DataBuilder.CreateUser(builder => 
            builder.WithEmail("specific@example.com")
                   .WithName("Specific User")
                   .WithId(testUserId));
        users.Add(specificTestUser);
        
        Console.WriteLine($"[SEED] Created test user with ID: {testUserId}");
        
        dbContext.Users.AddRange(users);
        
        // Add posts for some users
        var posts = new List<Post>();
        for (int i = 0; i < 5; i++)
        {
            posts.AddRange(new[]
            {
                DataBuilder.CreatePost(users[i]),
                DataBuilder.CreatePost(users[i]),
                DataBuilder.CreatePost(users[i])
            });
        }
        
        dbContext.Posts.AddRange(posts);
        await dbContext.SaveChangesAsync();
    }

    [TestMethod]
    public async Task GetUsers_ShouldReturnPagedResults()
    {
        // Act
        var response = await GetAsync<PagedResponse<UserDto>>("/v1/users");

        // Assert
        response.Should().NotBeNull();
        response!.Data.Should().NotBeNull();
        response.Data.Should().HaveCountLessOrEqualTo(20);
        response.Page.Should().Be(1);
        response.Limit.Should().Be(20);
        response.TotalCount.Should().BeGreaterThan(0);
    }

    [TestMethod]
    public async Task GetUsers_ShouldReturnOnlyActiveUsers()
    {
        // Act
        var response = await GetAsync<PagedResponse<UserDto>>("/v1/users");

        // Assert
        response.Should().NotBeNull();
        response!.Data.Should().AllSatisfy(user => 
            user.Status.Should().Be(UserStatus.Active));
    }

    [TestMethod]
    public async Task GetUsers_ShouldIncludePostsCounts()
    {
        // Act
        var response = await GetAsync<PagedResponse<UserDto>>("/v1/users");

        // Assert
        response.Should().NotBeNull();
        response!.Data.Should().NotBeEmpty();
        
        // Find a user that should have posts
        var userWithPosts = response.Data.FirstOrDefault(u => u.PostsCount > 0);
        userWithPosts.Should().NotBeNull();
        userWithPosts!.PostsCount.Should().BeGreaterThan(0);
    }

    [TestMethod]
    public async Task GetUserById_WithValidId_ShouldReturnUser()
    {
        // Arrange - First get any existing user from the database
        var allUsers = await GetAsync<PagedResponse<UserDto>>("/v1/users");
        allUsers.Should().NotBeNull();
        allUsers!.Data.Should().NotBeEmpty();
        
        var firstUser = allUsers.Data.First();
        Console.WriteLine($"[TEST] Using dynamic user ID: {firstUser.Id}");
        Console.WriteLine($"[TEST] User name: {firstUser.Name}, Email: {firstUser.Email}");

        // Act - Debug the URL construction  
        var url = $"/v1/users/{firstUser.Id}";
        Console.WriteLine($"[TEST] Making request to URL: {url}");
        var httpResponse = await Client.GetAsync(url);
        Console.WriteLine($"[TEST] Got response with status: {httpResponse.StatusCode}");
        
        httpResponse.EnsureSuccessStatusCode();
        var json = await httpResponse.Content.ReadAsStringAsync();
        var response = JsonSerializer.Deserialize<ApiResponse<UserDto>>(json, JsonOptions);

        // Assert
        response.Should().NotBeNull();
        response!.Data.Should().NotBeNull();
        response.Data.Id.Should().Be(firstUser.Id);
        response.Data.Email.Should().Be(firstUser.Email);
        response.Data.Name.Should().Be(firstUser.Name);
    }

    [TestMethod]
    public async Task GetUserById_WithInvalidId_ShouldReturnNotFound()
    {
        // Arrange
        var nonExistentId = Guid.NewGuid();

        // Act
        var httpResponse = await Client.GetAsync($"/v1/users/{nonExistentId}");

        // Assert
        AssertStatusCode(httpResponse, HttpStatusCode.NotFound);
    }

    [TestMethod]
    public async Task GetUserById_WithMalformedId_ShouldReturnBadRequest()
    {
        // Act
        var httpResponse = await Client.GetAsync("/v1/users/invalid-guid");

        // Assert
        AssertStatusCode(httpResponse, HttpStatusCode.BadRequest);
    }

    [TestMethod]
    public async Task SearchUsers_WithoutFilters_ShouldReturnAllActiveUsers()
    {
        // Act
        var response = await GetAsync<PagedResponse<UserDto>>("/v1/users/search");

        // Assert
        response.Should().NotBeNull();
        response!.Data.Should().NotBeEmpty();
        response.Data.Should().AllSatisfy(user => 
            user.Status.Should().Be(UserStatus.Active));
    }

    [TestMethod]
    public async Task SearchUsers_WithNameFilter_ShouldReturnMatchingUsers()
    {
        // Arrange
        var searchTerm = "User 1"; // Should match "User 1", "User 10", "User 11", etc.

        // Act
        var response = await GetAsync<PagedResponse<UserDto>>($"/v1/users/search?search={Uri.EscapeDataString(searchTerm)}");

        // Assert
        response.Should().NotBeNull();
        response!.Data.Should().NotBeEmpty();
        response.Data.Should().AllSatisfy(user => 
            user.Name.Should().Contain(searchTerm, "All returned users should match the search term"));
    }

    [TestMethod]
    public async Task SearchUsers_WithEmailFilter_ShouldReturnMatchingUsers()
    {
        // Arrange
        var searchTerm = "user1@"; // Should match users with emails starting with "user1@"

        // Act
        var response = await GetAsync<PagedResponse<UserDto>>($"/v1/users/search?search={Uri.EscapeDataString(searchTerm)}");

        // Assert
        response.Should().NotBeNull();
        response!.Data.Should().NotBeEmpty();
        response.Data.Should().AllSatisfy(user => 
            user.Email.Should().Contain(searchTerm, "All returned users should match the search term"));
    }

    [TestMethod]
    public async Task SearchUsers_WithStatusFilter_ShouldReturnUsersWithSpecifiedStatus()
    {
        // Act
        var response = await GetAsync<PagedResponse<UserDto>>($"/v1/users/search?status={UserStatus.Active}");

        // Assert
        response.Should().NotBeNull();
        response!.Data.Should().AllSatisfy(user => 
            user.Status.Should().Be(UserStatus.Active));
    }

    [TestMethod]
    public async Task SearchUsers_WithPaginationParameters_ShouldRespectLimits()
    {
        // Act
        var response = await GetAsync<PagedResponse<UserDto>>("/v1/users/search?page=1&limit=5");

        // Assert
        response.Should().NotBeNull();
        response!.Data.Should().HaveCountLessOrEqualTo(5);
        response.Page.Should().Be(1);
        response.Limit.Should().Be(5);
    }

    [TestMethod]
    public async Task SearchUsers_WithSortByName_ShouldReturnSortedResults()
    {
        // Act
        var response = await GetAsync<PagedResponse<UserDto>>("/v1/users/search?sort=Name&order=Asc");

        // Assert
        response.Should().NotBeNull();
        response!.Data.Should().NotBeEmpty();
        
        var names = response.Data.Select(u => u.Name).ToList();
        names.Should().BeInAscendingOrder("Users should be sorted by name in ascending order");
    }

    [TestMethod]
    public async Task SearchUsers_WithInvalidSortParameter_ShouldUseDefaultSort()
    {
        // Act
        var response = await GetAsync<PagedResponse<UserDto>>("/v1/users/search?sort=InvalidField");

        // Assert
        response.Should().NotBeNull();
        response!.Data.Should().NotBeEmpty();
        // Should default to CreatedAt sort without throwing error
    }

    [TestMethod]
    public async Task GetUsers_ResponseTime_ShouldBeWithinAcceptableRange()
    {
        // Act & Assert
        await AssertCompletesWithinAsync(TimeSpan.FromMilliseconds(200), async () =>
        {
            await GetAsync<PagedResponse<UserDto>>("/v1/users");
        });
    }

    [TestMethod]
    public async Task GetUserById_ResponseTime_ShouldBeWithinAcceptableRange()
    {
        // Arrange - use the pre-seeded test user
        var testUserId = new Guid("A1B2C3D4-E5F6-789A-BCDE-F0123456789A");

        // Act & Assert
        await AssertCompletesWithinAsync(TimeSpan.FromMilliseconds(100), async () =>
        {
            await GetAsync<ApiResponse<UserDto>>($"/v1/users/{testUserId}");
        });
    }

    [TestMethod]
    public async Task SearchUsers_ResponseTime_ShouldBeWithinAcceptableRange()
    {
        // Act & Assert
        await AssertCompletesWithinAsync(TimeSpan.FromMilliseconds(300), async () =>
        {
            await GetAsync<PagedResponse<UserDto>>("/v1/users/search?search=test");
        });
    }

    [TestMethod]
    public async Task MultipleSimultaneousRequests_ShouldAllSucceed()
    {
        // Arrange
        var tasks = new List<Task<PagedResponse<UserDto>?>>();
        
        // Act
        for (int i = 0; i < 10; i++)
        {
            tasks.Add(GetAsync<PagedResponse<UserDto>>("/v1/users"));
        }
        
        var results = await Task.WhenAll(tasks);

        // Assert
        results.Should().AllSatisfy(response =>
        {
            response.Should().NotBeNull();
            response!.Data.Should().NotBeNull();
        });
    }

    [TestMethod]
    public async Task GetUsers_ResponseHeaders_ShouldIncludeCorrectContentType()
    {
        // Act
        var httpResponse = await Client.GetAsync("/v1/users");

        // Assert
        AssertStatusCode(httpResponse, HttpStatusCode.OK);
        AssertContentType(httpResponse, "application/json");
    }

    [TestMethod]
    public async Task UserEndpoints_ShouldHandleEmptyDatabase()
    {
        // Arrange
        await ClearDatabaseAsync();

        // Act
        var usersResponse = await GetAsync<PagedResponse<UserDto>>("/v1/users");
        var searchResponse = await GetAsync<PagedResponse<UserDto>>("/v1/users/search");

        // Assert
        usersResponse.Should().NotBeNull();
        usersResponse!.Data.Should().BeEmpty();
        usersResponse.TotalCount.Should().Be(0);

        searchResponse.Should().NotBeNull();
        searchResponse!.Data.Should().BeEmpty();
        searchResponse.TotalCount.Should().Be(0);
    }

    [TestMethod]
    public async Task UserEndpoints_ShouldHandleLargeDatasets()
    {
        // Arrange
        await ClearDatabaseAsync();
        
        var largeUserSet = DataBuilder.CreateUsers(100);
        DbContext.Users.AddRange(largeUserSet);
        await DbContext.SaveChangesAsync();

        // Act
        var response = await GetAsync<PagedResponse<UserDto>>("/v1/users");

        // Assert
        response.Should().NotBeNull();
        response!.Data.Should().HaveCount(20); // Should be limited to page size
        response.TotalCount.Should().Be(100);
        response.TotalPages.Should().Be(5);
        response.HasNextPage.Should().BeTrue();
    }
}