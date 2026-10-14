<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public API for rules_csharp.

<a id="csharp_analyzer_import"></a>

## csharp_analyzer_import

<pre>
load("@rules_csharp//csharp:defs.bzl", "csharp_analyzer_import")

csharp_analyzer_import(<a href="#csharp_analyzer_import-name">name</a>, <a href="#csharp_analyzer_import-analyzers">analyzers</a>, <a href="#csharp_analyzer_import-dlls">dlls</a>)
</pre>

Imports precompiled Roslyn analyzer and source generator assemblies.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="csharp_analyzer_import-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="csharp_analyzer_import-analyzers"></a>analyzers |  Precompiled Roslyn analyzer DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_analyzer_import-dlls"></a>dlls |  Precompiled implementation assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |


<a id="csharp_analyzer_library"></a>

## csharp_analyzer_library

<pre>
load("@rules_csharp//csharp:defs.bzl", "csharp_analyzer_library")

csharp_analyzer_library(<a href="#csharp_analyzer_library-name">name</a>, <a href="#csharp_analyzer_library-deps">deps</a>, <a href="#csharp_analyzer_library-srcs">srcs</a>, <a href="#csharp_analyzer_library-resources">resources</a>, <a href="#csharp_analyzer_library-analyzers">analyzers</a>, <a href="#csharp_analyzer_library-compile_refs">compile_refs</a>, <a href="#csharp_analyzer_library-defines">defines</a>, <a href="#csharp_analyzer_library-dlls">dlls</a>,
                        <a href="#csharp_analyzer_library-exports">exports</a>, <a href="#csharp_analyzer_library-native_libs">native_libs</a>, <a href="#csharp_analyzer_library-nowarn">nowarn</a>, <a href="#csharp_analyzer_library-plugins">plugins</a>, <a href="#csharp_analyzer_library-runtime_dlls">runtime_dlls</a>, <a href="#csharp_analyzer_library-target_framework">target_framework</a>,
                        <a href="#csharp_analyzer_library-target_type">target_type</a>)
</pre>

Compiles Roslyn analyzer or source generator assemblies.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="csharp_analyzer_library-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="csharp_analyzer_library-deps"></a>deps |  Direct dependency libraries.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_analyzer_library-srcs"></a>srcs |  C# source files to compile.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_analyzer_library-resources"></a>resources |  Embedded resource files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_analyzer_library-analyzers"></a>analyzers |  Precompiled Roslyn analyzer DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_analyzer_library-compile_refs"></a>compile_refs |  Precompiled reference assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_analyzer_library-defines"></a>defines |  Preprocessor symbols to define during compilation.   | List of strings | optional |  `[]`  |
| <a id="csharp_analyzer_library-dlls"></a>dlls |  Precompiled implementation assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_analyzer_library-exports"></a>exports |  Dependencies exported to downstream consumers.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_analyzer_library-native_libs"></a>native_libs |  Unmanaged target platform shared libraries.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_analyzer_library-nowarn"></a>nowarn |  Compiler diagnostic codes to suppress.   | List of strings | optional |  `[]`  |
| <a id="csharp_analyzer_library-plugins"></a>plugins |  Roslyn analyzer and generator plugins.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_analyzer_library-runtime_dlls"></a>runtime_dlls |  Precompiled runtime implementation assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_analyzer_library-target_framework"></a>target_framework |  Target framework moniker string.   | String | optional |  `""`  |
| <a id="csharp_analyzer_library-target_type"></a>target_type |  Compiler target type output flag.   | String | optional |  `"library"`  |


<a id="csharp_binary"></a>

## csharp_binary

<pre>
load("@rules_csharp//csharp:defs.bzl", "csharp_binary")

csharp_binary(<a href="#csharp_binary-name">name</a>, <a href="#csharp_binary-deps">deps</a>, <a href="#csharp_binary-srcs">srcs</a>, <a href="#csharp_binary-resources">resources</a>, <a href="#csharp_binary-defines">defines</a>, <a href="#csharp_binary-exports">exports</a>, <a href="#csharp_binary-nowarn">nowarn</a>, <a href="#csharp_binary-plugins">plugins</a>, <a href="#csharp_binary-target_framework">target_framework</a>,
              <a href="#csharp_binary-target_type">target_type</a>)
</pre>

Compiles a C# executable and stamps the native application host binary.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="csharp_binary-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="csharp_binary-deps"></a>deps |  Direct dependency libraries.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_binary-srcs"></a>srcs |  C# source files to compile.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_binary-resources"></a>resources |  Embedded resource files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_binary-defines"></a>defines |  Preprocessor symbols to define during compilation.   | List of strings | optional |  `[]`  |
| <a id="csharp_binary-exports"></a>exports |  Dependencies exported to downstream consumers.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_binary-nowarn"></a>nowarn |  Compiler diagnostic codes to suppress.   | List of strings | optional |  `[]`  |
| <a id="csharp_binary-plugins"></a>plugins |  Roslyn analyzer and generator plugins.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_binary-target_framework"></a>target_framework |  Target framework moniker string.   | String | optional |  `""`  |
| <a id="csharp_binary-target_type"></a>target_type |  Compiler target type output flag.   | String | optional |  `"exe"`  |


