let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let bc_src = {
    name = "bc-src-7.0.3",
    tag = "Source",
    object_hash = "bbe519b53980f899bb5a9ecba390aa077cf0db48e4047a41e566aa73116a391c",
    origin = {
      type = "http",
      url = "https://github.com/gavinhoward/bc/archive/c8dabac65d39fd527a9264a5e505a99b1d8df3d8.tar.gz",
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
      image = pkgs.buildpack_deps_image,
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
