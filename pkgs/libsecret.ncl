let recipe = import "../recipe-lib.ncl" in
# libsecret -- client library for the Secret Service API (password/secret
# storage). evolution-data-server stores credentials through it. Meson build.
# Transport encryption via libgcrypt (the default). man pages, vala bindings and
# the gi-docgen reference are off; GObject introspection stays on.
# Configure version and hash through `pkgs.libsecret_src`.
let series = recipe.version_prefix 2 in

fun pkgs =>
  let libsecret_src = {
    version | default = "0.21.7",
    name = "libsecret-src-%{version}",
    tag = "Source",
    object_hash | default = "6b452e4750590a2b5617adc40026f28d2f4903de15f1250e1d1c40bfd68ed55e",
    origin = {
      tag = "Http",
      url = "https://download.gnome.org/sources/libsecret/%{series version}/libsecret-%{version}.tar.xz",
    },
  }
  in

  let libsecret = {
    name = "libsecret-%{inputs.source.version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.libgcrypt,
        pkgs.gobject_introspection,
        pkgs.gettext,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.glib,
        pkgs.libgcrypt,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dmanpage=false",
        "-Dvapi=false",
        "-Dgtk_doc=false",
      ],
    },
    inputs = {
      source = pkgs.libsecret_src,
    },
  }
  in

  {
    include [
      libsecret_src,
      libsecret,
    ],
  }
