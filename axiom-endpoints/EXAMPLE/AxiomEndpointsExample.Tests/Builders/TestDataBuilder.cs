using AxiomEndpointsExample.Api;
using AutoFixture;

namespace AxiomEndpointsExample.Tests.Builders;

/// <summary>
/// Builder for creating test data with realistic values
/// </summary>
public class TestDataBuilder
{
    private readonly IFixture _fixture;

    public TestDataBuilder(IFixture fixture)
    {
        _fixture = fixture;
    }

    /// <summary>
    /// Creates a valid user with default values
    /// </summary>
    public User CreateUser() => CreateUser(builder => { });

    /// <summary>
    /// Creates a user with custom configuration
    /// </summary>
    public User CreateUser(Action<UserBuilder> configure)
    {
        var builder = new UserBuilder(_fixture);
        configure(builder);
        return builder.Build();
    }

    /// <summary>
    /// Creates multiple users
    /// </summary>
    public List<User> CreateUsers(int count) => CreateUsers(count, builder => { });

    /// <summary>
    /// Creates multiple users with custom configuration
    /// </summary>
    public List<User> CreateUsers(int count, Action<UserBuilder> configure)
    {
        return Enumerable.Range(0, count)
            .Select(_ => CreateUser(configure))
            .ToList();
    }

    /// <summary>
    /// Creates a post for a user
    /// </summary>
    public Post CreatePost(User user) => CreatePost(user, builder => { });

    /// <summary>
    /// Creates a post with custom configuration
    /// </summary>
    public Post CreatePost(User user, Action<PostBuilder> configure)
    {
        var builder = new PostBuilder(_fixture, user);
        configure(builder);
        return builder.Build();
    }

    /// <summary>
    /// Creates a comment for a post
    /// </summary>
    public Comment CreateComment(Post post, User author) => CreateComment(post, author, builder => { });

    /// <summary>
    /// Creates a comment with custom configuration
    /// </summary>
    public Comment CreateComment(Post post, User author, Action<CommentBuilder> configure)
    {
        var builder = new CommentBuilder(_fixture, post, author);
        configure(builder);
        return builder.Build();
    }

    /// <summary>
    /// Creates a complete user with posts and comments
    /// </summary>
    public User CreateUserWithContent(int postCount = 3, int commentsPerPost = 2)
    {
        var user = CreateUser();
        var posts = CreatePosts(user, postCount);
        
        foreach (var post in posts)
        {
            CreateComments(post, user, commentsPerPost);
        }
        
        return user;
    }

    private List<Post> CreatePosts(User user, int count)
    {
        return Enumerable.Range(0, count)
            .Select(_ => CreatePost(user))
            .ToList();
    }

    private List<Comment> CreateComments(Post post, User author, int count)
    {
        return Enumerable.Range(0, count)
            .Select(_ => CreateComment(post, author))
            .ToList();
    }
}

/// <summary>
/// Builder for User entities
/// </summary>
public class UserBuilder
{
    private readonly IFixture _fixture;
    private readonly User _user;

    public UserBuilder(IFixture fixture)
    {
        _fixture = fixture;
        _user = new User
        {
            Id = Guid.NewGuid(),
            Email = $"test.{Guid.NewGuid():N}@example.com",
            Name = $"Test User {_fixture.Create<int>()}",
            Bio = _fixture.Create<string>()[..Math.Min(500, _fixture.Create<string>().Length)],
            CreatedAt = DateTime.UtcNow.AddDays(-_fixture.Create<int>() % 365),
            Status = UserStatus.Active,
            Posts = new List<Post>()
        };
    }

    public UserBuilder WithId(Guid id)
    {
        _user.Id = id;
        return this;
    }

    public UserBuilder WithEmail(string email)
    {
        _user.Email = email;
        return this;
    }

    public UserBuilder WithName(string name)
    {
        _user.Name = name;
        return this;
    }

    public UserBuilder WithBio(string bio)
    {
        _user.Bio = bio;
        return this;
    }

    public UserBuilder WithStatus(UserStatus status)
    {
        _user.Status = status;
        return this;
    }

    public UserBuilder WithCreatedAt(DateTime createdAt)
    {
        _user.CreatedAt = createdAt;
        return this;
    }

    public UserBuilder AsInactive()
    {
        _user.Status = UserStatus.Inactive;
        return this;
    }

    public UserBuilder AsSuspended()
    {
        _user.Status = UserStatus.Suspended;
        return this;
    }

    public User Build() => _user;
}

/// <summary>
/// Builder for Post entities
/// </summary>
public class PostBuilder
{
    private readonly IFixture _fixture;
    private readonly Post _post;

    public PostBuilder(IFixture fixture, User author)
    {
        _fixture = fixture;
        _post = new Post
        {
            Id = _fixture.Create<int>(),
            Title = $"Test Post {_fixture.Create<int>()}",
            Content = _fixture.Create<string>(),
            CreatedAt = DateTime.UtcNow.AddDays(-_fixture.Create<int>() % 30),
            UserId = author.Id,
            User = author,
            Comments = new List<Comment>()
        };
    }

    public PostBuilder WithTitle(string title)
    {
        _post.Title = title;
        return this;
    }

    public PostBuilder WithContent(string content)
    {
        _post.Content = content;
        return this;
    }

    public PostBuilder WithCreatedAt(DateTime createdAt)
    {
        _post.CreatedAt = createdAt;
        return this;
    }

    public Post Build() => _post;
}

/// <summary>
/// Builder for Comment entities
/// </summary>
public class CommentBuilder
{
    private readonly IFixture _fixture;
    private readonly Comment _comment;

    public CommentBuilder(IFixture fixture, Post post, User author)
    {
        _fixture = fixture;
        _comment = new Comment
        {
            Id = _fixture.Create<int>(),
            Content = $"Test comment {_fixture.Create<int>()}",
            CreatedAt = DateTime.UtcNow.AddDays(-_fixture.Create<int>() % 7),
            PostId = post.Id,
            Post = post,
            UserId = author.Id,
            User = author
        };
    }

    public CommentBuilder WithContent(string content)
    {
        _comment.Content = content;
        return this;
    }

    public CommentBuilder WithCreatedAt(DateTime createdAt)
    {
        _comment.CreatedAt = createdAt;
        return this;
    }

    public Comment Build() => _comment;
}