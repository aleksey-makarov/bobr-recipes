let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let gcc_src =
    {
      name = "gcc-src-15.2.0",
      tag = "Fetch",
      config = {
      url = [
        "https://ftp.gnu.org/gnu/gcc/gcc-15.2.0/gcc-15.2.0.tar.xz",
        "https://mirrors.kernel.org/gnu/gcc/gcc-15.2.0/gcc-15.2.0.tar.xz",
      ],
      hash = "md5:b861b092bf1af683c46a8aa2e689a6fd",
      },
      inputs = {},
    }
  in

  let gcc_gen1 =
    recipe.binary "gcc-gen1-15.2.0" {
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
      gcc_src,
      pkgs.gmp_src,
      pkgs.mpfr_src,
      pkgs.mpc_src,
    ]
  in

  let gcc =
    recipe.binary "gcc-15.2.0" {
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
        post_install = "ln -sv gcc \"${MBUILD_INSTALL_DIR}/usr/bin/cc\"",
      },
    } pkgs.system_image_0 pkgs.buildscript_autotools [
      gcc_src,
      pkgs.gmp_src,
      pkgs.mpfr_src,
      pkgs.mpc_src,
    ]
  in

  {
    include [
      gcc_src,
      gcc_gen1,
      gcc,
    ],
  }
