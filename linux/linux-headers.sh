#!/usr/bin/env bash
set -euo pipefail

phase="${1:-${MBUILD_STEP_NAME:-}}"
phase="${phase:?step name is required}"
source_dir="${MBUILD_SOURCE_DIR:?MBUILD_SOURCE_DIR is required}"
install_dir="${MBUILD_INSTALL_DIR:?MBUILD_INSTALL_DIR is required}"
build_dir="${MBUILD_BUILD_DIR:?MBUILD_BUILD_DIR is required}"
prepared_source_dir="${build_dir}/source"
prepared_marker="${build_dir}/.mbuild-linux-source-prepared"

prepare_source() {
  if [ -f "$prepared_marker" ]; then
    return
  fi

  rm -rf "$prepared_source_dir"
  mkdir -p "$prepared_source_dir"

  if [ -d "$source_dir" ]; then
    tar -C "$source_dir" -cf - . | tar -C "$prepared_source_dir" -xf -
  elif [ -f "$source_dir" ]; then
    tar -C "$prepared_source_dir" -xf "$source_dir"
  else
    echo "linux-headers build-script: source input is neither file nor directory: ${source_dir}" >&2
    exit 1
  fi

  touch "$prepared_marker"
}

resolve_source_dir() {
  if [ -f "$prepared_source_dir/Makefile" ]; then
    printf '%s\n' "$prepared_source_dir"
    return
  fi

  local candidates=()
  local d
  for d in "$prepared_source_dir"/*; do
    if [ -d "$d" ] && [ -f "$d/Makefile" ]; then
      candidates+=("$d")
    fi
  done
  if [ "${#candidates[@]}" -eq 1 ]; then
    printf '%s\n' "${candidates[0]}"
    return
  fi

  echo "linux-headers build-script: Makefile not found in ${prepared_source_dir}" >&2
  exit 1
}

phase_configure() {
  prepare_source
}

phase_build() {
  local project_source_dir
  prepare_source
  project_source_dir="$(resolve_source_dir)"
  cd "$project_source_dir"
  make mrproper
  make headers
  find usr/include -type f ! -name '*.h' -delete
}

phase_install() {
  local project_source_dir
  prepare_source
  project_source_dir="$(resolve_source_dir)"
  cd "$project_source_dir"
  mkdir -p "$install_dir/usr"
  cp -rv usr/include "$install_dir/usr"
}

phase_post_install() {
  :
}

case "$phase" in
  configure) phase_configure ;;
  build) phase_build ;;
  install) phase_install ;;
  post_install) phase_post_install ;;
  *)
    echo "linux-headers build-script: unsupported phase '$phase'" >&2
    exit 1
    ;;
esac
