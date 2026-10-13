let recipe = import "../recipe-lib.ncl" in
# gnome-session -- the GNOME session manager. It registers
# org.gnome.SessionManager, seeds the D-Bus/systemd activation environment (so
# D-Bus-activated apps like org.gnome.Settings inherit XDG_CURRENT_DESKTOP), and
# starts the session's components (gnome-shell, gnome-settings-daemon) in order
# via its systemd user target. Replaces the earlier standalone
# `gnome-shell --display-server` launch. Meson build; man pages/docbook off.
# Configure version and hash through `pkgs.gnome_session_src`.
fun pkgs =>
  let series = recipe.version_prefix 1 in

  let gnome_session_src = {
    version | default = "50.1",
    name = "gnome-session-src-%{version}",
    tag = "Source",
    object_hash | default = "6289b6afa44d3e4c999ce5761ff8b2c10ba309f55f9425f2b13f98208c81f6fb",
    origin = {
      tag = "Http",
      url = "https://download.gnome.org/sources/gnome-session/%{series version}/gnome-session-%{version}.tar.xz",
    },
  }
  in

  let gnome_session = {
    name = "gnome-session-%{inputs.source.version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.gnome_desktop,
        pkgs.systemd_dev,
        pkgs.gettext,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.glib,
        pkgs.gnome_desktop,
        pkgs.systemd_libs,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dman=false",
        "-Ddocbook=false",
      ],
    },
    inputs = {
      source = pkgs.gnome_session_src,
    },
  }
  in

  {
    include [
      gnome_session_src,
      gnome_session
    ]
  }
