#!/usr/bin/env bash

# Exercise shared and independent Linux Sources without builds or downloads.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
temporary="$(mktemp -d)"
trap 'rm -rf -- "${temporary}"' EXIT
checks="${repo_root}/tools/test/linux-source-checks.ncl"
count="$(nickel export --format json --field count "${checks}")"

for ((index = 0; index < count; index++)); do
  if ! nickel export --format json >"${temporary}/result.json" 2>"${temporary}/nickel.log" <<EOF_NICKEL
(import "${checks}").run "${repo_root}" ${index}
EOF_NICKEL
  then
    printf 'Linux Source tests: Nickel failed (case %s)\n' "${index}" >&2
    cat "${temporary}/nickel.log" >&2
    exit 1
  fi
  if ! jq -e '.passed and (.failures | length) == 0' "${temporary}/result.json" >/dev/null; then
    printf 'Linux Source tests: wiring failed (case %s)\n' "${index}" >&2
    cat "${temporary}/result.json" >&2
    exit 1
  fi
done

for version in invalid 6 -6.1; do
  if nickel export --format json >"${temporary}/invalid.json" 2>"${temporary}/invalid.log" <<EOF_NICKEL
let pkgs = (import "${repo_root}/bobrpkgs.ncl") [fun _final => fun prev => {
  linux_src = prev.linux_src & {version = "${version}"},
}] in pkgs.linux_src.origin.url
EOF_NICKEL
  then
    printf 'Linux Source tests: invalid URL version accepted: %s\n' "${version}" >&2
    exit 1
  fi
  if ! rg -q 'version must start with a major version' "${temporary}/invalid.log"; then
    cat "${temporary}/invalid.log" >&2
    exit 1
  fi
done

printf 'Linux Source tests passed (%s cases; 3 invalid URL versions)\n' "${count}"
