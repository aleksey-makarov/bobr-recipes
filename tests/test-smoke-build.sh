#!/usr/bin/env bash
set -euo pipefail

out="${MBUILD_PRIMARY_OUTPUT:?MBUILD_PRIMARY_OUTPUT is required}"
dest="/out/${out}"

mkdir -p "$dest"
printf '%s\n' "test-smoke-build ok" > "$dest/status.txt"
