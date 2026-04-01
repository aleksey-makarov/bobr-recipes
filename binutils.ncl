let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let pkg_name = "binutils" in
  let pkg_version = "2.45" in

  let source_name = "%{pkg_name}-src-%{pkg_version}" in
  let gen1_script_name = "buildscript-%{pkg_name}-gen1-%{pkg_version}" in
  let gen1_name = "%{pkg_name}-gen1-%{pkg_version}" in

  let binutils_src_2_45 =
    recipe.fetch source_name {
      url = [
        "https://sourceware.org/pub/binutils/releases/binutils-2.45.tar.xz",
        "https://mirrors.kernel.org/gnu/binutils/binutils-2.45.tar.xz",
      ],
      hash = "md5:dee5b4267e0305a99a3c9d6131f45759",
    }
  in

  let buildscript_binutils_gen1_2_45 =
    recipe.text gen1_script_name {
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
          --without-zstd                           \
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
    recipe.binary gen1_name {
      kind = "binary-output",
      optimize = "size",
    } pkgs.host_image buildscript_binutils_gen1_2_45 [binutils_src_2_45]
  in

  let binutils_2_45 =
    build.build_bootstrap_autotools {
      name = "binutils-2.45",
      sources = [binutils_src_2_45],
      script_config = {
        build_dir = "build",
        configure_args = [
          "--libdir=/usr/lib64",
          "--enable-shared",
          "--enable-64-bit-bfd",
          "--enable-new-dtags",
          "--enable-default-hash-style=gnu",
          "--disable-nls",
          "--disable-werror",
          "--disable-gprofng",
          "--without-zstd",
        ],
      },
    }
  in

  {
    include [
      binutils_src_2_45,
      binutils_gen1_2_45,
      binutils_2_45,
    ],
  }
