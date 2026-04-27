let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let bc_src = {
    name = "bc-src-7.0.3",
    tag = "Source",
    object_hash = "31e2e5aceea232645423625c5250bbfddce3797565af380db798e283cde0e5ba",
    origin = {
      type = "http",
      url = "https://github.com/gavinhoward/bc/archive/c8dabac65d39fd527a9264a5e505a99b1d8df3d8.tar.gz",
      unpack = true,
    },
    meta = {},
  }
  in

  let bc = {
    name = "bc-7.0.3",
    tag = "Autotools",
    config = {
      configure_args = [
        "--disable-history",
        "--disable-man-pages",
        "--disable-nls",
      ],
    },
    inputs = {
      image = pkgs.host_image,
      source = bc_src,
    },
  }
  in

  {
    include [
      bc_src,
      bc,
    ],
  }
