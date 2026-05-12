let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let mpfr_src = {
    name = "mpfr-src-4.2.2",
    tag = "Source",
    object_hash = "e04bf6225b30a6ca872935e6f74f6a8072b898e147e97b23dad9f2d4ea758994",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/mpfr/mpfr-4.2.2.tar.xz",
        "https://mirrors.kernel.org/gnu/mpfr/mpfr-4.2.2.tar.xz",
      ],
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
