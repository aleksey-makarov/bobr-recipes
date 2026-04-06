#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
contract_file="${repo_root}/contracts/meta.ncl"
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

run_case() {
  local name="$1"
  local expect="$2"
  local json_payload="$3"

  printf '%s\n' "${json_payload}" > "${tmpdir}/meta.json"
  cat > "${tmpdir}/check.ncl" <<EOF_INNER
let contracts = import "${contract_file}" in
let meta = import "./meta.json" in
contracts.validate_meta meta
EOF_INNER

  if (cd "${tmpdir}" && nickel export check.ncl --format json >/dev/null 2>&1); then
    if [[ "${expect}" != "pass" ]]; then
      echo "expected failure for ${name}" >&2
      return 1
    fi
  else
    if [[ "${expect}" != "fail" ]]; then
      echo "expected success for ${name}" >&2
      return 1
    fi
  fi
}

run_case "empty" pass '{}'
run_case "container-image" pass '{"manifest_digest":"sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"}'
run_case "binary-output" pass '{"install":{"owners":[{"path":"**","uid":0,"gid":0}]}}'

run_case "extra-field" fail '{"extra":true}'
run_case "bad-manifest-digest" fail '{"manifest_digest":"sha256:short"}'
run_case "bad-install-owner" fail '{"install":{"owners":[{"path":"**","uid":"0","gid":0}]}}'
run_case "mixed-shapes" fail '{"install":{"owners":[{"path":"**","uid":0,"gid":0}]},"manifest_digest":"sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"}'
run_case "old-kind" fail '{"kind":"plain-text"}'

echo "meta contract smoke tests passed"
