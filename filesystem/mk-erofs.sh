#!/bin/bash
# Pack a materialized fs-tree into a reproducible EROFS image.
#
# The Sandbox exposes the tree to pack at $BOBR_INPUTS_DIR/_tree (a materialized
# fs-tree root, carrying the real uid/gid/mode of every entry) and the output
# directory at $BOBR_OUT_DIR. SOURCE_DATE_EPOCH is pinned by the sandbox, so the
# superblock build time is host-independent.
#
# The image UUID and label are derived deterministically from $BOBR_BUILD_SEED
# (a per-build seed the sandbox exports; itself a digest of this build's reuse
# key). Same inputs -> same seed -> same UUID, so the image stays reproducible,
# yet distinct rootfs contents get distinct, non-null UUIDs.
#
# Uses only bash builtins (parameter expansion, arithmetic, printf) so the build
# rootfs needs nothing beyond bash and mkfs.erofs -- no coreutils.
#
# Reproducibility flags mirror what the former native ErofsRootfs builder used:
#   --sort=path        deterministic on-disk ordering
#   -T $SOURCE_DATE_EPOCH  fixed build time (mkfs treats -T 0 as unset)
set -eu

tree="${BOBR_INPUTS_DIR:?BOBR_INPUTS_DIR is required}/_tree"
image="${BOBR_OUT_DIR:?BOBR_OUT_DIR is required}/erofs-rootfs.erofs"
seed="${BOBR_BUILD_SEED:?BOBR_BUILD_SEED is required}"

if [[ ! "${seed}" =~ ^[0-9a-fA-F]{32} ]]; then
  echo "mk-erofs: BOBR_BUILD_SEED is not a 32+ hex string: ${seed}" >&2
  exit 1
fi

# First 32 hex chars = 128 bits for the UUID.
h="${seed:0:32}"

# Format as an RFC 9562 version-8 (custom) UUID: force the version nibble (hex
# 13) to 8, and the variant nibble (hex 17) to 10xx (8..b), keeping the rest of
# the seed entropy.
variant_out=$(printf '%x' "$(( 8 + (0x${h:16:1} & 3) ))")
uuid="${h:0:8}-${h:8:4}-8${h:13:3}-${variant_out}${h:17:3}-${h:20:12}"

label="bobr-rootfs"

exec mkfs.erofs \
  --sort=path \
  -T "${SOURCE_DATE_EPOCH}" \
  -U "${uuid}" \
  -L "${label}" \
  "${image}" \
  "${tree}"
