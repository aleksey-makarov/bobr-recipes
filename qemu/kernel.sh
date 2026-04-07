#!/usr/bin/env bash
set -euo pipefail

src="${MBUILD_SOURCE_INPUT:?MBUILD_SOURCE_INPUT is required}"
out="${MBUILD_PRIMARY_OUTPUT:?MBUILD_PRIMARY_OUTPUT is required}"

export ARCH=x86_64
export KBUILD_BUILD_USER=mbuild
export KBUILD_BUILD_HOST=mbuild
export KBUILD_BUILD_TIMESTAMP='1970-01-01'
export KBUILD_BUILD_VERSION=1
export SOURCE_DATE_EPOCH=0
export LC_ALL=C
export TZ=UTC

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
cp /in/sources1 .config
make olddefconfig

jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
make -j"${jobs}" bzImage

mkdir -p "/out/${out}/boot"
install -m0644 arch/x86/boot/bzImage "/out/${out}/boot/bzImage"
install -m0644 System.map "/out/${out}/boot/System.map"
install -m0644 .config "/out/${out}/boot/kernel.config"
