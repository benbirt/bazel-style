#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  a) echo one ;;
  b)
    echo two
    ;;
esac
if [ -n "${2:-}" ]; then
  echo "$2"
fi
