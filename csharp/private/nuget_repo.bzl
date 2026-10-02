"""Repository rules for NuGet packages and NuGet hub."""

TFM_PRECEDENCE = [
    "net10.0",
    "net9.0",
    "net8.0",
    "net7.0",
    "net6.0",
    "netstandard2.1",
    "netstandard2.0",
    "net5.0",
    "netcoreapp3.1",
    "netcoreapp3.0",
    "netstandard1.6",
    "netstandard1.5",
    "netstandard1.4",
    "netstandard1.3",
    "netstandard1.2",
    "netstandard1.1",
    "netstandard1.0",
    "net48",
    "net472",
    "net471",
    "net47",
    "net462",
    "net461",
    "net452",
    "net451",
    "net45",
    "net40",
]

SUPPORTED_RIDS = {
    "osx-arm64": "@rules_csharp//csharp/constraints:osx_arm64",
    "linux-x64": "@rules_csharp//csharp/constraints:linux_x64",
    "linux-arm64": "@rules_csharp//csharp/constraints:linux_arm64",
    "win-x64": "@rules_csharp//csharp/constraints:win_x64",
}

def _has_dlls(path):
    if not path.exists or not path.is_dir:
        return False
    for child in path.readdir():
        if not child.is_dir and child.basename.lower().endswith(".dll"):
            return True
    return False

def _has_files(path):
    if not path.exists or not path.is_dir:
        return False
    for child in path.readdir():
        if not child.is_dir:
            return True
    return False

def _has_dlls_iterative(path):
    if not path.exists:
        return False
    if not path.is_dir:
        return path.basename.lower().endswith(".dll")
    stack = [path]
    for _ in range(100):
        if not stack:
            break
        curr = stack.pop()
        for child in curr.readdir():
            if not child.is_dir and child.basename.lower().endswith(".dll"):
                return True
            if child.is_dir:
                stack.append(child)
    return False

def _find_best_tfm_dir(repository_ctx, base_rel):
    base_path = repository_ctx.path(base_rel)
    if not base_path.exists or not base_path.is_dir:
        return None

    for tfm in TFM_PRECEDENCE:
        child = base_path.get_child(tfm)
        if _has_dlls(child):
            return base_rel + "/" + tfm

    for child in base_path.readdir():
        if _has_dlls(child):
            return base_rel + "/" + child.basename

    return None

def _find_analyzer_dir(repository_ctx):
    analyzers_path = repository_ctx.path("analyzers")
    if not analyzers_path.exists or not analyzers_path.is_dir:
        return None

    # 1. Direct analyzers/dotnet/cs
    direct_cs = repository_ctx.path("analyzers/dotnet/cs")
    if direct_cs.exists and direct_cs.is_dir and _has_dlls_iterative(direct_cs):
        return "analyzers/dotnet/cs"

    # 2. Roslyn versioned: analyzers/roslynX.Y/dotnet/cs
    roslyn_dirs = []
    for child in analyzers_path.readdir():
        if child.is_dir and child.basename.startswith("roslyn"):
            cs_path = child.get_child("dotnet").get_child("cs")
            if cs_path.exists and cs_path.is_dir and _has_dlls_iterative(cs_path):
                roslyn_dirs.append(child.basename)

    if roslyn_dirs:
        sorted_dirs = sorted(roslyn_dirs)
        highest = sorted_dirs[-1]
        return "analyzers/" + highest + "/dotnet/cs"

    # 3. Any subdirectory of analyzers containing dotnet/cs
    for child in analyzers_path.readdir():
        if child.is_dir:
            cs_path = child.get_child("dotnet").get_child("cs")
            if cs_path.exists and cs_path.is_dir and _has_dlls_iterative(cs_path):
                return "analyzers/" + child.basename + "/dotnet/cs"

    # 4. Any dlls anywhere in analyzers
    if _has_dlls_iterative(analyzers_path):
        return "analyzers"

    return None


def _sanitize_name(name):
    return name.replace(".", "_").replace("-", "_").lower()

