"""Toolchain definitions and repository rules for rules_csharp."""

load(
    "@bazel_tools//tools/build_defs/repo:utils.bzl",
    "read_netrc",
    "read_user_netrc",
    "use_netrc",
)

PLATFORMS = {
    "darwin_arm64": {
        "apphost_name": "apphost",
        "archive_ext": "tar.gz",
        "cpu": "@platforms//cpu:aarch64",
        "os": "@platforms//os:osx",
        "rid": "osx-arm64",
    },
    "linux_arm64": {
        "apphost_name": "apphost",
        "archive_ext": "tar.gz",
        "cpu": "@platforms//cpu:aarch64",
        "os": "@platforms//os:linux",
        "rid": "linux-arm64",
    },
    "linux_x86_64": {
        "apphost_name": "apphost",
        "archive_ext": "tar.gz",
        "cpu": "@platforms//cpu:x86_64",
        "os": "@platforms//os:linux",
        "rid": "linux-x64",
    },
    "windows_x86_64": {
        "apphost_name": "apphost.exe",
        "archive_ext": "zip",
        "cpu": "@platforms//cpu:x86_64",
        "os": "@platforms//os:windows",
        "rid": "win-x64",
    },
}

def version_to_tfm(version):
    """Derives target framework moniker from SDK version."""
    major = version.split(".")[0]
    return "net" + major + ".0"

def _resolve_netrc_auth(repository_ctx, urls):
    if repository_ctx.attr.netrc:
        netrc_data = read_netrc(repository_ctx, repository_ctx.attr.netrc)
    elif "NETRC" in repository_ctx.os.environ:
        netrc_data = read_netrc(repository_ctx, repository_ctx.os.environ["NETRC"])
    else:
        netrc_data = read_user_netrc(repository_ctx)
    auth_patterns = repository_ctx.attr.auth_patterns if hasattr(repository_ctx.attr, "auth_patterns") else {}
    return use_netrc(netrc_data, urls, auth_patterns)

def _sdk_exec_impl(repository_ctx):
    version = repository_ctx.attr.dotnet_version
    rid = repository_ctx.attr.rid
    ext = repository_ctx.attr.archive_ext
    archive = "dotnet-sdk-{}-{}.{}".format(version, rid, ext)

    urls = list(repository_ctx.attr.urls)
    if not urls:
        urls = ["https://dotnetcli.azureedge.net/dotnet/Sdk/{}/{}".format(version, archive)]

    auth = _resolve_netrc_auth(repository_ctx, urls)
    type_ext = "zip" if ext == "zip" else "tar.gz"

    repository_ctx.download_and_extract(
        url = urls,
        sha256 = repository_ctx.attr.sha256 if repository_ctx.attr.sha256 else "",
        auth = auth,
        type = type_ext,
    )

    is_windows = "win" in rid
    dotnet_bin = "dotnet.exe" if is_windows else "dotnet"

    build_content = """package(default_visibility = ["//visibility:public"])

exports_files(["{dotnet_bin}"])

filegroup(
    name = "dotnet_muxer",
    srcs = ["{dotnet_bin}"],
)

filegroup(
    name = "csc_dll",
    srcs = glob(["sdk/*/Roslyn/bincore/csc.dll"]),
)

filegroup(
    name = "sdk_files",
    srcs = glob(["**/*"]),
)
""".format(dotnet_bin = dotnet_bin)

    repository_ctx.file("BUILD.bazel", build_content)

sdk_exec = repository_rule(
    doc = "Downloads and extracts host .NET SDK binaries.",
    implementation = _sdk_exec_impl,
    attrs = {
        "archive_ext": attr.string(
            default = "tar.gz",
            doc = "Archive file extension string.",
        ),
        "auth_patterns": attr.string_dict(
            doc = "Host to authentication pattern mappings.",
        ),
        "dotnet_version": attr.string(
            doc = ".NET SDK version string.",
            mandatory = True,
        ),
        "netrc": attr.label(
            doc = "Authentication netrc configuration file label.",
        ),
        "platform": attr.string(
            doc = "Platform moniker string.",
            mandatory = True,
        ),
        "rid": attr.string(
            doc = "Runtime identifier string.",
            mandatory = True,
        ),
        "sha256": attr.string(
            doc = "Expected SHA-256 integrity hash string.",
        ),
        "urls": attr.string_list(
            doc = "Ordered candidate download URL list.",
        ),
    },
)

