#!/usr/bin/env bash
# Perl-module build script for the SandboxInstall builder: installs into the live
# read-write overlay root (make pure_install, no DESTDIR) rather than into a
# staging $out. The build's additions become the captured fs-tree layer.
#
# The `pure_install` target installs the module files (lib, man, and the
# module's own auto/<Module>/.packlist) but, unlike `install`, does not run
# doc_install and therefore never writes the shared perllocal.pod. That keeps
# the layer additive (perllocal.pod already exists in the lower rootfs and
# appending to it would be a modification) and reproducible in one move.
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

resolve_project_source_dir() {
  local project_source_dir="$source_dir"

  if [ -f "${cfg}/source_subdir" ]; then
    project_source_dir="${source_dir}/$(cat "${cfg}/source_subdir")"
  fi

  if [ ! -d "$project_source_dir" ] || [ ! -f "$project_source_dir/Makefile.PL" ]; then
    echo "perl-module build-script: Makefile.PL not found in ${project_source_dir}" >&2
    exit 1
  fi

  printf '%s\n' "$project_source_dir"
}

prepare_tmpdir() {
  local cwd="$1"
  mkdir -p "$cwd/.tmp"
  export TMPDIR="${TMPDIR:-$cwd/.tmp}"
}

step_configure() {
  local project_source_dir
  local perl_args=()
  project_source_dir="$(resolve_project_source_dir)"
  cd "$project_source_dir"
  prepare_tmpdir "$project_source_dir"
  append_dir_files_to_array "${cfg}/perl_args" perl_args
  perl Makefile.PL "${perl_args[@]}"
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
  # Install into the live overlay root; the writes land in the overlay upper
  # layer and become the captured fs-tree. `pure_install` skips doc_install so
  # the shared perllocal.pod is never touched.
  make "${make_args[@]}" pure_install
}

load_env_files
bobr_prepare_source

case "$step" in
  prepare) : ;;
  configure) step_configure ;;
  build) step_build ;;
  install) step_install ;;
  *)
    echo "perl-module build-script: unsupported step '$step'" >&2
    exit 1
    ;;
esac
