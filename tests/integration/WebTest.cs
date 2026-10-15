using System;

namespace RulesCsharp.IntegrationTests;

public class WebTest
{
    public static int Main()
    {
        Console.WriteLine("Testing Microsoft.NET.Sdk.Web compilation and runtime references.");
        var builder = Microsoft.AspNetCore.Builder.WebApplication.CreateBuilder(new string[0]);
        var app = builder.Build();
        if (app == null)
        {
            Console.Error.WriteLine("Failed to create WebApplication instance.");
            return 1;
        }
        Console.WriteLine("WebApplication instance created successfully.");
        return 0;
    }
}
