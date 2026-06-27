#!/usr/bin/env bash

bobr_prepare_source() {
  local source_input="${BOBR_SOURCE_INPUT:?BOBR_SOURCE_INPUT is required}"
  local source_dir="${BOBR_SOURCE_DIR:?BOBR_SOURCE_DIR is required}"

  case "$source_dir" in
    ""|"/")
      echo "synthetic build-script: refusing unsafe source dir: ${source_dir}" >&2
      exit 1
      ;;
  esac

  local source_parent
  source_parent="$(dirname "$source_dir")"
  local marker="${source_parent}/.bobr-source-prepared"

  if [ -f "$marker" ]; then
    return
  fi

  if [ -e "$source_dir" ]; then
    rm -rf -- "$source_dir"
  fi
  mkdir -p "$source_dir"

  if [ -d "$source_input" ]; then
    tar -C "$source_input" -cf - . | tar -C "$source_dir" -xf -
  elif [ -f "$source_input" ]; then
    tar -C "$source_dir" -xf "$source_input"
    bobr_normalize_single_archive_root "$source_dir"
  else
    echo "synthetic build-script: source input is neither file nor directory: ${source_input}" >&2
    exit 1
  fi

  bobr_apply_patches "$source_dir"
  touch "$marker"
}

bobr_normalize_single_archive_root() {
  local source_dir="$1"
  local entries=()
  mapfile -d '' entries < <(find "$source_dir" -mindepth 1 -maxdepth 1 -print0 | sort -z)

  if [ "${#entries[@]}" -ne 1 ]; then
    return
  fi

  local wrapper="${entries[0]}"
  if [ ! -d "$wrapper" ] || [ -L "$wrapper" ]; then
    return
  fi

  local children=()
  mapfile -d '' children < <(find "$wrapper" -mindepth 1 -maxdepth 1 -print0 | sort -z)
  if [ "${#children[@]}" -gt 0 ]; then
    mv -- "${children[@]}" "$source_dir/"
  fi
  rmdir "$wrapper"
}

bobr_apply_patches() {
  local source_dir="$1"
  local patch_input
  local patch_file

  export LC_ALL=C
  for patch_input in ${BOBR_PATCH_INPUTS:-}; do
    if [ -f "$patch_input" ]; then
      bobr_apply_patch_file "$source_dir" "$patch_input"
    elif [ -d "$patch_input" ]; then
      for patch_file in "$patch_input"/*.patch; do
        [ -e "$patch_file" ] || continue
        [ -f "$patch_file" ] || continue
        bobr_apply_patch_file "$source_dir" "$patch_file"
      done
    else
      echo "synthetic build-script: patch input is neither file nor directory: ${patch_input}" >&2
      exit 1
    fi
  done
}

bobr_apply_patch_file() {
  local source_dir="$1"
  local patch_file="$2"

  echo "synthetic build-script: applying patch ${patch_file}" >&2
  (
    cd "$source_dir"
    patch -Np1 -i "$patch_file"
  )
}
