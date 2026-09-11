"""Toolchain definitions and repository rules for rules_csharp."""

PLATFORMS = {
    "darwin_arm64": {
        "rid": "osx-arm64",
        "archive_ext": "tar.gz",
        "os": "@platforms//os:osx",
        "cpu": "@platforms//cpu:aarch64",
        "apphost_name": "apphost",
    },
    "linux_x86_64": {
        "rid": "linux-x64",
        "archive_ext": "tar.gz",
        "os": "@platforms//os:linux",
        "cpu": "@platforms//cpu:x86_64",
        "apphost_name": "apphost",
    },
    "linux_arm64": {
        "rid": "linux-arm64",
        "archive_ext": "tar.gz",
        "os": "@platforms//os:linux",
        "cpu": "@platforms//cpu:aarch64",
        "apphost_name": "apphost",
    },
    "windows_x86_64": {
        "rid": "win-x64",
        "archive_ext": "zip",
        "os": "@platforms//os:windows",
        "cpu": "@platforms//cpu:x86_64",
        "apphost_name": "apphost.exe",
    },
}

def version_to_tfm(version):
    major = version.split(".")[0]
    return "net" + major + ".0"

def _sdk_exec_impl(repository_ctx):
    version = repository_ctx.attr.dotnet_version
    rid = repository_ctx.attr.rid
    ext = repository_ctx.attr.archive_ext
    url = "https://dotnetcli.azureedge.net/dotnet/Sdk/{}/dotnet-sdk-{}-{}.{}".format(version, version, rid, ext)

    repository_ctx.download_and_extract(
        url = url,
        sha256 = repository_ctx.attr.sha256 if repository_ctx.attr.sha256 else "",
    )

    is_windows = "win" in rid
    dotnet_bin = "dotnet.exe" if is_windows else "dotnet"

    build_content = """package(default_visibility = ["//visibility:public"])

exports_files(["{dotnet_bin}"])

filegroup(
    name = "dotnet",
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
    implementation = _sdk_exec_impl,
    attrs = {
        "dotnet_version": attr.string(mandatory = True),
        "platform": attr.string(mandatory = True),
        "rid": attr.string(mandatory = True),
        "archive_ext": attr.string(default = "tar.gz"),
        "sha256": attr.string(),
    },
)

def _runtime_pack_impl(repository_ctx):
    version = repository_ctx.attr.dotnet_version
    rid = repository_ctx.attr.rid
    ext = repository_ctx.attr.archive_ext
    url = "https://dotnetcli.azureedge.net/dotnet/Sdk/{}/dotnet-sdk-{}-{}.{}".format(version, version, rid, ext)

    repository_ctx.download_and_extract(
        url = url,
        sha256 = repository_ctx.attr.sha256 if repository_ctx.attr.sha256 else "",
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
        "shared/Microsoft.NETCore.App/*/*.dll",
        "shared/Microsoft.NETCore.App/*/*.dylib",
        "shared/Microsoft.NETCore.App/*/*.so",
    ], allow_empty = True),
)

filegroup(
    name = "all_files",
    srcs = glob(["**/*"]),
)
""".format(rid = rid, apphost_name = apphost_name)

    repository_ctx.file("BUILD.bazel", build_content)

runtime_pack = repository_rule(
    implementation = _runtime_pack_impl,
    attrs = {
        "dotnet_version": attr.string(mandatory = True),
        "platform": attr.string(mandatory = True),
        "rid": attr.string(mandatory = True),
        "archive_ext": attr.string(default = "tar.gz"),
        "sha256": attr.string(),
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
    dotnet_muxer = "@dotnet_sdk_{v_slug}_{exec_p}//:dotnet",
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
                    impl_name = impl_name,
                    tc_name = tc_name,
                    v_slug = v_slug,
                    exec_p = exec_p,
                    target_p = target_p,
                    tfm = tfm,
                    target_rid = target_info["rid"],
                    host_rid = exec_info["rid"],
                    exec_os = exec_info["os"],
                    exec_cpu = exec_info["cpu"],
                    target_os = target_info["os"],
                    target_cpu = target_info["cpu"],
                ))

    repository_ctx.file("BUILD.bazel", "\n".join(lines))

csharp_toolchains_hub = repository_rule(
    implementation = _csharp_toolchains_hub_impl,
    attrs = {
        "dotnet_versions": attr.string_list(default = ["8.0.403", "9.0.200", "10.0.100"]),
    },
)
