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

    args.add("-target:library")
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
    if toolchain.csc_worker:
        direct_inputs.append(toolchain.csc_worker)

    inputs_depset = depset(
        direct = direct_inputs,
        transitive = [toolchain.ref_pack, analyzers_depset] + transitive_compile_depsets,
    )

    execution_requirements = {}
    if toolchain.csc_worker:
        execution_requirements = {
            "supports-multiplex-workers": "1",
            "requires-worker-protocol": "proto",
        }

    ctx.actions.run(
        outputs = [out_dll, refout_dll, pdb],
        inputs = inputs_depset,
        executable = toolchain.dotnet_muxer,
        arguments = [toolchain.csc_dll.path.replace("\\", "/"), args],
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

def _csharp_library_impl(ctx):
    return _compile_impl(ctx, is_analyzer = False)

def _csharp_analyzer_library_impl(ctx):
    return _compile_impl(ctx, is_analyzer = True)

_COMMON_ATTRS = {
    "srcs": attr.label_list(allow_files = [".cs"], default = []),
    "deps": attr.label_list(providers = [[CSharpInfo]], default = []),
    "exports": attr.label_list(providers = [[CSharpInfo]], default = []),
    "plugins": attr.label_list(providers = [[CSharpAnalyzerInfo]], default = []),
    "resources": attr.label_list(allow_files = True, default = []),
    "target_framework": attr.string(default = ""),
    "defines": attr.string_list(default = []),
    "nowarn": attr.string_list(default = []),
}

csharp_library = rule(
    implementation = _csharp_library_impl,
    attrs = _COMMON_ATTRS,
    toolchains = ["@rules_csharp//csharp:toolchain_type"],
)

csharp_analyzer_library = rule(
    implementation = _csharp_analyzer_library_impl,
    attrs = _COMMON_ATTRS,
    toolchains = ["@rules_csharp//csharp:toolchain_type"],
)