def _nuget_package_repo_impl(repository_ctx):
    pkg_id = repository_ctx.attr.package_id
    version = repository_ctx.attr.version
    content_hash = repository_ctx.attr.content_hash

    id_lower = pkg_id.lower()
    ver_lower = version.lower()

    url = "https://api.nuget.org/v3-flatcontainer/{}/{}/{}.{}.nupkg".format(
        id_lower,
        ver_lower,
        id_lower,
        ver_lower,
    )

    integrity = "sha512-" + content_hash if content_hash else ""
    repository_ctx.download_and_extract(
        url = url,
        type = "zip",
        integrity = integrity,
    )

    # 1. Compile references: ref/<tfm>/ falling back to lib/<tfm>/
    compile_dir = _find_best_tfm_dir(repository_ctx, "ref")
    if not compile_dir:
        compile_dir = _find_best_tfm_dir(repository_ctx, "lib")

    # 2. Default runtime assemblies: lib/<tfm>/
    default_runtime_dir = _find_best_tfm_dir(repository_ctx, "lib")
    if not default_runtime_dir and compile_dir:
        default_runtime_dir = compile_dir

    # 3. RID-specific runtime assemblies: runtimes/<rid>/lib/<tfm>/
    rid_lib_dirs = {}
    for rid in SUPPORTED_RIDS.keys():
        r_dir = _find_best_tfm_dir(repository_ctx, "runtimes/" + rid + "/lib")
        if r_dir:
            rid_lib_dirs[rid] = r_dir

    # 4. Native libraries: runtimes/<rid>/native/
    rid_native_dirs = {}
    for rid in SUPPORTED_RIDS.keys():
        n_path = repository_ctx.path("runtimes/" + rid + "/native")
        if _has_files(n_path):
            rid_native_dirs[rid] = "runtimes/" + rid + "/native/*"

    # 5. Analyzers
    analyzer_dir = _find_analyzer_dir(repository_ctx)

    # Build file generation
    lines = [
        '"""Generated BUILD.bazel for NuGet package: {}"""'.format(pkg_id),
        'load("@rules_csharp//csharp:defs.bzl", "csharp_import", "csharp_analyzer_library")',
        'package(default_visibility = ["//visibility:public"])',
        '',
    ]

    has_analyzers = bool(analyzer_dir)
    if has_analyzers:
        lines.append('csharp_analyzer_library(')
        lines.append('    name = "analyzers",')
        lines.append('    dlls = glob(["{}/**/*.dll", "{}/*.dll"]),'.format(analyzer_dir, analyzer_dir))
        lines.append(')')
        lines.append('')

    # Dependencies mapping
    dep_labels = []
    for dep in repository_ctx.attr.dependencies:
        dep_labels.append('"@nuget_{}//:{}"'.format(_sanitize_name(dep), dep))

    # Compile refs expression
    if compile_dir:
        compile_refs_expr = 'glob(["{}/*.dll"])'.format(compile_dir)
    else:
        compile_refs_expr = '[]'

    # Runtime dlls expression
    if rid_lib_dirs:
        select_cases = []
        for rid, constraint in SUPPORTED_RIDS.items():
            if rid in rid_lib_dirs:
                select_cases.append('        "{}": glob(["{}/*.dll"]),'.format(constraint, rid_lib_dirs[rid]))
            elif default_runtime_dir:
                select_cases.append('        "{}": glob(["{}/*.dll"]),'.format(constraint, default_runtime_dir))
            else:
                select_cases.append('        "{}": [],'.format(constraint))
        if default_runtime_dir:
            select_cases.append('        "//conditions:default": glob(["{}/*.dll"]),'.format(default_runtime_dir))
        else:
            select_cases.append('        "//conditions:default": [],')

        runtime_dlls_expr = 'select({\n' + '\n'.join(select_cases) + '\n    })'
    elif default_runtime_dir:
        runtime_dlls_expr = 'glob(["{}/*.dll"])'.format(default_runtime_dir)
    else:
        runtime_dlls_expr = '[]'

    # Native libs expression
    if rid_native_dirs:
        select_cases = []
        for rid, constraint in SUPPORTED_RIDS.items():
            if rid in rid_native_dirs:
                select_cases.append('        "{}": glob(["{}"]),'.format(constraint, rid_native_dirs[rid]))
            else:
                select_cases.append('        "{}": [],'.format(constraint))
        select_cases.append('        "//conditions:default": [],')
        native_libs_expr = 'select({\n' + '\n'.join(select_cases) + '\n    })'
    else:
        native_libs_expr = '[]'

    plugins_expr = '[":analyzers"]' if has_analyzers else '[]'
    deps_expr = '[\n        ' + ',\n        '.join(dep_labels) + '\n    ]' if dep_labels else '[]'

    lines.append('csharp_import(')
    lines.append('    name = "{}",'.format(pkg_id))
    lines.append('    compile_refs = {},'.format(compile_refs_expr))
    lines.append('    runtime_dlls = {},'.format(runtime_dlls_expr))
    lines.append('    native_libs = {},'.format(native_libs_expr))
    lines.append('    deps = {},'.format(deps_expr))
    lines.append('    plugins = {},'.format(plugins_expr))
    lines.append(')')
    lines.append('')

    # Aliases
    lines.append('alias(')
    lines.append('    name = "pkg",')
    lines.append('    actual = ":{}",'.format(pkg_id))
    lines.append(')')
    lines.append('')

    if pkg_id.lower() != pkg_id:
        lines.append('alias(')
        lines.append('    name = "{}",'.format(pkg_id.lower()))
        lines.append('    actual = ":{}",'.format(pkg_id))
        lines.append(')')
        lines.append('')

    repository_ctx.file("BUILD.bazel", "\n".join(lines) + "\n")

nuget_package_repo = repository_rule(
    implementation = _nuget_package_repo_impl,
    attrs = {
        "package_id": attr.string(mandatory = True),
        "version": attr.string(mandatory = True),
        "content_hash": attr.string(default = ""),
        "dependencies": attr.string_list(default = []),
    },
)

def _nuget_hub_repo_impl(repository_ctx):
    packages = repository_ctx.attr.packages
    lines = [
        '"""Generated hub BUILD.bazel for NuGet packages"""',
        'package(default_visibility = ["//visibility:public"])',
        '',
    ]

    for pkg_id, repo_name in packages.items():
        lines.append('alias(')
        lines.append('    name = "{}",'.format(pkg_id))
        lines.append('    actual = "@{}//:{}",'.format(repo_name, pkg_id))
        lines.append(')')
        lines.append('')

        if pkg_id.lower() != pkg_id:
            lines.append('alias(')
            lines.append('    name = "{}",'.format(pkg_id.lower()))
            lines.append('    actual = "@{}//:{}",'.format(repo_name, pkg_id))
            lines.append(')')
            lines.append('')

        sanitized = _sanitize_name(pkg_id)
        if sanitized != pkg_id and sanitized != pkg_id.lower():
            lines.append('alias(')
            lines.append('    name = "{}",'.format(sanitized))
            lines.append('    actual = "@{}//:{}",'.format(repo_name, pkg_id))
            lines.append(')')
            lines.append('')

    repository_ctx.file("BUILD.bazel", "\n".join(lines) + "\n")

nuget_hub_repo = repository_rule(
    implementation = _nuget_hub_repo_impl,
    attrs = {
        "packages": attr.string_dict(default = {}),
    },
)
