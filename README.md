# bazel-style

The formatters, their settings and the Starlark lint shared by benbirt's Bazel repositories, as one Bazel module,
`bazel_style`. A repository calls one macro instead of keeping its own formatter setup and configuration files.

## Using it

In `MODULE.bazel`:

```starlark
bazel_dep(name = "bazel_style", version = "0.0.0", dev_dependency = True)
git_override(
    module_name = "bazel_style",
    commit = "<commit>",
    remote = "https://github.com/benbirt/bazel-style.git",
)
```

The [Bazel updates](https://github.com/benbirt/workflows) workflow moves `commit` to the head of `main`.

In `.bazelrc`, to turn off the telemetry that aspect_rules_lint and aspect_rules_js report to Aspect (an empty value
does not):

```
common --repo_env=ASPECT_TOOLS_TELEMETRY=-all
```

In `tools/BUILD.bazel`:

```starlark
load("@bazel_style//:defs.bzl", "style")

style()
```

To use another formatter for a language, pass it under rules_lint's name for that language, for example
`style(terraform = "@rules_tofu//tofu")` in a repository that has rules_tofu. It runs with rules_lint's flags, without
bazel_style's.

`style()` creates three targets:

- `bazel run //tools:format` formats every file git tracks, by language.
- `bazel run //tools:format.check` fails if any file would change.
- `bazel run //tools:lint` fails on any buildifier warning or formatting difference in a Starlark file, untracked files
  included.

To leave a file as it is, give it the `rules-lint-ignored` attribute in `.gitattributes`. To accept a lint warning,
add `# buildifier: disable=<warning>` with the reason.

## What it formats

| Files                        | Formatter                                    |
| ---------------------------- | -------------------------------------------- |
| CSS, LESS, SCSS              | Prettier                                     |
| JavaScript, TypeScript, JSON | Prettier                                     |
| Markdown                     | Prettier                                     |
| HTML, templates included     | djlint, with its embedded CSS and JavaScript |
| Python                       | ruff                                         |
| Shell                        | shfmt                                        |
| Starlark                     | buildifier                                   |
| YAML                         | yamlfmt                                      |
| Go                           | gofmt, from the build's host Go SDK          |
| OpenTofu (`.tf`, `.tfvars`)  | `terraform fmt`, from rules_lint             |

Every repository gets every formatter, whether or not it has files of that language, so the first run fetches them all
(Node, Python, a Go SDK, Terraform and the others).

## Settings

The settings are fixed here: a repository's own configuration files (`.editorconfig`, `.prettierrc*`, `.yamlfmt`,
`.djlintrc`) do not change them.

- Prettier: line width 120 ([`prettier/.prettierrc.json`](prettier/.prettierrc.json)), Prettier's defaults otherwise,
  so Markdown paragraphs are never rewrapped.
- djlint: the Jinja profile, two-space indentation and line width 120 ([`djlint/.djlintrc`](djlint/.djlintrc)). It
  formats every `.html` file, because Prettier changes the meaning of template syntax.
- shfmt: two-space indentation, with `case` branches indented (`-i 2 -ci`).
- yamlfmt: the basic formatter, keeping single blank lines ([`yamlfmt/.yamlfmt`](yamlfmt/.yamlfmt)).
- ruff, buildifier, gofmt and `terraform fmt`: their defaults.

## Changing it

- Prettier's version:
  `bazel run -- @pnpm//:pnpm --dir $PWD/prettier add --save-dev --save-exact --lockfile-only prettier@<version>`.
- djlint's version: edit `djlint/requirements.in` if needed, then `bazel run //djlint:requirements.update`.
- `tests/fixture_test.sh`, which CI runs, checks `style()` in a consumer workspace, `tests/fixture`. Its files are
  committed formatted; `tests/unformatted` holds an unformatted copy of each.
