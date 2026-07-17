# libvorbis -- reference implementation of the Vorbis audio codec. Provides
# libvorbisfile, which libcanberra uses to decode the event-sound theme .ogg
# files; libcanberra in turn is a hard dependency of gnome-settings-daemon.
# Autotools build; links libogg.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let libvorbis_src = fun version =>
    fun hash =>
      {
        name = "libvorbis-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://downloads.xiph.org/releases/vorbis/libvorbis-%{version}.tar.xz",
        },
      }
  in

  let libvorbis = {
    version | default = "1.3.7",
    source_object_hash
      | default
      = "b33cc4934322bcbf6efcbacf49e3ca01aadbea4114ec9589d1b1e9d20f72954b",
    name = "libvorbis-%{version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.libogg,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.libogg,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
      ],
    },
    inputs = {
      source = libvorbis_src version source_object_hash,
    },
  }
  in

  {
    include [
      libvorbis,
    ],
  }
