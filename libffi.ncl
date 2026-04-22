let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let libffi_src = {
    name = "libffi-src-3.5.2",
    tag = "Fetch",
    config = {
      url = "https://github.com/libffi/libffi/releases/download/v3.5.2/libffi-3.5.2.tar.gz",
      hash = "md5:92af9efad4ba398995abf44835c5d9e9",
    },
    inputs = {},
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
      image = pkgs.system_image_2,
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
