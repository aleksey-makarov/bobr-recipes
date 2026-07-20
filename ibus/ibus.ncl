# ibus -- Intelligent Input Bus. gnome-shell imports its IBus-1.0 typelib at
# startup (the keyboard/input-source machinery), so libibus + that typelib are a
# hard dependency of the GNOME session even when no CJK input method is used.
# Autotools build reduced to the library + introspection + ibus-daemon + the
# Wayland IM bridge: every GUI/toolkit path (gtk2/3/4, panel UI, setup tool,
# appindicator, libnotify), X input module (xim), dconf, and the emoji/unicode
# dictionaries are off. Wayland is kept ON: the shipped Vala-generated
# tools/main.c unconditionally links libwayland, and it is the right backend for
# a Wayland GNOME session anyway (protocol sources are pre-generated in the
# tarball). XFixes/libevdev checks are soft (optional features), so their
# absence just disables those features rather than failing configure.
# The internal compose table (embedded in libibus as a GResource) is generated
# at build time from a Compose file; upstream reads it from libX11's locale data
# which we do not ship, so we build in-tree and supply a minimal ./Compose via a
# patch (see ibus-compose.patch). gnome-shell needs only the IBus-1.0 typelib.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let ibus_src = fun version =>
    fun hash =>
      {
        name = "ibus-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://github.com/ibus/ibus/releases/download/%{version}/ibus-%{version}.tar.gz",
        },
      }
  in

  let ibus = {
    version | default = "1.5.34",
    source_object_hash
      | default
      = "12a72210ce5250f8a66df562a75e034e67b2bce74c4df2983dc86d1154894943",
    name = "ibus-%{version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.glib,
        pkgs.dbus,
        pkgs.iso_codes,
        pkgs.libevdev,
        pkgs.systemd_dev,
        pkgs.xkeyboard_config,
        pkgs.wayland,
        pkgs.wayland_protocols,
        pkgs.libxkbcommon,
        pkgs.gobject_introspection,
        # g-ir-scanner imports distutils (gone in 3.13); setuptools provides it.
        pkgs.python_setuptools,
        pkgs.python,
        pkgs.gettext,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.dbus,
        pkgs.iso_codes,
        pkgs.libevdev,
        pkgs.systemd_libs,
        pkgs.wayland,
        pkgs.libxkbcommon,
      ],
    },
    config = {
      # In-tree build so gencomposetable finds ./Compose (from the patch).
      in-tree = true,
      configure_args = [
        "--enable-introspection",
        "--disable-gtk2",
        "--disable-gtk3",
        "--disable-gtk4",
        "--disable-ui",
        "--disable-setup",
        "--disable-xim",
        "--enable-wayland",
        "--disable-dconf",
        "--disable-libnotify",
        "--disable-emoji-dict",
        "--disable-unicode-dict",
        "--disable-vala",
        "--disable-tests",
        "--disable-gtk-doc",
        "--disable-python-library",
        "--disable-python2",
        "--disable-dbus-python-check",
        "--disable-appindicator",
        "--disable-systemd-services",
      ],
    },
    inputs = {
      source = ibus_src version source_object_hash,
      # Supplies src/Compose for the build-time compose-table generator.
      # Applied by the synthetic builder (input name matches ^patch).
      patch_compose = {
        name = "ibus-compose-patch",
        tag = "Source",
        object_hash = import "ibus-compose.patch.fsobj-hash" as 'Text,
        origin = {
          tag = "RecipePath",
          path = "ibus/ibus-compose.patch",
        },
      },
    },
  }
  in

  {
    include [
      ibus,
    ],
  }
