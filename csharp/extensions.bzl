"""Module extensions for rules_csharp."""

load("//csharp:toolchains.bzl", "PLATFORMS", "csharp_toolchains_hub", "runtime_pack", "sdk_exec")
load("//csharp/private:nuget_repo.bzl", "nuget_hub_repo", "nuget_package_repo")

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

from_lock_tag = tag_class(
    attrs = {
        "name": attr.string(default = "nuget"),
        "packages_lock_json": attr.label(mandatory = True),
        "directory_packages_props": attr.label(default = None),
    },
)

def _sanitize_name(name):
    return name.replace(".", "_").replace("-", "_").lower()

def _nuget_impl(module_ctx):
    packages = {}
    hub_name = "nuget"

    for mod in module_ctx.modules:
        for tag in mod.tags.from_lock:
            if tag.name:
                hub_name = tag.name

            content = module_ctx.read(tag.packages_lock_json)
            data = json.decode(content)

            dependencies = data.get("dependencies", {})
            for _framework, fw_pkgs in dependencies.items():
                for pkg_id, pkg_info in fw_pkgs.items():
                    resolved = pkg_info.get("resolved", "")
                    content_hash = pkg_info.get("contentHash", "")
                    dep_dict = pkg_info.get("dependencies", {})

                    if pkg_id not in packages:
                        packages[pkg_id] = {
                            "version": resolved,
                            "content_hash": content_hash,
                            "dependencies": list(dep_dict.keys()),
                        }
                    else:
                        existing_deps = packages[pkg_id]["dependencies"]
                        for d in dep_dict.keys():
                            if d not in existing_deps:
                                existing_deps.append(d)

    hub_packages = {}
    for pkg_id, info in packages.items():
        repo_name = "nuget_" + _sanitize_name(pkg_id)
        hub_packages[pkg_id] = repo_name
        nuget_package_repo(
            name = repo_name,
            package_id = pkg_id,
            version = info["version"],
            content_hash = info["content_hash"],
            dependencies = info["dependencies"],
        )

    nuget_hub_repo(
        name = hub_name,
        packages = hub_packages,
    )

nuget = module_extension(
    implementation = _nuget_impl,
    tag_classes = {
        "from_lock": from_lock_tag,
    },
)
