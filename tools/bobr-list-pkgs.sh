#!/usr/bin/env bash

# List attribute names, package names and the original (pre-lowering) recipe tag
# exported by the default package set
# in the package set — use it to pick a build target for `bobr-build.sh`. By
# default it reads `bobr-recipes/recipe-set.ncl`, but you may pass an explicit
# path to another recipe-set-compatible file:
#
#   tools/bobr-list-pkgs.sh
#   tools/bobr-list-pkgs.sh ./recipe-set.ncl

set -euo pipefail

script_path="$(readlink -f "${BASH_SOURCE[0]}")"
recipes_root="$(cd "$(dirname "${script_path}")/.." && pwd)"
default_pkgs="${recipes_root}/recipe-set.ncl"

if [ "$#" -gt 1 ]; then
  echo "usage: $(basename "$0") [recipe-set.ncl]" >&2
  exit 2
fi

pkgs_path="${1:-$default_pkgs}"
pkgs_path="$(realpath "$pkgs_path")"

tmp_ncl="$(mktemp)"
cleanup() {
  rm -f "$tmp_ncl"
}
trap cleanup EXIT

cat > "$tmp_ncl" <<NCL
let mkPkgs = import "$pkgs_path" in
let pkgs = mkPkgs [] in
let attrs = std.array.sort std.string.compare (std.record.fields pkgs) in
std.string.join "\n" (
  std.array.map
    (fun attr =>
      let node = std.record.get attr pkgs in
      let tag = if std.record.has_field "tag" node then node.tag else "?" in
      "%{attr}\t%{node.name}\t%{tag}")
    attrs
) ++ "\n"
NCL

nickel export --format raw "$tmp_ncl"
