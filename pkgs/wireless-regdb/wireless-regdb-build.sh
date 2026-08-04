#!/usr/bin/env bash
set -euo pipefail

cd "${BOBR_SOURCE_DIR}"

# The release ships the database already built and already signed, so there is
# nothing to compile here -- upstream's Makefile only regenerates it when you
# hold the signing key. The detached .p7s signature has to travel with the
# database: the kernel is built with CONFIG_CFG80211_REQUIRE_SIGNED_REGDB, and
# verifies it against the certificates compiled into cfg80211.
install -Dm 0644 regulatory.db "${BOBR_INSTALL_DIR}/usr/lib/firmware/regulatory.db"
install -Dm 0644 regulatory.db.p7s \
  "${BOBR_INSTALL_DIR}/usr/lib/firmware/regulatory.db.p7s"

# regulatory.bin, and its manual page, are the format the retired CRDA helper
# read; the kernel reads regulatory.db itself, and CFG80211_CRDA_SUPPORT is off,
# so only this manual page is worth shipping.
install -Dm 0644 regulatory.db.5 \
  "${BOBR_INSTALL_DIR}/usr/share/man/man5/regulatory.db.5"
