#!/usr/bin/env bash
# Pack a materialized fs-tree into a deterministic `newc` cpio initramfs.
#
# The tree to pack is mounted read-only at $BOBR_INPUTS_DIR/_tree (a materialized
# fs-tree, carrying the real uid/gid/mode of every entry) and the output goes to
# $BOBR_OUT_DIR/initramfs.img.
#
# The archive is written by the kernel's own `gen_init_cpio`, driven by a spec
# file this script generates from the tree -- the same two-stage scheme the
# kernel uses for CONFIG_INITRAMFS_SOURCE (usr/gen_initramfs.sh). Reproducibility
# rests on that split: the spec carries only path, type, permissions, and
# ownership, and gen_init_cpio synthesizes everything else (inode numbers from a
# constant, fixed link counts, one timestamp for all entries). Running `cpio(1)`
# over the tree instead would copy the on-disk inode numbers, link counts, and
# mtimes -- and a materialized fs-tree hardlinks its files from the store's
# shared fs-files, so those vary with what else the store holds.
#
# Entries are emitted in byte order of their paths, which also puts every
# directory before its contents (a tab separator sorts below `/`), as the
# kernel's unpacker requires.
set -euo pipefail

export LC_ALL=C

target="${BOBR_INPUTS_DIR:?BOBR_INPUTS_DIR is required}/_tree"
dest="${BOBR_OUT_DIR:?BOBR_OUT_DIR is required}"
list="${BOBR_BUILD_DIR:?BOBR_BUILD_DIR is required}/cpio_list"

if [ ! -d "$target" ]; then
  echo "mk-initramfs: tree to pack missing at ${target}" >&2
  exit 1
fi

# The whole point of this builder: a fixed timestamp for every entry. The sandbox
# pins SOURCE_DATE_EPOCH, so two builds of the same tree agree.
timestamp="${SOURCE_DATE_EPOCH:-0}"

# gen_init_cpio's spec parser splits fields on whitespace, so a path or symlink
# target containing any would be silently misread. Refuse instead.
: > "$list"
while IFS=$'\t' read -r rel type mode uid gid link; do
  case "${rel}${link}" in
    *[[:space:]]*)
      echo "mk-initramfs: path or symlink target contains whitespace: /${rel}" >&2
      exit 1
      ;;
  esac
  case "$type" in
    d) printf 'dir /%s %s %s %s\n' "$rel" "$mode" "$uid" "$gid" ;;
    f) printf 'file /%s %s %s %s %s\n' "$rel" "$target/$rel" "$mode" "$uid" "$gid" ;;
    l) printf 'slink /%s %s %s %s %s\n' "$rel" "$link" "$mode" "$uid" "$gid" ;;
    *)
      # fs-trees model only regular files, directories, and symlinks; anything
      # else means the tree (or this script) is wrong, so fail loudly.
      echo "mk-initramfs: unsupported entry type '${type}' at /${rel}" >&2
      exit 1
      ;;
  esac >> "$list"
done < <(find "$target" -mindepth 1 -printf '%P\t%y\t%m\t%U\t%G\t%l\n' | sort)

if [ ! -s "$list" ]; then
  echo "mk-initramfs: tree at ${target} is empty" >&2
  exit 1
fi

mkdir -p "$dest"
gen_init_cpio -t "$timestamp" -o "${dest}/initramfs.img" "$list"
