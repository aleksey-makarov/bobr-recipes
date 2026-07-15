# gsound -- small GObject library for playing system sounds (a thin wrapper over
# libcanberra). Pulled in as a dependency of gnome-bluetooth. Meson build; links
# glib and libcanberra and produces the GSound-1.0 typelib.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let gsound_src = fun version =>
    fun hash =>
      {
        name = "gsound-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/gsound/1.0/gsound-%{version}.tar.xz",
        },
      }
  in

  let gsound = {
    version | default = "1.0.3",
    source_object_hash
      | default
      = "ca2d039e1ebd148647017a7f548862350bc9af01986d39f10cfdc8e95f07881a",
    name = "gsound-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.libcanberra,
        pkgs.vala,
        pkgs.gobject_introspection,
        pkgs.python,
        pkgs.gettext,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.libcanberra,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
      ],
    },
    inputs = {
      source = gsound_src version source_object_hash,
    },
  }
  in

  {
    include [
      gsound,
    ],
  }
