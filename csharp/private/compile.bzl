"""Compilation rules for rules_csharp."""

load(":providers.bzl", "CSharpAnalyzerInfo", "CSharpInfo", "CSharpToolchainInfo")

def _compile_impl(ctx, is_analyzer = False):
    toolchain = ctx.toolchains["@rules_csharp//csharp:toolchain_type"].csharp_info

    out_dll = ctx.actions.declare_file(ctx.label.name + ".dll")
    refout_dll = ctx.actions.declare_file(ctx.label.name + ".ref.dll")
    pdb = ctx.actions.declare_file(ctx.label.name + ".pdb")

    direct_deps_and_exports = list(ctx.attr.deps) + list(getattr(ctx.attr, "exports", []))

    # Transitive compile references from deps and exports (preorder)
    transitive_compile_depsets = []
    for dep in direct_deps_and_exports:
        if CSharpInfo in dep:
            transitive_compile_depsets.append(dep[CSharpInfo].transitive_compile_refs)

    # Analyzers from plugins and deps
    analyzer_depsets = []
    for plugin in getattr(ctx.attr, "plugins", []):
        if CSharpAnalyzerInfo in plugin:
            analyzer_depsets.append(plugin[CSharpAnalyzerInfo].analyzers)
    for dep in ctx.attr.deps:
        if CSharpAnalyzerInfo in dep:
            analyzer_depsets.append(dep[CSharpAnalyzerInfo].analyzers)

    analyzers_depset = depset(transitive = analyzer_depsets)

    # Response file arguments
    args = ctx.actions.args()
    args.use_param_file("@%s", use_always = True)
    args.set_param_file_format("multiline")

    target_type = getattr(ctx.attr, "target_type", "library")
    args.add("-target:" + target_type)
    args.add("-out:" + out_dll.path.replace("\\", "/"))
    args.add("-refout:" + refout_dll.path.replace("\\", "/"))
    args.add("-pdb:" + pdb.path.replace("\\", "/"))

    # Unconditional architectural invariant flags
    args.add("-noconfig")
    args.add("-nostdlib+")
    args.add("-deterministic+")
    args.add("-utf8output")
    args.add("-debug:portable")
    args.add("-highentropyva+")
    args.add("-nullable:enable")
    args.add("-langversion:latest")
    args.add("-pathmap:.=/_/")

    for d in getattr(ctx.attr, "defines", []):
        args.add("-define:" + d)
    for nw in getattr(ctx.attr, "nowarn", []):
        args.add("-nowarn:" + nw)

    # Toolchain reference assemblies
    for ref in toolchain.ref_pack.to_list():
        args.add("-reference:" + ref.path.replace("\\", "/"))

    sdk_flavor = getattr(ctx.attr, "sdk", "Microsoft.NET.Sdk")
    aspnet_depsets = []
    if sdk_flavor == "Microsoft.NET.Sdk.Web" and hasattr(toolchain, "aspnetcore_ref_pack") and toolchain.aspnetcore_ref_pack:
        aspnet_depsets.append(toolchain.aspnetcore_ref_pack)
        for ref in toolchain.aspnetcore_ref_pack.to_list():
            args.add("-reference:" + ref.path.replace("\\", "/"))

    # Dependency compile references
    all_compile_refs = depset(transitive = transitive_compile_depsets, order = "preorder").to_list()
    for ref in all_compile_refs:
        args.add("-reference:" + ref.path.replace("\\", "/"))

    # Analyzers
    for analyzer in analyzers_depset.to_list():
        args.add("-analyzer:" + analyzer.path.replace("\\", "/"))

    # Resources
    for r in ctx.files.resources:
        args.add("-resource:" + r.path.replace("\\", "/"))

    # Sources
    for s in ctx.files.srcs:
        args.add(s.path.replace("\\", "/"))

    # Inputs strictly limited to srcs, resources, toolchain ref_pack, analyzers, and transitive_compile_refs
    direct_inputs = [toolchain.csc_dll] + ctx.files.srcs + ctx.files.resources
    worker_depsets = []
    if toolchain.csc_worker:
        direct_inputs.append(toolchain.csc_worker)
        if hasattr(toolchain, "csc_worker_files") and toolchain.csc_worker_files:
            worker_depsets.append(toolchain.csc_worker_files)

    inputs_depset = depset(
        direct = direct_inputs,
        transitive = [toolchain.ref_pack, analyzers_depset] + transitive_compile_depsets + aspnet_depsets + worker_depsets,
    )

    if toolchain.csc_worker:
        compiler_executable = toolchain.csc_worker
        compiler_args = ["--persistent_worker", args]
        execution_requirements = {
            "requires-worker-protocol": "proto",
            "supports-multiplex-workers": "1",
        }
    else:
        compiler_executable = toolchain.dotnet_muxer
        compiler_args = [toolchain.csc_dll.path.replace("\\", "/"), args]
        execution_requirements = {}

    ctx.actions.run(
        outputs = [out_dll, refout_dll, pdb],
        inputs = inputs_depset,
        executable = compiler_executable,
        arguments = compiler_args,
        mnemonic = "CSharpCompile",
        progress_message = "Compiling C# %{label}",
        use_default_shell_env = False,
        execution_requirements = execution_requirements,
    )

    transitive_compile_refs = depset(
        direct = [refout_dll],
        transitive = transitive_compile_depsets,
        order = "preorder",
    )

    transitive_runtime_dlls = depset(
        direct = [out_dll],
        transitive = [dep[CSharpInfo].transitive_runtime_dlls for dep in direct_deps_and_exports if CSharpInfo in dep],
        order = "preorder",
    )

    transitive_native_libs = depset(
        transitive = [dep[CSharpInfo].transitive_native_libs for dep in direct_deps_and_exports if CSharpInfo in dep],
        order = "preorder",
    )

    csharp_info = CSharpInfo(
        target_framework = getattr(ctx.attr, "target_framework", "") or toolchain.target_framework,
        compile_ref = refout_dll,
        runtime_dll = out_dll,
        pdb = pdb,
        transitive_compile_refs = transitive_compile_refs,
        transitive_runtime_dlls = transitive_runtime_dlls,
        transitive_native_libs = transitive_native_libs,
    )

    default_info = DefaultInfo(
        files = depset([out_dll, refout_dll, pdb]),
        runfiles = ctx.runfiles(
            files = [out_dll, pdb],
            transitive_files = depset(transitive_runtime_dlls.to_list()),
        ),
    )

    providers = [csharp_info, default_info]

    if is_analyzer:
        analyzer_info = CSharpAnalyzerInfo(
            analyzers = depset([out_dll]),
        )
        providers.append(analyzer_info)

    return providers

