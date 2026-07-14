# PulseAudio -- built CLIENT-ONLY (-Ddaemon=false) to provide libpulse and
# libpulse-mainloop-glib, which gnome-shell's bundled gvc (volume control)
# subproject links against. Skipping the daemon drops the whole server-side
# dependency surface (ALSA, udev, bluez, X11, speex, webrtc, ...); the remaining
# hard dep is libsndfile. Meson build. `version`/`source_object_hash` are node
# fields (overridable).
fun pkgs =>
  let pulseaudio_src = fun version =>
    fun hash =>
      {
        name = "pulseaudio-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://www.freedesktop.org/software/pulseaudio/releases/pulseaudio-%{version}.tar.xz",
        },
      }
  in

  let pulseaudio = {
    version | default = "17.0",
    source_object_hash
      | default
      = "053794d6671a3e397d849e478a80b82a63cb9d8ca296bd35b73317bb5ceb87b5",
    name = "pulseaudio-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.dbus,
        pkgs.libsndfile,
        pkgs.systemd_dev,
        pkgs.gettext,
        pkgs.m4,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.dbus,
        pkgs.libsndfile,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Ddaemon=false",
        "-Ddoxygen=false",
        "-Dman=false",
        "-Dtests=false",
        "-Dgsettings=disabled",
      ],
    },
    inputs = {
      source = pulseaudio_src version source_object_hash,
    },
  }
  in

  {
    include [
      pulseaudio,
    ],
  }
