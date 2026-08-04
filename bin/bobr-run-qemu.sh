#!/usr/bin/env bash

# Boot the plain (graphics-less) system: pkgs.qemu_image, headless. The serial
# console (ttyS0 autologin) is on the terminal and there is no window. Shares the
# network and the ttyS1 diag socket (for bobr-agent-exec-guest.py) with the graphical
# launchers -- see bobr-run-qemu-lib.sh for the common core and env knobs.

set -euo pipefail

VARIANT_IMAGE_ATTR="qemu_image"
VARIANT_GRAPHICAL=0
VARIANT_MEM_DEFAULT=1024
VARIANT_HOME_IMG="home.img"
VARIANT_DIAG_SOCK="diag.sock"

source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/bobr-run-qemu-lib.sh"
qemu_run "$@"
