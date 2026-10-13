#!/usr/bin/env bash

# Check that linux.sh follows the final kernel configuration when deciding
# whether to build and install loadable modules. No kernel build is run.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
temporary="$(mktemp -d)"
trap 'rm -rf -- "${temporary}"' EXIT

fail() {
  echo "test-linux-build-script.sh: $*" >&2
  exit 1
}

mkdir -p "${temporary}/bin"
cat >"${temporary}/bin/make" <<'EOF_MAKE'
#!/usr/bin/env bash
set -euo pipefail
printf '<%s>' "$@" >>"${MAKE_LOG:?MAKE_LOG is required}"
printf '\n' >>"${MAKE_LOG}"
EOF_MAKE
chmod +x "${temporary}/bin/make"

run_case() {
  local modules="$1" case_dir source_dir install_dir log
  case_dir="${temporary}/${modules}"
  source_dir="${case_dir}/source"
  install_dir="${case_dir}/install"
  log="${case_dir}/make.log"
  mkdir -p "${source_dir}/arch/x86/boot" "${install_dir}"
  printf 'CONFIG_MODULES=%s\n' "${modules}" >"${source_dir}/.config"
  : >"${source_dir}/arch/x86/boot/bzImage"
  : >"${source_dir}/System.map"
  : >"${log}"

  env \
    PATH="${temporary}/bin:${PATH}" \
    MAKE_LOG="${log}" \
    BOBR_STEP_NAME=build \
    BOBR_LINUX_BUILD_KIND=full \
    BOBR_SOURCE_DIR="${source_dir}" \
    BOBR_INSTALL_DIR="${install_dir}" \
    "${repo_root}/linux/linux.sh"

  if [ "${modules}" = y ]; then
    rg -q '<bzImage><modules>$' "${log}" \
      || fail "CONFIG_MODULES=y did not build modules"
  else
    rg -q '<bzImage>$' "${log}" \
      || fail "CONFIG_MODULES=n did not build bzImage alone"
    ! rg -q '<modules>' "${log}" \
      || fail "CONFIG_MODULES=n attempted to build modules"
  fi

  : >"${log}"
  env \
    PATH="${temporary}/bin:${PATH}" \
    MAKE_LOG="${log}" \
    BOBR_STEP_NAME=install \
    BOBR_LINUX_BUILD_KIND=full \
    BOBR_SOURCE_DIR="${source_dir}" \
    BOBR_INSTALL_DIR="${install_dir}" \
    "${repo_root}/linux/linux.sh"

  if [ "${modules}" = y ]; then
    rg -q '<modules_install>$' "${log}" \
      || fail "CONFIG_MODULES=y did not install modules"
  else
    [ ! -s "${log}" ] \
      || fail "CONFIG_MODULES=n attempted to install modules"
  fi
}

run_case y
run_case n
printf 'Linux build script module tests passed\n'
