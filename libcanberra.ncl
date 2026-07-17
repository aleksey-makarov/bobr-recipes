# libcanberra -- event sound library (freedesktop sound theme spec). A hard
# dependency of gnome-settings-daemon (the media-keys/sound plugins). Old (0.30)
# Autotools project: the PulseAudio backend is kept (our session audio), the
# vorbisfile loader decodes the theme .ogg files, and backend modules are loaded
# through libltdl. ALSA, OSS, GStreamer, udev, tdb and all GTK bindings are off.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let libcanberra_src = fun version =>
    fun hash =>
      {
        name = "libcanberra-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "http://0pointer.de/lennart/projects/libcanberra/libcanberra-%{version}.tar.xz",
        },
      }
  in

  let libcanberra = {
    version | default = "0.30",
    source_object_hash
      | default
      = "c2b671e67e0c288a69fc33dc1b6f1b534d07882c2aceed37004bf48c601afa72",
    name = "libcanberra-%{version}",
    tag = "AutotoolsInstall",
    deps = {
      build = [
        pkgs.libvorbis,
        pkgs.libogg,
        pkgs.pulseaudio,
        pkgs.libtool,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.libvorbis,
        pkgs.libogg,
        pkgs.pulseaudio,
        pkgs.libtool,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--disable-alsa",
        "--disable-oss",
        "--disable-gstreamer",
        "--disable-udev",
        "--disable-tdb",
        "--disable-gtk",
        "--disable-gtk3",
      ],
    },
    inputs = {
      source = libcanberra_src version source_object_hash,
    },
  }
  in

  {
    include [
      libcanberra,
    ],
  }
