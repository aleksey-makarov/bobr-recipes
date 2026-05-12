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
    meta = {},
  }
  in

  let elfutils = {
    name = "elfutils-0.193",
    tag = "Autotools",
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
      image = pkgs.buildpack_deps_image,
      source = elfutils_src,
    },
  }
  in

  {
    include [
      elfutils_src,
      elfutils,
    ],
  }
