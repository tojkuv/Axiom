using System.ComponentModel.DataAnnotations;
using System.Reflection;
using System.Text;
using System.Text.Json.Serialization;
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.CSharp.Syntax;

namespace AxiomEndpoints.ProtoGen.Core;

/// <summary>
/// Generates comprehensive proto files from C# types
/// </summary>
public class ProtoTypeGenerator
{
    private readonly ProtoGeneratorOptions _options;
    private readonly TypeAnalyzer _typeAnalyzer;
    private readonly Dictionary<Type, ProtoMessage> _processedTypes = new();

    public ProtoTypeGenerator(ProtoGeneratorOptions options)
    {
        _options = options;
        _typeAnalyzer = new TypeAnalyzer();
    }

    public async Task<ProtoPackage> GenerateProtoPackageAsync(Assembly assembly)
    {
        var package = new ProtoPackage
        {
            Name = _options.PackageName ?? assembly.GetName().Name!.ToLowerInvariant(),
            CSharpNamespace = assembly.GetName().Name!,
            Version = assembly.GetName().Version?.ToString() ?? "1.0.0",
            Options = new ProtoOptions
            {
                JavaPackage = $"com.{_options.Organization ?? "company"}.{_options.PackageName ?? assembly.GetName().Name!.ToLowerInvariant()}",
                JavaMultipleFiles = true,
                SwiftPrefix = _options.SwiftPrefix ?? "",
                ObjcClassPrefix = _options.ObjcClassPrefix ?? "AX",
                GoPackage = $"github.com/{_options.Organization ?? "company"}/{_options.PackageName ?? assembly.GetName().Name!.ToLowerInvariant()}"
            }
        };

        // Extract all types used in endpoints
        var endpointTypes = ExtractEndpointTypes(assembly);
        var eventTypes = ExtractEventTypes(assembly);
        var domainTypes = ExtractDomainTypes(assembly);

        // Process all types
        foreach (var type in endpointTypes.Concat(eventTypes).Concat(domainTypes).Distinct())
        {
            ProcessType(type, package);
        }

        // Generate service definitions from endpoints
        GenerateServices(assembly, package);

        // Add well-known types imports
        AddWellKnownImports(package);

        // Sort messages by dependency order
        package.Messages = SortByDependency(package.Messages);

        return package;
    }

    private void ProcessType(Type type, ProtoPackage package)
    {
        if (_processedTypes.ContainsKey(type) || ShouldSkipType(type))
            return;

        if (type.IsEnum)
        {
            var protoEnum = GenerateEnum(type);
            package.Enums.Add(protoEnum);
            _processedTypes[type] = new ProtoMessage { Name = protoEnum.Name, CSharpType = type.FullName! };
        }
        else if (IsCollectionType(type))
        {
            // Process element type
            var elementType = GetElementType(type);
            ProcessType(elementType, package);
        }
        else if (type.IsClass || type.IsValueType)
        {
            var protoMessage = GenerateMessage(type, package);
            package.Messages.Add(protoMessage);
            _processedTypes[type] = protoMessage;
        }
    }

    private ProtoMessage GenerateMessage(Type type, ProtoPackage package)
    {
        var message = new ProtoMessage
        {
            Name = GetProtoMessageName(type),
            CSharpType = type.FullName!,
            Documentation = ExtractXmlDocumentation(type)
        };

        // Handle inheritance
        if (type.BaseType != null && type.BaseType != typeof(object) &&
            !type.BaseType.IsAbstract && !IsSystemType(type.BaseType))
        {
            ProcessType(type.BaseType, package);
            message.BaseType = GetProtoMessageName(type.BaseType);
        }

        // Process properties
        var properties = type.GetProperties(BindingFlags.Public | BindingFlags.Instance)
            .Where(p => p.CanRead && !p.IsSpecialName);

        int fieldNumber = 1;
        foreach (var property in properties)
        {
            var field = GenerateField(property, fieldNumber++, package);
            if (field != null)
            {
                message.Fields.Add(field);
            }
        }

        // Add metadata for special types
        if (IsTimestampType(type))
        {
            message.Options.Add("(axiom.timestamp) = true");
        }

        if (IsDomainEvent(type))
        {
            message.Options.Add("(axiom.domain_event) = true");
        }

        // Handle generic types
        if (type.IsGenericType)
        {
            message.IsGeneric = true;
            message.GenericParameters = type.GetGenericArguments()
                .Select(t => t.Name)
                .ToList();
        }

        return message;
    }

