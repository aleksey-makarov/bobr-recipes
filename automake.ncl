let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let automake_src = fun version => fun hash => {
    name = "automake-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/automake/automake-%{version}.tar.xz",
        "https://mirrors.kernel.org/gnu/automake/automake-%{version}.tar.xz",
      ],
    },
  }
  in

  let automake = {
    version | default = "1.18.1",
    source_object_hash | default = "168aa363278351b89af56684448f525a5bce5079d0b6842bd910fdd3f1646887",
    name = "automake-%{version}",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.autoconf,
        pkgs.m4,
        pkgs.perl,
      ],
    },
    config = {
      configure_args = [
        "--docdir=/usr/share/doc/automake-%{version}",
      ],
    },
    inputs = {
      source = automake_src version source_object_hash,
    },
  }
  in

  {
    include [
      automake,
    ],
  }
