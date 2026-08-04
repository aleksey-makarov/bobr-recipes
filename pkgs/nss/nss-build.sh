#!/usr/bin/env bash
set -euo pipefail

# NSS build driver. NSS ships no configure/`make install`; it builds with its own
# coreconf make system into dist/Linux*/ and is installed by hand (the LFS/BLFS
# recipe). We use the make build (not build.sh) to avoid the gyp/ninja toolchain.
# NSPR, system sqlite and system zlib come from the build rootfs.

step="${1:-${BOBR_STEP_NAME:-}}"
step="${step:?step name is required}"
source_dir="${BOBR_SOURCE_DIR:?BOBR_SOURCE_DIR is required}"
# Install into the virgin /stage (SandboxStageRootfs): everything lands under
# /stage/usr so the recursive `chown -R 0:0` touches only nss's own files, and
# the lowering's TreeMove re-roots /stage -> /.
out_dir="/stage"

make_flags=(
  BUILD_OPT=1
  NSPR_INCLUDE_DIR=/usr/include/nspr
  USE_SYSTEM_ZLIB=1
  ZLIB_LIBS=-lz
  NSS_ENABLE_WERROR=0
  USE_64=1
  NSS_USE_SYSTEM_SQLITE=1
  NSS_DISABLE_GTESTS=1
)

step_build() {
  cd "${source_dir}/nss"
  make "${make_flags[@]}"
}

# The HMAC key for the FIPS integrity checksums (.chk). shlibsign defaults to
# HMAC-SHA256 but, without -K, embeds a *random* key each run -- the .chk stores
# the key next to the MAC, so both fields vary run-to-run and break
# reproducibility (nixpkgs leaves this non-reproducible). The key is not a
# secret -- softoken reads it back from the .chk to verify -- so we use the
# sandbox's deterministic per-build seed (BOBR_BUILD_SEED, 64 hex chars),
# yielding a reproducible checksum without a magic constant in the recipe.
nss_chk_key="${BOBR_BUILD_SEED:?BOBR_BUILD_SEED is required}"

step_install() {
  cd "${source_dir}/dist"
  mkdir -p "${out_dir}/usr/lib/pkgconfig" "${out_dir}/usr/include/nss"
  install -m755 Linux*/lib/*.so "${out_dir}/usr/lib/"

  # Regenerate the FIPS integrity checksums (.chk) deterministically, signing
  # the just-installed real libraries (the dist .chk are symlinks into the build
  # tree, so signing them in place loops). `find` avoids dereferencing them; we
  # only need the set of library basenames that get a checksum.
  local shlibsign chkpath name so
  shlibsign="${PWD}/$(ls -d Linux*/bin)/shlibsign"
  while IFS= read -r chkpath; do
    name="$(basename "$chkpath" .chk)"
    so="${out_dir}/usr/lib/${name}.so"
    [ -f "$so" ] || continue
    LD_LIBRARY_PATH="${out_dir}/usr/lib:/usr/lib" \
      "$shlibsign" -v -i "$so" -o "${so%.so}.chk" -K "$nss_chk_key"
  done < <(find Linux*/lib -maxdepth 1 -name '*.chk')
  cp -RL public/nss/* private/nss/* "${out_dir}/usr/include/nss/"
  # The make build does not emit nss.pc; write it by hand. Cflags/Libs are what
  # consumers (evolution-data-server's camel) compile and link against; nspr is
  # pulled transitively so its include dir and libs come along.
  cat > "${out_dir}/usr/lib/pkgconfig/nss.pc" <<'EOF'
prefix=/usr
exec_prefix=/usr
libdir=/usr/lib
includedir=/usr/include/nss

Name: NSS
Description: Network Security Services
Version: 3.125
Requires: nspr
Libs: -L${libdir} -lnss3 -lnssutil3 -lsmime3 -lssl3
Cflags: -I${includedir}
EOF
  # Everything installs root-owned so a TreeMerge into other root-owned trees
  # does not clash on directory metadata.
  chown -R 0:0 "${out_dir}/usr"
}

case "$step" in
  build) step_build ;;
  install) step_install ;;
  *)
    echo "nss build-script: unsupported step '$step'" >&2
    exit 1
    ;;
esac