    private ProtoField? GenerateField(PropertyInfo property, int fieldNumber, ProtoPackage package)
    {
        var propertyType = property.PropertyType;
        var field = new ProtoField
        {
            Name = ToSnakeCase(property.Name),
            CSharpName = property.Name,
            FieldNumber = fieldNumber,
            Documentation = ExtractXmlDocumentation(property)
        };

        // Handle nullable types
        if (Nullable.GetUnderlyingType(propertyType) != null)
        {
            propertyType = Nullable.GetUnderlyingType(propertyType)!;
            field.IsOptional = true;
        }

        // Handle collections
        if (IsCollectionType(propertyType))
        {
            field.IsRepeated = true;
            propertyType = GetElementType(propertyType);

            if (IsDictionaryType(property.PropertyType))
            {
                // Handle as map
                var keyType = property.PropertyType.GetGenericArguments()[0];
                var valueType = property.PropertyType.GetGenericArguments()[1];
                field.IsMap = true;
                field.ProtoType = $"map<{GetProtoType(keyType)}, {GetProtoType(valueType)}>";

                // Process value type if custom
                if (!IsWellKnownType(valueType))
                {
                    ProcessType(valueType, package);
                }

                return field;
            }
        }

        // Get proto type
        field.ProtoType = GetProtoType(propertyType);

        // Process custom types
        if (!IsWellKnownType(propertyType))
        {
            ProcessType(propertyType, package);
        }

        // Add field options
        AddFieldOptions(field, property);

        return field;
    }

    private void AddFieldOptions(ProtoField field, PropertyInfo property)
    {
        // Add validation rules
        var validationAttributes = property.GetCustomAttributes()
            .Where(a => IsValidationAttribute(a))
            .ToList();

        foreach (var attr in validationAttributes)
        {
            switch (attr)
            {
                case RequiredAttribute:
                    field.Options.Add("(axiom.required) = true");
                    break;

                case StringLengthAttribute stringLength:
                    field.Options.Add($"(axiom.min_length) = {stringLength.MinimumLength}");
                    field.Options.Add($"(axiom.max_length) = {stringLength.MaximumLength}");
                    break;

                case RangeAttribute range:
                    field.Options.Add($"(axiom.min_value) = {range.Minimum}");
                    field.Options.Add($"(axiom.max_value) = {range.Maximum}");
                    break;

                case RegularExpressionAttribute regex:
                    field.Options.Add($"(axiom.pattern) = \"{EscapeString(regex.Pattern)}\"");
                    break;
            }
        }

        // Add serialization options
        var jsonProperty = property.GetCustomAttribute<JsonPropertyNameAttribute>();
        if (jsonProperty != null)
        {
            field.Options.Add($"json_name = \"{jsonProperty.Name}\"");
        }

        // Mark as deprecated if needed
        if (property.GetCustomAttribute<ObsoleteAttribute>() != null)
        {
            field.Options.Add("deprecated = true");
        }
    }

    private string GetProtoType(Type type)
    {
        // Well-known proto types
        var typeMap = new Dictionary<Type, string>
        {
            [typeof(bool)] = "bool",
            [typeof(int)] = "int32",
            [typeof(uint)] = "uint32",
            [typeof(long)] = "int64",
            [typeof(ulong)] = "uint64",
            [typeof(float)] = "float",
            [typeof(double)] = "double",
            [typeof(string)] = "string",
            [typeof(byte[])] = "bytes",
            [typeof(DateTime)] = "google.protobuf.Timestamp",
            [typeof(DateTimeOffset)] = "google.protobuf.Timestamp",
            [typeof(TimeSpan)] = "google.protobuf.Duration",
            [typeof(Guid)] = "string", // With format annotation
            [typeof(decimal)] = "axiom.Decimal", // Custom decimal type
            [typeof(DateOnly)] = "google.type.Date",
            [typeof(TimeOnly)] = "google.type.TimeOfDay"
        };

        if (typeMap.TryGetValue(type, out var protoType))
            return protoType;

        if (type.IsEnum)
            return GetProtoMessageName(type);

        if (type.IsGenericType)
        {
            var genericDef = type.GetGenericTypeDefinition();
            if (genericDef == typeof(List<>) || genericDef == typeof(IList<>) ||
                genericDef == typeof(IEnumerable<>) || genericDef == typeof(HashSet<>))
            {
                // Handled by IsRepeated
                return GetProtoType(type.GetGenericArguments()[0]);
            }

            if (genericDef == typeof(Dictionary<,>) || genericDef == typeof(IDictionary<,>))
            {
                // Handled as map
                var keyType = type.GetGenericArguments()[0];
                var valueType = type.GetGenericArguments()[1];
                return $"map<{GetProtoType(keyType)}, {GetProtoType(valueType)}>";
            }

            // Handle other generic types
            return GetProtoMessageName(type);
        }

        return GetProtoMessageName(type);
    }

