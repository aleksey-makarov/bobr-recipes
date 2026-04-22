let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let gcc_src = {
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

  let gcc_gen1 = {
    name = "gcc-gen1-15.2.0",
    tag = "Autotools",
    config = {
      pre_configure = {
        name = "link_gcc_prereqs",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            rm -rf gmp mpfr mpc
            ln -s "${gmp}" gmp
            ln -s "${mpfr}" mpfr
            ln -s "${mpc}" mpc
          "%,
        ],
      },
      configure_args = [
        "--enable-languages=c,c++",
        "--disable-multilib",
        "--disable-bootstrap",
        "--disable-fixincludes",
        "--disable-nls",
        "--without-zstd",
      ],
    },
    inputs = {
      image = pkgs.host_image,
      source = gcc_src,
      gmp = pkgs.gmp_src,
      mpfr = pkgs.mpfr_src,
      mpc = pkgs.mpc_src,
    },
  }
  in

  let gcc = {
    name = "gcc-15.2.0",
    tag = "Autotools",
    config = {
      pre_configure = {
        name = "link_gcc_prereqs",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            rm -rf gmp mpfr mpc
            ln -s "${gmp}" gmp
            ln -s "${mpfr}" mpfr
            ln -s "${mpc}" mpc
          "%,
        ],
      },
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
      post_install = {
        name = "add_cc_symlink",
        run_as = "root",
        argv = [
          "ln",
          "-sv",
          "gcc",
          "${out}/usr/bin/cc",
        ],
      },
    },
    inputs = {
      image = pkgs.system_image_0,
      source = gcc_src,
      gmp = pkgs.gmp_src,
      mpfr = pkgs.mpfr_src,
      mpc = pkgs.mpc_src,
    },
  }
  in

  {
    include [
      gcc_src,
      gcc_gen1,
      gcc,
    ],
  }
