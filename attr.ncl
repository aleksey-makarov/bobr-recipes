let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let attr_src = {
    name = "attr-src-2.5.2",
    tag = "Source",
    object_hash = "62530c618f7f6b7594e0b0e886f509775efd10b11ecf348d6768e24fedabde7c",
    origin = {
      type = "http",
      url = "https://download.savannah.gnu.org/releases/attr/attr-2.5.2.tar.gz",
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
      rootfs = pkgs.system_rootfs_2,
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
