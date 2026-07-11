let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let attr_src = fun version => fun hash => {
    name = "attr-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://download.savannah.gnu.org/releases/attr/attr-%{version}.tar.gz",
    },
  }
  in

  let attr = {
    version | default = "2.5.2",
    source_object_hash | default = "39bf67452fa41d0948c2197601053f48b3d78a029389734332a6309a680c6c87",
    name = "attr-%{version}",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = [
        "--disable-static",
        "--sysconfdir=/etc",
        "--docdir=/usr/share/doc/attr-%{version}",
      ],
    },
    inputs = {
      _rootfs = pkgs.system_rootfs_2,
      source = attr_src version source_object_hash,
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
