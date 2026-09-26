"""Binary and test rules for rules_csharp."""

load(":compile.bzl", "compile_impl")
load(":providers.bzl", "CSharpAnalyzerInfo", "CSharpInfo", "CSharpToolchainInfo")

def _binary_common_impl(ctx, is_test = False):
    toolchain = ctx.toolchains["@rules_csharp//csharp:toolchain_type"].csharp_info

    # Compile the assembly
    compile_providers = compile_impl(ctx, is_analyzer = False)
    csharp_info = compile_providers[0]
    main_dll = csharp_info.runtime_dll
    pdb = csharp_info.pdb

    #monikers
    tfm = csharp_info.target_framework or "net8.0"
    version_num = tfm.replace("net", "")
    major = version_num.split(".")[0]
    framework_version = major + ".0.0"

    pkg = ctx.label.package
    probing_paths = ['"."']
    if pkg:
        probing_paths.append('"{}"'.format(pkg))
    probing_paths_str = ", ".join(probing_paths)

    # 1. Synthesize <name>.runtimeconfig.json
    runtimeconfig_json = ctx.actions.declare_file(ctx.label.name + ".runtimeconfig.json")
    runtimeconfig_content = """{{
  "runtimeOptions": {{
    "tfm": "{tfm}",
    "rollForward": "LatestMajor",
    "framework": {{
      "name": "Microsoft.NETCore.App",
      "version": "{framework_version}"
    }},
    "additionalProbingPaths": [
      {probing_paths_str}
    ],
    "configProperties": {{
      "System.GC.Server": true,
      "System.Reflection.NullabilityInfoContext.IsSupported": true
    }}
  }}
}}
""".format(
        tfm = tfm,
        framework_version = framework_version,
        probing_paths_str = probing_paths_str,
    )
    ctx.actions.write(
        output = runtimeconfig_json,
        content = runtimeconfig_content,
    )

    # 2. Synthesize <name>.deps.json
    deps_json = ctx.actions.declare_file(ctx.label.name + ".deps.json")

    main_deps = {}
    target_entries = []
    library_entries = []

    seen_dep_names = {ctx.label.name: True}
    for dep_file in csharp_info.transitive_runtime_dlls.to_list():
        if dep_file.basename != main_dll.basename:
            dep_name = dep_file.basename[:-4] if dep_file.basename.endswith(".dll") else dep_file.basename
            if dep_name not in seen_dep_names:
                seen_dep_names[dep_name] = True
                main_deps[dep_name] = "1.0.0"
                target_entries.append("""      "{dep_name}/1.0.0": {{
        "runtime": {{
          "{dll_name}": {{}}
        }}
      }}""".format(dep_name = dep_name, dll_name = dep_file.basename))
                library_entries.append("""    "{dep_name}/1.0.0": {{
      "type": "package",
      "serviceable": false,
      "sha512": "",
      "path": "."
    }}""".format(dep_name = dep_name))

    main_dep_lines = ['          "{}": "{}"'.format(k, v) for k, v in main_deps.items()]
    main_deps_str = ",\n".join(main_dep_lines)

    root_target_entry = """      "{name}/1.0.0": {{
        "dependencies": {{
{main_deps_str}
        }},
        "runtime": {{
          "{dll_name}": {{}}
        }}
      }}""".format(
        name = ctx.label.name,
        dll_name = main_dll.basename,
        main_deps_str = main_deps_str,
    )

    root_library_entry = """    "{name}/1.0.0": {{
      "type": "project",
      "serviceable": false,
      "sha512": ""
    }}""".format(name = ctx.label.name)

    all_target_entries = [root_target_entry] + target_entries
    all_library_entries = [root_library_entry] + library_entries

    deps_content = """{{
  "runtimeTarget": {{
    "name": ".NETCoreApp,Version=v{version_num}"
  }},
  "targets": {{
    ".NETCoreApp,Version=v{version_num}": {{
{targets}
    }}
  }},
  "libraries": {{
{libraries}
  }}
}}
""".format(
        version_num = version_num,
        targets = ",\n".join(all_target_entries),
        libraries = ",\n".join(all_library_entries),
    )
    ctx.actions.write(
        output = deps_json,
        content = deps_content,
    )

    # 3. Stamp target platform's native apphost template binary
    is_windows = "win" in toolchain.target_rid
    exe_file = ctx.actions.declare_file(ctx.label.name + (".exe" if is_windows else ""))

    patcher_info = ctx.attr._patcher[CSharpInfo]
    patcher_dll = patcher_info.runtime_dll
    patcher_runtimeconfig = ctx.file._patcher_runtimeconfig

    ctx.actions.run(
        executable = toolchain.dotnet_muxer,
        inputs = [
            toolchain.host_pack,
            patcher_dll,
            patcher_runtimeconfig,
        ] + toolchain.ref_pack.to_list() + toolchain.runtime_pack.to_list(),
        arguments = [
            patcher_dll.path,
            "--apphost-template=" + toolchain.host_pack.path,
            "--output=" + exe_file.path,
            "--assembly-name=" + main_dll.basename,
        ],
        outputs = [exe_file],
        env = {
            "PATH": "/usr/bin:/bin",
            "DOTNET_ROOT": toolchain.dotnet_muxer.dirname,
        },
        mnemonic = "CSharpAppHostPatch",
        progress_message = "Stamping AppHost %{label}",
        use_default_shell_env = False,
    )

    # 4. Assemble runfiles
    runfiles_files = [
        exe_file,
        main_dll,
        pdb,
        runtimeconfig_json,
        deps_json,
        toolchain.dotnet_muxer,
    ] + toolchain.runtime_pack.to_list()

    pkg = ctx.label.package
    prefix = pkg + "/" if pkg else ""

    runfiles_symlinks = {}
    for f in toolchain.runtime_pack.to_list():
        if "shared/Microsoft.NETCore.App/" in f.path:
            idx = f.path.find("shared/Microsoft.NETCore.App/")
            runfiles_symlinks[prefix + f.path[idx:]] = f
        elif "host/fxr/" in f.path:
            runfiles_symlinks[prefix + f.basename] = f
            idx = f.path.find("host/fxr/")
            runfiles_symlinks[prefix + f.path[idx:]] = f

    for f in csharp_info.transitive_runtime_dlls.to_list():
        runfiles_symlinks[prefix + f.basename] = f

    for f in csharp_info.transitive_native_libs.to_list():
        runfiles_symlinks[prefix + f.basename] = f

    runfiles_symlinks[prefix + runtimeconfig_json.basename] = runtimeconfig_json
    runfiles_symlinks[prefix + deps_json.basename] = deps_json


    runfiles = ctx.runfiles(
        files = runfiles_files,
        symlinks = runfiles_symlinks,
        transitive_files = depset(
            csharp_info.transitive_runtime_dlls.to_list() +
            csharp_info.transitive_native_libs.to_list(),
        ),
    )

    providers = [
        DefaultInfo(
            executable = exe_file,
            files = depset([exe_file, main_dll, pdb, runtimeconfig_json, deps_json]),
            runfiles = runfiles,
        ),
        csharp_info,
    ]

    pack_ws = getattr(toolchain.host_pack.owner, "workspace_name", "") or getattr(toolchain.host_pack.owner, "repo_name", "")
    dotnet_root_rel = "../" + pack_ws if pack_ws else toolchain.dotnet_muxer.dirname

    if is_test:
        providers.append(
            testing.TestEnvironment(
                environment = {
                    "DOTNET_ROOT": dotnet_root_rel,
                },
            ),
        )

    return providers

