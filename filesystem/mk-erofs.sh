#!/bin/sh
# Pack a materialized fs-tree into a reproducible EROFS image.
#
# The Sandbox exposes the tree to pack at $BOBR_INPUTS_DIR/_tree (a materialized
# fs-tree root, carrying the real uid/gid/mode of every entry) and the output
# directory at $BOBR_OUT_DIR. SOURCE_DATE_EPOCH is pinned by the sandbox, so the
# superblock build time is host-independent.
#
# Reproducibility flags mirror what the former native ErofsRootfs builder used:
#   --sort=path        deterministic on-disk ordering
#   -T $SOURCE_DATE_EPOCH  fixed build time (mkfs treats -T 0 as unset)
#   -U clear           zero the filesystem UUID
set -eu

tree="${BOBR_INPUTS_DIR:?BOBR_INPUTS_DIR is required}/_tree"
image="${BOBR_OUT_DIR:?BOBR_OUT_DIR is required}/erofs-rootfs.erofs"

exec mkfs.erofs \
  --sort=path \
  -T "${SOURCE_DATE_EPOCH}" \
  -U clear \
  -L bobr-rootfs \
  "${image}" \
  "${tree}"
