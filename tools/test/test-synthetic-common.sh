#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
common="${repo_root}/synthetic/common.sh"
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

assert_file() {
  local path="$1"
  local expected="$2"
  local actual
  actual="$(cat "$path")"
  if [ "$actual" != "$expected" ]; then
    echo "unexpected content in ${path}: ${actual}" >&2
    return 1
  fi
}

run_directory_source_case() {
  local input_dir="${tmpdir}/dir-source"
  local build_dir="${tmpdir}/dir-build"
  local patch_file="${tmpdir}/direct.patch"
  local patch_dir="${tmpdir}/patches"

  mkdir -p "$input_dir" "$patch_dir/subdir"
  printf 'old\n' > "${input_dir}/hello.txt"
  printf 'before\n' > "${input_dir}/dir.txt"
  printf 'ignored\n' > "${input_dir}/ignored.txt"

  cat > "$patch_file" <<'EOF_PATCH'
--- a/hello.txt
+++ b/hello.txt
@@ -1 +1 @@
-old
+new
EOF_PATCH

  cat > "${patch_dir}/01-dir.patch" <<'EOF_PATCH'
--- a/dir.txt
+++ b/dir.txt
@@ -1 +1 @@
-before
+after
EOF_PATCH

  cat > "${patch_dir}/ignored.diff" <<'EOF_PATCH'
--- a/ignored.txt
+++ b/ignored.txt
@@ -1 +1 @@
-ignored
+changed
EOF_PATCH

  cat > "${patch_dir}/subdir/ignored.patch" <<'EOF_PATCH'
--- a/ignored.txt
+++ b/ignored.txt
@@ -1 +1 @@
-ignored
+changed
EOF_PATCH

  BOBR_SOURCE_INPUT="$input_dir"
  BOBR_SOURCE_DIR="${build_dir}/source"
  BOBR_PATCH_INPUTS="${patch_file} ${patch_dir}"
  export BOBR_SOURCE_INPUT BOBR_SOURCE_DIR BOBR_PATCH_INPUTS

  # shellcheck source=/dev/null
  . "$common"
  bobr_prepare_source
  bobr_prepare_source

  assert_file "${BOBR_SOURCE_DIR}/hello.txt" "new"
  assert_file "${BOBR_SOURCE_DIR}/dir.txt" "after"
  assert_file "${BOBR_SOURCE_DIR}/ignored.txt" "ignored"
}

run_archive_source_case() {
  local archive_root="${tmpdir}/archive-root"
  local archive="${tmpdir}/source.tar"
  local build_dir="${tmpdir}/archive-build"

  mkdir -p "${archive_root}/pkg"
  printf 'from archive\n' > "${archive_root}/pkg/file.txt"
  tar -C "$archive_root" -cf "$archive" pkg

  BOBR_SOURCE_INPUT="$archive"
  BOBR_SOURCE_DIR="${build_dir}/source"
  BOBR_PATCH_INPUTS=""
  export BOBR_SOURCE_INPUT BOBR_SOURCE_DIR BOBR_PATCH_INPUTS

  # shellcheck source=/dev/null
  . "$common"
  bobr_prepare_source

  assert_file "${BOBR_SOURCE_DIR}/file.txt" "from archive"
}

run_directory_source_case
run_archive_source_case

echo "synthetic common helper tests passed"
