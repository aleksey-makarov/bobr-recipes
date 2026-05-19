#!/usr/bin/env bash

# Smoke-test the host-side runtime rootfs checker with synthetic roots and a
# fake readelf implementation.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
checker="${repo_root}/tools/check-runtime-rootfs.py"
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

fake_readelf="${tmpdir}/readelf"
cat > "${fake_readelf}" <<'EOF_INNER'
#!/usr/bin/env bash
set -euo pipefail

mode="$1"
path="$2"
base="$(basename "$path")"

case "${mode}:${base}" in
  -l:app|-l:origin-app|-l:bad-app)
    cat <<'EOF_OUTER'
      [Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]
EOF_OUTER
    ;;
  -l:interp-missing)
    cat <<'EOF_OUTER'
      [Requesting program interpreter: /lib64/missing-loader.so]
EOF_OUTER
    ;;
  -l:*)
    ;;
  -d:app|-d:interp-missing)
    cat <<'EOF_OUTER'
Dynamic section at offset 0x0 contains 2 entries:
 0x0000000000000001 (NEEDED)             Shared library: [libfoo.so]
 0x0000000000000000 (NULL)               0x0
EOF_OUTER
    ;;
  -d:origin-app)
    cat <<'EOF_OUTER'
Dynamic section at offset 0x0 contains 3 entries:
 0x0000000000000001 (NEEDED)             Shared library: [libbar.so]
 0x000000000000001d (RUNPATH)            Library runpath: [$ORIGIN]
 0x0000000000000000 (NULL)               0x0
EOF_OUTER
    ;;
  -d:bad-app)
    cat <<'EOF_OUTER'
Dynamic section at offset 0x0 contains 2 entries:
 0x0000000000000001 (NEEDED)             Shared library: [libmissing.so]
 0x0000000000000000 (NULL)               0x0
EOF_OUTER
    ;;
  -d:*)
    cat <<'EOF_OUTER'
Dynamic section at offset 0x0 contains 1 entry:
 0x0000000000000000 (NULL)               0x0
EOF_OUTER
    ;;
  *)
    echo "unsupported fake readelf invocation: $*" >&2
    exit 1
    ;;
esac
EOF_INNER
chmod +x "${fake_readelf}"

write_elf() {
  local path="$1"
  mkdir -p "$(dirname "${path}")"
  printf '\177ELFfake\n' > "${path}"
}

expect_failure() {
  local output
  if output="$("$@" 2>&1)"; then
    echo "expected failure: $*" >&2
    exit 1
  fi
  printf '%s\n' "${output}"
}

valid_root="${tmpdir}/valid-root"
mkdir -p "${valid_root}/bin" "${valid_root}/etc" "${valid_root}/lib64" "${valid_root}/usr/bin" "${valid_root}/usr/lib/plugin"
ln -s usr/bin "${valid_root}/bin-link"
ln -s /proc/self/mounts "${valid_root}/etc/mtab"
write_elf "${valid_root}/lib64/ld-linux-x86-64.so.2"
write_elf "${valid_root}/usr/lib/libfoo.so"
write_elf "${valid_root}/usr/bin/app"
write_elf "${valid_root}/usr/lib/plugin/origin-app"
write_elf "${valid_root}/usr/lib/plugin/libbar.so"

python3 "${checker}" --root "${valid_root}" --name valid-root --readelf "${fake_readelf}" >/dev/null

broken_symlink_root="${tmpdir}/broken-symlink-root"
mkdir -p "${broken_symlink_root}/usr/bin"
ln -s missing "${broken_symlink_root}/usr/bin/tool"
broken_symlink_output="$(
  expect_failure python3 "${checker}" --root "${broken_symlink_root}" --name broken-symlink-root --readelf "${fake_readelf}"
)"
if ! rg "broken symlink: /usr/bin/tool -> missing" <<<"${broken_symlink_output}" >/dev/null; then
  echo "expected broken symlink diagnostic" >&2
  printf '%s\n' "${broken_symlink_output}" >&2
  exit 1
fi

missing_library_root="${tmpdir}/missing-library-root"
mkdir -p "${missing_library_root}/lib64" "${missing_library_root}/usr/bin"
write_elf "${missing_library_root}/lib64/ld-linux-x86-64.so.2"
write_elf "${missing_library_root}/usr/bin/bad-app"
missing_library_output="$(
  expect_failure python3 "${checker}" --root "${missing_library_root}" --name missing-library-root --readelf "${fake_readelf}"
)"
if ! rg "missing shared library for /usr/bin/bad-app: libmissing.so" <<<"${missing_library_output}" >/dev/null; then
  echo "expected missing shared library diagnostic" >&2
  printf '%s\n' "${missing_library_output}" >&2
  exit 1
fi

missing_interpreter_root="${tmpdir}/missing-interpreter-root"
mkdir -p "${missing_interpreter_root}/usr/bin" "${missing_interpreter_root}/usr/lib"
write_elf "${missing_interpreter_root}/usr/bin/interp-missing"
write_elf "${missing_interpreter_root}/usr/lib/libfoo.so"
missing_interpreter_output="$(
  expect_failure python3 "${checker}" --root "${missing_interpreter_root}" --name missing-interpreter-root --readelf "${fake_readelf}"
)"
if ! rg "missing ELF interpreter for /usr/bin/interp-missing: /lib64/missing-loader.so" <<<"${missing_interpreter_output}" >/dev/null; then
  echo "expected missing interpreter diagnostic" >&2
  printf '%s\n' "${missing_interpreter_output}" >&2
  exit 1
fi

echo "runtime rootfs checker smoke tests passed"
