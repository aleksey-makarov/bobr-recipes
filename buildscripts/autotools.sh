#!/usr/bin/env bash
set -euo pipefail

cfg="${MBUILD_SCRIPT_CONFIG_DIR:?MBUILD_SCRIPT_CONFIG_DIR is required}"
phase="${MBUILD_PHASE:?MBUILD_PHASE is required}"
source_dir="${MBUILD_SOURCE_DIR:?MBUILD_SOURCE_DIR is required}"
install_dir="${MBUILD_INSTALL_DIR:?MBUILD_INSTALL_DIR is required}"
default_build_dir="${MBUILD_BUILD_DIR:-$source_dir/build}"

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
  if [ -x "$source_dir/configure" ]; then
    printf '%s\n' "$source_dir"
    return
  fi

  local candidates=()
  local d
  for d in "$source_dir"/*; do
    if [ -d "$d" ] && [ -x "$d/configure" ]; then
      candidates+=("$d")
    fi
  done

  if [ "${#candidates[@]}" -eq 1 ]; then
    printf '%s\n' "${candidates[0]}"
    return
  fi

  echo "autotools build-script: ./configure not found in ${source_dir}" >&2
  exit 1
}

resolve_build_layout() {
  if [ -f "${cfg}/build_layout" ]; then
    cat "${cfg}/build_layout"
  else
    printf 'out-of-tree\n'
  fi
}

resolve_build_dir() {
  local project_source_dir="$1"
  local layout="$2"
  if [ "$layout" = "in-tree" ]; then
    printf '%s\n' "$project_source_dir"
    return
  fi
  if [ -f "${cfg}/build_dir" ]; then
    local configured_build_dir
    configured_build_dir="$(cat "${cfg}/build_dir")"
    if [[ "$configured_build_dir" = /* ]]; then
      printf '%s\n' "$configured_build_dir"
    else
      printf '%s\n' "$project_source_dir/$configured_build_dir"
    fi
    return
  fi
  printf '%s\n' "$default_build_dir"
}

prepare_tmpdir() {
  local cwd="$1"
  mkdir -p "$cwd/.tmp"
  export TMPDIR="${TMPDIR:-$cwd/.tmp}"
}

phase_configure() {
  local project_source_dir layout build_dir configure_cmd
  local configure_args=()
  project_source_dir="$(resolve_project_source_dir)"
  layout="$(resolve_build_layout)"
  build_dir="$(resolve_build_dir "$project_source_dir" "$layout")"

  cd "$project_source_dir"
  prepare_tmpdir "$project_source_dir"
  if [ -f "${cfg}/pre_configure" ]; then
    source "${cfg}/pre_configure"
  fi

  append_dir_files_to_array "${cfg}/configure_args" configure_args
  configure_cmd="$project_source_dir/configure"
  if [ "$layout" = "out-of-tree" ]; then
    mkdir -p "$build_dir"
    cd "$build_dir"
    prepare_tmpdir "$build_dir"
  else
    cd "$project_source_dir"
  fi

  "$configure_cmd" --prefix=/usr "${configure_args[@]}"
}

phase_build() {
  local project_source_dir layout build_dir jobs
  local make_args=()
  project_source_dir="$(resolve_project_source_dir)"
  layout="$(resolve_build_layout)"
  build_dir="$(resolve_build_dir "$project_source_dir" "$layout")"
  cd "$build_dir"
  prepare_tmpdir "$build_dir"
  append_dir_files_to_array "${cfg}/make_args" make_args
  jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
  make -j"$jobs" "${make_args[@]}"
}

phase_install() {
  local project_source_dir layout build_dir
  local make_args=()
  project_source_dir="$(resolve_project_source_dir)"
  layout="$(resolve_build_layout)"
  build_dir="$(resolve_build_dir "$project_source_dir" "$layout")"
  cd "$build_dir"
  prepare_tmpdir "$build_dir"
  append_dir_files_to_array "${cfg}/make_args" make_args
  mkdir -p "$install_dir"
  make DESTDIR="$install_dir" "${make_args[@]}" install
}

phase_post_install() {
  local project_source_dir layout build_dir
  project_source_dir="$(resolve_project_source_dir)"
  layout="$(resolve_build_layout)"
  build_dir="$(resolve_build_dir "$project_source_dir" "$layout")"
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
    echo "autotools build-script: unsupported phase '$phase'" >&2
    exit 1
    ;;
esac
