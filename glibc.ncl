let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let glibc_fhs_patch_2_42 =
    recipe.fetch "glibc-fhs-patch-2.42" {
      url = "https://www.linuxfromscratch.org/patches/lfs/12.4/glibc-2.42-fhs-1.patch",
      hash = "md5:9a5997c3452909b1769918c759eff8a2",
      unpack = false,
    }
  in

  let glibc_src_2_42 =
    recipe.fetch "glibc-src-2.42" {
      url = [
        "https://ftp.gnu.org/gnu/glibc/glibc-2.42.tar.xz",
        "https://mirrors.kernel.org/gnu/glibc/glibc-2.42.tar.xz",
      ],
      hash = "md5:23c6f5a27932b435cae94e087cb8b1f5",
    }
  in

  let buildscript_glibc_gen1_2_42 =
    recipe.text "buildscript-glibc-gen1-2.42" {
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

        patch -Np1 -i /in/sources1
        mkdir -p build
        cd build

        echo "rootsbindir=/usr/sbin" > configparms

        ../configure                               \
          --prefix=/usr                            \
          --disable-nscd                           \
          --without-selinux                        \
          --enable-kernel=5.4

        jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
        make -j"${jobs}"
        make DESTDIR="/out/${out}" install
        "%,
    }
  in

  let glibc_gen1_build_image =
    recipe.image "glibc-gen1-build-image" {
      mode = "layered",
    } pkgs.host_image [pkgs.gawk_gen1_5_3_2, pkgs.bison_gen1_3_8_2]
  in

  let glibc_gen1_2_42 =
    recipe.binary "glibc-gen1-2.42" {
      kind = "binary-output",
      optimize = "size",
    } glibc_gen1_build_image buildscript_glibc_gen1_2_42 [glibc_src_2_42, glibc_fhs_patch_2_42]
  in

  let glibc_2_42 =
    build.build_bootstrap_autotools {
      name = "glibc-2.42",
      sources = [glibc_src_2_42, glibc_fhs_patch_2_42],
      script_config = {
        build_dir = "build",
        pre_configure = m%"
          patch -Np1 -i /in/sources1
          mkdir -p build
          echo "rootsbindir=/usr/sbin" > build/configparms
        "%,
        configure_args = [
          "--disable-werror",
          "--enable-kernel=4.19",
          "--enable-stack-protector=strong",
          "--disable-nscd",
          "--without-selinux",
        ],
      },
    }
  in

  {
    include [
      glibc_fhs_patch_2_42,
      glibc_src_2_42,
      glibc_gen1_build_image,
      glibc_gen1_2_42,
      glibc_2_42,
    ],
  }
