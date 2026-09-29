"""Public API for rules_csharp."""

load("//csharp/private:binary.bzl", _csharp_binary = "csharp_binary", _csharp_test = "csharp_test")
load(
    "//csharp/private:compile.bzl",
    _csharp_analyzer_import = "csharp_analyzer_import",
    _csharp_analyzer_library = "csharp_analyzer_library",
    _csharp_import = "csharp_import",
    _csharp_library = "csharp_library",
)
load(
    "//csharp/private:providers.bzl",
    _CSharpAnalyzerInfo = "CSharpAnalyzerInfo",
    _CSharpInfo = "CSharpInfo",
    _CSharpToolchainInfo = "CSharpToolchainInfo",
)

csharp_library = _csharp_library
csharp_binary = _csharp_binary
csharp_test = _csharp_test
csharp_analyzer_library = _csharp_analyzer_library
csharp_import = _csharp_import
csharp_analyzer_import = _csharp_analyzer_import

CSharpInfo = _CSharpInfo
CSharpAnalyzerInfo = _CSharpAnalyzerInfo
CSharpToolchainInfo = _CSharpToolchainInfo

