#!/usr/bin/env bash
set -euo pipefail

src="${MBUILD_SOURCE_INPUT:?MBUILD_SOURCE_INPUT is required}"
out="${MBUILD_PRIMARY_OUTPUT:?MBUILD_PRIMARY_OUTPUT is required}"

cd "/in/${src}"

if [ ! -f Configure ]; then
  candidates=()
  for d in ./*; do
    if [ -d "$d" ] && [ -f "$d/Configure" ]; then
      candidates+=("$d")
    fi
  done
  if [ "${#candidates[@]}" -eq 1 ]; then
    cd "${candidates[0]}"
  fi
fi

if [ ! -f Configure ]; then
  echo "perl-configure build-script: Configure not found in /in/${src}" >&2
  exit 1
fi

export BUILD_ZLIB=False
export BUILD_BZIP2=0

jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"

sh Configure -des \
  -D prefix=/usr \
  -D vendorprefix=/usr \
  -D privlib=/usr/lib/perl5/5.42/core_perl \
  -D archlib=/usr/lib/perl5/5.42/core_perl \
  -D sitelib=/usr/lib/perl5/5.42/site_perl \
  -D sitearch=/usr/lib/perl5/5.42/site_perl \
  -D vendorlib=/usr/lib/perl5/5.42/vendor_perl \
  -D vendorarch=/usr/lib/perl5/5.42/vendor_perl \
  -D man1dir=/usr/share/man/man1 \
  -D man3dir=/usr/share/man/man3 \
  -D pager='/usr/bin/less -isR' \
  -D useshrplib \
  -D usethreads

make -j"$jobs"
mkdir -p "/out/${out}"
make DESTDIR="/out/${out}" install
