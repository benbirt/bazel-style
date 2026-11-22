#!/usr/bin/env bash
# Runs a formatter with its settings file from bazel_style's runfiles.

# A launcher started by path from inside another binary's runfiles tree, as
# rules_lint starts formatters, finds that tree from its own path.
if [[ -z "${RUNFILES_DIR:-}" && -z "${RUNFILES_MANIFEST_FILE:-}" && "$0" == *.runfiles/* ]]; then
  export RUNFILES_DIR="${0%%.runfiles/*}.runfiles"
fi

# --- begin runfiles.bash initialization v3 ---
set -uo pipefail; set +e; f=bazel_tools/tools/bash/runfiles/runfiles.bash
# shellcheck disable=SC1090
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
  source "$0.runfiles/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  { echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
# --- end runfiles.bash initialization v3 ---

tool="$(rlocation "__TOOL__")"
config="$(rlocation "__CONFIG__")"
args=(__ARGS__)

# Exit code 1 means only that files were changed when the caller passed the
# flag below, if any (djlint exits 1 after --reformat changes a file), which
# rules_lint would otherwise report as a failure of the formatter.
changed_flag="__CHANGED_FLAG__"
if [[ -n "$changed_flag" && " $* " == *" $changed_flag "* ]]; then
  status=0
  "$tool" "${args[@]}" "$config" "$@" || status=$?
  if [[ "$status" == 1 ]]; then
    exit 0
  fi
  exit "$status"
fi
exec "$tool" "${args[@]}" "$config" "$@"
