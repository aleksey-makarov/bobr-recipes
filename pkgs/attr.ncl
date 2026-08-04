let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let attr_src = fun version => fun hash => {
    name = "attr-src-%{version}",
    tag = "Source",
    object_hash = hash,
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
    version | default = "2.5.2",
    source_object_hash | default = "f2e97b0ab7ce293681ab701915766190d607a1dba7fae8a718138150b700a70b",
    name = "attr-%{version}",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--sysconfdir=/etc",
        "--docdir=/usr/share/doc/attr-%{version}",
      ],
    },
    inputs = {
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
