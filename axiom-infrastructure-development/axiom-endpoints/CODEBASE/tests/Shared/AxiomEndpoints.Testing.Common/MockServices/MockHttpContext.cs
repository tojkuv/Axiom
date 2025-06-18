using System.Diagnostics.CodeAnalysis;
using System.Net.WebSockets;
using System.Security.Cryptography.X509Certificates;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.Features;

namespace AxiomEndpoints.Testing.Common.MockServices;

public class MockHttpContext : HttpContext
{
    private readonly Dictionary<Type, object> _features = new();
    private readonly Dictionary<object, object?> _items = new();

    public MockHttpContext()
    {
        Request = new MockHttpRequest(this);
        Response = new MockHttpResponse(this);
        Connection = new MockConnectionInfo();
        WebSockets = new MockWebSocketManager();
        User = new System.Security.Claims.ClaimsPrincipal();
        Features = new MockFeatureCollection(_features);
        Items = _items;
        RequestServices = new MockServiceProvider();
        Session = new MockSession();
    }

    public override HttpRequest Request { get; }
    public override HttpResponse Response { get; }
    public override ConnectionInfo Connection { get; }
    public override WebSocketManager WebSockets { get; }
    public override System.Security.Claims.ClaimsPrincipal User { get; set; }
    public override IDictionary<object, object?> Items { get; set; }
    public override IServiceProvider RequestServices { get; set; }
    public override CancellationToken RequestAborted { get; set; }
    public override string TraceIdentifier { get; set; } = "MockTraceId";
    public override ISession Session { get; set; }
    public override IFeatureCollection Features { get; }

    public override void Abort() { }
}

public class MockHttpRequest : HttpRequest
{
    public MockHttpRequest(HttpContext context)
    {
        HttpContext = context;
        Headers = new HeaderDictionary();
        Query = new QueryCollection();
        Cookies = new MockRequestCookieCollection();
        Form = new FormCollection(new Dictionary<string, Microsoft.Extensions.Primitives.StringValues>());
        Body = new MemoryStream();
    }

    public override HttpContext HttpContext { get; }
    public override string Method { get; set; } = "GET";
    public override string Scheme { get; set; } = "http";
    public override bool IsHttps { get; set; }
    public override HostString Host { get; set; } = new("localhost");
    public override PathString PathBase { get; set; }
    public override PathString Path { get; set; } = "/";
    public override QueryString QueryString { get; set; }
    public override IQueryCollection Query { get; set; }
    public override string Protocol { get; set; } = "HTTP/1.1";
    public override IHeaderDictionary Headers { get; }
    public override IRequestCookieCollection Cookies { get; set; }
    public override long? ContentLength { get; set; }
    public override string? ContentType { get; set; }
    public override Stream Body { get; set; }
    public override bool HasFormContentType => ContentType?.StartsWith("application/x-www-form-urlencoded") == true ||
                                                ContentType?.StartsWith("multipart/form-data") == true;
    public override IFormCollection Form { get; set; }

    public override Task<IFormCollection> ReadFormAsync(CancellationToken cancellationToken = default)
    {
        return Task.FromResult(Form);
    }
}

public class MockHttpResponse : HttpResponse
{
    public MockHttpResponse(HttpContext context)
    {
        HttpContext = context;
        Headers = new HeaderDictionary();
        Cookies = new MockResponseCookies();
        Body = new MemoryStream();
    }

    public override HttpContext HttpContext { get; }
    public override int StatusCode { get; set; } = 200;
    public override IHeaderDictionary Headers { get; }
    public override Stream Body { get; set; }
    public override long? ContentLength { get; set; }
    public override string? ContentType { get; set; }
    public override IResponseCookies Cookies { get; }
    public override bool HasStarted => false;

    public override void OnStarting(Func<object, Task> callback, object state) { }
    public override void OnCompleted(Func<object, Task> callback, object state) { }
    public override void Redirect(string location, bool permanent) { }
}

public class MockConnectionInfo : ConnectionInfo
{
    public override string Id { get; set; } = "MockConnectionId";
    public override System.Net.IPAddress? RemoteIpAddress { get; set; }
    public override int RemotePort { get; set; }
    public override System.Net.IPAddress? LocalIpAddress { get; set; }
    public override int LocalPort { get; set; }
    public override X509Certificate2? ClientCertificate { get; set; }

    public override Task<X509Certificate2?> GetClientCertificateAsync(CancellationToken cancellationToken = default)
    {
        return Task.FromResult(ClientCertificate);
    }
}

public class MockWebSocketManager : WebSocketManager
{
    public override bool IsWebSocketRequest => false;
    public override IList<string> WebSocketRequestedProtocols => new List<string>();

    public override Task<WebSocket> AcceptWebSocketAsync(string? subProtocol)
    {
        throw new NotSupportedException("WebSocket not supported in mock context");
    }
}

public class MockRequestCookieCollection : IRequestCookieCollection
{
    private readonly Dictionary<string, string> _cookies = new();

    public string? this[string key] => _cookies.TryGetValue(key, out var value) ? value : null;
    public int Count => _cookies.Count;
    public ICollection<string> Keys => _cookies.Keys;

    public bool ContainsKey(string key) => _cookies.ContainsKey(key);

    public IEnumerator<KeyValuePair<string, string>> GetEnumerator() => _cookies.GetEnumerator();
    System.Collections.IEnumerator System.Collections.IEnumerable.GetEnumerator() => GetEnumerator();

#pragma warning disable CS8769
    bool IRequestCookieCollection.TryGetValue(string key, out string? value) => _cookies.TryGetValue(key, out value!);
#pragma warning restore CS8769
}

public class MockResponseCookies : IResponseCookies
{
    private readonly List<string> _cookies = new();

    public void Append(string key, string value) => _cookies.Add($"{key}={value}");
    public void Append(string key, string value, CookieOptions options) => _cookies.Add($"{key}={value}");
    public void Delete(string key) => _cookies.RemoveAll(c => c.StartsWith($"{key}="));
    public void Delete(string key, CookieOptions options) => Delete(key);
}

public class MockSession : ISession
{
    private readonly Dictionary<string, byte[]> _sessionData = new();

    public string Id => "MockSessionId";
    public bool IsAvailable => true;
    public IEnumerable<string> Keys => _sessionData.Keys;

    public void Clear() => _sessionData.Clear();
    public Task CommitAsync(CancellationToken cancellationToken = default) => Task.CompletedTask;
    public Task LoadAsync(CancellationToken cancellationToken = default) => Task.CompletedTask;
    public void Remove(string key) => _sessionData.Remove(key);
    public void Set(string key, byte[] value) => _sessionData[key] = value;
    public bool TryGetValue(string key, out byte[] value) => _sessionData.TryGetValue(key, out value!);
}

public class MockFeatureCollection : IFeatureCollection
{
    private readonly Dictionary<Type, object> _features;

    public MockFeatureCollection(Dictionary<Type, object> features)
    {
        _features = features;
    }

    public object? this[Type key]
    {
        get => _features.TryGetValue(key, out var feature) ? feature : null;
        set => _features[key] = value!;
    }

    public TFeature? Get<TFeature>() => (TFeature?)this[typeof(TFeature)];
    public void Set<TFeature>(TFeature? instance) => this[typeof(TFeature)] = instance!;
    public bool IsReadOnly => false;
    public int Revision => 1;

    public IEnumerator<KeyValuePair<Type, object>> GetEnumerator() => _features.GetEnumerator();
    System.Collections.IEnumerator System.Collections.IEnumerable.GetEnumerator() => GetEnumerator();
}