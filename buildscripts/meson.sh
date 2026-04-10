#!/usr/bin/env bash
set -euo pipefail

src="${MBUILD_SOURCE_INPUT:?MBUILD_SOURCE_INPUT is required}"
out="${MBUILD_PRIMARY_OUTPUT:?MBUILD_PRIMARY_OUTPUT is required}"
meson_src_dir="/in/sources1"

cd "/in/${src}"

if [ ! -f meson.build ]; then
  candidates=""
  for d in ./*; do
    if [ -d "$d" ] && [ -f "$d/meson.build" ]; then
      candidates="$candidates $d"
    fi
  done

  set -- $candidates
  if [ "$#" -eq 1 ]; then
    cd "$1"
  else
    echo "meson build-script: meson.build not found (or ambiguous) in /in/${src}" >&2
    exit 1
  fi
fi

if [ ! -f "${meson_src_dir}/meson.py" ]; then
  candidates=""
  for d in "${meson_src_dir}"/*; do
    if [ -d "$d" ] && [ -f "$d/meson.py" ]; then
      candidates="$candidates $d"
    fi
  done

  set -- $candidates
  if [ "$#" -eq 1 ]; then
    meson_src_dir="$1"
  fi
fi

if [ ! -f "${meson_src_dir}/meson.py" ]; then
  echo "meson build-script: meson.py not found in /in/sources1" >&2
  exit 1
fi

jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
python3 "${meson_src_dir}/meson.py" setup build --prefix=/usr
python3 "${meson_src_dir}/meson.py" compile -C build -j"$jobs"
DESTDIR="/out/${out}" python3 "${meson_src_dir}/meson.py" install -C build
