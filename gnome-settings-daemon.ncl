# gnome-settings-daemon (gsd) -- the session daemon that applies GNOME settings
# (power, color, media keys, peripherals, ...). Needed here for two reasons: it
# installs the org.gnome.settings-daemon.* GSettings schemas that gnome-shell's
# quick-settings code looks up unconditionally at startup (a missing schema
# crashes the shell), and it is a real session service we start under the GNOME
# session. Meson build; the schemas are installed regardless of which plugins are
# enabled, so the plugins that need components we do not ship -- NetworkManager,
# ModemManager (wwan), CUPS, smartcard, USB protection, ALSA, Xwayland/X11 -- are
# all off. The remaining plugins use components we already build (colord, gudev,
# upower, geoclue, libgweather, pulseaudio, polkit, libcanberra, libnotify).
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let gsd_src = fun version =>
    fun hash =>
      {
        name = "gnome-settings-daemon-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/gnome-settings-daemon/50/gnome-settings-daemon-%{version}.tar.xz",
        },
      }
  in

  let gnome_settings_daemon = {
    version | default = "50.1",
    source_object_hash
      | default
      = "dd2c9730914f0ececa0229dd8a8c2940a57ddeb0802434558d4b164d79cfe05c",
    name = "gnome-settings-daemon-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.gnome_desktop,
        pkgs.libgweather,
        pkgs.geocode_glib,
        pkgs.libcanberra,
        pkgs.libnotify,
        pkgs.geoclue,
        pkgs.pulseaudio,
        pkgs.alsa_lib,
        pkgs.networkmanager,
        pkgs.polkit,
        pkgs.upower,
        pkgs.colord,
        pkgs.libgudev,
        pkgs.gsettings_desktop_schemas,
        pkgs.systemd_dev,
        pkgs.dbus,
        pkgs.gobject_introspection,
        pkgs.python,
        pkgs.perl,
        pkgs.gettext,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.gnome_desktop,
        pkgs.libgweather,
        pkgs.geocode_glib,
        pkgs.libcanberra,
        pkgs.libnotify,
        pkgs.geoclue,
        pkgs.pulseaudio,
        pkgs.alsa_lib,
        pkgs.networkmanager,
        pkgs.polkit,
        pkgs.upower,
        pkgs.colord,
        pkgs.libgudev,
        pkgs.gsettings_desktop_schemas,
        pkgs.systemd_libs,
        pkgs.dbus,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dcups=false",
        "-Dsmartcard=false",
        "-Dusb-protection=false",
        "-Dwwan=false",
        "-Dxwayland=false",
      ],
    },
    inputs = {
      source = gsd_src version source_object_hash,
    },
  }
  in

  {
    include [
      gnome_settings_daemon,
    ],
  }
