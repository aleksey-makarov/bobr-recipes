# librest (rest) -- helper library for RESTful web services (provides rest-1.0).
# A dependency of gnome-online-accounts, which control-center's online-accounts
# panel uses. Meson build against glib, libsoup 3 and json-glib. gtk-doc,
# examples and tests are off.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let librest_src = fun version =>
    fun hash =>
      {
        name = "rest-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/rest/0.9/rest-%{version}.tar.xz",
        },
      }
  in

  let librest = {
    version | default = "0.9.1",
    source_object_hash
      | default
      = "9266a5c10ece383e193dfb7ffb07b509cc1f51521ab8dad76af96ed14212c2e3",
    name = "rest-%{version}",
    tag = "MesonInstall",
    deps = {
      build = [
        pkgs.glib,
        pkgs.libsoup,
        pkgs.json_glib,
        pkgs.libxml2,
        pkgs.gobject_introspection,
        pkgs.python,
        pkgs.gettext,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.libsoup,
        pkgs.json_glib,
        pkgs.libxml2,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dgtk_doc=false",
        "-Dexamples=false",
        "-Dtests=false",
      ],
    },
    inputs = {
      source = librest_src version source_object_hash,
    },
  }
  in

  {
    include [
      librest,
    ],
  }
