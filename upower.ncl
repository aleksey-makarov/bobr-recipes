# upower -- D-Bus service (org.freedesktop.UPower) for power/battery state.
# gnome-shell loads its UPowerGlib-1.0 typelib at startup (the power indicator),
# so libupower-glib + that typelib are a hard dependency of the GNOME session.
# Meson build; introspection on (produces the typelib), the libimobiledevice
# iOS-battery backend off, docs/man off, Linux (udev/logind) OS backend. Upstream
# ships no static release tarball, so we take Debian's repackaged orig tarball.
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
          url = "https://deb.debian.org/debian/pool/main/u/upower/upower_%{version}.orig.tar.bz2",
        },
      }
  in

  let upower = {
    version | default = "1.91.3",
    source_object_hash
      | default
      = "12227b3dcd34c5097bbda25984b192ea0bd5e11dce479358d9ef70415a38e4b6",
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
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.libgudev,
        pkgs.systemd_libs,
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
