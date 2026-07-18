#!/usr/bin/env bash
set -euo pipefail

src="${BOBR_SOURCE_DIR:?BOBR_SOURCE_DIR is required}"
out="${BOBR_INSTALL_DIR:?BOBR_INSTALL_DIR is required}"

# Install the prebuilt DejaVu TTFs (the -ttf tarball ships them ready under
# ttf/); no font compilation needed.
dest="${out}/usr/share/fonts/dejavu"
mkdir -p "${dest}"
cp -v "${src}"/ttf/*.ttf "${dest}/"
