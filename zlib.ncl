let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let zlib_src = {
    name = "zlib-src-1.3.1",
    tag = "Source",
    object_hash = "1cbe3faca1e06ad72608148a8451eb8bd555200216adedd8ef2417fa9c539304",
    origin = {
      type = "http",
      url = "https://zlib.net/fossils/zlib-1.3.1.tar.gz",
    },
  }
  in

  let zlib = {
    name = "zlib-1.3.1",
    tag = "Autotools",
    config = {
      configure_args = [
        "--libdir=/usr/lib64",
      ],
    },
    inputs = {
      rootfs = pkgs.system_rootfs_1,
      source = zlib_src,
    },
  }
  in

  let zlib_autotools_package = {
    name = "zlib-autotools-package-1.3.1",
    tag = "AutotoolsPackage",
    deps = {
      build = [
        pkgs.linux_headers,
        pkgs.glibc,
        pkgs.binutils,
        pkgs.gcc,
        pkgs.bash_gen1,
        pkgs.make_gen1,
        pkgs.coreutils_gen1,
        pkgs.sed_gen1,
        pkgs.grep_gen1,
        pkgs.gzip_gen1,
        pkgs.tar_gen1,
        pkgs.findutils_gen1,
      ],
      runtime = [
        pkgs.glibc,
      ],
    },
    config = {
      configure_args = [
        "--libdir=/usr/lib64",
      ],
    },
    inputs = {
      build_base = pkgs.base_filesystem,
      source = zlib_src,
    },
  }
  in

  {
    include [
      zlib_src,
      zlib,
      zlib_autotools_package,
    ],
  }
