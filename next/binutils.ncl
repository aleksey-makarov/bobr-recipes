fun pkgs =>
  let pkg_name = "binutils" in
  let pkg_version = "2.45" in

  let source_name = "%{pkg_name}-src-%{pkg_version}" in
  let gen1_script_name = "buildscript-%{pkg_name}-gen1-%{pkg_version}" in
  let gen1_name = "%{pkg_name}-gen1-%{pkg_version}" in

  let binutils_src_2_45 =
    store.fetch source_name {
      url = [
        "https://sourceware.org/pub/binutils/releases/binutils-2.45.tar.xz",
        "https://mirrors.kernel.org/gnu/binutils/binutils-2.45.tar.xz",
      ],
      hash = "md5:dee5b4267e0305a99a3c9d6131f45759",
    }
  in

  let buildscript_binutils_gen1_2_45 =
    store.text gen1_script_name {
      kind = "build-script",
      source = m%"
        #!/usr/bin/env bash
        set -euo pipefail

        src="${MBUILD_SOURCE_INPUT:?MBUILD_SOURCE_INPUT is required}"
        out="${MBUILD_PRIMARY_OUTPUT:?MBUILD_PRIMARY_OUTPUT is required}"

        cd "/in/${src}"

        if [ ! -x ./configure ]; then
          candidates=()
          for d in ./*; do
            if [ -d "$d" ] && [ -x "$d/configure" ]; then
              candidates+=("$d")
            fi
          done
          if [ "${#candidates[@]}" -eq 1 ]; then
            cd "${candidates[0]}"
          fi
        fi

        mkdir -p build
        cd build

        ../configure                               \
          --prefix=/usr                            \
          --disable-nls                            \
          --enable-gprofng=no                      \
          --disable-werror                         \
          --enable-new-dtags                       \
          --enable-default-hash-style=gnu

        jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
        make -j"${jobs}"
        make DESTDIR="/out/${out}" install
        "%,
    }
  in

  let binutils_gen1_2_45 =
    store.bind binutils_src_2_45 (fun src =>
    store.bind buildscript_binutils_gen1_2_45 (fun script =>
    store.bind pkgs.host_image (fun image =>
    store.binary gen1_name {
      kind = "binary-output",
      optimize = "size",
    } image script [src])))
  in

  {
    include [
      binutils_src_2_45,
      buildscript_binutils_gen1_2_45,
      binutils_gen1_2_45,
    ],
  }
