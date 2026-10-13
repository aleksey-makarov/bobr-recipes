# libnma -- NetworkManager UI helper library. gnome-shell, when built with
# NetworkManager support, imports the NMA4-1.0 typelib (misc/dependencies.js) and
# uses libnma-gtk4 widgets (e.g. the Wi-Fi secret dialog) in its network
# indicator. Upstream libnma always builds a GTK3 library and only optionally
# adds the GTK4 one; we ship no GTK3, so a patch makes the GTK3 half optional
# (-Dlibnma_gtk3=false) and we build the GTK4 library and its NMA4 typelib alone.
# Meson build; libnm/gtk4/gcr/iso-codes are the real deps; the mobile-broadband
# provider database, Vala bindings and gtk-doc are off.
# Configure version and hash through `pkgs.libnma_src`.
fun pkgs =>
  let libnma_src = {
    version | default = "1.10.6",
    name = "libnma-src-%{version}",
    tag = "Source",
    object_hash | default = "53a6fb2b190ad37c5986caed3e98bede7c3c602399ee4f93c8fc054303d76dab",
    origin = {
      tag = "Http",
      url = "https://download.gnome.org/sources/libnma/1.10/libnma-%{version}.tar.xz",
    },
  }
  in

  let libnma = {
    name = "libnma-%{inputs.source.version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.gtk4,
        pkgs.gcr,
        pkgs.iso_codes,
        pkgs.networkmanager,
        pkgs.gobject_introspection,
        pkgs.python,
        pkgs.gettext,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.glib,
        pkgs.gtk4,
        pkgs.gcr,
        pkgs.iso_codes,
        pkgs.networkmanager,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dlibnma_gtk3=false",
        "-Dlibnma_gtk4=true",
        "-Dintrospection=true",
        "-Dvapi=false",
        "-Dgtk_doc=false",
        "-Dmobile_broadband_provider_info=false",
      ],
    },
    inputs = {
      source = pkgs.libnma_src,
      # Makes the GTK3 half of libnma optional so we can build GTK4-only (we ship
      # no GTK3). Applied by the synthetic builder (input name matches ^patch).
      patch_gtk4_only = {
        name = "libnma-gtk4-only-patch",
        tag = "Source",
        object_hash = import "libnma-gtk4-only.patch.fsobj-hash" as 'Text,
        origin = {
          tag = "RecipePath",
          path = "pkgs/libnma/libnma-gtk4-only.patch",
        },
      },
    },
  }
  in

  {
    include [
      libnma_src,
      libnma,
    ],
  }
