#!/usr/bin/env bash
set -euo pipefail

cfg="${MBUILD_CONFIG_DIR:?MBUILD_CONFIG_DIR is required}"
step="${1:-${MBUILD_STEP_NAME:-}}"
step="${step:?step name is required}"
source_dir="${MBUILD_SOURCE_DIR:?MBUILD_SOURCE_DIR is required}"
out_dir="${MBUILD_OUT_DIR:?MBUILD_OUT_DIR is required}"

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

prepare_tmpdir() {
  local cwd="$1"
  mkdir -p "$cwd/.tmp"
  export TMPDIR="${TMPDIR:-$cwd/.tmp}"
}

step_build() {
  local jobs
  local make_args=()
  cd "$source_dir"
  prepare_tmpdir "$source_dir"
  append_dir_files_to_array "${cfg}/make_args" make_args
  jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
  make -j"$jobs" "${make_args[@]}"
}

step_install() {
  local skip_install
  local make_args=()
  cd "$source_dir"
  prepare_tmpdir "$source_dir"
  append_dir_files_to_array "${cfg}/make_args" make_args
  mkdir -p "$out_dir"
  skip_install="false"
  if [ -f "${cfg}/skip_install" ]; then
    skip_install="$(cat "${cfg}/skip_install")"
  fi
  if [ "$skip_install" != "true" ]; then
    make DESTDIR="$out_dir" "${make_args[@]}" install
  fi
}

step_post_install() {
  :
}

load_env_files

case "$step" in
  build) step_build ;;
  install) step_install ;;
  post_install) step_post_install ;;
  *)
    echo "gnu-make build-script: unsupported step '$step'" >&2
    exit 1
    ;;
esac
