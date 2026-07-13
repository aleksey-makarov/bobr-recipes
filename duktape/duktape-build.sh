#!/usr/bin/env bash
set -euo pipefail

# duktape build driver. Upstream ships an amalgamated single-file engine under
# src/ (duktape.c + duktape.h + duk_config.h) and only a non-installing
# Makefile.sharedlibrary, so we compile the shared library and lay out the
# install tree (lib + headers + a pkg-config file) by hand. polkit consumes it
# via dependency('duktape') / -lduktape.
#
# SONAME follows upstream's Makefile.sharedlibrary convention for 2.7.0:
# DUK_VERSION 20700 -> real name libduktape.so.207.20700, SONAME libduktape.so.207.
# Pinned to the recipe's duktape version; bump together on a version change.
pc_version="2.7.0"
soname="libduktape.so.207"
realname="libduktape.so.207.20700"

step="${1:-${BOBR_STEP_NAME:-}}"
step="${step:?step name is required}"
source_dir="${BOBR_SOURCE_DIR:?BOBR_SOURCE_DIR is required}"
out_dir="${BOBR_OUT_DIR:?BOBR_OUT_DIR is required}"
build_dir="${BOBR_BUILD_DIR:?BOBR_BUILD_DIR is required}"

step_build() {
  cd "$build_dir"
  cc -O2 -fPIC -std=c99 -c "${source_dir}/src/duktape.c" \
    -I"${source_dir}/src" -o duktape.o
  cc -shared -Wl,-soname,"${soname}" -o "${realname}" duktape.o -lm
}

step_install() {
  cd "$build_dir"
  install -Dm755 "${realname}" "${out_dir}/usr/lib/${realname}"
  ln -sf "${realname}" "${out_dir}/usr/lib/${soname}"
  ln -sf "${soname}" "${out_dir}/usr/lib/libduktape.so"
  install -Dm644 "${source_dir}/src/duktape.h" "${out_dir}/usr/include/duktape.h"
  install -Dm644 "${source_dir}/src/duk_config.h" "${out_dir}/usr/include/duk_config.h"
  mkdir -p "${out_dir}/usr/lib/pkgconfig"
  cat > "${out_dir}/usr/lib/pkgconfig/duktape.pc" <<EOF
prefix=/usr
exec_prefix=\${prefix}
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: duktape
Description: Duktape embeddable Javascript engine
Version: ${pc_version}
Libs: -L\${libdir} -lduktape
Libs.private: -lm
Cflags: -I\${includedir}
EOF
}

case "$step" in
  build) step_build ;;
  install) step_install ;;
  *)
    echo "duktape build-script: unsupported step '$step'" >&2
    exit 1
    ;;
esac
