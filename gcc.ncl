let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let gcc_src = {
    name = "gcc-src-15.2.0",
    tag = "Source",
    object_hash = "5198aafc0a81a63a95c199fb60d4f6636872bc5d51af4e92a152223c880e6a29",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/gcc/gcc-15.2.0/gcc-15.2.0.tar.xz",
        "https://mirrors.kernel.org/gnu/gcc/gcc-15.2.0/gcc-15.2.0.tar.xz",
      ],
      unpack = true,
    },
    meta = {},
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
            ln -s "@{gmp}" gmp
            ln -s "@{mpfr}" mpfr
            ln -s "@{mpc}" mpc
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
            ln -s "@{gmp}" gmp
            ln -s "@{mpfr}" mpfr
            ln -s "@{mpc}" mpc
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
          "@{out}/usr/bin/cc",
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
