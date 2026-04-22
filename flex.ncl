let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let flex_src = {
    name = "flex-src-2.6.4",
    tag = "Fetch",
    config = {
      url = "https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz",
      hash = "sha256:e87aae032bf07c26f85ac0ed3250998c37621d95f8bd748b31f15b33c45ee995",
    },
    inputs = {},
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
      image = pkgs.host_image,
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
