# librest (rest) -- helper library for RESTful web services (provides rest-1.0).
# A dependency of gnome-online-accounts, which control-center's online-accounts
# panel uses. Meson build against glib, libsoup 3 and json-glib. gtk-doc,
# examples and tests are off.
# Configure version and hash through `pkgs.librest_src`.
fun pkgs =>
  let librest_src = {
    version | default = "0.9.1",
    name = "rest-src-%{version}",
    tag = "Source",
    object_hash | default = "9266a5c10ece383e193dfb7ffb07b509cc1f51521ab8dad76af96ed14212c2e3",
    origin = {
      tag = "Http",
      url = "https://download.gnome.org/sources/rest/0.9/rest-%{version}.tar.xz",
    },
  }
  in

  let librest = {
    name = "rest-%{inputs.source.version}",
    tag = "Meson",
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
        pkgs.c_runtime,
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
      source = pkgs.librest_src,
    },
  }
  in

  {
    include [
      librest_src,
      librest,
    ],
  }
