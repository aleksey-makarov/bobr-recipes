#!/usr/bin/env bash

# Boot the Weston system: pkgs.qemu_weston_image, graphical. qemu presents a
# venus virtio-gpu (guest /dev/dri) and an sdl window; Weston runs as the user
# session under the tty1 autologin, with the serial console (ttyS0) still on the
# terminal. Shares the network and the ttyS1 diag socket (for bobr-agent-exec-guest.py) with
# the other launchers -- see bobr-run-qemu-lib.sh for the common core and env
# knobs.

set -euo pipefail

VARIANT_IMAGE_ATTR="qemu_weston_image"
VARIANT_GRAPHICAL=1
VARIANT_MEM_DEFAULT=4096
VARIANT_HOME_IMG="home-weston.img"
VARIANT_DIAG_SOCK="diag-weston.sock"

source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/bobr-run-qemu-lib.sh"
qemu_run "$@"
