let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let libffi_src = {
    name = "libffi-src-3.5.2",
    tag = "Source",
    object_hash = "afcddd52785db63850239f2d8c39472af103df9a251b35fd03475197eddaeed0",
    origin = {
      type = "http",
      url = "https://github.com/libffi/libffi/releases/download/v3.5.2/libffi-3.5.2.tar.gz",
    },
    meta = {},
  }
  in

  let libffi = {
    name = "libffi-3.5.2",
    tag = "Autotools",
    config = {
      configure_args = [
        "--disable-static",
        "--with-gcc-arch=native",
      ],
    },
    inputs = {
      rootfs = pkgs.system_rootfs_2,
      source = libffi_src,
    },
  }
  in

  {
    include [
      libffi_src,
      libffi,
    ],
  }