    // Helper methods
    private List<Type> ExtractEndpointTypes(Assembly assembly)
    {
        var types = new List<Type>();
        
        // Find all IAxiom implementations
        var axiomTypes = assembly.GetTypes()
            .Where(t => t.GetInterfaces().Any(i => i.IsGenericType && 
                i.GetGenericTypeDefinition().Name.Contains("IAxiom")))
            .ToList();

        foreach (var axiomType in axiomTypes)
        {
            var axiomInterface = axiomType.GetInterfaces()
                .FirstOrDefault(i => i.IsGenericType && i.GetGenericTypeDefinition().Name.Contains("IAxiom"));
            
            if (axiomInterface != null)
            {
                var genericArgs = axiomInterface.GetGenericArguments();
                types.AddRange(genericArgs);
            }
        }

        return types.Distinct().ToList();
    }

    private List<Type> ExtractEventTypes(Assembly assembly)
    {
        return assembly.GetTypes()
            .Where(t => t.Name.EndsWith("Event") || t.Name.EndsWith("Command"))
            .ToList();
    }

    private List<Type> ExtractDomainTypes(Assembly assembly)
    {
        return assembly.GetTypes()
            .Where(t => t.IsClass && !t.IsAbstract && t.Namespace?.Contains("Models") == true)
            .ToList();
    }

    private void GenerateServices(Assembly assembly, ProtoPackage package)
    {
        var axiomTypes = assembly.GetTypes()
            .Where(t => t.GetInterfaces().Any(i => i.IsGenericType && 
                i.GetGenericTypeDefinition().Name.Contains("IAxiom")))
            .ToList();

        var serviceGroups = axiomTypes
            .GroupBy(t => GetServiceName(t))
            .ToList();

        foreach (var serviceGroup in serviceGroups)
        {
            var service = new ProtoService
            {
                Name = serviceGroup.Key,
                Documentation = $"Service for {serviceGroup.Key} operations"
            };

            foreach (var endpointType in serviceGroup)
            {
                var axiomInterface = endpointType.GetInterfaces()
                    .FirstOrDefault(i => i.IsGenericType && i.GetGenericTypeDefinition().Name.Contains("IAxiom"));

                if (axiomInterface != null)
                {
                    var genericArgs = axiomInterface.GetGenericArguments();
                    if (genericArgs.Length == 2)
                    {
                        var rpc = new ProtoRpc
                        {
                            Name = endpointType.Name,
                            RequestType = GetProtoMessageName(genericArgs[0]),
                            ResponseType = GetProtoMessageName(genericArgs[1]),
                            IsServerStreaming = false,
                            IsClientStreaming = false
                        };

                        service.Rpcs.Add(rpc);
                    }
                }
            }

            package.Services.Add(service);
        }
    }

    private ProtoEnum GenerateEnum(Type enumType)
    {
        var protoEnum = new ProtoEnum
        {
            Name = GetProtoMessageName(enumType),
            CSharpType = enumType.FullName!,
            Documentation = ExtractXmlDocumentation(enumType)
        };

        var enumValues = Enum.GetValues(enumType);
        foreach (var value in enumValues)
        {
            var enumValue = new ProtoEnumValue
            {
                Name = ToSnakeCase(value.ToString()!).ToUpperInvariant(),
                Value = Convert.ToInt32(value),
                Documentation = ExtractXmlDocumentation(enumType.GetField(value.ToString()!))
            };

            protoEnum.Values.Add(enumValue);
        }

        return protoEnum;
    }

