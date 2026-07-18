#!/usr/bin/env bash
set -euo pipefail

src_root="${BOBR_SOURCE_DIR}"

cd "${src_root}/unix"
mkdir -p .tmp
export TMPDIR="${TMPDIR:-$PWD/.tmp}"

./configure --prefix=/usr --mandir=/usr/share/man --disable-rpath

jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
make -j"$jobs"

sed -e "s|${src_root}/unix|/usr/lib|" \
    -e "s|${src_root}|/usr/include|" \
    -i tclConfig.sh

sed -e "s|${src_root}/unix/pkgs/tdbc1.1.10|/usr/lib/tdbc1.1.10|" \
    -e "s|${src_root}/pkgs/tdbc1.1.10/generic|/usr/include|" \
    -e "s|${src_root}/pkgs/tdbc1.1.10/library|/usr/lib/tcl8.6|" \
    -e "s|${src_root}/pkgs/tdbc1.1.10|/usr/include|" \
    -i pkgs/tdbc1.1.10/tdbcConfig.sh

sed -e "s|${src_root}/unix/pkgs/itcl4.3.2|/usr/lib/itcl4.3.2|" \
    -e "s|${src_root}/pkgs/itcl4.3.2/generic|/usr/include|" \
    -e "s|${src_root}/pkgs/itcl4.3.2|/usr/include|" \
    -i pkgs/itcl4.3.2/itclConfig.sh

mkdir -p "${BOBR_INSTALL_DIR}"
make INSTALL_ROOT="${BOBR_INSTALL_DIR}" install
chmod 644 "${BOBR_INSTALL_DIR}/usr/lib/libtclstub8.6.a"
chmod u+w "${BOBR_INSTALL_DIR}/usr/lib/libtcl8.6.so"
make INSTALL_ROOT="${BOBR_INSTALL_DIR}" install-private-headers
ln -sfv tclsh8.6 "${BOBR_INSTALL_DIR}/usr/bin/tclsh"
mv "${BOBR_INSTALL_DIR}/usr/share/man/man3/Thread.3" "${BOBR_INSTALL_DIR}/usr/share/man/man3/Tcl_Thread.3"
