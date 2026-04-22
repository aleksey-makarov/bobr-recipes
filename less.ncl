let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let less_src = {
    name = "less-src-679",
    tag = "Fetch",
    config = {
      url = "https://www.greenwoodsoftware.com/less/less-679.tar.gz",
      hash = "md5:0386dc14f6a081a94dfb4c2413864eed",
    },
    inputs = {},
  }
  in

  let less_build_image = {
    name = "less-build-image",
    tag = "Image",
    config = { ref_name | default = "less-build-image" } & {},
    inputs =
      { base = pkgs.system_image_2 }
      & recipe.numbered_inputs [
        pkgs.ncurses,
      ],
  }
  in

  let less = {
    name = "less-679",
    tag = "Autotools",
    config = {
      configure_args = [
        "--sysconfdir=/etc",
      ],
    },
    inputs = {
      image = less_build_image,
      source = less_src,
    },
  }
  in

  {
    include [
      less_src,
      less,
    ],
  }
