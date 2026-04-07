#!/usr/bin/env bash
set -euo pipefail

src="${MBUILD_SOURCE_INPUT:?MBUILD_SOURCE_INPUT is required}"
out="${MBUILD_PRIMARY_OUTPUT:?MBUILD_PRIMARY_OUTPUT is required}"

cd "/in/${src}"

if [ ! -f Makefile ]; then
  candidates=()
  for d in ./*; do
    if [ -d "$d" ] && [ -f "$d/Makefile" ]; then
      candidates+=("$d")
    fi
  done
  if [ "${#candidates[@]}" -eq 1 ]; then
    cd "${candidates[0]}"
  fi
fi

make mrproper
make headers
find usr/include -type f ! -name '*.h' -delete

mkdir -p "/out/${out}/usr"
cp -rv usr/include "/out/${out}/usr"