<a id="csharp_import"></a>

## csharp_import

<pre>
load("@rules_csharp//csharp:defs.bzl", "csharp_import")

csharp_import(<a href="#csharp_import-name">name</a>, <a href="#csharp_import-deps">deps</a>, <a href="#csharp_import-analyzers">analyzers</a>, <a href="#csharp_import-compile_refs">compile_refs</a>, <a href="#csharp_import-dlls">dlls</a>, <a href="#csharp_import-exports">exports</a>, <a href="#csharp_import-native_libs">native_libs</a>, <a href="#csharp_import-plugins">plugins</a>,
              <a href="#csharp_import-runtime_dlls">runtime_dlls</a>, <a href="#csharp_import-target_framework">target_framework</a>)
</pre>

Imports precompiled reference and implementation assemblies.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="csharp_import-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="csharp_import-deps"></a>deps |  Direct dependency libraries.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_import-analyzers"></a>analyzers |  Precompiled Roslyn analyzer DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_import-compile_refs"></a>compile_refs |  Precompiled reference assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_import-dlls"></a>dlls |  Precompiled implementation assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_import-exports"></a>exports |  Dependencies exported to downstream consumers.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_import-native_libs"></a>native_libs |  Unmanaged target platform shared libraries.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_import-plugins"></a>plugins |  Roslyn analyzer and generator plugins.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_import-runtime_dlls"></a>runtime_dlls |  Precompiled runtime implementation assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_import-target_framework"></a>target_framework |  Target framework moniker string.   | String | optional |  `""`  |


<a id="csharp_library"></a>

## csharp_library

<pre>
load("@rules_csharp//csharp:defs.bzl", "csharp_library")

csharp_library(<a href="#csharp_library-name">name</a>, <a href="#csharp_library-deps">deps</a>, <a href="#csharp_library-srcs">srcs</a>, <a href="#csharp_library-resources">resources</a>, <a href="#csharp_library-analyzers">analyzers</a>, <a href="#csharp_library-compile_refs">compile_refs</a>, <a href="#csharp_library-defines">defines</a>, <a href="#csharp_library-dlls">dlls</a>, <a href="#csharp_library-exports">exports</a>,
               <a href="#csharp_library-native_libs">native_libs</a>, <a href="#csharp_library-nowarn">nowarn</a>, <a href="#csharp_library-plugins">plugins</a>, <a href="#csharp_library-runtime_dlls">runtime_dlls</a>, <a href="#csharp_library-target_framework">target_framework</a>, <a href="#csharp_library-target_type">target_type</a>)
</pre>

Compiles C# source files into reference and implementation assemblies.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="csharp_library-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="csharp_library-deps"></a>deps |  Direct dependency libraries.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_library-srcs"></a>srcs |  C# source files to compile.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_library-resources"></a>resources |  Embedded resource files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_library-analyzers"></a>analyzers |  Precompiled Roslyn analyzer DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_library-compile_refs"></a>compile_refs |  Precompiled reference assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_library-defines"></a>defines |  Preprocessor symbols to define during compilation.   | List of strings | optional |  `[]`  |
| <a id="csharp_library-dlls"></a>dlls |  Precompiled implementation assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_library-exports"></a>exports |  Dependencies exported to downstream consumers.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_library-native_libs"></a>native_libs |  Unmanaged target platform shared libraries.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_library-nowarn"></a>nowarn |  Compiler diagnostic codes to suppress.   | List of strings | optional |  `[]`  |
| <a id="csharp_library-plugins"></a>plugins |  Roslyn analyzer and generator plugins.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_library-runtime_dlls"></a>runtime_dlls |  Precompiled runtime implementation assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_library-target_framework"></a>target_framework |  Target framework moniker string.   | String | optional |  `""`  |
| <a id="csharp_library-target_type"></a>target_type |  Compiler target type output flag.   | String | optional |  `"library"`  |


<a id="csharp_test"></a>

## csharp_test

<pre>
load("@rules_csharp//csharp:defs.bzl", "csharp_test")

csharp_test(<a href="#csharp_test-name">name</a>, <a href="#csharp_test-deps">deps</a>, <a href="#csharp_test-srcs">srcs</a>, <a href="#csharp_test-resources">resources</a>, <a href="#csharp_test-defines">defines</a>, <a href="#csharp_test-exports">exports</a>, <a href="#csharp_test-nowarn">nowarn</a>, <a href="#csharp_test-plugins">plugins</a>, <a href="#csharp_test-target_framework">target_framework</a>,
            <a href="#csharp_test-target_type">target_type</a>)
</pre>

