#!/usr/bin/env bash
set -euo pipefail

# SpiderMonkey (mozjs) build driver. mozjs is built from the full firefox source
# via the standalone js/src/configure in a separate objdir -- NOT via `mach`,
# which is less hermetic and reaches out for toolchains. The firefox tree vendors
# all Rust crates under third_party/rust and ships .cargo/config.toml.in usable
# verbatim, so the build is offline once cargo sees that config.

step="${1:-${BOBR_STEP_NAME:-}}"
step="${step:?step name is required}"
source_dir="${BOBR_SOURCE_DIR:?BOBR_SOURCE_DIR is required}"
# Install into the virgin /stage (SandboxStageRootfs): configure baked
# --prefix=/usr, DESTDIR relocates it, and the lowering's TreeMove re-roots
# /stage -> /.
out_dir="/stage"
build_dir="${BOBR_BUILD_DIR:?BOBR_BUILD_DIR is required}"

objdir="${build_dir}/obj"

jobs() { getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1; }

# Firefox ships .cargo/config.toml.in (crates-io + git sources replaced with the
# in-tree third_party/rust vendor dir). Its header says it can be copied as-is to
# .cargo/config.toml for offline rust builds; do that if the build system did not
# already generate one.
ensure_cargo_offline() {
  if [ ! -f "${source_dir}/.cargo/config.toml" ] \
     && [ -f "${source_dir}/.cargo/config.toml.in" ]; then
    cp "${source_dir}/.cargo/config.toml.in" "${source_dir}/.cargo/config.toml"
  fi
}

# mozjs-140 regression (Bugzilla 1973994): js-config.h.in lost the XP_UNIX /
# XP_WIN placeholders, so the generated (installed) js-config.h never defines
# the platform macro. mozilla/UniquePtrExtensions.h -- reached through the public
# jsapi headers -- gates its UniqueFileHandle typedef on XP_UNIX/XP_WIN, so
# embedders such as gjs fail to compile against our headers. Re-add the
# placeholders (upstream's temporary fix by the gjs maintainer): the build's
# substitution turns `#undef XP_UNIX` into `#define XP_UNIX 1` on Linux and
# leaves XP_WIN undefined, baking the macro into the installed header.
patch_js_config() {
  local f="${source_dir}/js/src/js-config.h.in"
  if [ -f "$f" ] && ! grep -q 'XP_UNIX' "$f"; then
    sed -i 's|#endif /\* js_config_h \*/|/* Controls API in UniquePtrExtensions.h. */\n#undef XP_UNIX\n#undef XP_WIN\n\n#endif /* js_config_h */|' "$f"
  fi
}

mozjs_env() {
  export CARGO_HOME="${build_dir}/.cargo-home"
  export HOME="${build_dir}"
  export MOZBUILD_STATE_PATH="${build_dir}/.mozbuild"
  export SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-0}"
  export CARGO_NET_OFFLINE=true
  export MOZ_NOSPAM=1
  # Compile with gcc; clang is present only for libclang (bindgen).
  export CC=gcc
  export CXX=g++
}

step_configure() {
  ensure_cargo_offline
  patch_js_config
  mozjs_env
  mkdir -p "$objdir"
  cd "$objdir"
  # js/src/configure is a /bin/sh wrapper that invokes the Python configure.py;
  # run it as a shell script, not with python3.
  sh "${source_dir}/js/src/configure" \
    --prefix=/usr \
    --disable-debug \
    --enable-optimize \
    --disable-debug-symbols \
    --disable-jemalloc \
    --with-system-zlib \
    --with-system-icu \
    --with-libclang-path=/usr/lib \
    --disable-tests
}

step_build() {
  mozjs_env
  cd "$objdir"
  make -j"$(jobs)"
}

step_install() {
  mozjs_env
  cd "$objdir"
  mkdir -p "$out_dir"
  make DESTDIR="$out_dir" install
}

case "$step" in
  configure) step_configure ;;
  build) step_build ;;
  install) step_install ;;
  *)
    echo "mozjs-configure build-script: unsupported step '$step'" >&2
    exit 1
    ;;
esac
