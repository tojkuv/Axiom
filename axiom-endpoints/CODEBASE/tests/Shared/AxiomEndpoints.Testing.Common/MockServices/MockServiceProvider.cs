namespace AxiomEndpoints.Testing.Common.MockServices;

public class MockServiceProvider : IServiceProvider
{
    private readonly Dictionary<Type, object> _services = new();

    public MockServiceProvider RegisterService<T>(T service) where T : class
    {
        _services[typeof(T)] = service;
        return this;
    }

    public MockServiceProvider RegisterService<TInterface, TImplementation>(TImplementation service) 
        where TInterface : class 
        where TImplementation : class, TInterface
    {
        _services[typeof(TInterface)] = service;
        return this;
    }

    public object? GetService(Type serviceType)
    {
        _services.TryGetValue(serviceType, out var service);
        return service;
    }

    public T? GetService<T>() where T : class
    {
        return GetService(typeof(T)) as T;
    }

    public T GetRequiredService<T>() where T : class
    {
        var service = GetService<T>();
        if (service == null)
        {
            throw new InvalidOperationException($"Service of type {typeof(T).Name} is not registered");
        }
        return service;
    }
}