def _csharp_import_impl(ctx):
    compile_refs = list(ctx.files.compile_refs) if hasattr(ctx.files, "compile_refs") else []
    runtime_dlls = list(ctx.files.runtime_dlls) if hasattr(ctx.files, "runtime_dlls") else []
    dlls = list(ctx.files.dlls) if hasattr(ctx.files, "dlls") else []
    native_libs = list(ctx.files.native_libs) if hasattr(ctx.files, "native_libs") else []
    analyzers = list(ctx.files.analyzers) if hasattr(ctx.files, "analyzers") else []

    if not compile_refs and dlls:
        compile_refs = dlls
    if not runtime_dlls and dlls:
        runtime_dlls = dlls
    if not compile_refs and runtime_dlls:
        compile_refs = runtime_dlls
    if not runtime_dlls and compile_refs:
        runtime_dlls = compile_refs

    direct_deps = list(ctx.attr.deps) + list(getattr(ctx.attr, "exports", []))

    transitive_compile_depsets = []
    if compile_refs:
        transitive_compile_depsets.append(depset(compile_refs, order = "preorder"))

    transitive_runtime_depsets = []
    if runtime_dlls:
        transitive_runtime_depsets.append(depset(runtime_dlls, order = "preorder"))

    transitive_native_depsets = []
    if native_libs:
        transitive_native_depsets.append(depset(native_libs, order = "preorder"))

    analyzer_depsets = []
    if analyzers:
        analyzer_depsets.append(depset(analyzers))

    for plugin in getattr(ctx.attr, "plugins", []):
        if CSharpAnalyzerInfo in plugin:
            analyzer_depsets.append(plugin[CSharpAnalyzerInfo].analyzers)

    for dep in direct_deps:
        if CSharpInfo in dep:
            transitive_compile_depsets.append(dep[CSharpInfo].transitive_compile_refs)
            transitive_runtime_depsets.append(dep[CSharpInfo].transitive_runtime_dlls)
            transitive_native_depsets.append(dep[CSharpInfo].transitive_native_libs)
        if CSharpAnalyzerInfo in dep:
            analyzer_depsets.append(dep[CSharpAnalyzerInfo].analyzers)

    transitive_compile_refs = depset(transitive = transitive_compile_depsets, order = "preorder")
    transitive_runtime_dlls = depset(transitive = transitive_runtime_depsets, order = "preorder")
    transitive_native_libs = depset(transitive = transitive_native_depsets, order = "preorder")
    analyzers_depset = depset(transitive = analyzer_depsets)

    primary_compile_ref = compile_refs[0] if compile_refs else None
    primary_runtime_dll = runtime_dlls[0] if runtime_dlls else None

    csharp_info = CSharpInfo(
        target_framework = getattr(ctx.attr, "target_framework", ""),
        compile_ref = primary_compile_ref,
        runtime_dll = primary_runtime_dll,
        pdb = None,
        transitive_compile_refs = transitive_compile_refs,
        transitive_runtime_dlls = transitive_runtime_dlls,
        transitive_native_libs = transitive_native_libs,
    )

    all_files = list(compile_refs) + list(runtime_dlls) + list(native_libs) + list(analyzers)
    default_info = DefaultInfo(
        files = depset(all_files),
        runfiles = ctx.runfiles(
            files = runtime_dlls + native_libs,
            transitive_files = depset(transitive = [transitive_runtime_dlls, transitive_native_libs]),
        ),
    )

    providers = [csharp_info, default_info]
    if analyzers or getattr(ctx.attr, "plugins", []):
        providers.append(CSharpAnalyzerInfo(analyzers = analyzers_depset))

    return providers

