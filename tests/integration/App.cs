using System;
using CommandLine;
using Riok.Mapperly.Abstractions;

namespace IntegrationTests;

public class Options
{
    [Option('v', "verbose", Required = false, HelpText = "Set output to verbose messages.")]
    public bool Verbose { get; set; }
}

public record User(string Name, int Id);
public record UserDto(string Name, int Id);

[Mapper]
public static partial class UserMapper
{
    public static partial UserDto ToDto(User user);
}

public class App
{
    public static int Main(string[] args)
    {
        string msg = Lib.GetMessage();
        Console.WriteLine(msg);
        if (msg != "Hello from rules_csharp!")
        {
            return 1;
        }

        // Test NuGet package: CommandLineParser
        var parsed = Parser.Default.ParseArguments<Options>(new[] { "--verbose" });
        if (parsed.Tag != ParserResultType.Parsed)
        {
            Console.WriteLine("Failed to parse commandline options.");
            return 2;
        }

        // Test NuGet source generator: Riok.Mapperly
        var user = new User("Antigravity", 42);
        var dto = UserMapper.ToDto(user);
        if (dto.Name != "Antigravity" || dto.Id != 42)
        {
            Console.WriteLine("Failed to map User to UserDto via Riok.Mapperly generator.");
            return 3;
        }

        Console.WriteLine($"Successfully verified CommandLineParser and Riok.Mapperly (DTO: {dto.Name}, {dto.Id})");
        return 0;
    }
}
