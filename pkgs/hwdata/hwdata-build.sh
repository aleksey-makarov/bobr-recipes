#!/usr/bin/env bash
set -euo pipefail

src="${BOBR_SOURCE_DIR:?BOBR_SOURCE_DIR is required}"
out="${BOBR_INSTALL_DIR:?BOBR_INSTALL_DIR is required}"

# hwdata is pure data; its Makefile only matters for distro packaging (and is
# incomplete in the git archive). Install the id databases directly and emit a
# minimal hwdata.pc so libdisplay-info can locate pnp.ids via pkg-config.
datadir="${out}/usr/share/hwdata"
pcdir="${out}/usr/share/pkgconfig"
mkdir -p "${datadir}" "${pcdir}"

install -m0644 "${src}/pnp.ids" "${src}/pci.ids" "${src}/usb.ids" "${datadir}/"

cat > "${pcdir}/hwdata.pc" <<'EOF'
pkgdatadir=/usr/share/hwdata

Name: hwdata
Description: Hardware identification and configuration data
Version: 0.395
EOF
