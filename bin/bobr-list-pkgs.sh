#!/usr/bin/env bash

# Lists what there is to build: attribute name, recipe name, and the original
# (pre-lowering) tag, one per line. Use it to pick a target for bobr-build.sh.
#
# Usage:
#   bobr-list-pkgs.sh [PROFILE.ncl]
#
#   PROFILE.ncl   a build profile (default: ./bobr.ncl, if it exists)
#
# It reads the same final package set as the build driver. Without a profile it
# falls back to `bobrpkgs []`.

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

if [ -n "${profile_path}" ]; then
  pkgs_expr="$(cat <<EOF_PKGS
let contracts = import "${recipes_root}/build-profile/build-profile.ncl" in
let profile | contracts.Profile = import "${profile_path}" in profile.pkgs
EOF_PKGS
)"
else
  pkgs_expr="(import \"${recipes_root}/bobrpkgs.ncl\") []"
fi

nickel export --format raw <<EOF_LIST
let pkgs = ${pkgs_expr} in
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
