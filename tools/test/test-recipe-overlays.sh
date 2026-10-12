#!/usr/bin/env bash

# Targeted fixed-point wiring tests. Export only summaries and lowered graphs,
# never the complete recursively expanded package set.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
temporary="$(mktemp -d)"
trap 'rm -rf -- "${temporary}"' EXIT

for base in acl attr glibc kmod libcap libdrm libxcrypt linux_pam ncurses \
  openssl slang systemd util_linux xz; do
  nickel export --format json >"${temporary}/split.json" <<EOF_NICKEL
let recipe = import "${repo_root}/recipe-lib.ncl" in
let package_set = import "${repo_root}/bobrpkgs.ncl" in
let original = package_set [] in
let test_case = fun renamed =>
  let replacement = {
    name = if renamed then "overlay-${base}-9.8.7" else original.${base}.name,
    tag = "Source",
    object_hash = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  } in
  let pkgs = package_set [fun _final => fun _prev => { ${base} = replacement }] in
  let split = pkgs.${base}_libs in
  {
    expected_name = if renamed then "overlay-${base}-libs-9.8.7" else original.${base}_libs.name,
    expected_tree_name = replacement.name,
    name = split.name,
    tag = split.tag,
    includes = split.config.include,
    original_includes = original.${base}_libs.config.include,
    tree_name = split.inputs.tree.name,
    tree_tag = split.inputs.tree.tag,
    # Do not traverse the original build graph when the wiring is wrong.
    lowered = if split.inputs.tree.tag == "Source" then
      recipe.to_request { recipes_path = "${repo_root}" } pkgs split
    else null,
  }
in
[test_case false, test_case true]
EOF_NICKEL
  if ! jq -e '
    length == 2 and all(.[];
      .name == .expected_name and .tag == "TreeSubset"
      and .includes == .original_includes
      and .tree_tag == "Source" and .tree_name == .expected_tree_name
      and .lowered.root.name == .expected_name
      and .lowered.root.config.include == .original_includes
      and (.lowered | length) == 2
      and (.lowered[.lowered.root.inputs.tree] |
        .tag == "Source"
        and .object_hash == "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
    )
  ' "${temporary}/split.json" >/dev/null; then
    echo "${base}_libs does not follow its final package-set input/name" >&2
    cat "${temporary}/split.json" >&2
    exit 1
  fi
done

# Ordinary record merges must propagate the version and source identity too.
nickel export --format json >"${temporary}/attr-version.json" <<EOF_NICKEL
let pkgs = (import "${repo_root}/bobrpkgs.ncl") [
  fun _final => fun prev => {
    attr = prev.attr & {
      version = "9.8.7",
      source_object_hash = "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
    },
  },
] in
{
  name = pkgs.attr_libs.name,
  tree_name = pkgs.attr_libs.inputs.tree.name,
  source_name = pkgs.attr_libs.inputs.tree.inputs.source.name,
  source_hash = pkgs.attr_libs.inputs.tree.inputs.source.object_hash,
}
EOF_NICKEL
jq -e '
  .name == "attr-libs-9.8.7" and .tree_name == "attr-9.8.7"
  and .source_name == "attr-src-9.8.7"
  and .source_hash == "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
' "${temporary}/attr-version.json" >/dev/null

# The development split must follow both the full package and the independently
# overridden library split; its name follows the full package's version.
nickel export --format json >"${temporary}/systemd-dev.json" <<EOF_NICKEL
let pkgs = (import "${repo_root}/bobrpkgs.ncl") [
  fun _final => fun _prev => {
    systemd = {
      name = "overlay-systemd-9.8.7",
      version = "9.8.7",
      tag = "Source",
      object_hash = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    },
    systemd_libs = {
      name = "overlay-systemd-libs-9.8.7",
      tag = "Source",
      object_hash = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
    },
  },
] in
{
  name = pkgs.systemd_dev.name,
  tree_name = pkgs.systemd_dev.inputs.tree.name,
  tree_hash = if pkgs.systemd_dev.inputs.tree.tag == "Source" then
    pkgs.systemd_dev.inputs.tree.object_hash else null,
  runtime = std.array.map (fun dependency => dependency.name) pkgs.systemd_dev.deps.runtime,
}
EOF_NICKEL
jq -e '
  .name == "systemd-dev-9.8.7"
  and .tree_name == "overlay-systemd-9.8.7"
  and .tree_hash == "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  and .runtime == ["overlay-systemd-libs-9.8.7"]
' "${temporary}/systemd-dev.json" >/dev/null

echo "recipe overlay tests passed (14 library splits and systemd_dev)"
