using System;

namespace RulesCsharp.Examples;

public static class GreeterTest
{
    public static int Main()
    {
        string result = Greeter.Greet("BCR");
        if (result != "Hello, BCR!")
        {
            Console.Error.WriteLine($"Assertion failed: expected 'Hello, BCR!', got '{result}'");
            return 1;
        }
        Console.WriteLine("Greeter test passed.");
        return 0;
    }
}
