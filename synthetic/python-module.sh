#!/usr/bin/env bash
# Python-module build script for the SandboxInstall builder: builds a wheel from
# the module source and installs it into the live read-write overlay root
# (pip install --prefix /usr, no --root) rather than a staging $out. The install
# additions become the captured fs-tree layer.
#
# pip runs with --no-build-isolation --no-deps, so the PEP 517 build backend
# (flit_core / setuptools / hatchling / ...) must already be present in the
# build rootfs via deps.build. flit_core bootstraps itself from its own source
# (its pyproject sets backend-path = ["."]).
set -euo pipefail

cfg="${BOBR_CONFIG_DIR:?BOBR_CONFIG_DIR is required}"
step="${1:-${BOBR_STEP_NAME:-}}"
step="${step:?step name is required}"
source_dir="${BOBR_SOURCE_DIR:?BOBR_SOURCE_DIR is required}"
build_workspace_dir="${BOBR_BUILD_DIR:?BOBR_BUILD_DIR is required}"
synthetic_common="${BOBR_SYNTHETIC_COMMON:?BOBR_SYNTHETIC_COMMON is required}"

. "$synthetic_common"

wheel_dir="${build_workspace_dir}/python-wheel"

load_env_files() {
  if [ -d "${cfg}/env" ]; then
    while IFS= read -r -d '' path; do
      export "$(basename "$path")=$(cat "$path")"
    done < <(find "${cfg}/env" -mindepth 1 -maxdepth 1 -type f -print0 | sort -z)
  fi
}

resolve_project_source_dir() {
  local project_source_dir="$source_dir"

  if [ -f "${cfg}/source_subdir" ]; then
    project_source_dir="${source_dir}/$(cat "${cfg}/source_subdir")"
  fi

  if [ ! -d "$project_source_dir" ]; then
    echo "python-module build-script: project source dir is not a directory: ${project_source_dir}" >&2
    exit 1
  fi
  if [ ! -f "$project_source_dir/pyproject.toml" ] && [ ! -f "$project_source_dir/setup.py" ]; then
    echo "python-module build-script: no pyproject.toml or setup.py in ${project_source_dir}" >&2
    exit 1
  fi

  printf '%s\n' "$project_source_dir"
}

prepare_tmpdir() {
  local cwd="$1"
  mkdir -p "$cwd/.tmp"
  export TMPDIR="${TMPDIR:-$cwd/.tmp}"
}

step_build() {
  local project_source_dir
  project_source_dir="$(resolve_project_source_dir)"
  prepare_tmpdir "$build_workspace_dir"
  rm -rf "$wheel_dir"
  mkdir -p "$wheel_dir"
  # Build only this module's wheel; the backend comes from the build rootfs.
  python3 -m pip wheel -w "$wheel_dir" --no-cache-dir --no-build-isolation --no-deps "$project_source_dir"
}

step_install() {
  # Install into the live overlay root (--prefix /usr, no --root); the writes
  # land in the overlay upper layer and become the captured fs-tree.
  python3 -m pip install --no-deps --no-index --ignore-installed \
    --no-warn-script-location --prefix /usr "$wheel_dir"/*.whl
}

load_env_files
bobr_prepare_source

case "$step" in
  prepare) : ;;
  configure) : ;;
  build) step_build ;;
  install) step_install ;;
  *)
    echo "python-module build-script: unsupported step '$step'" >&2
    exit 1
    ;;
esac
