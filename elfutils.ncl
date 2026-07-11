let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let elfutils_src = fun version => fun hash => {
    name = "elfutils-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://sourceware.org/ftp/elfutils/%{version}/elfutils-%{version}.tar.bz2",
    },
  }
  in

  let elfutils_rootfs = {
    name = "elfutils-rootfs",
    tag = "TreeMerge",
    config = {},
    inputs = {
      base = pkgs.system_rootfs_1,
      bzip2 = pkgs.bzip2_gen1,
      pkgconf = pkgs.pkgconf_gen1,
      zlib = pkgs.zlib,
    },
  }
  in

  let elfutils = {
    version | default = "0.193",
    source_object_hash | default = "7857f44b624f4d8d421df851aaae7b1402cfe6bcdd2d8049f15fc07d3dde7635",
    name = "elfutils-%{version}",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = [
        "--disable-debuginfod",
        "--disable-libdebuginfod",
        "--libdir=/usr/lib64",
        "--with-zlib",
        "--without-bzlib",
        "--without-lzma",
        "--without-zstd",
      ],
    },
    inputs = {
      _rootfs = elfutils_rootfs,
      source = elfutils_src version source_object_hash,
    },
  }
  in

  {
    include [
      elfutils_rootfs,
      elfutils,
    ],
  }
