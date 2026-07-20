#!/usr/bin/env bash
# Plain-Makefile build script for the SandboxInstall builder, staging variant:
# installs into a virgin /stage (make install DESTDIR=/stage) instead of the live
# overlay root. The MakefileStageRootfs lowering then re-roots /stage -> / via
# TreeMove, keeping the layer additive even when the package's output overlaps
# files already in the build rootfs (e.g. a toolchain member rebuilt on a rootfs
# that already carries it). Packages whose Makefile does not honour DESTDIR set
# skip_install and install into /stage from a post_install hook instead.
set -euo pipefail

cfg="${BOBR_CONFIG_DIR:?BOBR_CONFIG_DIR is required}"
step="${1:-${BOBR_STEP_NAME:-}}"
step="${step:?step name is required}"
source_dir="${BOBR_SOURCE_DIR:?BOBR_SOURCE_DIR is required}"
synthetic_common="${BOBR_SYNTHETIC_COMMON:?BOBR_SYNTHETIC_COMMON is required}"

. "$synthetic_common"

# Fixed staging root, matched by the MakefileStageRootfs lowering's
# TreeMove(strip_prefix="stage").
stage_root="/stage"

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

  if [ ! -d "$project_source_dir" ]; then
    echo "gnu-make-stage-install build-script: project source dir is not a directory: ${project_source_dir}" >&2
    exit 1
  fi

  printf '%s\n' "$project_source_dir"
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
  local project_source_dir skip_install
  local make_args=()
  project_source_dir="$(resolve_project_source_dir)"
  cd "$project_source_dir"
  prepare_tmpdir "$project_source_dir"
  append_dir_files_to_array "${cfg}/make_args" make_args
  skip_install="false"
  if [ -f "${cfg}/skip_install" ]; then
    skip_install="$(cat "${cfg}/skip_install")"
  fi
  if [ "$skip_install" != "true" ]; then
    # Install into the virgin ${stage_root}; the writes are all fresh additions
    # (they never overlap the build rootfs) and TreeMove re-roots them to /.
    make "${make_args[@]}" DESTDIR="${stage_root}" install
  fi
}

step_post_install() {
  :
}

load_env_files
bobr_prepare_source

case "$step" in
  prepare) : ;;
  build) step_build ;;
  install) step_install ;;
  post_install) step_post_install ;;
  *)
    echo "gnu-make-stage-install build-script: unsupported step '$step'" >&2
    exit 1
    ;;
esac
