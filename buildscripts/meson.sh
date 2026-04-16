#!/usr/bin/env bash
set -euo pipefail

cfg="${MBUILD_SCRIPT_CONFIG_DIR:?MBUILD_SCRIPT_CONFIG_DIR is required}"
phase="${MBUILD_PHASE:?MBUILD_PHASE is required}"
source_dir="${MBUILD_SOURCE_DIR:-}"
install_dir="${MBUILD_INSTALL_DIR:-}"
default_build_dir="${MBUILD_BUILD_DIR:-}"
meson_src_dir="/in/sources1"

source_dir="${MBUILD_SOURCE_DIR:?MBUILD_SOURCE_DIR is required}"
install_dir="${MBUILD_INSTALL_DIR:?MBUILD_INSTALL_DIR is required}"
default_build_dir="${default_build_dir:-$source_dir/build}"

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
  if [ -f "$source_dir/meson.build" ]; then
    printf '%s\n' "$source_dir"
    return
  fi

  local candidates=()
  local d
  for d in "$source_dir"/*; do
    if [ -d "$d" ] && [ -f "$d/meson.build" ]; then
      candidates+=("$d")
    fi
  done

  if [ "${#candidates[@]}" -eq 1 ]; then
    printf '%s\n' "${candidates[0]}"
    return
  fi

  echo "meson build-script: meson.build not found (or ambiguous) in ${source_dir}" >&2
  exit 1
}

resolve_meson_command() {
  if [ ! -f "${meson_src_dir}/meson.py" ]; then
    local candidates=()
    local d
    for d in "${meson_src_dir}"/*; do
      if [ -d "$d" ] && [ -f "$d/meson.py" ]; then
        candidates+=("$d")
      fi
    done
    if [ "${#candidates[@]}" -eq 1 ]; then
      meson_src_dir="${candidates[0]}"
    fi
  fi

  if [ -f "${meson_src_dir}/meson.py" ]; then
    printf 'python3\n%s\n' "${meson_src_dir}/meson.py"
  else
    printf 'meson\n'
  fi
}

resolve_build_dir() {
  local project_source_dir="$1"
  if [ -f "${cfg}/build_dir" ]; then
    local configured_build_dir
    configured_build_dir="$(cat "${cfg}/build_dir")"
    if [[ "$configured_build_dir" = /* ]]; then
      printf '%s\n' "$configured_build_dir"
    else
      printf '%s\n' "$project_source_dir/$configured_build_dir"
    fi
  else
    printf '%s\n' "$default_build_dir"
  fi
}

prepare_tmpdir() {
  local cwd="$1"
  mkdir -p "$cwd/.tmp"
  export TMPDIR="${TMPDIR:-$cwd/.tmp}"
}

phase_configure() {
  local project_source_dir build_dir
  local setup_args=()
  local meson_cmd=()
  project_source_dir="$(resolve_project_source_dir)"
  build_dir="$(resolve_build_dir "$project_source_dir")"
  cd "$project_source_dir"
  prepare_tmpdir "$project_source_dir"
  if [ -f "${cfg}/pre_configure" ]; then
    source "${cfg}/pre_configure"
  fi
  append_dir_files_to_array "${cfg}/setup_args" setup_args
  mapfile -t meson_cmd < <(resolve_meson_command)
  mkdir -p "$build_dir"
  prepare_tmpdir "$build_dir"
  "${meson_cmd[@]}" setup "$build_dir" "$project_source_dir" --prefix=/usr "${setup_args[@]}"
}

phase_build() {
  local project_source_dir build_dir jobs
  local meson_cmd=()
  project_source_dir="$(resolve_project_source_dir)"
  build_dir="$(resolve_build_dir "$project_source_dir")"
  prepare_tmpdir "$build_dir"
  mapfile -t meson_cmd < <(resolve_meson_command)
  jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
  "${meson_cmd[@]}" compile -C "$build_dir" -j"$jobs"
}

phase_install() {
  local project_source_dir build_dir
  local meson_cmd=()
  project_source_dir="$(resolve_project_source_dir)"
  build_dir="$(resolve_build_dir "$project_source_dir")"
  prepare_tmpdir "$build_dir"
  mapfile -t meson_cmd < <(resolve_meson_command)
  mkdir -p "$install_dir"
  DESTDIR="$install_dir" "${meson_cmd[@]}" install -C "$build_dir"
}

phase_post_install() {
  local project_source_dir build_dir
  project_source_dir="$(resolve_project_source_dir)"
  build_dir="$(resolve_build_dir "$project_source_dir")"
  cd "$build_dir"
  prepare_tmpdir "$build_dir"
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
    echo "meson build-script: unsupported phase '$phase'" >&2
    exit 1
    ;;
esac
