# graphene -- lightweight vector/matrix math used by GTK4 and mutter.
# `version`/`source_object_hash` are node fields (overridable), as in linux.ncl.

let branch = fun version =>
  let m = std.string.find "^([0-9]+[.][0-9]+)[.]" version in
  if m.index == 0 && std.array.length m.groups == 1 then std.array.at 0 m.groups
  else std.fail_with "graphene.ncl: version must be MAJOR.MINOR.PATCH"
in

fun pkgs =>
  let mk_src = fun version =>
    fun hash =>
      {
        name = "graphene-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/graphene/%{branch version}/graphene-%{version}.tar.xz",
        },
      }
  in

  let graphene = {
    version | default = "1.10.8",
    source_object_hash | default = "a37bb0e78a419dcbeaa9c7027bcff52f5ec2367c25ec859da31dfde2928f279a",
    name = "graphene-%{version}",
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
        "-Dtests=false",
        "-Dgtk_doc=false",
        "-Dintrospection=enabled",
      ],
    },
    inputs = {
      source = mk_src version source_object_hash,
    },
  }
  in

  {
    include [
      graphene,
    ],
  }
