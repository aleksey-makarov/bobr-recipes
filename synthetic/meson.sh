#!/usr/bin/env bash
set -euo pipefail

cfg="${BOBR_CONFIG_DIR:?BOBR_CONFIG_DIR is required}"
step="${1:-${BOBR_STEP_NAME:-}}"
step="${step:?step name is required}"
source_dir="${MBUILD_SOURCE_DIR:?MBUILD_SOURCE_DIR is required}"
out_dir="${BOBR_OUT_DIR:?BOBR_OUT_DIR is required}"
build_workspace_dir="${BOBR_BUILD_DIR:?BOBR_BUILD_DIR is required}"
synthetic_common="${MBUILD_SYNTHETIC_COMMON:?MBUILD_SYNTHETIC_COMMON is required}"

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
    echo "meson build-script: meson.build not found in ${project_source_dir}" >&2
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
  mkdir -p "$out_dir"
  DESTDIR="$out_dir" meson install -C "$build_dir"
}

load_env_files
mbuild_prepare_source

case "$step" in
  prepare) : ;;
  configure) step_configure ;;
  build) step_build ;;
  install) step_install ;;
  *)
    echo "meson build-script: unsupported step '$step'" >&2
    exit 1
    ;;
esac
