"""C# toolchain rule implementation."""

load(":providers.bzl", "CSharpToolchainInfo")

def _csharp_toolchain_impl(ctx):
    ref_files = []
    if ctx.attr.ref_pack:
        ref_files = ctx.files.ref_pack

    runtime_files = []
    if ctx.attr.runtime_pack:
        runtime_files = ctx.files.runtime_pack

    toolchain_info = CSharpToolchainInfo(
        dotnet_muxer = ctx.file.dotnet_muxer,
        csc_dll = ctx.file.csc_dll,
        csc_worker = ctx.executable.csc_worker if ctx.attr.csc_worker else None,
        ref_pack = depset(ref_files),
        host_pack = ctx.file.host_pack,
        runtime_pack = depset(runtime_files),
        target_framework = ctx.attr.target_framework,
        target_rid = ctx.attr.target_rid,
        host_rid = ctx.attr.host_rid,
    )

    return [
        platform_common.ToolchainInfo(
            csharp_info = toolchain_info,
            csharp = toolchain_info,
            toolchain_info = toolchain_info,
        ),
        toolchain_info,
    ]

csharp_toolchain = rule(
    implementation = _csharp_toolchain_impl,
    attrs = {
        "dotnet_muxer": attr.label(allow_single_file = True, mandatory = True, cfg = "exec"),
        "csc_dll": attr.label(allow_single_file = True, mandatory = True, cfg = "exec"),
        "csc_worker": attr.label(executable = True, allow_single_file = True, cfg = "exec"),
        "ref_pack": attr.label_list(allow_files = True, cfg = "target"),
        "host_pack": attr.label(allow_single_file = True, cfg = "target"),
        "runtime_pack": attr.label_list(allow_files = True, cfg = "target"),
        "target_framework": attr.string(mandatory = True),
        "target_rid": attr.string(mandatory = True),
        "host_rid": attr.string(mandatory = True),
    },
)
