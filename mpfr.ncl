let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let mpfr_src = {
    name = "mpfr-src-4.2.2",
    tag = "Source",
    object_hash = "f4df0e1987dc5541119a349fdd45ad5e69700f494dfab5b2c4fa2d4e0ee74a20",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/mpfr/mpfr-4.2.2.tar.xz",
        "https://mirrors.kernel.org/gnu/mpfr/mpfr-4.2.2.tar.xz",
      ],
      unpack = true,
    },
    meta = {},
  }
  in

  let mpfr_build_image = {
    name = "mpfr-build-image",
    tag = "Image",
    config = { ref_name | default = "mpfr-build-image" } & {},
    inputs =
      { base = pkgs.system_image }
      & recipe.numbered_inputs [
        pkgs.gmp,
      ],
  }
  in

  let mpfr = {
    name = "mpfr-4.2.2",
    tag = "Autotools",
    config = {
      configure_args = [
        "--disable-static",
        "--enable-thread-safe",
        "--docdir=/usr/share/doc/mpfr-4.2.2",
      ],
    },
    inputs = {
      image = mpfr_build_image,
      source = mpfr_src,
    },
  }
  in

  {
    include [
      mpfr_src,
      mpfr,
    ],
  }
