{
  "gmp-src-6.3.0" = {
    type = "fetch",
    outputs = ["gmp-src-6.3.0"],
    url = [
      "https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz",
      "https://mirrors.kernel.org/gnu/gmp/gmp-6.3.0.tar.xz",
    ],
    hash = "md5:956dc04e864001a9c22429f761f2c283",
  },

  "mpfr-src-4.2.2" = {
    type = "fetch",
    outputs = ["mpfr-src-4.2.2"],
    url = [
      "https://ftp.gnu.org/gnu/mpfr/mpfr-4.2.2.tar.xz",
      "https://mirrors.kernel.org/gnu/mpfr/mpfr-4.2.2.tar.xz",
    ],
    hash = "md5:aad7fac5d8de808a68437840e8e8ecaa",
  },

  "mpc-src-1.3.1" = {
    type = "fetch",
    outputs = ["mpc-src-1.3.1"],
    url = [
      "https://ftp.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz",
      "https://mirrors.kernel.org/gnu/mpc/mpc-1.3.1.tar.gz",
    ],
    hash = "md5:5c9bc658c9fd0f940e8e3e0f09530c62",
  },

  "gcc-src-15.2.0" = {
    type = "fetch",
    outputs = ["gcc-src-15.2.0"],
    url = [
      "https://ftp.gnu.org/gnu/gcc/gcc-15.2.0/gcc-15.2.0.tar.xz",
      "https://mirrors.kernel.org/gnu/gcc/gcc-15.2.0/gcc-15.2.0.tar.xz",
    ],
    hash = "md5:2095d9158192276687d968613f798a06",
  },

  "buildscript-gcc-temp-15.2.0" = {
    type = "text",
    artifact_kind = "build-script",
    outputs = ["buildscript-gcc-temp-15.2.0"],
    source = m%"
      #!/usr/bin/env bash
      set -euo pipefail

      src="${MBUILD_SOURCE_INPUT:?MBUILD_SOURCE_INPUT is required}"
      out="${MBUILD_PRIMARY_OUTPUT:?MBUILD_PRIMARY_OUTPUT is required}"

      gcc_root="/in/${src}"
      gmp_root="/in/gmp-src-6.3.0"
      mpfr_root="/in/mpfr-src-4.2.2"
      mpc_root="/in/mpc-src-1.3.1"

      detect_src_dir() {
        local root="$1"
        local entry
        local -a candidates=()
        for entry in "$root"/*; do
          [ -d "$entry" ] || continue
          candidates+=("$entry")
        done
        if [ "${#candidates[@]}" -eq 1 ]; then
          printf '%s\n' "${candidates[0]}"
        else
          printf '%s\n' "$root"
        fi
      }

      gcc_dir="$(detect_src_dir "${gcc_root}")"
      gmp_dir="$(detect_src_dir "${gmp_root}")"
      mpfr_dir="$(detect_src_dir "${mpfr_root}")"
      mpc_dir="$(detect_src_dir "${mpc_root}")"

      cd "${gcc_dir}"

      rm -rf gmp mpfr mpc
      cp -a "${gmp_dir}" gmp
      cp -a "${mpfr_dir}" mpfr
      cp -a "${mpc_dir}" mpc

      case $(uname -m) in
        x86_64)
          sed -e '/m64=/s/lib64/lib/' -i gcc/config/i386/t-linux64
          ;;
      esac

      export PATH="/tools/bin:${PATH:-}"

      mkdir -p build
      cd build

      ../configure                     \
        --target=x86_64-lfs-linux-gnu  \
        --prefix=/tools                \
        --with-glibc-version=2.42      \
        --with-sysroot=/               \
        --with-newlib                  \
        --without-headers              \
        --enable-default-pie           \
        --enable-default-ssp           \
        --disable-nls                  \
        --disable-shared               \
        --disable-multilib             \
        --disable-threads              \
        --disable-libatomic            \
        --disable-libgomp              \
        --disable-libquadmath          \
        --disable-libssp               \
        --disable-libvtv               \
        --disable-libstdcxx            \
        --enable-languages=c,c++

      jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
      make -j"${jobs}"
      make DESTDIR="/out/${out}" install

      cat ../gcc/limitx.h ../gcc/glimits.h ../gcc/limity.h > \
        "$(dirname "$(/out/${out}/tools/bin/x86_64-lfs-linux-gnu-gcc -print-libgcc-file-name)")/include/limits.h"
      "%,
  },

  "gcc-temp-15.2.0" = {
    type = "binary",
    inputs = [
      "gcc-src-15.2.0",
      "gmp-src-6.3.0",
      "mpfr-src-4.2.2",
      "mpc-src-1.3.1",
      "buildscript-gcc-temp-15.2.0",
      "bootstrap-for-gcc-temp-15.2.0",
    ],
    outputs = ["gcc-temp-15.2.0"],
  },
}
