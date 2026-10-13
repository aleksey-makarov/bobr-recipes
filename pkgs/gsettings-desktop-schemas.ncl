let recipe = import "../recipe-lib.ncl" in
# gsettings-desktop-schemas -- the org.gnome.desktop.* GSettings schemas (data)
# used across GNOME (mutter, gnome-shell, GTK reads e.g. cursor-size). The
# .gschema.xml install to /usr/share/glib-2.0/schemas and are compiled by the
# qemu_gnome_rootfs finalize step.
# Configure version and hash through `pkgs.gsettings_desktop_schemas_src`.
let branch = recipe.version_prefix 1 in

fun pkgs =>
  let gsettings_desktop_schemas_src = {
    version | default = "50.1",
    name = "gsettings-desktop-schemas-src-%{version}",
    tag = "Source",
    object_hash | default = "0a2aa25082672585d16fcdab61c7b0e33f035fb87476505c794f29565afa485b",
    origin = {
      tag = "Http",
      url = "https://download.gnome.org/sources/gsettings-desktop-schemas/%{branch version}/gsettings-desktop-schemas-%{version}.tar.xz",
    },
  }
  in

  let gsettings_desktop_schemas = {
    name = "gsettings-desktop-schemas-%{inputs.source.version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.gobject_introspection,
      ],
      runtime = [],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dintrospection=true",
      ],
    },
    inputs = {
      source = pkgs.gsettings_desktop_schemas_src,
    },
  }
  in

  {
    include [
      gsettings_desktop_schemas_src,
      gsettings_desktop_schemas,
    ],
  }
