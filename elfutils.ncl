let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let elfutils_src = {
    name = "elfutils-src-0.193",
    tag = "Source",
    object_hash = "f269f2c78fef52f24088404a8bf6ec3d7b74458b49e05ffcbe110f487a2adcc9",
    origin = {
      type = "http",
      url = "https://sourceware.org/ftp/elfutils/0.193/elfutils-0.193.tar.bz2",
      unpack = true,
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
