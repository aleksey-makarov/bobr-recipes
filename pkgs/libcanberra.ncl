# libcanberra -- event sound library (freedesktop sound theme spec). A hard
# dependency of gnome-settings-daemon (the media-keys/sound plugins). Old (0.30)
# Autotools project: the PulseAudio backend is kept (our session audio), the
# vorbisfile loader decodes the theme .ogg files, and backend modules are loaded
# through libltdl. ALSA, OSS, GStreamer, udev, tdb and all GTK bindings are off.
# Configure version and hash through `pkgs.libcanberra_src`.
fun pkgs =>
  let libcanberra_src = {
    version | default = "0.30",
    name = "libcanberra-src-%{version}",
    tag = "Source",
    object_hash | default = "c2b671e67e0c288a69fc33dc1b6f1b534d07882c2aceed37004bf48c601afa72",
    origin = {
      tag = "Http",
      url = [
        "http://0pointer.de/lennart/projects/libcanberra/libcanberra-%{version}.tar.xz",
        # 0pointer.de is frequently down; the BLFS conglomeration mirror
        # keeps the identical upstream tarball.
        "https://ftp.osuosl.org/pub/blfs/conglomeration/libcanberra/libcanberra-%{version}.tar.xz",
      ],
    },
  }
  in

  let libcanberra = {
    name = "libcanberra-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.libvorbis,
        pkgs.libogg,
        pkgs.pulseaudio,
        pkgs.libtool,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.c_runtime,
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
      source = pkgs.libcanberra_src,
    },
  }
  in

  {
    include [
      libcanberra_src,
      libcanberra,
    ],
  }
