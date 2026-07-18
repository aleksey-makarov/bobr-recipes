#!/usr/bin/env bash
set -euo pipefail

src="${BOBR_SOURCE_DIR:?BOBR_SOURCE_DIR is required}"
out="${BOBR_INSTALL_DIR:?BOBR_INSTALL_DIR is required}"

icons="${out}/usr/share/icons"
theme="${icons}/Bibata-Modern-Classic"

# prepare_source strips the archive's top dir, so cursors/ and the *.theme
# files sit directly under $src. Install the prebuilt XCursor theme as-is.
mkdir -p "${theme}"
cp -r "${src}/cursors" "${src}/index.theme" "${src}/cursor.theme" "${theme}/"

# Make it the system default cursor theme, so a client that asks for the
# "default" theme (Weston with no explicit cursor-theme) resolves to it and
# finds dnd-move/dnd-copy/dnd-none etc.
mkdir -p "${icons}/default"
cat > "${icons}/default/index.theme" <<'EOF'
[Icon Theme]
Name=Default
Comment=Default cursor theme
Inherits=Bibata-Modern-Classic
EOF
