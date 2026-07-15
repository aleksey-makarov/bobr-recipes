# gnome-session -- the GNOME session manager. It registers
# org.gnome.SessionManager, seeds the D-Bus/systemd activation environment (so
# D-Bus-activated apps like org.gnome.Settings inherit XDG_CURRENT_DESKTOP), and
# starts the session's components (gnome-shell, gnome-settings-daemon) in order
# via its systemd user target. Replaces the earlier standalone
# `gnome-shell --display-server` launch. Meson build; man pages/docbook off.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let series = fun v => std.array.at 0 (std.string.split "." v) in

  let gnome_session_src = fun version =>
    fun hash =>
      {
        name = "gnome-session-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/gnome-session/%{series version}/gnome-session-%{version}.tar.xz",
        },
      }
  in

  let gnome_session = {
    version | default = "50.1",
    source_object_hash
      | default
      = "6289b6afa44d3e4c999ce5761ff8b2c10ba309f55f9425f2b13f98208c81f6fb",
    name = "gnome-session-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.gnome_desktop,
        pkgs.systemd_dev,
        pkgs.json_glib,
        pkgs.gettext,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.gnome_desktop,
        pkgs.systemd_libs,
        pkgs.json_glib,
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
      source = gnome_session_src version source_object_hash,
    },
  }
  in

  { include [ gnome_session ] }
