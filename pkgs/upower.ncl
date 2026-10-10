# upower -- D-Bus service (org.freedesktop.UPower) for power/battery state.
# gnome-shell loads its UPowerGlib-1.0 typelib at startup (the power indicator),
# so libupower-glib + that typelib are a hard dependency of the GNOME session.
# Meson build; introspection on (produces the typelib), the libimobiledevice
# iOS-battery backend off, docs/man off, Linux (udev/logind) OS backend.
# Fetch the upstream release-tag archive from freedesktop.org GitLab; Debian's
# active pool removes superseded versions and is not a persistent source URL.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let upower_src = fun version =>
    fun hash =>
      {
        name = "upower-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://gitlab.freedesktop.org/upower/upower/-/archive/v%{version}/upower-v%{version}.tar.bz2",
        },
      }
  in

  let upower = {
    version | default = "1.91.5",
    source_object_hash
      | default
      = "c465a1c7fc05d00ac2bc7321c19b9b7e479410d8392bd7eb3e714275729629fd",
    name = "upower-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.libgudev,
        pkgs.systemd_dev,
        pkgs.polkit,
        pkgs.gobject_introspection,
        pkgs.python,
        pkgs.gettext,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.glib,
        pkgs.libgudev,
        pkgs.polkit,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dintrospection=enabled",
        "-Didevice=disabled",
        "-Dgtk-doc=false",
        "-Dman=false",
        "-Dos_backend=linux",
      ],
    },
    inputs = {
      source = upower_src version source_object_hash,
    },
  }
  in

  {
    include [
      upower,
    ],
  }
