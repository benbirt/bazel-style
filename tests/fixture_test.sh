#!/usr/bin/env bash
# Runs style() in tests/fixture, a workspace that depends on this checkout of
# bazel_style. Its files are committed formatted; tests/unformatted holds an
# unformatted copy of each, named <path>.unformatted so that no formatter
# matches it. The test checks that format.check and lint pass on the
# formatted files, fail once the unformatted copies are put in their place,
# and pass again after format, which must give back the committed files
# exactly.
#
# The fixture also holds a .editorconfig, .prettierrc.json, .yamlfmt and
# .djlintrc with other settings, which bazel_style must ignore, and a file
# marked rules-lint-ignored, which format must leave alone. tools/tofu
# overrides one formatter (tofu fmt for .tf and .tfvars files).
#
# Needs a git checkout: the formatters find files with git ls-files, and the
# result is compared with git diff.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$root/tests/fixture"
unformatted="$root/tests/unformatted"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

cd "$fixture"
git diff --quiet -- . || fail "tests/fixture has uncommitted changes"

echo "--- format.check and lint pass on the formatted fixture"
bazel run //tools:format.check || fail "format.check failed on the formatted fixture"
bazel run //tools:lint || fail "lint failed on the formatted fixture"

echo "--- put the unformatted copies in place"
while IFS= read -r copy; do
  target="${copy%.unformatted}"
  [ -f "$fixture/$target" ] || fail "tests/unformatted/$copy has no tests/fixture/$target"
  ! cmp -s "$unformatted/$copy" "$fixture/$target" || fail "tests/unformatted/$copy is already formatted"
  cp "$unformatted/$copy" "$fixture/$target"
done < <(cd "$unformatted" && find . -type f -name '*.unformatted' | sed 's|^\./||' | sort)

echo "--- format.check and lint fail"
! bazel run //tools:format.check || fail "format.check passed on unformatted files"
! bazel run //tools:lint || fail "lint passed on unformatted Starlark"

echo "--- format gives back the committed files"
bazel run //tools:format || fail "format failed"
git diff --exit-code -- . || fail "format did not give back the committed files (diff above)"

echo "--- format.check and lint pass again"
bazel run //tools:format.check || fail "format.check failed after format"
bazel run //tools:lint || fail "lint failed after format"

echo "--- an overridden formatter: tools/tofu formats .tf and .tfvars with tofu fmt"
tofu_fmt=//tools/tofu:format_Terraform_with_terraform-fmt
[ -n "$(bazel query "somepath($tofu_fmt, @rules_tofu//tofu)")" ] || fail "$tofu_fmt does not run @rules_tofu//tofu"
[ -z "$(bazel query "somepath(//tools:format, @rules_tofu//tofu)")" ] || fail "//tools:format runs @rules_tofu//tofu"
for file in main.tf terraform.tfvars; do cp "$unformatted/$file.unformatted" "$fixture/$file"; done
! bazel run "$tofu_fmt.check" || fail "$tofu_fmt.check passed on unformatted files"
bazel run "$tofu_fmt" || fail "$tofu_fmt failed"
git diff --exit-code -- . || fail "$tofu_fmt did not give back the committed files (diff above)"

echo "PASS"
