let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let autoconf_src = {
    name = "autoconf-src-2.72",
    tag = "Source",
    object_hash = "b3e588c79a56d7cb5f8dce6bf383ec1c01b4a85ef5700ef967ad08de7cbfc8ab",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/autoconf/autoconf-2.72.tar.xz",
        "https://mirrors.kernel.org/gnu/autoconf/autoconf-2.72.tar.xz",
      ],
      unpack = true,
    },
    meta = {},
  }
  in

  let autoconf_build_image = {
    name = "autoconf-build-image",
    tag = "Image",
    config = { ref_name | default = "autoconf-build-image" } & {},
    inputs =
      { base = pkgs.system_image_2 }
      & recipe.numbered_inputs [
        pkgs.perl,
        pkgs.inetutils,
      ],
  }
  in

  let autoconf = {
    name = "autoconf-2.72",
    tag = "Autotools",
    config = {},
    inputs = {
      image = autoconf_build_image,
      source = autoconf_src,
    },
  }
  in

  {
    include [
      autoconf_src,
      autoconf,
    ],
  }
