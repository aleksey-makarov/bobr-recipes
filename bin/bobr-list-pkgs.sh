#!/usr/bin/env bash

# Lists what there is to build: attribute name, recipe name, and the original
# (pre-lowering) tag, one per line. Use it to pick a target for bobr-build.sh.
#
# Usage:
#   bobr-list-pkgs.sh [PROFILE.ncl]
#
#   PROFILE.ncl   a build profile (default: ./bobr.ncl, if it exists)
#
# It reads the same profile the build driver does and applies its overlays, so
# the list is what would actually be built, not the untouched recipes. Without a
# profile it falls back to the plain recipe set.

set -euo pipefail

die() {
  echo "bobr-list-pkgs.sh: $*" >&2
  exit 2
}

script_path="$(readlink -f "${BASH_SOURCE[0]}")"
recipes_root="$(cd "$(dirname "${script_path}")/.." && pwd)"

[ "$#" -le 1 ] || die "usage: $(basename "$0") [PROFILE.ncl]"

profile_path="${1:-bobr.ncl}"
if [ -e "${profile_path}" ]; then
  profile_path="$(realpath -e -- "${profile_path}")"
elif [ "$#" -ge 1 ]; then
  die "no build profile at '${1}'"
else
  profile_path=""
fi

overlays_expr="[]"
if [ -n "${profile_path}" ]; then
  profile_dir="$(dirname "${profile_path}")"
  overlays_expr="$(
    nickel export --format raw <<EOF_OVERLAYS || die "invalid build profile '${profile_path}'"
let contracts = import "${recipes_root}/build-profile.ncl" in
let profile | contracts.Profile = import "${profile_path}" in
let absolute = fun path =>
  if std.string.is_match "^/" path then path else "${profile_dir}/" ++ path
in
if std.array.length profile.overlays == 0 then
  "[]"
else
  "(std.array.flatten (std.array.map (fun o => if std.is_function o then [o] else o) ["
  ++ std.string.join ", " (std.array.map (fun p => "import \"" ++ absolute p ++ "\"") profile.overlays)
  ++ "]))"
EOF_OVERLAYS
  )"
fi

nickel export --format raw <<EOF_LIST
let mkPkgs = import "${recipes_root}/recipe-set.ncl" in
let pkgs = mkPkgs ${overlays_expr} in
let attrs = std.array.sort std.string.compare (std.record.fields pkgs) in
std.string.join "\n" (
  std.array.map
    (fun attr =>
      let node = std.record.get attr pkgs in
      let tag = if std.record.has_field "tag" node then node.tag else "?" in
      "%{attr}\t%{node.name}\t%{tag}")
    attrs
) ++ "\n"
EOF_LIST
