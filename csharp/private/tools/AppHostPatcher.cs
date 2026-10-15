using System;
using System.Diagnostics;
using System.IO;
using System.Text;

namespace RulesCsharp.Tools
{
    public static class AppHostPatcher
    {
        private static readonly byte[] Placeholder = Encoding.ASCII.GetBytes(
            "c3ab8ff13720e8ad9047dd39466b3c8974e592c2fa383d4a3960714caef0c4f2"
        );

        public static int Main(string[] args)
        {
            string? templatePath = null;
            string? outputPath = null;
            string? dllName = null;

            for (int i = 0; i < args.Length; i++)
            {
                if (args[i].StartsWith("--apphost-template="))
                    templatePath = args[i].Substring("--apphost-template=".Length);
                else if (args[i].StartsWith("--template="))
                    templatePath = args[i].Substring("--template=".Length);
                else if (args[i].StartsWith("--output="))
                    outputPath = args[i].Substring("--output=".Length);
                else if (args[i].StartsWith("--assembly-name="))
                    dllName = args[i].Substring("--assembly-name=".Length);
                else if (args[i].StartsWith("--dll-name="))
                    dllName = args[i].Substring("--dll-name=".Length);
                else if (args[i] == "-t" && i + 1 < args.Length)
                    templatePath = args[++i];
                else if (args[i] == "-o" && i + 1 < args.Length)
                    outputPath = args[++i];
                else if (args[i] == "-a" && i + 1 < args.Length)
                    dllName = args[++i];
            }

            if (string.IsNullOrEmpty(templatePath) || string.IsNullOrEmpty(outputPath) || string.IsNullOrEmpty(dllName))
            {
                Console.Error.WriteLine("Usage: AppHostPatcher --apphost-template=<path> --output=<path> --assembly-name=<name>");
                return 1;
            }

            string resolvedTemplate = ResolveRunfile(templatePath);
            if (!File.Exists(resolvedTemplate))
            {
                Console.Error.WriteLine($"AppHost template not found at '{templatePath}' (resolved: '{resolvedTemplate}')");
                return 1;
            }

            byte[] data = File.ReadAllBytes(resolvedTemplate);
            int index = IndexOf(data, Placeholder);
            if (index == -1)
            {
                Console.Error.WriteLine($"Placeholder not found in '{resolvedTemplate}'");
                return 1;
            }

            byte[] dllBytes = Encoding.UTF8.GetBytes(dllName);
            Array.Clear(data, index, Placeholder.Length);
            Array.Copy(dllBytes, 0, data, index, dllBytes.Length);
            data[index + dllBytes.Length] = 0; // null terminator

            string? dir = Path.GetDirectoryName(outputPath);
            if (!string.IsNullOrEmpty(dir))
            {
                Directory.CreateDirectory(dir);
            }

            File.WriteAllBytes(outputPath, data);

            if (!OperatingSystem.IsWindows())
            {
                try
                {
                    File.SetUnixFileMode(
                        outputPath,
                        UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute |
                        UnixFileMode.GroupRead | UnixFileMode.GroupExecute |
                        UnixFileMode.OtherRead | UnixFileMode.OtherExecute
                    );
                }
                catch (Exception ex)
                {
                    Console.Error.WriteLine($"Warning: Failed to set unix file mode: {ex.Message}");
                }

                if (OperatingSystem.IsMacOS())
                {
                    try
                    {
                        var psi = new ProcessStartInfo("codesign", $"-s - -f \"{outputPath}\"")
                        {
                            RedirectStandardOutput = true,
                            RedirectStandardError = true,
                            UseShellExecute = false,
                        };
                        using var proc = Process.Start(psi);
                        proc?.WaitForExit();
                    }
                    catch
                    {
                        // Ignore if codesign is unavailable in foreign or cross environments
                    }
                }
            }

            return 0;
        }

        private static string ResolveRunfile(string path)
        {
            if (File.Exists(path)) return path;

            string? runfilesDir = Environment.GetEnvironmentVariable("RUNFILES_DIR");
            if (!string.IsNullOrEmpty(runfilesDir))
            {
                string combined = Path.Combine(runfilesDir, path.Replace('\\', '/').TrimStart('/'));
                if (File.Exists(combined)) return combined;
            }

            string? manifest = Environment.GetEnvironmentVariable("RUNFILES_MANIFEST_FILE");
            if (!string.IsNullOrEmpty(manifest) && File.Exists(manifest))
            {
                string normPath = path.Replace('\\', '/').TrimStart('.', '/');
                foreach (var line in File.ReadLines(manifest))
                {
                    int spaceIdx = line.IndexOf(' ');
                    if (spaceIdx > 0)
                    {
                        string rpath = line.Substring(0, spaceIdx);
                        if (rpath == normPath || rpath.EndsWith("/" + normPath) || normPath.EndsWith("/" + rpath))
                        {
                            string target = line.Substring(spaceIdx + 1).Trim();
                            if (File.Exists(target)) return target;
                        }
                    }
                }
            }

            return path;
        }

        private static int IndexOf(byte[] source, byte[] pattern)
        {
            if (pattern.Length == 0 || source.Length < pattern.Length) return -1;
            for (int i = 0; i <= source.Length - pattern.Length; i++)
            {
                bool match = true;
                for (int j = 0; j < pattern.Length; j++)
                {
                    if (source[i + j] != pattern[j])
                    {
                        match = false;
                        break;
                    }
                }
                if (match) return i;
            }
            return -1;
        }
    }
}
