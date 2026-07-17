#!/usr/bin/env bash
# Meson build script for the SandboxInstall builder: installs into the live
# read-write overlay root (--prefix=/usr, no DESTDIR) rather than into a staging
# $out. The build's additions become the captured fs-tree layer.
set -euo pipefail

cfg="${BOBR_CONFIG_DIR:?BOBR_CONFIG_DIR is required}"
step="${1:-${BOBR_STEP_NAME:-}}"
step="${step:?step name is required}"
source_dir="${BOBR_SOURCE_DIR:?BOBR_SOURCE_DIR is required}"
build_workspace_dir="${BOBR_BUILD_DIR:?BOBR_BUILD_DIR is required}"
synthetic_common="${BOBR_SYNTHETIC_COMMON:?BOBR_SYNTHETIC_COMMON is required}"

. "$synthetic_common"

load_env_files() {
  if [ -d "${cfg}/env" ]; then
    while IFS= read -r -d '' path; do
      export "$(basename "$path")=$(cat "$path")"
    done < <(find "${cfg}/env" -mindepth 1 -maxdepth 1 -type f -print0 | sort -z)
  fi
}

append_dir_files_to_array() {
  local dir="$1"
  local array_name="$2"
  local -n result_ref="$array_name"
  if [ -d "$dir" ]; then
    while IFS= read -r -d '' path; do
      result_ref+=("$(cat "$path")")
    done < <(find "$dir" -mindepth 1 -maxdepth 1 -type f -print0 | sort -z)
  fi
}

resolve_project_source_dir() {
  local project_source_dir="$source_dir"

  if [ -f "${cfg}/source_subdir" ]; then
    project_source_dir="${source_dir}/$(cat "${cfg}/source_subdir")"
  fi

  if [ ! -d "$project_source_dir" ] || [ ! -f "$project_source_dir/meson.build" ]; then
    echo "meson-install build-script: meson.build not found in ${project_source_dir}" >&2
    exit 1
  fi

  printf '%s\n' "$project_source_dir"
}

resolve_build_dir() {
  printf '%s\n' "${build_workspace_dir}/build"
}

prepare_tmpdir() {
  local cwd="$1"
  mkdir -p "$cwd/.tmp"
  export TMPDIR="${TMPDIR:-$cwd/.tmp}"
}

step_configure() {
  local project_source_dir build_dir
  local setup_args=()
  project_source_dir="$(resolve_project_source_dir)"
  build_dir="$(resolve_build_dir "$project_source_dir")"
  append_dir_files_to_array "${cfg}/setup_args" setup_args
  mkdir -p "$build_dir"
  prepare_tmpdir "$build_dir"
  meson setup "$build_dir" "$project_source_dir" --prefix=/usr "${setup_args[@]}"
}

step_build() {
  local project_source_dir build_dir jobs
  project_source_dir="$(resolve_project_source_dir)"
  build_dir="$(resolve_build_dir "$project_source_dir")"
  prepare_tmpdir "$build_dir"
  jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
  meson compile -C "$build_dir" -j"$jobs"
}

step_install() {
  local project_source_dir build_dir
  project_source_dir="$(resolve_project_source_dir)"
  build_dir="$(resolve_build_dir "$project_source_dir")"
  prepare_tmpdir "$build_dir"
  # Install into the live overlay root (configured --prefix=/usr); the writes
  # land in the overlay upper layer and become the captured fs-tree.
  meson install -C "$build_dir"
}

load_env_files
bobr_prepare_source

case "$step" in
  prepare) : ;;
  configure) step_configure ;;
  build) step_build ;;
  install) step_install ;;
  *)
    echo "meson-install build-script: unsupported step '$step'" >&2
    exit 1
    ;;
esac
