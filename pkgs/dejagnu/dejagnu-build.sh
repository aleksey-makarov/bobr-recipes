#!/usr/bin/env bash
set -euo pipefail

cd "${BOBR_SOURCE_DIR}"
mkdir -pv build
cd build
mkdir -p .tmp doc "${BOBR_INSTALL_DIR}/usr/share/doc/dejagnu-1.6.3"
export TMPDIR="${TMPDIR:-$PWD/.tmp}"

../configure --prefix=/usr
makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi
makeinfo --plaintext -o doc/dejagnu.txt ../doc/dejagnu.texi

jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
make -j"$jobs"
make DESTDIR="${BOBR_INSTALL_DIR}" install
rm -f "${BOBR_INSTALL_DIR}/usr/share/info/dir"
install -v -m644 doc/dejagnu.html doc/dejagnu.txt "${BOBR_INSTALL_DIR}/usr/share/doc/dejagnu-1.6.3"
