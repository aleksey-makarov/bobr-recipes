#!/usr/bin/env bash

# Exercise every migrated archive Source and all of its declared consumers.
# Requests are lowered in bounded batches without running any builds or network.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
temporary="$(mktemp -d)"
trap 'rm -rf -- "$temporary"' EXIT
checks="$repo_root/tools/test/public-source-checks.ncl"
count="$(nickel export --format json --field count "$checks")"
batch_size=32

for mode in default version_hash hash origin replacement input_first input_last input_same_version; do
  for ((begin = 0; begin < count; begin += batch_size)); do
    end=$((begin + batch_size))
    if ! nickel export --format json >"$temporary/result.json" 2>"$temporary/nickel.log" <<EOF_NICKEL
(import "$checks").run "$repo_root" "$mode" $begin $end
EOF_NICKEL
    then
      printf 'public Source tests: Nickel failed (%s, cases %s..%s)\n' "$mode" "$begin" "$end" >&2
      cat "$temporary/nickel.log" >&2
      exit 1
    fi
    if ! jq -e '.passed and (.failures | length) == 0' "$temporary/result.json" >/dev/null; then
      printf 'public Source tests: wiring failed (%s, cases %s..%s)\n' "$mode" "$begin" "$end" >&2
      cat "$temporary/result.json" >&2
      exit 1
    fi
  done
  printf 'public Source tests: %s (%s modules) passed\n' "$mode" "$count"
done
