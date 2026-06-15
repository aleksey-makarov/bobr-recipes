#!/usr/bin/env bash
set -euo pipefail

cfg="${MBUILD_CONFIG_DIR:?MBUILD_CONFIG_DIR is required}"
step="${1:-${MBUILD_STEP_NAME:-}}"
step="${step:?step name is required}"
source_dir="${MBUILD_SOURCE_DIR:?MBUILD_SOURCE_DIR is required}"
out_dir="${MBUILD_OUT_DIR:?MBUILD_OUT_DIR is required}"
build_workspace_dir="${MBUILD_BUILD_DIR:?MBUILD_BUILD_DIR is required}"
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
  local source_subdir=""

  if [ ! -d "$source_dir" ]; then
    echo "autotools build-script: source input is not a directory: ${source_dir}" >&2
    exit 1
  fi

  if [ -f "${cfg}/source_subdir" ]; then
    source_subdir="$(cat "${cfg}/source_subdir")"
    case "$source_subdir" in
      ""|/*|*"/../"*|../*|*"./"*|*"/.."|"..")
        echo "autotools build-script: invalid source_subdir '${source_subdir}'" >&2
        exit 1
        ;;
    esac
  fi

  local project_source_dir="$source_dir"
  if [ -n "$source_subdir" ]; then
    project_source_dir="${source_dir}/${source_subdir}"
  fi

  if [ ! -d "$project_source_dir" ]; then
    echo "autotools build-script: project source dir is not a directory: ${project_source_dir}" >&2
    exit 1
  fi

  if [ ! -x "$project_source_dir/configure" ]; then
    echo "autotools build-script: ./configure not found in ${project_source_dir}" >&2
    exit 1
  fi

  printf '%s\n' "$project_source_dir"
}

resolve_in_tree() {
  if [ ! -f "${cfg}/in-tree" ]; then
    return 1
  fi

  case "$(cat "${cfg}/in-tree")" in
    true|1|yes|on) return 0 ;;
    false|0|no|off|"") return 1 ;;
    *)
      echo "autotools build-script: invalid boolean in ${cfg}/in-tree" >&2
      exit 1
      ;;
  esac
}

resolve_build_dir() {
  local project_source_dir="$1"
  if resolve_in_tree; then
    printf '%s\n' "$project_source_dir"
    return
  fi
  printf '%s\n' "${build_workspace_dir}/build"
}

prepare_tmpdir() {
  local cwd="$1"
  mkdir -p "$cwd/.tmp"
  export TMPDIR="${TMPDIR:-$cwd/.tmp}"
}

step_configure() {
  local project_source_dir build_dir configure_cmd
  local configure_args=()
  project_source_dir="$(resolve_project_source_dir)"
  build_dir="$(resolve_build_dir "$project_source_dir")"

  cd "$project_source_dir"
  prepare_tmpdir "$project_source_dir"

  append_dir_files_to_array "${cfg}/configure_args" configure_args
  configure_cmd="$project_source_dir/configure"
  if [ "$build_dir" != "$project_source_dir" ]; then
    mkdir -p "$build_dir"
    cd "$build_dir"
    prepare_tmpdir "$build_dir"
  else
    cd "$project_source_dir"
  fi

  "$configure_cmd" --prefix=/usr "${configure_args[@]}"
}

step_build() {
  local project_source_dir build_dir jobs
  local make_args=()
  project_source_dir="$(resolve_project_source_dir)"
  build_dir="$(resolve_build_dir "$project_source_dir")"
  cd "$build_dir"
  prepare_tmpdir "$build_dir"
  append_dir_files_to_array "${cfg}/make_args" make_args
  jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
  make -j"$jobs" "${make_args[@]}"
}

step_install() {
  local project_source_dir build_dir
  local make_args=()
  project_source_dir="$(resolve_project_source_dir)"
  build_dir="$(resolve_build_dir "$project_source_dir")"
  cd "$build_dir"
  prepare_tmpdir "$build_dir"
  append_dir_files_to_array "${cfg}/make_args" make_args
  mkdir -p "$out_dir"
  make DESTDIR="$out_dir" "${make_args[@]}" install
}

load_env_files
export ARFLAGS="${ARFLAGS:-crD}"
export RANLIB="${RANLIB:-ranlib -D}"
mbuild_prepare_source

case "$step" in
  prepare) : ;;
  configure) step_configure ;;
  build) step_build ;;
  install) step_install ;;
  *)
    echo "autotools build-script: unsupported step '$step'" >&2
    exit 1
    ;;
esac
