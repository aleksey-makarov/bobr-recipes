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

if [ ! -f Makefile ] && [ ! -f makefile ] && [ ! -f GNUmakefile ]; then
  candidates=""
  for d in ./*; do
    if [ -d "$d" ] && { [ -f "$d/Makefile" ] || [ -f "$d/makefile" ] || [ -f "$d/GNUmakefile" ]; }; then
      candidates="$candidates $d"
    fi
  done

  set -- $candidates
  if [ "$#" -eq 1 ]; then
    cd "$1"
  fi
fi

if [ ! -f Makefile ] && [ ! -f makefile ] && [ ! -f GNUmakefile ]; then
  echo "gnu-make build-script: Makefile not found in /in/${src}" >&2
  exit 1
fi

mkdir -p .tmp
export TMPDIR="${TMPDIR:-$PWD/.tmp}"

if [ -f "${cfg}/pre_build" ]; then
  source "${cfg}/pre_build"
fi

make_args=()
if [ -d "${cfg}/make_args" ]; then
  while IFS= read -r -d '' path; do
    make_args+=("$(cat "$path")")
  done < <(find "${cfg}/make_args" -mindepth 1 -maxdepth 1 -type f -print0 | sort -z)
fi

jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
make -j"$jobs" "${make_args[@]}"
mkdir -p "/out/${out}"

skip_install="false"
if [ -f "${cfg}/skip_install" ]; then
  skip_install="$(cat "${cfg}/skip_install")"
fi

if [ "${skip_install}" != "true" ]; then
  make DESTDIR="/out/${out}" "${make_args[@]}" install
fi

if [ -f "${cfg}/post_install" ]; then
  source "${cfg}/post_install"
fi