Compiles and executes a C# test binary under the Bazel test harness.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="csharp_test-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="csharp_test-deps"></a>deps |  Direct dependency libraries.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_test-srcs"></a>srcs |  C# source files to compile.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_test-resources"></a>resources |  Embedded resource files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_test-defines"></a>defines |  Preprocessor symbols to define during compilation.   | List of strings | optional |  `[]`  |
| <a id="csharp_test-exports"></a>exports |  Dependencies exported to downstream consumers.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_test-nowarn"></a>nowarn |  Compiler diagnostic codes to suppress.   | List of strings | optional |  `[]`  |
| <a id="csharp_test-plugins"></a>plugins |  Roslyn analyzer and generator plugins.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_test-target_framework"></a>target_framework |  Target framework moniker string.   | String | optional |  `""`  |
| <a id="csharp_test-target_type"></a>target_type |  Compiler target type output flag.   | String | optional |  `"exe"`  |


<a id="CSharpAnalyzerInfo"></a>

## CSharpAnalyzerInfo

<pre>
load("@rules_csharp//csharp:defs.bzl", "CSharpAnalyzerInfo")

CSharpAnalyzerInfo(<a href="#CSharpAnalyzerInfo-analyzers">analyzers</a>)
</pre>

Propagates Roslyn analyzer and source generator assembly files.

**FIELDS**

| Name  | Description |
| :------------- | :------------- |
| <a id="CSharpAnalyzerInfo-analyzers"></a>analyzers |  Depset of Roslyn analyzer and generator assembly Files.    |


<a id="CSharpInfo"></a>

## CSharpInfo

<pre>
load("@rules_csharp//csharp:defs.bzl", "CSharpInfo")

CSharpInfo(<a href="#CSharpInfo-compile_ref">compile_ref</a>, <a href="#CSharpInfo-pdb">pdb</a>, <a href="#CSharpInfo-runtime_dll">runtime_dll</a>, <a href="#CSharpInfo-target_framework">target_framework</a>, <a href="#CSharpInfo-transitive_compile_refs">transitive_compile_refs</a>,
           <a href="#CSharpInfo-transitive_native_libs">transitive_native_libs</a>, <a href="#CSharpInfo-transitive_runtime_dlls">transitive_runtime_dlls</a>)
</pre>

Propagates compilation references, runtime assemblies, and unmanaged libraries.

**FIELDS**

| Name  | Description |
| :------------- | :------------- |
| <a id="CSharpInfo-compile_ref"></a>compile_ref |  Metadata-only reference assembly File produced by -refout.    |
| <a id="CSharpInfo-pdb"></a>pdb |  Portable program database symbol File.    |
| <a id="CSharpInfo-runtime_dll"></a>runtime_dll |  Implementation assembly File.    |
| <a id="CSharpInfo-target_framework"></a>target_framework |  Target framework moniker string (for example net8.0).    |
| <a id="CSharpInfo-transitive_compile_refs"></a>transitive_compile_refs |  Depset of reference assembly Files for compilation.    |
| <a id="CSharpInfo-transitive_native_libs"></a>transitive_native_libs |  Depset of target platform unmanaged shared libraries.    |
| <a id="CSharpInfo-transitive_runtime_dlls"></a>transitive_runtime_dlls |  Depset of runtime assembly Files for execution.    |


<a id="CSharpToolchainInfo"></a>

## CSharpToolchainInfo

<pre>
load("@rules_csharp//csharp:defs.bzl", "CSharpToolchainInfo")

CSharpToolchainInfo(<a href="#CSharpToolchainInfo-csc_dll">csc_dll</a>, <a href="#CSharpToolchainInfo-csc_worker">csc_worker</a>, <a href="#CSharpToolchainInfo-dotnet_muxer">dotnet_muxer</a>, <a href="#CSharpToolchainInfo-host_pack">host_pack</a>, <a href="#CSharpToolchainInfo-host_rid">host_rid</a>, <a href="#CSharpToolchainInfo-ref_pack">ref_pack</a>, <a href="#CSharpToolchainInfo-runtime_pack">runtime_pack</a>,
                    <a href="#CSharpToolchainInfo-target_framework">target_framework</a>, <a href="#CSharpToolchainInfo-target_rid">target_rid</a>)
</pre>

Defines resolved C# SDK tools, packs, and target monikers.

**FIELDS**

| Name  | Description |
| :------------- | :------------- |
| <a id="CSharpToolchainInfo-csc_dll"></a>csc_dll |  Host File for Roslyn compiler assembly.    |
| <a id="CSharpToolchainInfo-csc_worker"></a>csc_worker |  Host executable File for persistent compilation worker.    |
| <a id="CSharpToolchainInfo-dotnet_muxer"></a>dotnet_muxer |  Host executable File for dotnet driver.    |
| <a id="CSharpToolchainInfo-host_pack"></a>host_pack |  Binary template File for target platform application host.    |
| <a id="CSharpToolchainInfo-host_rid"></a>host_rid |  Host runtime identifier string.    |
| <a id="CSharpToolchainInfo-ref_pack"></a>ref_pack |  Depset of reference assembly Files for target framework.    |
| <a id="CSharpToolchainInfo-runtime_pack"></a>runtime_pack |  Depset of runtime assembly Files for target platform.    |
| <a id="CSharpToolchainInfo-target_framework"></a>target_framework |  Target framework moniker string.    |
| <a id="CSharpToolchainInfo-target_rid"></a>target_rid |  Target runtime identifier string.    |


