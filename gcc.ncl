let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let gcc_src_15_2_0 =
    recipe.fetch "gcc-src-15.2.0" {
      url = [
        "https://ftp.gnu.org/gnu/gcc/gcc-15.2.0/gcc-15.2.0.tar.xz",
        "https://mirrors.kernel.org/gnu/gcc/gcc-15.2.0/gcc-15.2.0.tar.xz",
      ],
      hash = "md5:b861b092bf1af683c46a8aa2e689a6fd",
    }
  in

  let buildscript_gcc_gen1_15_2_0 =
    recipe.text "buildscript-gcc-gen1-15.2.0" {
      kind = "build-script",
      source = m%"
        #!/usr/bin/env bash
        set -euo pipefail

        src="${MBUILD_SOURCE_INPUT:?MBUILD_SOURCE_INPUT is required}"
        out="${MBUILD_PRIMARY_OUTPUT:?MBUILD_PRIMARY_OUTPUT is required}"

        gcc_root="/in/${src}"
        gmp_root="/in/sources1"
        mpfr_root="/in/sources2"
        mpc_root="/in/sources3"

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

        mkdir -p build
        cd build

        ../configure                     \
          --prefix=/usr                  \
          --disable-nls                  \
          --disable-multilib             \
          --disable-bootstrap            \
          --disable-fixincludes          \
          --without-zstd                 \
          --enable-languages=c,c++

        jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
        make -j"${jobs}"
        make DESTDIR="/out/${out}" install
        "%,
    }
  in

  let gcc_gen1_15_2_0 =
    recipe.binary "gcc-gen1-15.2.0" {
      kind = "binary-output",
      optimize = "size",
    } pkgs.host_image buildscript_gcc_gen1_15_2_0 [
      gcc_src_15_2_0,
      pkgs.gmp_src_6_3_0,
      pkgs.mpfr_src_4_2_2,
      pkgs.mpc_src_1_3_1,
    ]
  in

  let gcc_15_2_0 =
    build.build_bootstrap_autotools {
      name = "gcc-15.2.0",
      sources = [
        gcc_src_15_2_0,
        pkgs.gmp_src_6_3_0,
        pkgs.mpfr_src_4_2_2,
        pkgs.mpc_src_1_3_1,
      ],
      script_config = {
        build_dir = "build",
        pre_configure = m%"
          rm -rf gmp mpfr mpc
          cp -a /in/sources1 gmp
          cp -a /in/sources2 mpfr
          cp -a /in/sources3 mpc
        "%,
        configure_args = [
          "--enable-languages=c,c++",
          "--enable-default-pie",
          "--enable-default-ssp",
          "--disable-multilib",
          "--disable-bootstrap",
          "--disable-fixincludes",
          "--disable-nls",
          "--without-zstd",
        ],
        post_install = "ln -sv gcc \"/out/${out}/usr/bin/cc\"",
      },
    }
  in

  {
    include [
      gcc_src_15_2_0,
      gcc_gen1_15_2_0,
      gcc_15_2_0,
    ],
  }
