let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let flex_src = {
    name = "flex-src-2.6.4",
    tag = "Source",
    object_hash = "5df5ea9e7af9b55a453c038e840e245efe79baf84da6f37c66505dfa0f51124f",
    origin = {
      type = "http",
      url = "https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz",
      unpack = true,
    },
    meta = {},
  }
  in

  let flex = {
    name = "flex-2.6.4",
    tag = "Autotools",
    config = {
      configure_args = [
        "--disable-nls",
      ],
    },
    inputs = {
      image = pkgs.buildpack_deps_image,
      source = flex_src,
    },
  }
  in

  {
    include [
      flex_src,
      flex,
    ],
  }
