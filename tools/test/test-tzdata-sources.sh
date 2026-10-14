#!/usr/bin/env bash

# Check the paired IANA code and data Sources used to build zoneinfo.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
temporary="$(mktemp -d)"
trap 'rm -rf -- "${temporary}"' EXIT

nickel export --format json >"${temporary}/positive.json" <<EOF_NICKEL
let recipe = import "${repo_root}/recipe-lib.ncl" in
let package_set = import "${repo_root}/bobrpkgs.ncl" in
let source = fun kind => fun version => fun hash => {
  name = "%{kind}-src-%{version}",
  include version,
  tag = "Source",
  object_hash = hash,
  origin = {
    tag = "Http",
    url = "https://example.invalid/%{kind}%{version}.tar.gz",
  },
} in
let summary = fun packages =>
  let graph = recipe.to_request { recipes_path = "${repo_root}" } packages packages.tzdata in
  {
    name = packages.tzdata.name,
    code = packages.tzdata.inputs.source,
    data = packages.tzdata.inputs.tzdata,
    public_code = packages.tzcode_src,
    public_data = packages.tzdata_src,
    has_version = std.record.has_field "version" packages.tzdata,
    has_code_hash = std.record.has_field "code_object_hash" packages.tzdata,
    has_data_hash = std.record.has_field "data_object_hash" packages.tzdata,
    lowered_name = graph.root.name,
    lowered_code = std.record.get graph.root.inputs.source graph,
    lowered_data = std.record.get graph.root.inputs.tzdata graph,
  }
in
let base_packages = package_set [] in
{
  original = summary base_packages,
  coordinated = summary (package_set [fun _final => fun _prev => {
    tzcode_src = source "tzcode" "2027a" "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    tzdata_src = source "tzdata" "2027a" "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
  }]),
  code_input = summary (package_set [fun _final => fun prev => {
    tzdata = prev.tzdata & {
      inputs.source | force = source "custom-code" "2026c" "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
    },
  }]),
  data_input = summary (package_set [fun _final => fun prev => {
    tzdata = prev.tzdata & {
      inputs.tzdata | force = source "custom-data" "2026c" "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
    },
  }]),
}
EOF_NICKEL

jq -e '
  .original.name == "tzdata-2026c"
  and .original.code.name == "tzcode-src-2026c"
  and .original.data.name == "tzdata-src-2026c"
  and .original.code == .original.public_code
  and .original.data == .original.public_data
  and (.original.has_version | not)
  and (.original.has_code_hash | not)
  and (.original.has_data_hash | not)
  and .original.lowered_name == .original.name
  and .original.lowered_code.name == .original.code.name
  and .original.lowered_code.object_hash == .original.code.object_hash
  and .original.lowered_data.name == .original.data.name
  and .original.lowered_data.object_hash == .original.data.object_hash
  and .coordinated.name == "tzdata-2027a"
  and .coordinated.code.name == "tzcode-src-2027a"
  and .coordinated.data.name == "tzdata-src-2027a"
  and .coordinated.lowered_name == .coordinated.name
  and .coordinated.lowered_code.object_hash == .coordinated.code.object_hash
  and .coordinated.lowered_data.object_hash == .coordinated.data.object_hash
  and .code_input.name == .original.name
  and .code_input.code.name == "custom-code-src-2026c"
  and .code_input.data == .original.data
  and .code_input.public_code == .original.public_code
  and .code_input.lowered_code.object_hash == .code_input.code.object_hash
  and .data_input.name == .original.name
  and .data_input.code == .original.code
  and .data_input.data.name == "custom-data-src-2026c"
  and .data_input.public_data == .original.public_data
  and .data_input.lowered_data.object_hash == .data_input.data.object_hash
' "${temporary}/positive.json" >/dev/null

for mismatch in public_sources code_input data_input; do
  case "${mismatch}" in
    public_sources)
      overlay='{
        tzcode_src = prev.tzcode_src & { version = "2027a", object_hash = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" },
      }'
      ;;
    code_input)
      overlay='{
        tzdata = prev.tzdata & {
          inputs.source | force = source "custom-code" "2027a" "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        },
      }'
      ;;
    data_input)
      overlay='{
        tzdata = prev.tzdata & {
          inputs.tzdata | force = source "custom-data" "2027a" "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        },
      }'
      ;;
  esac

  if nickel export --format json >"${temporary}/${mismatch}.json" 2>"${temporary}/${mismatch}.log" <<EOF_NICKEL
let package_set = import "${repo_root}/bobrpkgs.ncl" in
let source = fun kind => fun version => fun hash => {
  name = "%{kind}-src-%{version}",
  include version,
  tag = "Source",
  object_hash = hash,
  origin = { tag = "Http", url = "https://example.invalid/%{kind}.tar.gz" },
} in
let pkgs = package_set [fun _final => fun prev => ${overlay}] in
pkgs.tzdata.name
EOF_NICKEL
  then
    echo "tzdata accepted mismatched Sources in ${mismatch}" >&2
    exit 1
  fi
  rg -F "must match tzdata version" "${temporary}/${mismatch}.log" >/dev/null
done

echo "tzdata Source tests passed (paired releases and independent inputs)"
