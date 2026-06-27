#!/usr/bin/env bash
set -euo pipefail

cd "${BOBR_SOURCE_DIR}"
mkdir -p "${BOBR_INSTALL_DIR}/etc"
install -m 0644 services "${BOBR_INSTALL_DIR}/etc/services"
install -m 0644 protocols "${BOBR_INSTALL_DIR}/etc/protocols"
