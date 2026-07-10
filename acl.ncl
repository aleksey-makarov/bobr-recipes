let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let acl_src = {
    name = "acl-src-2.3.2",
    tag = "Source",
    object_hash = "97203a72cae99ab89a067fe2210c1cbf052bc492b479eca7d226d9830883b0bd",
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
