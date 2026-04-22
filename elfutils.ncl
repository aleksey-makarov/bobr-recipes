let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let elfutils_src = {
    name = "elfutils-src-0.193",
    tag = "Fetch",
    config = {
      url = "https://sourceware.org/ftp/elfutils/0.193/elfutils-0.193.tar.bz2",
      hash = "md5:ceefa052ded950a4c523688799193a44",
    },
    inputs = {},
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
      image = pkgs.host_image,
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
