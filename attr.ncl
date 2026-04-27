let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let attr_src = {
    name = "attr-src-2.5.2",
    tag = "Source",
    object_hash = "c0132672e62d9b4830b8e3ed6725b2cd0cd02eb448fffa127685b7bf444007b4",
    origin = {
      type = "http",
      url = "https://download.savannah.gnu.org/releases/attr/attr-2.5.2.tar.gz",
      unpack = true,
    },
    meta = {},
  }
  in

  let attr = {
    name = "attr-2.5.2",
    tag = "Autotools",
    config = {
      configure_args = [
        "--disable-static",
        "--sysconfdir=/etc",
        "--docdir=/usr/share/doc/attr-2.5.2",
      ],
    },
    inputs = {
      image = pkgs.system_image_2,
      source = attr_src,
    },
  }
  in

  {
    include [
      attr_src,
      attr,
    ],
  }
