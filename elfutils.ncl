let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let elfutils_src = {
    name = "elfutils-src-0.193",
    tag = "Source",
    object_hash = "4a388608efa2361f96d243752cbb19eda5f376ca5be827c4dd2012d08a3b53a9",
    origin = {
      type = "http",
      url = "https://sourceware.org/ftp/elfutils/0.193/elfutils-0.193.tar.bz2",
    },
  }
  in

  let elfutils_rootfs = {
    name = "elfutils-rootfs-0.193",
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
    name = "elfutils-0.193",
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
      rootfs = elfutils_rootfs,
      source = elfutils_src,
    },
  }
  in

  {
    include [
      elfutils_src,
      elfutils_rootfs,
      elfutils,
    ],
  }