    private void AddWellKnownImports(ProtoPackage package)
    {
        package.Imports.Add("google/protobuf/timestamp.proto");
        package.Imports.Add("google/protobuf/duration.proto");
        package.Imports.Add("google/protobuf/empty.proto");
        package.Imports.Add("google/type/date.proto");
        package.Imports.Add("google/type/timeofday.proto");
        package.Imports.Add("axiom_options.proto");
    }

    private List<ProtoMessage> SortByDependency(List<ProtoMessage> messages)
    {
        // Simple topological sort - in a real implementation, this would be more sophisticated
        return messages.OrderBy(m => m.Name).ToList();
    }

    private bool ShouldSkipType(Type type)
    {
        return type.IsGenericTypeDefinition ||
               type.IsInterface ||
               type.IsAbstract ||
               IsSystemType(type) ||
               type.Assembly.GetName().Name == "System.Private.CoreLib";
    }

    private bool IsSystemType(Type type)
    {
        return type.Namespace?.StartsWith("System") == true ||
               type.Namespace?.StartsWith("Microsoft") == true;
    }

    private bool IsCollectionType(Type type)
    {
        return type.IsArray ||
               (type.IsGenericType && (
                   type.GetGenericTypeDefinition() == typeof(List<>) ||
                   type.GetGenericTypeDefinition() == typeof(IList<>) ||
                   type.GetGenericTypeDefinition() == typeof(ICollection<>) ||
                   type.GetGenericTypeDefinition() == typeof(IEnumerable<>) ||
                   type.GetGenericTypeDefinition() == typeof(HashSet<>) ||
                   type.GetGenericTypeDefinition() == typeof(Dictionary<,>) ||
                   type.GetGenericTypeDefinition() == typeof(IDictionary<,>)
               ));
    }

    private bool IsDictionaryType(Type type)
    {
        return type.IsGenericType && (
            type.GetGenericTypeDefinition() == typeof(Dictionary<,>) ||
            type.GetGenericTypeDefinition() == typeof(IDictionary<,>)
        );
    }

    private Type GetElementType(Type type)
    {
        if (type.IsArray)
            return type.GetElementType()!;

        if (type.IsGenericType)
            return type.GetGenericArguments()[0];

        return type;
    }

    private bool IsWellKnownType(Type type)
    {
        return type.IsPrimitive ||
               type == typeof(string) ||
               type == typeof(DateTime) ||
               type == typeof(DateTimeOffset) ||
               type == typeof(TimeSpan) ||
               type == typeof(Guid) ||
               type == typeof(decimal) ||
               type == typeof(byte[]);
    }

    private bool IsTimestampType(Type type)
    {
        return type == typeof(DateTime) || type == typeof(DateTimeOffset);
    }

    private bool IsDomainEvent(Type type)
    {
        return type.Name.EndsWith("Event") || type.Name.EndsWith("Command");
    }

    private bool IsValidationAttribute(Attribute attr)
    {
        return attr is RequiredAttribute ||
               attr is StringLengthAttribute ||
               attr is RangeAttribute ||
               attr is RegularExpressionAttribute;
    }

    private string GetProtoMessageName(Type type)
    {
        if (type.IsGenericType)
        {
            var baseName = type.Name.Split('`')[0];
            return baseName;
        }

        return type.Name;
    }

    private string GetServiceName(Type endpointType)
    {
        var serviceName = endpointType.Namespace?.Split('.').LastOrDefault() ?? "Default";
        
        if (!serviceName.EndsWith("Service", StringComparison.OrdinalIgnoreCase))
        {
            serviceName += "Service";
        }

        return serviceName;
    }

    private string ToSnakeCase(string input)
    {
        if (string.IsNullOrEmpty(input))
            return input;

        var result = new StringBuilder();
        
        for (int i = 0; i < input.Length; i++)
        {
            if (i > 0 && char.IsUpper(input[i]))
            {
                result.Append('_');
            }
            result.Append(char.ToLowerInvariant(input[i]));
        }

        return result.ToString();
    }

    private string ExtractXmlDocumentation(MemberInfo member)
    {
        // In a real implementation, this would parse XML documentation
        return $"Documentation for {member.Name}";
    }

    private string ExtractXmlDocumentation(Type type)
    {
        // In a real implementation, this would parse XML documentation
        return $"Documentation for {type.Name}";
    }

    private string EscapeString(string input)
    {
        return input.Replace("\"", "\\\"").Replace("\\", "\\\\");
    }
}