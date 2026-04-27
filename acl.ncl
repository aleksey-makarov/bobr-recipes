let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let acl_src = {
    name = "acl-src-2.3.2",
    tag = "Source",
    object_hash = "18982c81ba304a0f0b9c1d7369845a3a76190aa051a637e21d52a912e55b62d7",
    origin = {
      type = "http",
      url = "https://download.savannah.gnu.org/releases/acl/acl-2.3.2.tar.xz",
      unpack = true,
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
