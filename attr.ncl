let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let attr_src = {
    name = "attr-src-2.5.2",
    tag = "Source",
    object_hash = "39bf67452fa41d0948c2197601053f48b3d78a029389734332a6309a680c6c87",
    origin = {
      tag = "Http",
      url = "https://download.savannah.gnu.org/releases/attr/attr-2.5.2.tar.gz",
    },
  }
  in

  let attr = {
    name = "attr-2.5.2",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = [
        "--disable-static",
        "--sysconfdir=/etc",
        "--docdir=/usr/share/doc/attr-2.5.2",
      ],
    },
    inputs = {
      _rootfs = pkgs.system_rootfs_2,
      source = attr_src,
    },
  }
  in

  let attr_libs =
    recipe.split.libs attr "usr/lib/*.so*"
    & {
      deps = {
        build = [],
        runtime = [
          pkgs.glibc_libs,
        ],
      },
    }
  in

  {
    include [
      attr,
      attr_libs,
    ],
  }
