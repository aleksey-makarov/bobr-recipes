# libvorbis -- reference implementation of the Vorbis audio codec. Provides
# libvorbisfile, which libcanberra uses to decode the event-sound theme .ogg
# files; libcanberra in turn is a hard dependency of gnome-settings-daemon.
# Autotools build; links libogg.
# Configure version and hash through `pkgs.libvorbis_src`.
fun pkgs =>
  let libvorbis_src = {
    version | default = "1.3.7",
    name = "libvorbis-src-%{version}",
    tag = "Source",
    object_hash | default = "b33cc4934322bcbf6efcbacf49e3ca01aadbea4114ec9589d1b1e9d20f72954b",
    origin = {
      tag = "Http",
      url = "https://downloads.xiph.org/releases/vorbis/libvorbis-%{version}.tar.xz",
    },
  }
  in

  let libvorbis = {
    name = "libvorbis-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.libogg,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.libogg,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
      ],
    },
    inputs = {
      source = pkgs.libvorbis_src,
    },
  }
  in

  {
    include [
      libvorbis_src,
      libvorbis,
    ],
  }
