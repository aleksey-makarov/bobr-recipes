let recipe = import "recipe-lib.ncl" in
let version = "2.73" in
let hashes = {
  "2.72" = "b3e588c79a56d7cb5f8dce6bf383ec1c01b4a85ef5700ef967ad08de7cbfc8ab",
  "2.73" = "cb8c3d26e2faecb5ddf70e8cf44c4857467a848339dd535669a6367dae9b52fb",
} in

fun pkgs =>
  let autoconf_src = {
    name = "autoconf-src-%{version}",
    tag = "Source",
    object_hash = hashes."%{version}",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/autoconf/autoconf-%{version}.tar.xz",
        "https://mirrors.kernel.org/gnu/autoconf/autoconf-%{version}.tar.xz",
      ],
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
    name = "autoconf-%{version}",
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