def _csharp_library_impl(ctx):
    if not ctx.files.srcs and (getattr(ctx.files, "compile_refs", []) or getattr(ctx.files, "runtime_dlls", []) or getattr(ctx.files, "dlls", [])):
        return _csharp_import_impl(ctx)
    return _compile_impl(ctx, is_analyzer = False)

def _csharp_analyzer_library_impl(ctx):
    if not ctx.files.srcs:
        dlls = getattr(ctx.files, "dlls", []) or getattr(ctx.files, "analyzers", [])
        return [
            CSharpAnalyzerInfo(analyzers = depset(dlls)),
            DefaultInfo(files = depset(dlls)),
        ]
    return _compile_impl(ctx, is_analyzer = True)

def _csharp_analyzer_import_impl(ctx):
    dlls = list(ctx.files.dlls) + list(ctx.files.analyzers)
    return [
        CSharpAnalyzerInfo(analyzers = depset(dlls)),
        DefaultInfo(files = depset(dlls)),
    ]

_COMMON_ATTRS = {
    "analyzers": attr.label_list(
        allow_files = [".dll"],
        default = [],
        doc = "Precompiled Roslyn analyzer DLL files.",
    ),
    "compile_refs": attr.label_list(
        allow_files = [".dll"],
        default = [],
        doc = "Precompiled reference assembly DLL files.",
    ),
    "defines": attr.string_list(
        default = [],
        doc = "Preprocessor symbols to define during compilation.",
    ),
    "deps": attr.label_list(
        default = [],
        doc = "Direct dependency libraries.",
        providers = [[CSharpInfo]],
    ),
    "dlls": attr.label_list(
        allow_files = [".dll"],
        default = [],
        doc = "Precompiled implementation assembly DLL files.",
    ),
    "exports": attr.label_list(
        default = [],
        doc = "Dependencies exported to downstream consumers.",
        providers = [[CSharpInfo]],
    ),
    "native_libs": attr.label_list(
        allow_files = True,
        default = [],
        doc = "Unmanaged target platform shared libraries.",
    ),
    "nowarn": attr.string_list(
        default = [],
        doc = "Compiler diagnostic codes to suppress.",
    ),
    "plugins": attr.label_list(
        default = [],
        doc = "Roslyn analyzer and generator plugins.",
        providers = [[CSharpAnalyzerInfo]],
    ),
    "resources": attr.label_list(
        allow_files = True,
        default = [],
        doc = "Embedded resource files.",
    ),
    "runtime_dlls": attr.label_list(
        allow_files = [".dll"],
        default = [],
        doc = "Precompiled runtime implementation assembly DLL files.",
    ),
    "sdk": attr.string(
        default = "Microsoft.NET.Sdk",
        doc = "Target .NET SDK project flavor.",
        values = [
            "Microsoft.NET.Sdk",
            "Microsoft.NET.Sdk.Web",
            "Microsoft.NET.Sdk.Worker",
        ],
    ),
    "srcs": attr.label_list(
        allow_files = [".cs"],
        default = [],
        doc = "C# source files to compile.",
    ),
    "target_framework": attr.string(
        default = "",
        doc = "Target framework moniker string.",
    ),
    "target_type": attr.string(
        default = "library",
        doc = "Compiler target type output flag.",
    ),
}

