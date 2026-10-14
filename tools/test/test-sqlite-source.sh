#!/usr/bin/env bash

# Check SQLite's release-year URL and packed upstream version.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
temporary="$(mktemp -d)"
trap 'rm -rf -- "${temporary}"' EXIT

nickel export --format json >"${temporary}/result.json" <<EOF_NICKEL
let recipe = import "${repo_root}/recipe-lib.ncl" in
let package_set = import "${repo_root}/bobrpkgs.ncl" in
let replacement = fun version => fun hash => {
  name = "sqlite-fixture-%{version}",
  include version,
  tag = "Source",
  object_hash = hash,
  origin = {
    tag = "Http",
    url = "https://example.invalid/sqlite-%{version}.tar.gz",
  },
} in
let summary = fun packages =>
  let graph = recipe.to_request { recipes_path = "${repo_root}" } packages packages.sqlite in
  {
    source = packages.sqlite_src,
    name = packages.sqlite.name,
    input = packages.sqlite.inputs.source,
    has_version = std.record.has_field "version" packages.sqlite,
    has_hash = std.record.has_field "source_object_hash" packages.sqlite,
    has_year = std.record.has_field "year" packages.sqlite,
    has_release_year = std.record.has_field "release_year" packages.sqlite,
    lowered_name = graph.root.name,
    lowered_source = std.record.get graph.root.inputs.source graph,
    lowered_has_version = std.record.has_field "version" (std.record.get graph.root.inputs.source graph),
    lowered_has_release_year = std.record.has_field "release_year" (std.record.get graph.root.inputs.source graph),
  }
in
let base_packages = package_set [] in
{
  original = summary base_packages,
  release = summary (package_set [fun _final => fun prev => {
    sqlite_src = prev.sqlite_src & {
      version = "4.7.12",
      release_year = "2031",
      object_hash = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    },
  }]),
  hash_origin = summary (package_set [fun _final => fun prev => {
    sqlite_src = prev.sqlite_src & {
      object_hash = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
      origin | force = {
        tag = "Http",
        url = "https://example.invalid/sqlite.tar.gz",
      },
    },
  }]),
  source_replacement = summary (package_set [fun _final => fun _prev => {
    sqlite_src = replacement "5.8.13" "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
  }]),
  input_replacement = summary (package_set [fun _final => fun prev => {
    sqlite = prev.sqlite & {
      inputs.source | force = replacement "6.9.14" "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
    },
  }]),
}
EOF_NICKEL

jq -e '
  .original.source.version == "3.53.3"
  and .original.source.release_year == "2026"
  and .original.source.name == "sqlite-src-3.53.3"
  and .original.source.origin.url == "https://www.sqlite.org/2026/sqlite-autoconf-3530300.tar.gz"
  and .original.name == "sqlite-3.53.3"
  and .original.input == .original.source
  and (.original.has_version | not)
  and (.original.has_hash | not)
  and (.original.has_year | not)
  and (.original.has_release_year | not)
  and .original.lowered_name == .original.name
  and .original.lowered_source.name == .original.source.name
  and .original.lowered_source.object_hash == .original.source.object_hash
  and (.original.lowered_has_version | not)
  and (.original.lowered_has_release_year | not)
  and .release.source.version == "4.7.12"
  and .release.source.release_year == "2031"
  and .release.source.origin.url == "https://www.sqlite.org/2031/sqlite-autoconf-4071200.tar.gz"
  and .release.name == "sqlite-4.7.12"
  and .release.input == .release.source
  and .release.lowered_source.object_hash == .release.source.object_hash
  and .hash_origin.name == .original.name
  and .hash_origin.source.object_hash == "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
  and .hash_origin.source.origin.url == "https://example.invalid/sqlite.tar.gz"
  and .hash_origin.lowered_source.object_hash == .hash_origin.source.object_hash
  and .source_replacement.name == "sqlite-5.8.13"
  and .source_replacement.input.name == "sqlite-fixture-5.8.13"
  and .source_replacement.lowered_source.object_hash == .source_replacement.source.object_hash
  and .input_replacement.source == .original.source
  and .input_replacement.name == "sqlite-6.9.14"
  and .input_replacement.input.name == "sqlite-fixture-6.9.14"
  and .input_replacement.lowered_source.object_hash == .input_replacement.input.object_hash
' "${temporary}/result.json" >/dev/null

echo "SQLite Source tests passed (release year and packed version URL)"
