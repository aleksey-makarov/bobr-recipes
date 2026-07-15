# gnome-online-accounts (goa) -- provides goa-1.0, a hard dependency of
# gnome-control-center's Online Accounts panel. Meson build against glib, gtk4,
# libadwaita, libsecret, libsoup 3, libxml2, json-glib, librest (rest-1.0) and
# gcr-4. The kerberos provider is disabled (`if enable_goabackend and
# enable_kerberos` at meson.build:189 gates it), so it needs no krb5/keyutils.
# Documentation, man pages and the Vala binding are off.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let series = fun v => std.string.join "." (std.array.slice 0 2 (std.string.split "." v)) in

  let goa_src = fun version =>
    fun hash =>
      {
        name = "gnome-online-accounts-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/gnome-online-accounts/%{series version}/gnome-online-accounts-%{version}.tar.xz",
        },
      }
  in

  let goa = {
    version | default = "3.58.1",
    source_object_hash
      | default
      = "9ec1900cc51409c2067c07c828c10be06fe3bf68d2999bb72d7d5ed325ed9bbc",
    name = "gnome-online-accounts-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.gtk4,
        pkgs.libadwaita,
        pkgs.libsecret,
        pkgs.libsoup,
        pkgs.libxml2,
        pkgs.json_glib,
        pkgs.librest,
        pkgs.gcr,
        pkgs.dbus,
        pkgs.systemd_dev,
        pkgs.gobject_introspection,
        pkgs.python,
        pkgs.gettext,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.gtk4,
        pkgs.libadwaita,
        pkgs.libsecret,
        pkgs.libsoup,
        pkgs.libxml2,
        pkgs.json_glib,
        pkgs.librest,
        pkgs.gcr,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dkerberos=false",
        "-Ddocumentation=false",
        "-Dman=false",
        "-Dvapi=false",
      ],
    },
    inputs = {
      source = goa_src version source_object_hash,
    },
  }
  in

  {
    include [
      goa,
    ],
  }
