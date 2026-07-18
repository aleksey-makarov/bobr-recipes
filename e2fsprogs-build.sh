#!/usr/bin/env bash
set -euo pipefail

cd "${BOBR_SOURCE_DIR}"
mkdir -pv build
cd build
mkdir -p .tmp "${BOBR_INSTALL_DIR}/usr/share/info"
export TMPDIR="${TMPDIR:-$PWD/.tmp}"

../configure --prefix=/usr --sbindir=/usr/bin --sysconfdir=/etc --enable-elf-shlibs --disable-libblkid --disable-libuuid --disable-uuidd --disable-fsck

jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
make -j"$jobs"
make DESTDIR="${BOBR_INSTALL_DIR}" install

# e2fsprogs' --enable-elf-shlibs install runs `ldconfig` (unconditionally, per
# its elf-lib template), which regenerates /etc/ld.so.cache. Under DESTDIR
# staging that cache landed in the discarded build root; under the additive
# SandboxInstall model (DESTDIR=/) it lands in the captured overlay. The tree's
# ld.so.cache is a finalize artifact (gnome-finalize regenerates it with
# `ldconfig -X`), so no package may ship one -- drop e2fsprogs' copy. It is our
# own freshly written upper file (glibc ships none), so removing it is additive.
rm -f "${BOBR_INSTALL_DIR}/etc/ld.so.cache"

rm -fv "${BOBR_INSTALL_DIR}/usr/lib/libcom_err.a" \
       "${BOBR_INSTALL_DIR}/usr/lib/libe2p.a" \
       "${BOBR_INSTALL_DIR}/usr/lib/libext2fs.a" \
       "${BOBR_INSTALL_DIR}/usr/lib/libss.a"

if [ -f "${BOBR_INSTALL_DIR}/usr/share/info/libext2fs.info.gz" ]; then
  gunzip -vf "${BOBR_INSTALL_DIR}/usr/share/info/libext2fs.info.gz"
  install-info --dir-file="${BOBR_INSTALL_DIR}/usr/share/info/dir" "${BOBR_INSTALL_DIR}/usr/share/info/libext2fs.info"
fi

makeinfo -o doc/com_err.info ../lib/et/com_err.texinfo
install -v -m644 doc/com_err.info "${BOBR_INSTALL_DIR}/usr/share/info"
install-info --dir-file="${BOBR_INSTALL_DIR}/usr/share/info/dir" "${BOBR_INSTALL_DIR}/usr/share/info/com_err.info"
rm -f "${BOBR_INSTALL_DIR}/usr/share/info/dir"

if [ -f "${BOBR_INSTALL_DIR}/etc/mke2fs.conf" ]; then
  sed 's/metadata_csum_seed,//' -i "${BOBR_INSTALL_DIR}/etc/mke2fs.conf"
fi

# NOTE: upstream's install ships the e2scrub cron job + systemd units under
# /etc/cron.d and /usr/lib/systemd/system. The former LFS-style blocks here
# (relocate them out of the real root into DESTDIR, then delete from /) were
# dead no-ops under the DESTDIR staging model -- the real-root paths they
# probed never existed, so the units stayed in the package. Under the additive
# SandboxInstall model DESTDIR is /, so those blocks would `install` a file
# onto itself and error; they are removed. The e2scrub units remain installed,
# exactly as the staging output shipped them.