_IMPORT_ATTRS = {
    "analyzers": attr.label_list(
        allow_files = [".dll"],
        default = [],
        doc = "Precompiled Roslyn analyzer DLL files.",
    ),
    "compile_refs": attr.label_list(
        allow_files = [".dll"],
        default = [],
        doc = "Precompiled reference assembly DLL files.",
    ),
    "deps": attr.label_list(
        default = [],
        doc = "Direct dependency libraries.",
        providers = [[CSharpInfo]],
    ),
    "dlls": attr.label_list(
        allow_files = [".dll"],
        default = [],
        doc = "Precompiled implementation assembly DLL files.",
    ),
    "exports": attr.label_list(
        default = [],
        doc = "Dependencies exported to downstream consumers.",
        providers = [[CSharpInfo]],
    ),
    "native_libs": attr.label_list(
        allow_files = True,
        default = [],
        doc = "Unmanaged target platform shared libraries.",
    ),
    "plugins": attr.label_list(
        default = [],
        doc = "Roslyn analyzer and generator plugins.",
        providers = [[CSharpAnalyzerInfo]],
    ),
    "runtime_dlls": attr.label_list(
        allow_files = [".dll"],
        default = [],
        doc = "Precompiled runtime implementation assembly DLL files.",
    ),
    "target_framework": attr.string(
        default = "",
        doc = "Target framework moniker string.",
    ),
}

compile_impl = _compile_impl

csharp_library = rule(
    doc = "Compiles C# source files into reference and implementation assemblies.",
    implementation = _csharp_library_impl,
    attrs = _COMMON_ATTRS,
    toolchains = ["@rules_csharp//csharp:toolchain_type"],
)

csharp_analyzer_library = rule(
    doc = "Compiles Roslyn analyzer or source generator assemblies.",
    implementation = _csharp_analyzer_library_impl,
    attrs = _COMMON_ATTRS,
    toolchains = ["@rules_csharp//csharp:toolchain_type"],
)

csharp_import = rule(
    doc = "Imports precompiled reference and implementation assemblies.",
    implementation = _csharp_import_impl,
    attrs = _IMPORT_ATTRS,
)

csharp_analyzer_import = rule(
    doc = "Imports precompiled Roslyn analyzer and source generator assemblies.",
    implementation = _csharp_analyzer_import_impl,
    attrs = {
        "analyzers": attr.label_list(
            allow_files = [".dll"],
            default = [],
            doc = "Precompiled Roslyn analyzer DLL files.",
        ),
        "dlls": attr.label_list(
            allow_files = [".dll"],
            default = [],
            doc = "Precompiled implementation assembly DLL files.",
        ),
    },
)


