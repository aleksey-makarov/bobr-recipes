fun pkgs =>
  # Configure version and hash through pkgs.automake_src.
  let automake_src = {
    version | default = "1.18.1",
    name = "automake-src-%{version}",
    tag = "Source",
    object_hash | default = "168aa363278351b89af56684448f525a5bce5079d0b6842bd910fdd3f1646887",
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
    name = "automake-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.autoconf,
        pkgs.perl,
      ],
    },
    config = {
      configure_args = [
        "--docdir=/usr/share/doc/automake-%{inputs.source.version}",
      ],
    },
    inputs = {
      source = pkgs.automake_src,
    },
  }
  in

  {
    include [
      automake,
      automake_src,
    ],
  }
