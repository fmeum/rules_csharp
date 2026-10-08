"""Rule transition to linux_arm64_platform for cross-compiled binary verification."""

def _linux_arm64_transition_impl(settings, attr):
    return {
        "//command_line_option:platforms": str(Label("//csharp/constraints:linux_arm64_platform")),
    }

_linux_arm64_transition = transition(
    implementation = _linux_arm64_transition_impl,
    inputs = [],
    outputs = ["//command_line_option:platforms"],
)

def _linux_binary_collector_impl(ctx):
    target = ctx.attr.binary[0] if type(ctx.attr.binary) == "list" else ctx.attr.binary
    exe_file = target[DefaultInfo].files.to_list()[0]
    out_file = ctx.actions.declare_file(ctx.label.name + "_linux_arm64")
    ctx.actions.symlink(
        output = out_file,
        target_file = exe_file,
    )
    return [
        DefaultInfo(
            files = depset([out_file]),
            runfiles = ctx.runfiles(files = [out_file]),
        ),
    ]

linux_binary_collector = rule(
    implementation = _linux_binary_collector_impl,
    attrs = {
        "binary": attr.label(cfg = _linux_arm64_transition),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
)
