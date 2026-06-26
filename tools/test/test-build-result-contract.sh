#!/usr/bin/env bash

# Validate every JSON build result under bobr-store/result-refs against the
# build-result contract.
# Run this after local builds when you want to check stored result records
# rather than recipe definitions.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${repo_root}/env.sh"
contract_file="${repo_root}/contracts/build-result.ncl"
result_refs_dir="${store_root}/result-refs"
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

if [[ ! -d "${result_refs_dir}" ]]; then
  echo "no result-refs directory at ${result_refs_dir}; no build results to validate"
  exit 0
fi

count=0

while IFS= read -r ref; do
  [[ -n "${ref}" ]] || continue
  target="$(readlink -f "${ref}")"
  name="$(basename "${ref}")"

  cat > "${tmpdir}/check.ncl" <<EOF_INNER
let results = import "${contract_file}" in
let result = import "${target}" in
results.validate_result result
EOF_INNER

  echo "validating ${name}"
  if ! nickel export "${tmpdir}/check.ncl" --format json >/dev/null; then
    echo "result validation failed for ${ref} -> ${target}" >&2
    exit 1
  fi

  count=$((count + 1))
done < <(find "${result_refs_dir}" -maxdepth 1 -type l -name '*.json' | sort)

if [[ ${count} -eq 0 ]]; then
  echo "no build results found under ${result_refs_dir}"
  exit 0
fi

echo "validated ${count} build result(s)"
