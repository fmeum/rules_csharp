"""Custom test runner for integration verification scripts."""

def _shell_test_impl(ctx):
    exe = ctx.actions.declare_file(ctx.label.name + "_runner.sh")
    script = ctx.file.src
    ctx.actions.write(
        output = exe,
        content = """#!/usr/bin/env bash
set -e
SCRIPT="{script}"
if [[ -f "$SCRIPT" ]]; then
    exec "$SCRIPT" "$@"
elif [[ -f "$TEST_SRCDIR/$TEST_WORKSPACE/$SCRIPT" ]]; then
    exec "$TEST_SRCDIR/$TEST_WORKSPACE/$SCRIPT" "$@"
else
    # Fallback search
    FOUND=$(find . -name "$(basename "$SCRIPT")" | head -n 1)
    if [[ -n "$FOUND" ]]; then
        exec "$FOUND" "$@"
    fi
    echo "Error: Could not locate $SCRIPT"
    exit 1
fi
""".format(script = script.short_path),
        is_executable = True,
    )

    runfiles = ctx.runfiles(files = [script, exe] + ctx.files.data)
    for d in ctx.attr.data:
        if DefaultInfo in d:
            runfiles = runfiles.merge(d[DefaultInfo].default_runfiles)

    return [
        DefaultInfo(executable = exe, runfiles = runfiles),
    ]

shell_test = rule(
    implementation = _shell_test_impl,
    attrs = {
        "data": attr.label_list(allow_files = True, default = []),
        "src": attr.label(allow_single_file = True, mandatory = True),
    },
    test = True,
)
