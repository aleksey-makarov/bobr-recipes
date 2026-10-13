let recipe = import "../recipe-lib.ncl" in
# gnome-online-accounts (goa) -- provides goa-1.0, a hard dependency of
# gnome-control-center's Online Accounts panel. Meson build against glib, gtk4,
# libadwaita, libsecret, libsoup 3, libxml2, json-glib and librest (rest-1.0).
# The Fedora and Kerberos providers are disabled, so the conditional GCR,
# krb5, and keyutils dependencies are not part of this build.
# Documentation, man pages and the Vala binding are off.
# Configure version and hash through `pkgs.gnome_online_accounts_src`.
fun pkgs =>
  let series = recipe.version_prefix 2 in

  let gnome_online_accounts_src = {
    version | default = "3.58.1",
    name = "gnome-online-accounts-src-%{version}",
    tag = "Source",
    object_hash | default = "9ec1900cc51409c2067c07c828c10be06fe3bf68d2999bb72d7d5ed325ed9bbc",
    origin = {
      tag = "Http",
      url = "https://download.gnome.org/sources/gnome-online-accounts/%{series version}/gnome-online-accounts-%{version}.tar.xz",
    },
  }
  in

  let gnome_online_accounts = {
    name = "gnome-online-accounts-%{inputs.source.version}",
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
        pkgs.dbus,
        pkgs.systemd_dev,
        pkgs.gobject_introspection,
        pkgs.python,
        pkgs.gettext,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.glib,
        pkgs.gtk4,
        pkgs.libadwaita,
        pkgs.libsecret,
        pkgs.libsoup,
        pkgs.libxml2,
        pkgs.json_glib,
        pkgs.librest,
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
      source = pkgs.gnome_online_accounts_src,
    },
  }
  in

  {
    include [
      gnome_online_accounts_src,
      gnome_online_accounts,
    ],
  }
