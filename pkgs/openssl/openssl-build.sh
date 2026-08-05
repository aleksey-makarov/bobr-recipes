#!/usr/bin/env bash
set -euo pipefail

: "${OPENSSL_VERSION:?the recipe passes the version in}"

cd "${BOBR_SOURCE_DIR}"
mkdir -p .tmp "${BOBR_INSTALL_DIR}"
export TMPDIR="${TMPDIR:-$PWD/.tmp}"

./config --prefix=/usr --openssldir=/etc/ssl --libdir=lib shared zlib-dynamic

jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
make -j"$jobs"

sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile

# openssl installs its docs under $(INSTALLTOP)/share/doc/$(BASENAME), that is
# `.../doc/openssl`, and DOCDIR is a plain make variable, so the versioned name
# can be asked for directly. Installing and then renaming the directory would be
# the obvious alternative and is the wrong one: a SandboxInstall may only add,
# and a directory that arrives by rename is recorded by overlayfs as one that
# masks whatever lies beneath it -- which some kernels then refuse and others do
# not, depending on whether they can rename a directory at all.
docdir="/usr/share/doc/openssl-${OPENSSL_VERSION}"
make DESTDIR="${BOBR_INSTALL_DIR}" MANSUFFIX=ssl DOCDIR="${docdir}" install

# The tarball's own doc/ tree is not part of `make install`; ship it alongside.
install -vdm755 "${BOBR_INSTALL_DIR}${docdir}"
cp -vfr doc/* "${BOBR_INSTALL_DIR}${docdir}"
