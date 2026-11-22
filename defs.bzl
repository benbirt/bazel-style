"""The style() macro: formatting and Starlark lint for a repository."""

load("@aspect_rules_lint//format:defs.bzl", "format_multirun")
load("@buildifier_prebuilt//:rules.bzl", "buildifier")
load("@go_host_compatible_sdk_label//:defs.bzl", "HOST_COMPATIBLE_SDK")

# shfmt's style as flags: two-space indentation and indented case branches.
# Given any printer flag, shfmt reads no .editorconfig.
_SHFMT_STYLE = ["-i", "2", "-ci"]

# The formatter of each language, by rules_lint's attribute name, with the
# flags bazel_style gives it where they are not rules_lint's defaults.
_FORMATTERS = {
    # Also LESS and SCSS.
    "css": {"tool": Label("//prettier")},
    "go": {"tool": HOST_COMPATIBLE_SDK.same_package_label("bin/gofmt")},
    "html": {
        "tool": Label("//djlint"),
        # djlint's flags for templates, as rules_lint passes them for "HTML Jinja".
        "check_args": ["--format-css", "--format-js", "--check"],
        "fix_args": ["--format-css", "--format-js", "--reformat"],
    },
    # Also TypeScript and JSON.
    "javascript": {"tool": Label("//prettier")},
    "markdown": {"tool": Label("//prettier")},
    "python": {"tool": Label("@aspect_rules_lint//format:ruff")},
    "shell": {
        "tool": Label("@aspect_rules_lint//format:shfmt"),
        "check_args": ["--diff", "--apply-ignore"] + _SHFMT_STYLE,
        "fix_args": ["-w", "--apply-ignore"] + _SHFMT_STYLE,
    },
    "starlark": {"tool": Label("@buildifier_prebuilt//:buildifier")},
    # terraform fmt, from rules_lint.
    "terraform": {"tool": Label("@aspect_rules_lint//format:terraform")},
    "yaml": {"tool": Label("//yamlfmt")},
}

# buildifier: disable=unnamed-macro
def style(**formatters):
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

    Args:
      **formatters: a formatter for a language, named as rules_lint's
        `format_multirun` names it, in place of bazel_style's, for example
        `terraform = "@rules_tofu//tofu"`. It runs with rules_lint's flags
        for that language, without bazel_style's flags or settings.
    """
    attrs = {}
    for language, formatter in _FORMATTERS.items():
        if language in formatters:
            continue
        attrs[language] = formatter["tool"]
        if "check_args" in formatter:
            attrs[language + "_check_args"] = formatter["check_args"]
            attrs[language + "_fix_args"] = formatter["fix_args"]
    attrs.update(formatters)

    format_multirun(
        name = "format",
        **attrs
    )

    buildifier(
        name = "lint",
        # Not git refs such as refs/heads/fix/BUILD.
        exclude_patterns = ["./.git/*"],
        lint_mode = "warn",
        mode = "check",
    )
