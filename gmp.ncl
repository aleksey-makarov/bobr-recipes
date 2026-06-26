let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let gmp_src = {
    name = "gmp-src-6.3.0",
    tag = "Source",
    object_hash = "e86ea25598752f10e3e24ee9480f4043bf5a207e900a2c49a952450f620b7d51",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz",
        "https://mirrors.kernel.org/gnu/gmp/gmp-6.3.0.tar.xz",
      ],
    },
  }
  in

  let gmp = {
    name = "gmp-6.3.0",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
      ],
    },
    config = {
      pre_configure = {
        name = "patch_configure",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          "sed -i '/long long t1;/,+1s/()/(...)/' configure",
        ],
      },
      configure_args = [
        "--enable-cxx",
        "--disable-static",
        # gmp's bundled config.guess runtime-detects the build CPU via
        # /proc/cpuinfo and bakes -march/-mtune into gmp.h (__GMP_CFLAGS),
        # so the build differs across machines. Pass a generic --build triple
        # to stop the autodetect, and --enable-fat so asm routines for all x86
        # sub-archs are compiled in and dispatched at runtime (reproducible
        # code + good performance). Follows nixpkgs.
        "--build=x86_64-pc-linux-gnu",
        "--enable-fat",
        "--docdir=/usr/share/doc/gmp-6.3.0",
      ],
    },
    inputs = {
      source = gmp_src,
    },
  }
  in

  {
    include [
      gmp,
    ],
  }
