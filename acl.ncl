let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let acl_src = {
    name = "acl-src-2.3.2",
    tag = "Source",
    object_hash = "4531ab451ba78c0e2e04b7688c3a6faf3fb9de76a57ceb7aa8ae8d05f6682b74",
    origin = {
      type = "http",
      url = "https://download.savannah.gnu.org/releases/acl/acl-2.3.2.tar.xz",
    },
    meta = {},
  }
  in

  let acl_build_image = {
    name = "acl-build-image",
    tag = "Image",
    config = { ref_name | default = "acl-build-image" } & {},
    inputs =
      { base = pkgs.system_image_2 }
      & recipe.numbered_inputs [
        pkgs.attr,
      ],
  }
  in

  let acl = {
    name = "acl-2.3.2",
    tag = "Autotools",
    config = {
      configure_args = [
        "--disable-static",
        "--docdir=/usr/share/doc/acl-2.3.2",
      ],
    },
    inputs = {
      image = acl_build_image,
      source = acl_src,
    },
  }
  in

  {
    include [
      acl_src,
      acl,
    ],
  }
