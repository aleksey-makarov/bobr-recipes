fun pkgs =>
  # Configure version and hash through pkgs.gmp_src.
  let gmp_src = {
    version | default = "6.3.0",
    name = "gmp-src-%{version}",
    tag = "Source",
    object_hash | default = "a3c2b80201b89e68616f4ad30bc66aee4927c3ce50e33929ca819d5c43538898",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/gmp/gmp-%{version}.tar.xz",
        "https://mirrors.kernel.org/gnu/gmp/gmp-%{version}.tar.xz",
      ],
    },
  }
  in

  let gmp = {
    name = "gmp-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.c_runtime,
        pkgs.gcc_libstdcxx,
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
        "--docdir=/usr/share/doc/gmp-%{inputs.source.version}",
      ],
    },
    inputs = {
      source = pkgs.gmp_src,
    },
  }
  in

  {
    include [
      gmp,
      gmp_src,
    ],
  }
