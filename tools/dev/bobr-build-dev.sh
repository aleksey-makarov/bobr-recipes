#!/usr/bin/env bash

# Builds from a source checkout of bobr instead of an installed release.
#
# Usage:
#   tools/dev/bobr-build-dev.sh [--debug] [BUILD ARGS...]
#
#   --debug        build the debug profile (default: release)
#   BUILD ARGS...  passed through to bin/bobr-build.sh
#
# It does two things the user-facing driver deliberately does not: compile the
# binaries from the sibling `bobr` checkout, and refresh the recipes' hash locks.
# Then it runs bin/bobr-build.sh with the fresh binaries in front of PATH, so
# development and everyday use follow the same path -- there is no second build
# driver to keep in step.

set -euo pipefail

die() {
  echo "bobr-build-dev.sh: $*" >&2
  exit 2
}

profile=release
if [ "${1:-}" = "--debug" ]; then
  profile=debug
  shift
fi

script_path="$(readlink -f "${BASH_SOURCE[0]}")"
recipes_path="$(cd "$(dirname "${script_path}")/../.." && pwd)"
bobr_repo="$(cd "${recipes_path}/.." && pwd)/bobr"

[ -d "${bobr_repo}" ] || die "no bobr checkout beside the recipes: ${bobr_repo}"

cargo_args=()
[ "${profile}" = "release" ] && cargo_args+=(--release)

echo "==> cargo build (${profile}) in ${bobr_repo}" >&2
(cd "${bobr_repo}" && cargo build "${cargo_args[@]}")

bin_dir="${bobr_repo}/target/${profile}"
for tool in bobr fsobj-hash; do
  [ -x "${bin_dir}/${tool}" ] || die "cargo did not produce ${bin_dir}/${tool}"
done

# Refreshing the locks belongs here rather than in the user-facing driver: this
# is the path taken while editing recipes, and it is the only one allowed to
# write into the recipes tree.
echo "==> refreshing fsobj-hash locks" >&2
"${recipes_path}/bin/bobr-update-fsobj-hashes.sh" --fsobj-hash="${bin_dir}/fsobj-hash"

PATH="${bin_dir}:${PATH}" exec "${recipes_path}/bin/bobr-build.sh" "$@"
