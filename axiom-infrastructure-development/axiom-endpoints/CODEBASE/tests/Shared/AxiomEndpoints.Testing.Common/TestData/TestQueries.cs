namespace AxiomEndpoints.Testing.Common.TestData;

public static class TestQueries
{
    public static class Simple
    {
        public const string Single = "?name=value";
        public const string Multiple = "?name=value&type=test";
        public const string Empty = "";
        public const string OnlyQuestionMark = "?";
    }

    public static class TypedValues
    {
        public const string Integer = "?id=123";
        public const string IntegerNegative = "?id=-456";
        public const string Guid = "?id=550e8400-e29b-41d4-a716-446655440000";
        public const string Boolean = "?active=true";
        public const string BooleanFalse = "?active=false";
        public const string DateTime = "?date=2023-12-01T10:30:00Z";
        public const string String = "?name=test%20value";
        public const string Decimal = "?price=19.99";
        public const string Double = "?rate=3.14159";
    }

    public static class Arrays
    {
        public const string IntegerArray = "?ids=1&ids=2&ids=3";
        public const string StringArray = "?tags=red&tags=blue&tags=green";
        public const string MixedTypes = "?id=123&tags=red&tags=blue&active=true";
    }

    public static class EdgeCases
    {
        public const string SpecialCharacters = "?name=test%20%26%20special%20%3Cchars%3E";
        public const string EmptyValue = "?name=";
        public const string NoValue = "?name";
        public const string Duplicate = "?name=first&name=second";
        public const string Unicode = "?name=test%C3%A9%C3%B1";
        public static readonly string VeryLong = "?data=" + new string('a', 1000);
    }

    public static class Invalid
    {
        public const string MalformedGuid = "?id=not-a-guid";
        public const string MalformedInteger = "?id=abc123";
        public const string MalformedBoolean = "?active=maybe";
        public const string MalformedDateTime = "?date=not-a-date";
    }

    public static class Pagination
    {
        public const string FirstPage = "?page=1&size=10";
        public const string LargePage = "?page=100&size=50";
        public const string ZeroPage = "?page=0&size=10";
        public const string NegativePage = "?page=-1&size=10";
        public const string LargeSize = "?page=1&size=1000";
    }

    public static class Filtering
    {
        public const string DateRange = "?startDate=2023-01-01&endDate=2023-12-31";
        public const string StatusFilter = "?status=active&status=pending";
        public const string SearchTerm = "?search=user%20query&category=products";
        public const string SortBy = "?sortBy=name&sortDirection=asc";
        public const string ComplexFilter = "?category=electronics&minPrice=100&maxPrice=500&inStock=true";
    }

    public static Dictionary<string, string[]> GetQueryDictionary(string queryString)
    {
        var result = new Dictionary<string, string[]>();
        
        if (string.IsNullOrEmpty(queryString) || queryString == "?")
            return result;

        var query = queryString.TrimStart('?');
        var pairs = query.Split('&', StringSplitOptions.RemoveEmptyEntries);

        foreach (var pair in pairs)
        {
            var parts = pair.Split('=', 2);
            var key = Uri.UnescapeDataString(parts[0]);
            var value = parts.Length > 1 ? Uri.UnescapeDataString(parts[1]) : string.Empty;

            if (result.ContainsKey(key))
            {
                var existing = result[key];
                var newArray = new string[existing.Length + 1];
                Array.Copy(existing, newArray, existing.Length);
                newArray[^1] = value;
                result[key] = newArray;
            }
            else
            {
                result[key] = [value];
            }
        }

        return result;
    }

    public static bool TryParseTypedValue<T>(string value, out T? result) where T : IParsable<T>
    {
        try
        {
            result = T.Parse(value, null);
            return true;
        }
        catch
        {
            result = default;
            return false;
        }
    }
}