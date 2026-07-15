# libogg -- reference implementation of the Ogg container format. Pulled in only
# as a dependency of libvorbis (and thus libcanberra, gnome-settings-daemon's
# sound backend). Plain Autotools build with no external dependencies.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let libogg_src = fun version =>
    fun hash =>
      {
        name = "libogg-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://downloads.xiph.org/releases/ogg/libogg-%{version}.tar.xz",
        },
      }
  in

  let libogg = {
    version | default = "1.3.5",
    source_object_hash
      | default
      = "c4d91be36fc8e54deae7575241e03f4211eb102afb3fc0775fbbc1b740016705",
    name = "libogg-%{version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
      ],
    },
    inputs = {
      source = libogg_src version source_object_hash,
    },
  }
  in

  {
    include [
      libogg,
    ],
  }
