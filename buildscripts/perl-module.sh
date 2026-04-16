#!/usr/bin/env bash
set -euo pipefail

cfg="${MBUILD_SCRIPT_CONFIG_DIR:?MBUILD_SCRIPT_CONFIG_DIR is required}"
phase="${1:-${MBUILD_STEP_NAME:-}}"
phase="${phase:?step name is required}"
source_dir="${MBUILD_SOURCE_DIR:?MBUILD_SOURCE_DIR is required}"
install_dir="${MBUILD_INSTALL_DIR:?MBUILD_INSTALL_DIR is required}"

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

resolve_source_dir() {
  if [ -f "$source_dir/Makefile.PL" ]; then
    printf '%s\n' "$source_dir"
    return
  fi

  local candidates=()
  local d
  for d in "$source_dir"/*; do
    if [ -d "$d" ] && [ -f "$d/Makefile.PL" ]; then
      candidates+=("$d")
    fi
  done
  if [ "${#candidates[@]}" -eq 1 ]; then
    printf '%s\n' "${candidates[0]}"
    return
  fi

  echo "perl-module build-script: Makefile.PL not found in ${source_dir}" >&2
  exit 1
}

prepare_tmpdir() {
  local cwd="$1"
  mkdir -p "$cwd/.tmp"
  export TMPDIR="${TMPDIR:-$cwd/.tmp}"
}

phase_configure() {
  local project_source_dir
  local perl_args=()
  project_source_dir="$(resolve_source_dir)"
  cd "$project_source_dir"
  prepare_tmpdir "$project_source_dir"
  if [ -f "${cfg}/pre_configure" ]; then
    source "${cfg}/pre_configure"
  fi
  append_dir_files_to_array "${cfg}/perl_args" perl_args
  perl Makefile.PL "${perl_args[@]}"
}

phase_build() {
  local project_source_dir jobs
  local make_args=()
  project_source_dir="$(resolve_source_dir)"
  cd "$project_source_dir"
  prepare_tmpdir "$project_source_dir"
  append_dir_files_to_array "${cfg}/make_args" make_args
  jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
  make -j"$jobs" "${make_args[@]}"
}

phase_install() {
  local project_source_dir
  local make_args=()
  project_source_dir="$(resolve_source_dir)"
  cd "$project_source_dir"
  prepare_tmpdir "$project_source_dir"
  append_dir_files_to_array "${cfg}/make_args" make_args
  mkdir -p "$install_dir"
  make DESTDIR="$install_dir" "${make_args[@]}" install
}

phase_post_install() {
  local project_source_dir
  project_source_dir="$(resolve_source_dir)"
  cd "$project_source_dir"
  prepare_tmpdir "$project_source_dir"
  if [ -f "${cfg}/post_install" ]; then
    source "${cfg}/post_install"
  fi
}

load_env_files

case "$phase" in
  configure) phase_configure ;;
  build) phase_build ;;
  install) phase_install ;;
  post_install) phase_post_install ;;
  *)
    echo "perl-module build-script: unsupported phase '$phase'" >&2
    exit 1
    ;;
esac
