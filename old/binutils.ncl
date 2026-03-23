{
  "buildscript-binutils-pass2-2.45" = {
    type = "text",
    artifact_kind = "build-script",
    outputs = ["buildscript-binutils-pass2-2.45"],
    source = m%"
      #!/usr/bin/env bash
      set -euo pipefail

      src="${MBUILD_SOURCE_INPUT:?MBUILD_SOURCE_INPUT is required}"
      out="${MBUILD_PRIMARY_OUTPUT:?MBUILD_PRIMARY_OUTPUT is required}"

      cd "/in/${src}"

      if [ ! -f ./ltmain.sh ]; then
        candidates=()
        for d in ./*; do
          if [ -d "$d" ] && [ -f "$d/ltmain.sh" ] && [ -x "$d/config.guess" ]; then
            candidates+=("$d")
          fi
        done
        if [ "${#candidates[@]}" -eq 1 ]; then
          cd "${candidates[0]}"
        fi
      fi

      export PATH="/tools/bin:${PATH:-}"

      sed '6031s/$add_dir//' -i ltmain.sh

      mkdir -p build
      cd build

      ../configure                        \
        --prefix=/usr                     \
        --build="$(../config.guess)"      \
        --host=x86_64-lfs-linux-gnu       \
        --disable-nls                     \
        --enable-shared                   \
        --enable-gprofng=no               \
        --disable-werror                  \
        --enable-64-bit-bfd               \
        --enable-new-dtags                \
        --enable-default-hash-style=gnu

      jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
      make -j"${jobs}"
      make DESTDIR="/out/${out}" install

      rm -fv \
        "/out/${out}/usr/lib/libbfd.a" \
        "/out/${out}/usr/lib/libbfd.la" \
        "/out/${out}/usr/lib/libctf.a" \
        "/out/${out}/usr/lib/libctf.la" \
        "/out/${out}/usr/lib/libctf-nobfd.a" \
        "/out/${out}/usr/lib/libctf-nobfd.la" \
        "/out/${out}/usr/lib/libopcodes.a" \
        "/out/${out}/usr/lib/libopcodes.la" \
        "/out/${out}/usr/lib/libsframe.a" \
        "/out/${out}/usr/lib/libsframe.la"
      "%,
  },

  "buildscript-binutils-pass1-2.45" =
    (import "build/autotools.ncl").autotools {
      output = "buildscript-binutils-pass1-2.45",
      prefix = "/tools",
      in_source = false,
      configure_args = [
        "--with-sysroot=/",
        "--target=x86_64-lfs-linux-gnu",
        "--disable-nls",
        "--enable-gprofng=no",
        "--disable-werror",
        "--enable-new-dtags",
        "--enable-default-hash-style=gnu",
      ],
    },

  "binutils-pass1-2.45" = {
    type = "binary",
    inputs = ["binutils-src-2.45", "buildscript-binutils-pass1-2.45", "bootstrap-binary-image"],
    outputs = ["binutils-pass1-2.45"],
  },

  "binutils-pass2-2.45" = {
    type = "binary",
    inputs = [
      "binutils-src-2.45",
      "buildscript-binutils-pass2-2.45",
      "bootstrap-pass1",
    ],
    outputs = ["binutils-pass2-2.45"],
  },

  "binutils-src-2.45" = {
    type = "fetch",
    outputs = ["binutils-src-2.45"],
    url = "https://sourceware.org/pub/binutils/releases/binutils-2.45.tar.xz",
    hash = "md5:dee5b4267e0305a99a3c9d6131f45759",
  },
}
