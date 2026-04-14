#!/usr/bin/env bash
set -euo pipefail

src="${MBUILD_SOURCE_INPUT:?MBUILD_SOURCE_INPUT is required}"
out="${MBUILD_PRIMARY_OUTPUT:?MBUILD_PRIMARY_OUTPUT is required}"
cfg="${MBUILD_SCRIPT_CONFIG_DIR:?MBUILD_SCRIPT_CONFIG_DIR is required}"

cd "/in/${src}"

if [ -d "${cfg}/env" ]; then
  while IFS= read -r -d '' path; do
    export "$(basename "$path")=$(cat "$path")"
  done < <(find "${cfg}/env" -mindepth 1 -maxdepth 1 -type f -print0 | sort -z)
fi

if [ ! -x ./configure ]; then
  candidates=""
  for d in ./*; do
    if [ -d "$d" ] && [ -x "$d/configure" ]; then
      candidates="$candidates $d"
    fi
  done

  set -- $candidates
  if [ "$#" -eq 1 ]; then
    cd "$1"
  fi
fi

if [ ! -x ./configure ]; then
  echo "autotools build-script: ./configure not found in /in/${src}" >&2
  exit 1
fi

mkdir -p .tmp
export TMPDIR="${TMPDIR:-$PWD/.tmp}"

if [ -f "${cfg}/pre_configure" ]; then
  source "${cfg}/pre_configure"
fi

configure_cmd="./configure"
if [ -f "${cfg}/build_dir" ]; then
  build_dir="$(cat "${cfg}/build_dir")"
  mkdir -p "${build_dir}"
  cd "${build_dir}"
  configure_cmd="../configure"
fi

configure_args=()
if [ -d "${cfg}/configure_args" ]; then
  while IFS= read -r -d '' path; do
    configure_args+=("$(cat "$path")")
  done < <(find "${cfg}/configure_args" -mindepth 1 -maxdepth 1 -type f -print0 | sort -z)
fi

make_args=()
if [ -d "${cfg}/make_args" ]; then
  while IFS= read -r -d '' path; do
    make_args+=("$(cat "$path")")
  done < <(find "${cfg}/make_args" -mindepth 1 -maxdepth 1 -type f -print0 | sort -z)
fi

jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
"${configure_cmd}" --prefix=/usr "${configure_args[@]}"
make -j"$jobs" "${make_args[@]}"
mkdir -p "/out/${out}"
make DESTDIR="/out/${out}" "${make_args[@]}" install

if [ -f "${cfg}/post_install" ]; then
  source "${cfg}/post_install"
fi
