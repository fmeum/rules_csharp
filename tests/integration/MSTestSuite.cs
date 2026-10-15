using System;

namespace RulesCsharp.IntegrationTests;

public static class MSTestSuite
{
    public static int Main()
    {
        string? filter = Environment.GetEnvironmentVariable("TESTBRIDGE_TEST_ONLY");
        Console.WriteLine($"MSTest runner started. Active filter: '{filter}'");
        bool passed = true;
        if (string.IsNullOrEmpty(filter) || filter.Contains("Unit") || filter.Contains("TestCategory=Unit"))
        {
            Console.WriteLine("[TestMethod] TestMethod_Addition: PASSED");
        }
        else
        {
            Console.WriteLine("Filtered out TestMethod_Addition");
        }
        return passed ? 0 : 1;
    }
}
