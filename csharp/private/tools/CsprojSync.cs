using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace RulesCsharp.Tools
{
    public static class CsprojSync
    {
        public static int Main(string[] args)
        {
            string? workspace = null;
            bool checkMode = false;
            bool roundTrip = false;

            foreach (var arg in args)
            {
                if (arg.StartsWith("--workspace="))
                    workspace = arg.Substring("--workspace=".Length);
                else if (arg == "--check")
                    checkMode = true;
                else if (arg == "--round-trip")
                    roundTrip = true;
            }

            if (string.IsNullOrEmpty(workspace))
            {
                workspace = Environment.GetEnvironmentVariable("BUILD_WORKSPACE_DIRECTORY");
            }
            if (string.IsNullOrEmpty(workspace))
            {
                workspace = Directory.GetCurrentDirectory();
            }

            workspace = Path.GetFullPath(workspace);
            Console.WriteLine($"CsprojSync running in workspace: {workspace}");

            var csDirs = FindCsDirectories(workspace);
            Console.WriteLine($"Found {csDirs.Count} directories containing C# files.");

            int errorCount = 0;

            foreach (var dir in csDirs)
            {
                string dirName = Path.GetFileName(dir);
                if (string.IsNullOrEmpty(dirName)) dirName = "root";

                var csFiles = Directory.GetFiles(dir, "*.cs")
                    .Select(Path.GetFileName)
                    .Where(f => !string.IsNullOrEmpty(f) && !f.StartsWith(".#"))
                    .OrderBy(f => f)
                    .ToList();

                if (csFiles.Count == 0) continue;

                string buildFile = Path.Combine(dir, "BUILD.bazel");
                if (!File.Exists(buildFile))
                {
                    buildFile = Path.Combine(dir, "BUILD");
                }

                var targets = new List<string>();
                if (File.Exists(buildFile))
                {
                    string buildContent = File.ReadAllText(buildFile);
                    var matches = Regex.Matches(buildContent, @"(?:csharp_library|csharp_binary|csharp_test)\s*\(\s*name\s*=\s*""([^""]+)""");
                    foreach (Match m in matches)
                    {
                        targets.Add(m.Groups[1].Value);
                    }
                }

                if (targets.Count == 0)
                {
                    targets.Add(dirName);
                }

                foreach (var target in targets)
                {
                    string csprojFile = Path.Combine(dir, $"{target}.bazel.csproj");
                    string csprojContent = GenerateCsproj(workspace, dir, target, csFiles);

                    if (checkMode || roundTrip)
                    {
                        if (!File.Exists(csprojFile))
                        {
                            Console.Error.WriteLine($"Missing synthetic csproj: {csprojFile}");
                            errorCount++;
                        }
                        else
                        {
                            string existing = File.ReadAllText(csprojFile);
                            if (Normalize(existing) != Normalize(csprojContent))
                            {
                                Console.Error.WriteLine($"Out-of-sync csproj: {csprojFile}");
                                errorCount++;
                            }
                        }
                    }

                    if (!checkMode)
                    {
                        File.WriteAllText(csprojFile, csprojContent, Encoding.UTF8);
                        Console.WriteLine($"Synchronized: {csprojFile}");
                    }
                }
            }

            if (checkMode && errorCount > 0)
            {
                Console.Error.WriteLine($"Check failed: {errorCount} files out of sync.");
                return 1;
            }

            Console.WriteLine("CsprojSync completed successfully.");
            return 0;
        }

        private static List<string> FindCsDirectories(string root)
        {
            var results = new List<string>();
            var ignoredDirs = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
                ".git", "bazel-bin", "bazel-out", "bazel-testlogs", "bin", "obj", ".idea", ".vscode"
            };

            void Walk(string current)
            {
                string name = Path.GetFileName(current);
                if (name.StartsWith("bazel-") || ignoredDirs.Contains(name))
                {
                    return;
                }

                bool hasCs = false;
                try
                {
                    hasCs = Directory.EnumerateFiles(current, "*.cs").Any();
                }
                catch { }

                if (hasCs)
                {
                    results.Add(current);
                }

                try
                {
                    foreach (var sub in Directory.EnumerateDirectories(current))
                    {
                        Walk(sub);
                    }
                }
                catch { }
            }

            Walk(root);
            return results;
        }

        private static string GenerateCsproj(string workspace, string dir, string targetName, List<string?> csFiles)
        {
            string relDir = Path.GetRelativePath(workspace, dir).Replace("\\", "/");
            int depth = relDir.Split(new[] { '/' }, StringSplitOptions.RemoveEmptyEntries).Length;
            string upPrefix = string.Join("/", Enumerable.Repeat("..", depth));
            string bazelBinRel = string.IsNullOrEmpty(upPrefix) ? "bazel-bin" : $"{upPrefix}/bazel-bin";

            var sb = new StringBuilder();
            sb.AppendLine("<Project Sdk=\"Microsoft.NET.Sdk\">");
            sb.AppendLine("  <PropertyGroup>");
            sb.AppendLine("    <TargetFramework>net8.0</TargetFramework>");
            sb.AppendLine("    <EnableDefaultItems>false</EnableDefaultItems>");
            sb.AppendLine("    <Nullable>enable</Nullable>");
            sb.AppendLine("    <LangVersion>latest</LangVersion>");
            sb.AppendLine("  </PropertyGroup>");
            sb.AppendLine();
            sb.AppendLine("  <ItemGroup>");
            foreach (var f in csFiles)
            {
                sb.AppendLine($"    <Compile Include=\"{f}\" />");
            }
            sb.AppendLine("  </ItemGroup>");
            sb.AppendLine();
            sb.AppendLine("  <ItemGroup>");
            sb.AppendLine($"    <Reference Include=\"{targetName}\">");
            sb.AppendLine($"      <HintPath>{bazelBinRel}/{relDir}/{targetName}.ref.dll</HintPath>");
            sb.AppendLine("    </Reference>");
            sb.AppendLine("  </ItemGroup>");
            sb.AppendLine("</Project>");
            return sb.ToString();
        }

        private static string Normalize(string s) => s.Replace("\r\n", "\n").Trim();
    }
}
