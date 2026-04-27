let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let less_src = {
    name = "less-src-679",
    tag = "Source",
    object_hash = "5c06289ae858eec085744ac6af4271ebbf45ac9ae543d1d1c81e46da3683df41",
    origin = {
      type = "http",
      url = "https://www.greenwoodsoftware.com/less/less-679.tar.gz",
      unpack = true,
    },
    meta = {},
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
