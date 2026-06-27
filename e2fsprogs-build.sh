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

if [ -f /etc/cron.d/e2scrub_all ]; then
  install -v -Dm644 /etc/cron.d/e2scrub_all "${BOBR_INSTALL_DIR}/etc/cron.d/e2scrub_all"
  rm -f /etc/cron.d/e2scrub_all
fi

for unit in e2scrub@.service e2scrub_all.service e2scrub_all.timer e2scrub_fail@.service; do
  if [ -f "/usr/lib/systemd/system/${unit}" ]; then
    install -v -Dm644 "/usr/lib/systemd/system/${unit}" "${BOBR_INSTALL_DIR}/usr/lib/systemd/system/${unit}"
    rm -f "/usr/lib/systemd/system/${unit}"
  fi
done
