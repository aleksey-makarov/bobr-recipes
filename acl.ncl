let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let acl_src = {
    name = "acl-src-2.3.2",
    tag = "Source",
    object_hash = "4531ab451ba78c0e2e04b7688c3a6faf3fb9de76a57ceb7aa8ae8d05f6682b74",
    origin = {
      tag = "Http",
      url = "https://download.savannah.gnu.org/releases/acl/acl-2.3.2.tar.xz",
    },
  }
  in

  let acl_build_rootfs = {
    name = "acl-build-rootfs",
    tag = "TreeMerge",
    config = {},
    inputs =
      { base = pkgs.system_rootfs_2 }
      & recipe.numbered_inputs [
        pkgs.attr,
      ],
  }
  in

  let acl = {
    name = "acl-2.3.2",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = [
        "--disable-static",
        "--docdir=/usr/share/doc/acl-2.3.2",
      ],
    },
    inputs = {
      _rootfs = acl_build_rootfs,
      source = acl_src,
    },
  }
  in

  let acl_libs =
    recipe.split.libs acl "usr/lib/*.so*"
    & {
      deps = {
        build = [],
        runtime = [
          pkgs.glibc_libs,
          pkgs.attr_libs,
        ],
      },
    }
  in

  {
    include [
      acl,
      acl_libs,
    ],
  }
