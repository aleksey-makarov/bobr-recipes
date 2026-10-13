# libogg -- reference implementation of the Ogg container format. Pulled in only
# as a dependency of libvorbis (and thus libcanberra, gnome-settings-daemon's
# sound backend). Plain Autotools build with no external dependencies.
# Configure version and hash through `pkgs.libogg_src`.
fun pkgs =>
  let libogg_src = {
    version | default = "1.3.5",
    name = "libogg-src-%{version}",
    tag = "Source",
    object_hash | default = "c4d91be36fc8e54deae7575241e03f4211eb102afb3fc0775fbbc1b740016705",
    origin = {
      tag = "Http",
      url = "https://downloads.xiph.org/releases/ogg/libogg-%{version}.tar.xz",
    },
  }
  in

  let libogg = {
    name = "libogg-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.c_runtime,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
      ],
    },
    inputs = {
      source = pkgs.libogg_src,
    },
  }
  in

  {
    include [
      libogg_src,
      libogg,
    ],
  }
