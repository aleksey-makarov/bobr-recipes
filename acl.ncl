let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let acl_src = fun version => fun hash => {
    name = "acl-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://download.savannah.gnu.org/releases/acl/acl-%{version}.tar.xz",
    },
  }
  in

  let acl = {
    version | default = "2.3.2",
    source_object_hash | default = "97203a72cae99ab89a067fe2210c1cbf052bc492b479eca7d226d9830883b0bd",
    name = "acl-%{version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.attr,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.attr_libs,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--docdir=/usr/share/doc/acl-%{version}",
      ],
    },
    inputs = {
      source = acl_src version source_object_hash,
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
