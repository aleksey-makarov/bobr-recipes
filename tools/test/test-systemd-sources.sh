#!/usr/bin/env bash

# Check systemd's paired source/man-pages releases and derived splits.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
temporary="$(mktemp -d)"
trap 'rm -rf -- "${temporary}"' EXIT

nickel export --format json >"${temporary}/positive.json" <<EOF_NICKEL
let recipe = import "${repo_root}/recipe-lib.ncl" in
let package_set = import "${repo_root}/bobrpkgs.ncl" in
let mk_source = fun kind => fun version => fun hash => {
  name = "%{kind}-src-%{version}",
  include version,
  tag = "Source",
  object_hash = hash,
  origin = {
    tag = "Http",
    url = "https://example.invalid/%{kind}-%{version}.tar.xz",
  },
} in
let summary = fun packages =>
  let graph = recipe.to_request { recipes_path = "${repo_root}" } packages packages.systemd in
  {
    public_source = packages.systemd_src,
    public_man_pages = packages.systemd_man_pages_src,
    systemd = {
      name = packages.systemd.name,
      source = packages.systemd.inputs.source,
      man_pages = packages.systemd.inputs.man_pages,
      setup_args = packages.systemd.config.setup_args,
      has_version = std.record.has_field "version" packages.systemd,
      has_source_hash = std.record.has_field "source_object_hash" packages.systemd,
      has_man_pages_hash = std.record.has_field "man_pages_object_hash" packages.systemd,
    },
    libs = {
      name = packages.systemd_libs.name,
      tree = packages.systemd_libs.inputs.tree.name,
    },
    dev = {
      name = packages.systemd_dev.name,
      tree = packages.systemd_dev.inputs.tree.name,
    },
    lowered = {
      name = graph.root.name,
      source = std.record.get graph.root.inputs.source graph,
      man_pages = std.record.get graph.root.inputs.man_pages graph,
    },
  }
in
let base_packages = package_set [] in
{
  original = summary base_packages,
  coordinated = summary (package_set [fun _final => fun _prev => {
    systemd_src = mk_source "systemd" "261.2" "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    systemd_man_pages_src = mk_source "systemd-man-pages" "261.2" "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
  }]),
  source_input = summary (package_set [fun _final => fun prev => {
    systemd = prev.systemd & {
      inputs = prev.systemd.inputs & {
        source | force = mk_source "custom-systemd" "260.1" "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
      },
    },
  }]),
  man_pages_input = summary (package_set [fun _final => fun prev => {
    systemd = prev.systemd & {
      inputs = prev.systemd.inputs & {
        man_pages | force = mk_source "custom-man-pages" "260.1" "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
      },
    },
  }]),
}
EOF_NICKEL

jq -e '
  .original.public_source.name == "systemd-src-260.1"
  and .original.public_man_pages.name == "systemd-man-pages-src-260.1"
  and .original.systemd.name == "systemd-260.1"
  and .original.systemd.source == .original.public_source
  and .original.systemd.man_pages == .original.public_man_pages
  and (.original.systemd.setup_args | index("-Ddocdir=/usr/share/doc/systemd-260.1")) != null
  and (.original.systemd.has_version | not)
  and (.original.systemd.has_source_hash | not)
  and (.original.systemd.has_man_pages_hash | not)
  and .original.libs.name == "systemd-libs-260.1"
  and .original.libs.tree == .original.systemd.name
  and .original.dev.name == "systemd-dev-260.1"
  and .original.dev.tree == .original.systemd.name
  and .original.lowered.name == .original.systemd.name
  and .original.lowered.source.name == .original.systemd.source.name
  and .original.lowered.source.object_hash == .original.systemd.source.object_hash
  and .original.lowered.man_pages.name == .original.systemd.man_pages.name
  and .original.lowered.man_pages.object_hash == .original.systemd.man_pages.object_hash
  and .coordinated.systemd.name == "systemd-261.2"
  and .coordinated.systemd.source.name == "systemd-src-261.2"
  and .coordinated.systemd.man_pages.name == "systemd-man-pages-src-261.2"
  and (.coordinated.systemd.setup_args | index("-Ddocdir=/usr/share/doc/systemd-261.2")) != null
  and .coordinated.libs.name == "systemd-libs-261.2"
  and .coordinated.libs.tree == .coordinated.systemd.name
  and .coordinated.dev.name == "systemd-dev-261.2"
  and .coordinated.dev.tree == .coordinated.systemd.name
  and .coordinated.lowered.name == .coordinated.systemd.name
  and .coordinated.lowered.source.object_hash == .coordinated.systemd.source.object_hash
  and .coordinated.lowered.man_pages.object_hash == .coordinated.systemd.man_pages.object_hash
  and .source_input.public_source == .original.public_source
  and .source_input.systemd.name == .original.systemd.name
  and .source_input.systemd.source.name == "custom-systemd-src-260.1"
  and .source_input.systemd.man_pages == .original.systemd.man_pages
  and .source_input.libs.name == .original.libs.name
  and .source_input.dev.name == .original.dev.name
  and .source_input.lowered.source.object_hash == .source_input.systemd.source.object_hash
  and .man_pages_input.public_man_pages == .original.public_man_pages
  and .man_pages_input.systemd.name == .original.systemd.name
  and .man_pages_input.systemd.source == .original.systemd.source
  and .man_pages_input.systemd.man_pages.name == "custom-man-pages-src-260.1"
  and .man_pages_input.libs.name == .original.libs.name
  and .man_pages_input.dev.name == .original.dev.name
  and .man_pages_input.lowered.man_pages.object_hash == .man_pages_input.systemd.man_pages.object_hash
' "${temporary}/positive.json" >/dev/null

for mismatch in public_sources source_input man_pages_input; do
  case "${mismatch}" in
    public_sources)
      overlay='{
        systemd_src = prev.systemd_src & { version = "261.2", object_hash = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" },
      }'
      ;;
    source_input)
      overlay='{
        systemd = prev.systemd & {
          inputs = prev.systemd.inputs & {
            source | force = mk_source "custom-systemd" "261.2" "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
          },
        },
      }'
      ;;
    man_pages_input)
      overlay='{
        systemd = prev.systemd & {
          inputs = prev.systemd.inputs & {
            man_pages | force = mk_source "custom-man-pages" "261.2" "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
          },
        },
      }'
      ;;
  esac

  if nickel export --format json >"${temporary}/${mismatch}.json" 2>"${temporary}/${mismatch}.log" <<EOF_NICKEL
let package_set = import "${repo_root}/bobrpkgs.ncl" in
let mk_source = fun kind => fun version => fun hash => {
  name = "%{kind}-src-%{version}",
  include version,
  tag = "Source",
  object_hash = hash,
  origin = { tag = "Http", url = "https://example.invalid/%{kind}.tar.xz" },
} in
let pkgs = package_set [fun _final => fun prev => ${overlay}] in
pkgs.systemd.name
EOF_NICKEL
  then
    echo "systemd accepted mismatched Sources in ${mismatch}" >&2
    exit 1
  fi
  rg -F "must match man pages version" "${temporary}/${mismatch}.log" >/dev/null
done

echo "systemd Source tests passed (paired release and derived splits)"
