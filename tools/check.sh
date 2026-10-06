#!/usr/bin/env bash

# Runs the complete standalone check suite used by bobr-recipes CI.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: tools/check.sh

Check formatting, shell scripts, profile and repository integration, recipe
contracts, synthetic source preparation, and store-comparison behavior.
EOF
}

case "$#" in
  0) ;;
  1)
    case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 2
      ;;
    esac
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

script_path="$(readlink -f "${BASH_SOURCE[0]}")"
repository_path="$(cd "$(dirname "${script_path}")/.." && pwd)"
cd "${repository_path}"

for command in git jq nickel patch python3 rg shellcheck tar \
  "${BOBR_FSOBJ_HASH:-bobr-fsobj-hash}"; do
  if ! command -v "${command}" >/dev/null 2>&1; then
    echo "check.sh: required tool not found on PATH: ${command}" >&2
    exit 1
  fi
done

step() { printf '==> %s\n' "$*" >&2; }

step "nickel formatting"
tools/format.sh --check

step "shell scripts"
mapfile -d '' shell_files < <(git ls-files -z -- '*.sh')
shellcheck "${shell_files[@]}"

step "build profiles"
tools/test/test-profile.sh

step "output repository integration"
tools/test/test-output-repository.sh

step "recipe contracts"
tools/test/test-recipe-contract.sh

step "synthetic source preparation"
tools/test/test-synthetic-common.sh

step "store comparison"
python3 tools/test/test-bobr-compare-stores.py
