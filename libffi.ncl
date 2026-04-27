let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let libffi_src = {
    name = "libffi-src-3.5.2",
    tag = "Source",
    object_hash = "814f16b2755ecf7390072198fbbcce558aee5a655d63ced1537eb35c2ecc2232",
    origin = {
      type = "http",
      url = "https://github.com/libffi/libffi/releases/download/v3.5.2/libffi-3.5.2.tar.gz",
      unpack = true,
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
