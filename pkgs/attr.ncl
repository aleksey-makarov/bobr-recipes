let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  # Configure version and hash through pkgs.attr_src.
  let attr_src = {
    version | default = "2.5.2",
    name = "attr-src-%{version}",
    tag = "Source",
    object_hash | default = "f2e97b0ab7ce293681ab701915766190d607a1dba7fae8a718138150b700a70b",
    origin = {
      tag = "Http",
      url = [
        "https://download.savannah.gnu.org/releases/attr/attr-%{version}.tar.xz",
        "https://deb.debian.org/debian/pool/main/a/attr/attr_%{version}.orig.tar.xz",
      ],
    },
  }
  in

  let attr = {
    name = "attr-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.c_runtime,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--sysconfdir=/etc",
        "--docdir=/usr/share/doc/attr-%{inputs.source.version}",
      ],
    },
    inputs = {
      source = pkgs.attr_src,
    },
  }
  in

  let attr_libs =
    recipe.split.libs pkgs.attr "usr/lib/*.so*"
    & {
      deps = {
        build = [],
        runtime = [
          pkgs.c_runtime,
        ],
      },
    }
  in

  {
    include [
      attr,
      attr_libs,
      attr_src,
    ],
  }
