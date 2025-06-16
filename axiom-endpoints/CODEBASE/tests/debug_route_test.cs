using AxiomEndpoints.Routing;
using AxiomEndpoints.Tests;

// Quick debug test
var template1 = RouteTemplateGenerator.Generate<UsersWithParam.ById>();
Console.WriteLine($"UsersWithParam.ById: {template1}");

var template2 = RouteTemplateGenerator.Generate<Orders.ByUserAndId>();
Console.WriteLine($"Orders.ByUserAndId: {template2}");

var template3 = RouteTemplateGenerator.Generate<UserById>();
Console.WriteLine($"UserById: {template3}");

var template4 = RouteTemplateGenerator.Generate<OrderByUserAndId>();
Console.WriteLine($"OrderByUserAndId: {template4}");