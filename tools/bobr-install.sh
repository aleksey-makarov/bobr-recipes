#!/usr/bin/env bash

# Installs the bobr host tools into <workspace>/bobr-bin.
#
# Usage: bobr-install.sh [--src | --potato]
#
#   no option  install the latest published GitHub release
#   --src      build the HEAD of the public GitHub repository locally
#   --potato   build the HEAD of potato:/mnt/git/bobr.git locally
#
# Source builds share the script-owned <workspace>/bobr-bin/src checkout and
# its Cargo target directory. The installed bin/ directory is replaced only
# after a complete release download or source build has succeeded.

set -euo pipefail

die() {
  echo "bobr-install.sh: $*" >&2
  exit 2
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "required tool not found on PATH: $1"
}

mode=release
mode_selected=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --src)
      [ "${mode_selected}" -eq 0 ] || die "source mode specified more than once"
      mode=github
      mode_selected=1
      shift
      ;;
    --potato)
      [ "${mode_selected}" -eq 0 ] || die "source mode specified more than once"
      mode=potato
      mode_selected=1
      shift
      ;;
    -h | --help)
      sed -n '3,13p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2
      exit 0
      ;;
    *) die "unexpected argument: $1" ;;
  esac
done

script_path="$(readlink -f "${BASH_SOURCE[0]}")"
recipes_repo="$(cd "$(dirname "${script_path}")/.." && pwd)"
workspace_root="$(cd "${recipes_repo}/.." && pwd)"
bobr_root="${workspace_root}/bobr-bin"
bin_dir="${bobr_root}/bin"
source_dir="${bobr_root}/src"
commit_file="${bobr_root}/commit.txt"

github_repo="https://github.com/aleksey-makarov/bobr.git"
github_api="https://api.github.com/repos/aleksey-makarov/bobr"
potato_repo="potato:/mnt/git/bobr.git"
required_binaries=(bobr fsobj-hash bobr-sandbox-launcher)

[ -d "${recipes_repo}/.git" ] || die "missing git repository: ${recipes_repo}"

mkdir -p "${bobr_root}"
stage="$(mktemp -d "${bobr_root}/.install.XXXXXX")"
new_bin=""
old_bin=""
bin_replaced=0
install_complete=0

cleanup() {
  local status=$?
  if [ "${install_complete}" -eq 0 ] && [ "${bin_replaced}" -eq 1 ]; then
    rm -rf -- "${bin_dir}"
    if [ -n "${old_bin}" ] && [ -e "${old_bin}" ]; then
      mv -- "${old_bin}" "${bin_dir}"
    fi
  fi
  [ -z "${new_bin}" ] || rm -rf -- "${new_bin}"
  rm -f -- "${bobr_root}/.commit.new.$$"
  rm -rf -- "${stage}"
  exit "${status}"
}
trap cleanup EXIT

validate_commit() {
  local commit="$1"
  [[ "${commit}" =~ ^[0-9a-f]{40}$ || "${commit}" =~ ^[0-9a-f]{64}$ ]] \
    || die "invalid Git commit '${commit}'"
}

validate_staged_bin() {
  local staged_bin="$1" binary
  for binary in "${required_binaries[@]}"; do
    [ -x "${staged_bin}/${binary}" ] \
      || die "installation did not produce executable ${binary}"
  done
  "${staged_bin}/bobr" --version >&2
  "${staged_bin}/fsobj-hash" --help >/dev/null
  "${staged_bin}/bobr-sandbox-launcher" --protocol-info >/dev/null
}

resolve_release_commit() {
  local tag="$1" ref object_type object_sha
  ref="$(curl -fsSL "${github_api}/git/ref/tags/${tag}")" \
    || die "cannot resolve the tag ${tag}"
  object_type="$(printf '%s' "${ref}" | jq -r '.object.type')"
  object_sha="$(printf '%s' "${ref}" | jq -r '.object.sha')"
  if [ "${object_type}" = "tag" ]; then
    object_sha="$(
      curl -fsSL "${github_api}/git/tags/${object_sha}" | jq -r '.object.sha'
    )" || die "cannot dereference the annotated tag ${tag}"
  fi
  validate_commit "${object_sha}"
  printf '%s\n' "${object_sha}"
}