def _csharp_binary_impl(ctx):
    return _binary_common_impl(ctx, is_test = False)

def _csharp_test_impl(ctx):
    return _binary_common_impl(ctx, is_test = True)

_BINARY_ATTRS = {
    "_patcher": attr.label(
        cfg = "exec",
        default = Label("//csharp/private/tools:apphost_patcher"),
        doc = "Host executable for application host binary patching.",
    ),
    "_patcher_runtimeconfig": attr.label(
        allow_single_file = True,
        cfg = "exec",
        default = Label("//csharp/private/tools:apphost_patcher_runtimeconfig"),
        doc = "Runtime configuration file for patcher executable.",
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
    "exports": attr.label_list(
        default = [],
        doc = "Dependencies exported to downstream consumers.",
        providers = [[CSharpInfo]],
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
        default = "exe",
        doc = "Compiler target type output flag.",
    ),
}

csharp_binary = rule(
    doc = "Compiles a C# executable and stamps the native application host binary.",
    implementation = _csharp_binary_impl,
    attrs = _BINARY_ATTRS,
    executable = True,
    toolchains = ["@rules_csharp//csharp:toolchain_type"],
)

csharp_test = rule(
    doc = "Compiles and executes a C# test binary under the Bazel test harness.",
    implementation = _csharp_test_impl,
    attrs = _BINARY_ATTRS,
    executable = True,
    test = True,
    toolchains = ["@rules_csharp//csharp:toolchain_type"],
)

