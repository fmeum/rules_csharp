"""C# Providers for rules_csharp."""

CSharpInfo = provider(
    doc = "Provider for C# compilation and runtime artifacts.",
    fields = {
        "target_framework": "string: Target framework moniker (e.g., 'net8.0', 'net9.0', 'net10.0')",
        "compile_ref": "File: The metadata-only .ref.dll produced by -refout",
        "runtime_dll": "File: The full implementation .dll",
        "pdb": "File: The portable .pdb symbol file",
        "transitive_compile_refs": "depset[File]: Transitive compile-time reference assemblies (preorder)",
        "transitive_runtime_dlls": "depset[File]: Transitive implementation assemblies (preorder)",
        "transitive_native_libs": "depset[File]: Unmanaged RID-specific shared libraries",
    },
)

CSharpAnalyzerInfo = provider(
    doc = "Provider holding Roslyn analyzer and IIncrementalGenerator DLLs.",
    fields = {
        "analyzers": "depset[File]: Roslyn analyzer and source generator DLLs",
    },
)

CSharpToolchainInfo = provider(
    doc = "Provider holding the resolved C# toolchain configuration and tools.",
    fields = {
        "dotnet_muxer": "File: Platform-specific dotnet binary",
        "csc_dll": "File: Roslyn csc.dll compiler",
        "csc_worker": "File: Persistent multiplex worker executable (optional)",
        "ref_pack": "depset[File]: Reference assemblies for target framework",
        "host_pack": "File: Native apphost binary template for target platform",
        "runtime_pack": "depset[File]: Runtime assemblies and libraries for target platform",
        "target_framework": "string: Target framework moniker",
        "target_rid": "string: Target RID (e.g., 'osx-arm64', 'linux-x64')",
        "host_rid": "string: Host RID",
    },
)
