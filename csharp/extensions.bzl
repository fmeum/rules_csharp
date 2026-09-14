"""Module extensions for rules_csharp."""

load("//csharp:toolchains.bzl", "PLATFORMS", "csharp_toolchains_hub", "runtime_pack", "sdk_exec")

toolchain_tag = tag_class(
    attrs = {
        "dotnet_versions": attr.string_list(default = ["8.0.403", "9.0.200", "10.0.100"]),
    },
)

def _csharp_impl(module_ctx):
    dotnet_versions = ["8.0.403", "9.0.200", "10.0.100"]

    for mod in module_ctx.modules:
        for tag in mod.tags.toolchain:
            if tag.dotnet_versions:
                dotnet_versions = tag.dotnet_versions

    for version in dotnet_versions:
        v_slug = version.replace(".", "_")
        for p_name, p_info in PLATFORMS.items():
            sdk_name = "dotnet_sdk_{}_{}".format(v_slug, p_name)
            sdk_exec(
                name = sdk_name,
                dotnet_version = version,
                platform = p_name,
                rid = p_info["rid"],
                archive_ext = p_info["archive_ext"],
            )

            pack_name = "csharp_pack_{}_{}".format(v_slug, p_name)
            runtime_pack(
                name = pack_name,
                dotnet_version = version,
                platform = p_name,
                rid = p_info["rid"],
                archive_ext = p_info["archive_ext"],
            )

    csharp_toolchains_hub(
        name = "csharp_toolchains",
        dotnet_versions = dotnet_versions,
    )

csharp = module_extension(
    implementation = _csharp_impl,
    tag_classes = {
        "toolchain": toolchain_tag,
    },
)
