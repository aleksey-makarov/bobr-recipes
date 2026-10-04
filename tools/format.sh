#!/usr/bin/env bash

# Formats every tracked Nickel source in this repository, or checks that all
# tracked Nickel sources already use the canonical format.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: tools/format.sh [--check]

With no arguments, format every tracked *.ncl file in place.
With --check, change nothing and fail if any file needs formatting.
EOF
}

script_path="$(readlink -f "${BASH_SOURCE[0]}")"
repository_path="$(cd "$(dirname "${script_path}")/.." && pwd)"
version_file="${repository_path}/.nickel-version"
mode="format"

case "${1:-}" in
  "") ;;
  --check)
    mode="check"
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

if [ "$#" -gt 1 ]; then
  usage >&2
  exit 2
fi

IFS= read -r expected_version < "${version_file}"
if [[ ! "${expected_version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "format.sh: invalid Nickel version in ${version_file}" >&2
  exit 2
fi

if ! command -v nickel >/dev/null 2>&1; then
  echo "format.sh: nickel ${expected_version} is required but was not found on PATH" >&2
  exit 1
fi

nickel_version_output="$(nickel --version)"
if [[ "${nickel_version_output}" =~ ^nickel-lang-cli[[:space:]]+nickel[[:space:]]+([^[:space:]]+) ]]; then
  actual_version="${BASH_REMATCH[1]}"
else
  echo "format.sh: cannot parse Nickel version: ${nickel_version_output}" >&2
  exit 1
fi

if [ "${actual_version}" != "${expected_version}" ]; then
  echo "format.sh: Nickel ${expected_version} is required, found ${actual_version}" >&2
  exit 1
fi

mapfile -d '' nickel_files \
  < <(git -C "${repository_path}" ls-files -z -- '*.ncl')

failed=0
for relative_path in "${nickel_files[@]}"; do
  if [ "${mode}" = "check" ]; then
    if ! nickel format --check "${repository_path}/${relative_path}"; then
      failed=1
    fi
  else
    printf 'Formatting: %s\n' "${relative_path}"
    if ! nickel format "${repository_path}/${relative_path}"; then
      failed=1
    fi
  fi
done

if [ "${failed}" -ne 0 ]; then
  echo "format.sh: one or more Nickel files failed ${mode}" >&2
  exit 1
fi
