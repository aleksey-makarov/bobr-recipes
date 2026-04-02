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

  let gcc_gen1_15_2_0 =
    recipe.binary "gcc-gen1-15.2.0" {
      kind = "binary-output",
      optimize = "size",
      script_config = {
        build_dir = "build",
        pre_configure = m%"
          rm -rf gmp mpfr mpc
          ln -s /in/sources1 gmp
          ln -s /in/sources2 mpfr
          ln -s /in/sources3 mpc
        "%,
        configure_args = [
          "--enable-languages=c,c++",
          "--disable-multilib",
          "--disable-bootstrap",
          "--disable-fixincludes",
          "--disable-nls",
          "--without-zstd",
        ],
      },
    } pkgs.host_image pkgs.buildscript_autotools [
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
          ln -s /in/sources1 gmp
          ln -s /in/sources2 mpfr
          ln -s /in/sources3 mpc
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
