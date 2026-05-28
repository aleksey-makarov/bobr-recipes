#!/usr/bin/env bash
set -euo pipefail

cd "${MBUILD_SOURCE_DIR}"
mkdir -p "${MBUILD_INSTALL_DIR}"
rm -fv man3/crypt*
rm -fv man3/getspnam.3 man3/getspent.3 man3/lckpwdf.3
rm -fv man5/passwd.5
make -R GIT=false prefix=/usr DESTDIR="${MBUILD_INSTALL_DIR}" install
