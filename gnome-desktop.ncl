let recipe = import "recipe-lib.ncl" in
# gnome-desktop -- the libgnome-desktop-4 support library (GnomeBG wallpapers,
# GnomeLanguages, thumbnailing, ...). gnome-shell links gnome-desktop-4. GNOME 50
# pins the 44.x stable series. Meson build; GTK4 library only (the legacy GTK3
# libgnome-desktop-3.0 and its X11/xrandr deps are off), docs/tests off, udev and
# systemd integration off. The thumbnail sandbox uses libseccomp.
# `version`/`source_object_hash`/`series` are node fields (overridable).
let series = recipe.version_prefix 1 in

fun pkgs =>
  let gnome_desktop_src = fun version =>
    fun hash =>
      {
        name = "gnome-desktop-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/gnome-desktop/%{series version}/gnome-desktop-%{version}.tar.xz",
        },
      }
  in

  let gnome_desktop = {
    version | default = "44.5",
    source_object_hash
      | default
      = "20e0995a6e3a03e8c1026c5a27bc3f45e69ffcc392ad743dcab6107a541d232f",
    name = "gnome-desktop-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.gtk4,
        pkgs.gdk_pixbuf,
        pkgs.gsettings_desktop_schemas,
        pkgs.fontconfig,
        pkgs.xkeyboard_config,
        pkgs.libxkbcommon,
        pkgs.iso_codes,
        pkgs.libseccomp,
        pkgs.gobject_introspection,
        pkgs.gettext,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.gtk4,
        pkgs.gdk_pixbuf,
        pkgs.gsettings_desktop_schemas,
        pkgs.fontconfig,
        pkgs.libxkbcommon,
        pkgs.iso_codes,
        pkgs.libseccomp,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dbuild_gtk4=true",
        "-Dlegacy_library=false",
        "-Dudev=disabled",
        "-Dsystemd=disabled",
        "-Ddesktop_docs=false",
        "-Dgtk_doc=false",
        "-Dinstalled_tests=false",
      ],
    },
    inputs = {
      source = gnome_desktop_src version source_object_hash,
    },
  }
  in

  {
    include [
      gnome_desktop,
    ],
  }
