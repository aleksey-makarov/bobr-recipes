#!/usr/bin/env bash
# CMake build script for the Cmake builder (SandboxInstall model): installs into
# the live read-write overlay root (-DCMAKE_INSTALL_PREFIX=/usr, then `make
# install` with no DESTDIR). The build's additions become the captured fs-tree
# layer.
#
# In-source build (cmake -S . -B .), matching what these recipes did when they
# ran cmake by hand through the Makefile builder. The universal flags
# (-DCMAKE_INSTALL_PREFIX=/usr, -DCMAKE_BUILD_TYPE=Release) are baked in;
# per-project flags come from cmake_args, and the build/install `make` steps
# honour make_args (e.g. -j1). CMake's default generator on Linux is "Unix
# Makefiles", so the build and install steps drive plain `make`.
set -euo pipefail

cfg="${BOBR_CONFIG_DIR:?BOBR_CONFIG_DIR is required}"
step="${1:-${BOBR_STEP_NAME:-}}"
step="${step:?step name is required}"
source_dir="${BOBR_SOURCE_DIR:?BOBR_SOURCE_DIR is required}"
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

prepare_tmpdir() {
  local cwd="$1"
  mkdir -p "$cwd/.tmp"
  export TMPDIR="${TMPDIR:-$cwd/.tmp}"
}

resolve_project_source_dir() {
  local project_source_dir="$source_dir"

  if [ -f "${cfg}/source_subdir" ]; then
    project_source_dir="${source_dir}/$(cat "${cfg}/source_subdir")"
  fi

  if [ ! -d "$project_source_dir" ] || [ ! -f "$project_source_dir/CMakeLists.txt" ]; then
    echo "cmake build-script: CMakeLists.txt not found in ${project_source_dir}" >&2
    exit 1
  fi

  printf '%s\n' "$project_source_dir"
}

step_configure() {
  local project_source_dir
  local cmake_args=()
  project_source_dir="$(resolve_project_source_dir)"
  cd "$project_source_dir"
  prepare_tmpdir "$project_source_dir"
  append_dir_files_to_array "${cfg}/cmake_args" cmake_args
  cmake -S . -B . -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release "${cmake_args[@]}"
}

step_build() {
  local project_source_dir jobs
  local make_args=()
  project_source_dir="$(resolve_project_source_dir)"
  cd "$project_source_dir"
  prepare_tmpdir "$project_source_dir"
  append_dir_files_to_array "${cfg}/make_args" make_args
  jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
  make -j"$jobs" "${make_args[@]}"
}

step_install() {
  local project_source_dir
  local make_args=()
  project_source_dir="$(resolve_project_source_dir)"
  cd "$project_source_dir"
  prepare_tmpdir "$project_source_dir"
  append_dir_files_to_array "${cfg}/make_args" make_args
  # Install into the live overlay root (configured -DCMAKE_INSTALL_PREFIX=/usr);
  # the writes land in the overlay upper layer and become the captured fs-tree.
  make "${make_args[@]}" install
}

load_env_files
bobr_prepare_source

case "$step" in
  prepare) : ;;
  configure) step_configure ;;
  build) step_build ;;
  install) step_install ;;
  *)
    echo "cmake build-script: unsupported step '$step'" >&2
    exit 1
    ;;
esac
