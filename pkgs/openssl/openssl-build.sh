#!/usr/bin/env bash
set -euo pipefail

cd "${BOBR_SOURCE_DIR}"
mkdir -p .tmp "${BOBR_INSTALL_DIR}"
export TMPDIR="${TMPDIR:-$PWD/.tmp}"

./config --prefix=/usr --openssldir=/etc/ssl --libdir=lib shared zlib-dynamic

jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
make -j"$jobs"

sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make DESTDIR="${BOBR_INSTALL_DIR}" MANSUFFIX=ssl install

if [ -d "${BOBR_INSTALL_DIR}/usr/share/doc/openssl" ]; then
  mv -v "${BOBR_INSTALL_DIR}/usr/share/doc/openssl" "${BOBR_INSTALL_DIR}/usr/share/doc/openssl-3.5.2"
else
  install -vdm755 "${BOBR_INSTALL_DIR}/usr/share/doc/openssl-3.5.2"
fi

cp -vfr doc/* "${BOBR_INSTALL_DIR}/usr/share/doc/openssl-3.5.2"
