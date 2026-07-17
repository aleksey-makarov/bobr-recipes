# libsecret -- client library for the Secret Service API (password/secret
# storage). evolution-data-server stores credentials through it. Meson build.
# Transport encryption via libgcrypt (the default). man pages, vala bindings and
# the gi-docgen reference are off; GObject introspection stays on.
# `version`/`source_object_hash`/`series` are node fields (overridable).
let series = fun v =>
  let p = std.string.split "." v in
  "%{std.array.at 0 p}.%{std.array.at 1 p}"
in

fun pkgs =>
  let libsecret_src = fun version =>
    fun hash =>
      {
        name = "libsecret-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/libsecret/%{series version}/libsecret-%{version}.tar.xz",
        },
      }
  in

  let libsecret = {
    version | default = "0.21.7",
    source_object_hash
      | default
      = "6b452e4750590a2b5617adc40026f28d2f4903de15f1250e1d1c40bfd68ed55e",
    name = "libsecret-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.libgcrypt,
        pkgs.gobject_introspection,
        pkgs.gettext,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
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
      source = libsecret_src version source_object_hash,
    },
  }
  in

  {
    include [
      libsecret,
    ],
  }
