# gsettings-desktop-schemas -- the org.gnome.desktop.* GSettings schemas (data)
# used across GNOME (mutter, gnome-shell, GTK reads e.g. cursor-size). The
# .gschema.xml install to /usr/share/glib-2.0/schemas and are compiled by the
# gnome_rootfs finalize step. `version`/`source_object_hash` are node fields (overridable),
# as in linux.ncl.

let branch = fun version =>
  let m = std.string.find "^([0-9]+)" version in
  if m.index == 0 && std.array.length m.groups == 1 then std.array.at 0 m.groups
  else std.fail_with "gsettings-desktop-schemas.ncl: version must start with a number"
in

fun pkgs =>
  let mk_src = fun version =>
    fun hash =>
      {
        name = "gsettings-desktop-schemas-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/gsettings-desktop-schemas/%{branch version}/gsettings-desktop-schemas-%{version}.tar.xz",
        },
      }
  in

  let gsettings_desktop_schemas = {
    version | default = "50.1",
    source_object_hash | default = "0a2aa25082672585d16fcdab61c7b0e33f035fb87476505c794f29565afa485b",
    name = "gsettings-desktop-schemas-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.gobject_introspection,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.glib,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dintrospection=true",
      ],
    },
    inputs = {
      source = mk_src version source_object_hash,
    },
  }
  in

  {
    include [
      gsettings_desktop_schemas,
    ],
  }
