#!/usr/bin/env bash

# List attribute names exported by the default package set in `pkgs.ncl`.
# By default this uses `mbuild-recipes/pkgs.ncl`, but you may pass an explicit
# path to another `pkgs.ncl`-compatible file:
#
#   tools/list-pkgs-attrs.sh
#   tools/list-pkgs-attrs.sh ./pkgs.ncl

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
recipes_root="$(cd "${script_dir}/.." && pwd)"
default_pkgs="${recipes_root}/pkgs.ncl"

if [ "$#" -gt 1 ]; then
  echo "usage: $(basename "$0") [pkgs.ncl]" >&2
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
    (fun attr => "%{attr}\t%{(std.record.get attr pkgs).name}")
    attrs
) ++ "\n"
NCL

nickel export --format raw "$tmp_ncl"