def _runtime_pack_impl(repository_ctx):
    version = repository_ctx.attr.dotnet_version
    rid = repository_ctx.attr.rid
    ext = repository_ctx.attr.archive_ext
    archive = "dotnet-sdk-{}-{}.{}".format(version, rid, ext)

    urls = list(repository_ctx.attr.urls)
    if not urls:
        urls = ["https://dotnetcli.azureedge.net/dotnet/Sdk/{}/{}".format(version, archive)]

    auth = _resolve_netrc_auth(repository_ctx, urls)
    type_ext = "zip" if ext == "zip" else "tar.gz"

    repository_ctx.download_and_extract(
        url = urls,
        sha256 = repository_ctx.attr.sha256 if repository_ctx.attr.sha256 else "",
        auth = auth,
        type = type_ext,
    )

    is_windows = "win" in rid
    apphost_name = "apphost.exe" if is_windows else "apphost"

    build_content = """package(default_visibility = ["//visibility:public"])

filegroup(
    name = "ref_pack",
    srcs = glob(["packs/Microsoft.NETCore.App.Ref/*/ref/*/*.dll"]),
)

filegroup(
    name = "host_pack",
    srcs = glob(["packs/Microsoft.NETCore.App.Host.{rid}/*/runtimes/{rid}/native/{apphost_name}"], allow_empty = True),
)

filegroup(
    name = "runtime_pack",
    srcs = glob([
        "shared/Microsoft.NETCore.App/**",
        "host/fxr/**",
    ], allow_empty = True),
)

filegroup(
    name = "all_files",
    srcs = glob(["**/*"]),
)
""".format(apphost_name = apphost_name, rid = rid)

    repository_ctx.file("BUILD.bazel", build_content)

runtime_pack = repository_rule(
    doc = "Downloads and extracts target platform reference and runtime packs.",
    implementation = _runtime_pack_impl,
    attrs = {
        "archive_ext": attr.string(
            default = "tar.gz",
            doc = "Archive file extension string.",
        ),
        "auth_patterns": attr.string_dict(
            doc = "Host to authentication pattern mappings.",
        ),
        "dotnet_version": attr.string(
            doc = ".NET SDK version string.",
            mandatory = True,
        ),
        "netrc": attr.label(
            doc = "Authentication netrc configuration file label.",
        ),
        "platform": attr.string(
            doc = "Platform moniker string.",
            mandatory = True,
        ),
        "rid": attr.string(
            doc = "Runtime identifier string.",
            mandatory = True,
        ),
        "sha256": attr.string(
            doc = "Expected SHA-256 integrity hash string.",
        ),
        "urls": attr.string_list(
            doc = "Ordered candidate download URL list.",
        ),
    },
)

def _csharp_toolchains_hub_impl(repository_ctx):
    lines = [
        "load(\"@rules_csharp//csharp/private:toolchain_impl.bzl\", \"csharp_toolchain\")",
        "package(default_visibility = [\"//visibility:public\"])",
        "",
    ]

    for version in repository_ctx.attr.dotnet_versions:
        v_slug = version.replace(".", "_")
        tfm = version_to_tfm(version)

        for exec_p, exec_info in PLATFORMS.items():
            for target_p, target_info in PLATFORMS.items():
                impl_name = "csharp_toolchain_{}_{}_{}".format(v_slug, exec_p, target_p)
                tc_name = "toolchain_{}_{}_{}".format(v_slug, exec_p, target_p)

                lines.append("""csharp_toolchain(
    name = "{impl_name}",
    dotnet_muxer = "@dotnet_sdk_{v_slug}_{exec_p}//:dotnet_muxer",
    csc_dll = "@dotnet_sdk_{v_slug}_{exec_p}//:csc_dll",
    ref_pack = ["@csharp_pack_{v_slug}_{target_p}//:ref_pack"],
    host_pack = "@csharp_pack_{v_slug}_{target_p}//:host_pack",
    runtime_pack = ["@csharp_pack_{v_slug}_{target_p}//:runtime_pack"],
    target_framework = "{tfm}",
    target_rid = "{target_rid}",
    host_rid = "{host_rid}",
)

toolchain(
    name = "{tc_name}",
    toolchain_type = "@rules_csharp//csharp:toolchain_type",
    toolchain = ":{impl_name}",
    exec_compatible_with = [
        "{exec_os}",
        "{exec_cpu}",
    ],
    target_compatible_with = [
        "{target_os}",
        "{target_cpu}",
    ],
)
""".format(
                    exec_cpu = exec_info["cpu"],
                    exec_os = exec_info["os"],
                    exec_p = exec_p,
                    host_rid = exec_info["rid"],
                    impl_name = impl_name,
                    target_cpu = target_info["cpu"],
                    target_os = target_info["os"],
                    target_p = target_p,
                    target_rid = target_info["rid"],
                    tc_name = tc_name,
                    tfm = tfm,
                    v_slug = v_slug,
                ))

    repository_ctx.file("BUILD.bazel", "\n".join(lines))

csharp_toolchains_hub = repository_rule(
    doc = "Generates toolchain target declarations for all platform combinations.",
    implementation = _csharp_toolchains_hub_impl,
    attrs = {
        "dotnet_versions": attr.string_list(
            default = ["8.0.403", "9.0.200", "10.0.100"],
            doc = "Supported .NET SDK version strings.",
        ),
    },
)
