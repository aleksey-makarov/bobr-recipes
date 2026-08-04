#!/usr/bin/env bash

# Pull both bobr repositories, (re)build the bobr binaries, then rebuild the
# world into a fresh store via bobr-recipes/tools/bobr-rebuild-world.sh.
#
# All arguments are forwarded to bobr-rebuild-world.sh.
# Usage: rebuild-world.sh [--jobs N] [--podman-unshare] [pkgs-attr]

set -euo pipefail

workspace_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bobr_repo="${workspace_root}/bobr"
recipes_repo="${workspace_root}/bobr-recipes"
rebuild_world="${recipes_repo}/tools/bobr-rebuild-world.sh"

case "${1:-}" in
  -h | --help)
    echo "usage: $0 [--jobs N] [--podman-unshare] [pkgs-attr]" >&2
    echo "Pulls both repos, rebuilds bobr, then runs bobr-rebuild-world.sh." >&2
    exit 0
    ;;
esac

for repo in "${bobr_repo}" "${recipes_repo}"; do
  if [ ! -d "${repo}/.git" ]; then
    echo "rebuild-world.sh: missing git repository: ${repo}" >&2
    exit 2
  fi
done
if [ ! -x "${rebuild_world}" ]; then
  echo "rebuild-world.sh: missing bobr-rebuild-world.sh: ${rebuild_world}" >&2
  exit 2
fi
case "$(uname -m)" in
  x86_64)
    sandbox_launcher_alias="build-sandbox-launcher-x86_64"
    ;;
  aarch64)
    sandbox_launcher_alias="build-sandbox-launcher-aarch64"
    ;;
  *)
    echo "rebuild-world.sh: unsupported host architecture: $(uname -m)" >&2
    exit 2
    ;;
esac

echo "==> pull bobr" >&2
git -C "${bobr_repo}" pull --ff-only

echo "==> pull bobr-recipes" >&2
git -C "${recipes_repo}" pull --ff-only

echo "==> build bobr binaries" >&2
(
  cd "${bobr_repo}"
  cargo build --release
  cargo "${sandbox_launcher_alias}" --release
)

echo "==> rebuild world" >&2
exec "${rebuild_world}" "$@"
