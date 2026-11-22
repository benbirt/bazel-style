"""The style() macro: formatting and Starlark lint for a repository."""

load("@aspect_rules_lint//format:defs.bzl", "format_multirun")
load("@buildifier_prebuilt//:rules.bzl", "buildifier")
load("@go_host_compatible_sdk_label//:defs.bzl", "HOST_COMPATIBLE_SDK")

# djlint's flags for templates, as rules_lint passes them for "HTML Jinja".
_DJLINT_FIX_ARGS = ["--format-css", "--format-js", "--reformat"]
_DJLINT_CHECK_ARGS = ["--format-css", "--format-js", "--check"]

# shfmt's style as flags: two-space indentation and indented case branches.
# Given any printer flag, shfmt reads no .editorconfig.
_SHFMT_STYLE = ["-i", "2", "-ci"]

# buildifier: disable=unnamed-macro
def style():
    """Formatting and Starlark lint for the repository, called once in tools/BUILD.bazel.

    Creates three targets in the calling package:

    - `format`: `bazel run //tools:format` formats every file git tracks,
      by language.
    - `format.check`: `bazel run //tools:format.check` fails if any file
      would change.
    - `lint`: `bazel run //tools:lint` fails on any buildifier warning or
      formatting difference in a Starlark file, untracked files included.

    The macro creates fixed target names rather than taking `name`, since CI
    and the documentation of every repository run these three.
    """
    format_multirun(
        name = "format",
        # Also LESS and SCSS.
        css = Label("//prettier"),
        go = HOST_COMPATIBLE_SDK.same_package_label("bin/gofmt"),
        html = Label("//djlint"),
        html_check_args = _DJLINT_CHECK_ARGS,
        html_fix_args = _DJLINT_FIX_ARGS,
        # Also TypeScript and JSON.
        javascript = Label("//prettier"),
        markdown = Label("//prettier"),
        python = Label("@aspect_rules_lint//format:ruff"),
        shell = Label("@aspect_rules_lint//format:shfmt"),
        shell_check_args = ["--diff", "--apply-ignore"] + _SHFMT_STYLE,
        shell_fix_args = ["-w", "--apply-ignore"] + _SHFMT_STYLE,
        starlark = Label("@buildifier_prebuilt//:buildifier"),
        terraform = Label("@rules_tofu//tofu"),
        yaml = Label("//yamlfmt"),
    )

    buildifier(
        name = "lint",
        # Not git refs such as refs/heads/fix/BUILD.
        exclude_patterns = ["./.git/*"],
        lint_mode = "warn",
        mode = "check",
    )