obtain_release() {
  require_cmd curl
  require_cmd jq
  require_cmd sha256sum
  require_cmd tar

  local host_target
  case "$(uname -m)" in
    x86_64) host_target="x86_64-unknown-linux-musl" ;;
    *)
      die "no published bobr archive for $(uname -m); use --src or --potato"
      ;;
  esac

  local latest tag commit archive download_dir download unpacked binary
  latest="$(curl -fsSL "${github_api}/releases/latest")" \
    || die "cannot reach the GitHub release API"
  tag="$(printf '%s' "${latest}" | jq -r '.tag_name')"
  [ -n "${tag}" ] && [ "${tag}" != "null" ] \
    || die "the latest release has no tag"
  commit="$(resolve_release_commit "${tag}")"

  archive="bobr-${tag}-${host_target}.tar.xz"
  download="https://github.com/aleksey-makarov/bobr/releases/download/${tag}"
  download_dir="${stage}/download"
  mkdir "${download_dir}"

  echo "==> download bobr ${tag}" >&2
  curl -fsSL -o "${download_dir}/${archive}" "${download}/${archive}" \
    || die "cannot download ${archive}"
  curl -fsSL -o "${download_dir}/SHA256SUMS" "${download}/SHA256SUMS" \
    || die "cannot download SHA256SUMS for ${tag}"
  (
    cd "${download_dir}"
    awk -v archive="${archive}" '
      $2 == archive || $2 == "./" archive { print; found = 1 }
      END { if (!found) exit 1 }
    ' SHA256SUMS | sha256sum -c --quiet -
  ) || die "checksum mismatch for ${archive}"

  tar -C "${download_dir}" -xf "${download_dir}/${archive}"
  unpacked="${download_dir}/bobr-${tag}-${host_target}"
  [ -d "${unpacked}/bin" ] || die "unexpected archive layout in ${archive}"
  mkdir "${stage}/bin"
  for binary in "${unpacked}/bin"/*; do
    [ -f "${binary}" ] || continue
    install -m755 "${binary}" "${stage}/bin/$(basename "${binary}")"
  done
  printf '%s\n' "${commit}" > "${stage}/commit.txt"
}

obtain_source() {
  local source_url="$1" source_name="$2" commit
  require_cmd git

  if [ -e "${source_dir}" ] && [ ! -d "${source_dir}/.git" ]; then
    die "source path exists but is not a Git checkout: ${source_dir}"
  fi
  if [ ! -d "${source_dir}/.git" ]; then
    mkdir -p "${source_dir}"
    git -C "${source_dir}" init --quiet
  fi

  echo "==> fetch bobr HEAD from ${source_name}" >&2
  git -C "${source_dir}" fetch --depth=1 "${source_url}" HEAD
  git -C "${source_dir}" -c advice.detachedHead=false \
    checkout --detach --force FETCH_HEAD
  git -C "${source_dir}" clean -fd
  commit="$(git -C "${source_dir}" rev-parse HEAD)"
  validate_commit "${commit}"

  echo "==> build bobr ${commit} from ${source_name}" >&2
  BOBR_DEV_BIN="${stage}/bin" "${source_dir}/tools/build-dev.sh" --quick
  printf '%s\n' "${commit}" > "${stage}/commit.txt"
}

case "${mode}" in
  release) obtain_release ;;
  github) obtain_source "${github_repo}" GitHub ;;
  potato) obtain_source "${potato_repo}" potato ;;
esac

validate_staged_bin "${stage}/bin"
commit="$(tr -d '[:space:]' < "${stage}/commit.txt")"
validate_commit "${commit}"

# Replace the installed set as one directory. The source checkout is outside
# bin/ and remains available as a build cache across release and source modes.
new_bin="${bobr_root}/.bin.new.$$"
old_bin="${bobr_root}/.bin.old.$$"
mv -- "${stage}/bin" "${new_bin}"
printf '%s\n' "${commit}" > "${bobr_root}/.commit.new.$$"
if [ -e "${bin_dir}" ] || [ -L "${bin_dir}" ]; then
  mv -- "${bin_dir}" "${old_bin}"
fi
mv -- "${new_bin}" "${bin_dir}"
new_bin=""
bin_replaced=1
mv -- "${bobr_root}/.commit.new.$$" "${commit_file}"
install_complete=1
rm -rf -- "${old_bin}"
old_bin=""

echo "==> installed bobr ${commit} into ${bin_dir}" >&2
