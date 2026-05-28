#!/usr/bin/env bash
set -euo pipefail

cd "${MBUILD_SOURCE_DIR}"
mkdir -p "${MBUILD_INSTALL_DIR}/etc"
install -m 0644 services "${MBUILD_INSTALL_DIR}/etc/services"
install -m 0644 protocols "${MBUILD_INSTALL_DIR}/etc/protocols"
