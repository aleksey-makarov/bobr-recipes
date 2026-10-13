let recipe = import "../recipe-lib.ncl" in
# graphene -- lightweight vector/matrix math used by GTK4 and mutter.
# Configure version and hash through `pkgs.graphene_src`.
let branch = recipe.version_prefix 2 in

fun pkgs =>
  let graphene_src = {
    version | default = "1.10.8",
    name = "graphene-src-%{version}",
    tag = "Source",
    object_hash | default = "a37bb0e78a419dcbeaa9c7027bcff52f5ec2367c25ec859da31dfde2928f279a",
    origin = {
      tag = "Http",
      url = "https://download.gnome.org/sources/graphene/%{branch version}/graphene-%{version}.tar.xz",
    },
  }
  in

  let graphene = {
    name = "graphene-%{inputs.source.version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.gobject_introspection,
      ],
      runtime = [
        pkgs.c_runtime,
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
      source = pkgs.graphene_src,
    },
  }
  in

  {
    include [
      graphene_src,
      graphene,
    ],
  }
