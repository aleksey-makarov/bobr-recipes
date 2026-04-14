#!/usr/bin/env bash

# Smoke-test the recipe contract with synthetic cases and then shallow-
# validate every raw recipe from mk-pkgs.ncl.
# Run this when editing recipe contracts, mk-pkgs wiring, or recipe shapes.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
contract_file="${repo_root}/contracts/recipe.ncl"
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

run_case() {
  local name="$1"
  local expect="$2"
  local json_payload="$3"

  printf '%s\n' "${json_payload}" > "${tmpdir}/recipe.json"
  cat > "${tmpdir}/check.ncl" <<EOF_INNER
let contracts = import "${contract_file}" in
let recipe = import "./recipe.json" in
contracts.validate_recipe recipe
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

run_case "text" pass '{"name":"hello","tag":"Text","config":{"source":"hi","executable":false},"inputs":{}}'
run_case "tree-file" pass '{"name":"hello-tree","tag":"Tree","config":{"tree":{"entries":[{"type":"file","path":"hello.txt","text":"hi\n","executable":false}]}},"inputs":{}}'
run_case "tree-dir" pass '{"name":"runtime-tree","tag":"Tree","config":{"tree":{"entries":[{"type":"dir","path":"dev"},{"type":"file","path":"etc/hostname","text":"mbuild\n","executable":false}]},"install":{"owners":[{"path":"**","uid":0,"gid":0}]}},"inputs":{}}'
run_case "tree-symlink" pass '{"name":"runtime-tree","tag":"Tree","config":{"tree":{"entries":[{"type":"dir","path":"usr/bin"},{"type":"symlink","path":"bin","target":"usr/bin"}]},"install":{"owners":[{"path":"**","uid":0,"gid":0}]}},"inputs":{}}'
run_case "fetch" pass '{"name":"src","tag":"Fetch","config":{"url":"https://example.invalid/src.tar.xz","hash":"sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"},"inputs":{}}'
run_case "container-image" pass '{"name":"img","tag":"ContainerImage","config":{"image":"docker.io/library/alpine:latest","digest":"sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"},"inputs":{}}'
run_case "binary" pass '{"name":"bin","tag":"Binary","config":{},"inputs":{"image":{"name":"img","tag":"ContainerImage","config":{"image":"docker.io/library/alpine:latest","digest":"sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"},"inputs":{}},"script":{"name":"script","tag":"Text","config":{"source":"#!/bin/sh\n","executable":true},"inputs":{}},"sources":[]}}'
run_case "ext4-rootfs" pass '{"name":"rootfs","tag":"Ext4Rootfs","config":{"size_mib":256,"label":"rootfs"},"inputs":{"inputs":[{"name":"bin","tag":"Binary","config":{},"inputs":{"image":{"name":"img","tag":"ContainerImage","config":{"image":"docker.io/library/alpine:latest","digest":"sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"},"inputs":{}},"script":{"name":"script","tag":"Text","config":{"source":"#!/bin/sh\n","executable":true},"inputs":{}},"sources":[]}}]}}'
run_case "image" pass '{"name":"img2","tag":"Image","config":{"mode":"bootstrap"},"inputs":{"base":null,"inputs":[]}}'

run_case "unknown-tag" fail '{"name":"bad","tag":"Demo","config":{},"inputs":{}}'
run_case "tree-bad-install-shape" fail '{"name":"runtime-tree","tag":"Tree","config":{"tree":{"entries":[{"type":"dir","path":"dev"}]},"install":{"owners":[{"path":"**","uid":"0","gid":0}]}},"inputs":{}}'
run_case "tree-bad-entry-type" fail '{"name":"runtime-tree","tag":"Tree","config":{"tree":{"entries":[{"type":"pipe","path":"lib"}]},"install":{"owners":[{"path":"**","uid":0,"gid":0}]}},"inputs":{}}'
run_case "tree-symlink-missing-target" fail '{"name":"runtime-tree","tag":"Tree","config":{"tree":{"entries":[{"type":"symlink","path":"lib"}]},"install":{"owners":[{"path":"**","uid":0,"gid":0}]}},"inputs":{}}'
run_case "missing-input-slot" fail '{"name":"bin","tag":"Binary","config":{},"inputs":{"image":{"name":"img","tag":"ContainerImage","config":{"image":"docker.io/library/alpine:latest","digest":"sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"},"inputs":{}},"sources":[]}}'
run_case "extra-top-level-field" fail '{"name":"hello","tag":"Text","config":{"source":"hi","executable":false},"inputs":{},"extra":true}'
run_case "wrong-many-shape" fail '{"name":"img2","tag":"Image","config":{"mode":"bootstrap"},"inputs":{"base":null,"inputs":{}}}'
run_case "bad-fetch-archive-format" fail '{"name":"src","tag":"Fetch","config":{"url":"https://example.invalid/src.tar.xz","hash":"sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","archive_format":"tar-zst"},"inputs":{}}'
run_case "bad-ext4-rootfs-size" fail '{"name":"rootfs","tag":"Ext4Rootfs","config":{"label":"rootfs"},"inputs":{"inputs":[]}}'

cat > "${tmpdir}/list-raw-pkgs.ncl" <<EOF_INNER
let raw_pkgs = (import "${repo_root}/mk-pkgs.ncl") [] in
std.record.fields raw_pkgs
EOF_INNER
attr_count="$(
  cd "${tmpdir}" &&
    nickel export list-raw-pkgs.ncl --format json | jq 'length'
)"

cat > "${tmpdir}/check-shallow-raw-pkgs.ncl" <<EOF_INNER
let contracts = import "${contract_file}" in
let raw_pkgs = (import "${repo_root}/mk-pkgs.ncl") [] in
std.record.map
  (fun _ recipe => let checked = recipe | contracts.shallow_recipe in checked.tag)
  raw_pkgs
EOF_INNER

(cd "${tmpdir}" && nickel export check-shallow-raw-pkgs.ncl --format json >/dev/null)

echo "recipe contract smoke tests passed (${attr_count} raw recipes shallow-validated)"
