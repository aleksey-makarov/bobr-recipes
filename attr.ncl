let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let attr_src = {
    name = "attr-src-2.5.2",
    tag = "Fetch",
    config = {
      url = "https://download.savannah.gnu.org/releases/attr/attr-2.5.2.tar.gz",
      hash = "md5:227043ec2f6ca03c0948df5517f9c927",
    },
    inputs = {},
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
