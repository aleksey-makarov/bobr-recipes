# AppStream -- library for reading software metainfo (the libappstream C API).
# libadwaita links it (AdwAboutDialog can populate itself from a component's
# metainfo), and gnome-control-center uses it too. The 0.16 line is used because
# it needs only libyaml (not libfyaml) while still parsing YAML/XML catalogs.
# Meson build against glib, libxml2, libyaml, libxmlb and libcurl. The Qt
# bindings, systemd/journal, Vala, gir, apt support, SVG rendering, the Snowball
# stemmer, the compose tool and all docs are off.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let appstream_src = fun version =>
    fun hash =>
      {
        name = "appstream-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://www.freedesktop.org/software/appstream/releases/AppStream-%{version}.tar.xz",
        },
      }
  in

  let appstream = {
    version | default = "0.16.4",
    source_object_hash
      | default
      = "d4f722d79c6a2f29d9dc5c6f464927469543353f386581c778c9bed7c60a54ed",
    name = "appstream-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.libxml2,
        pkgs.libyaml,
        pkgs.libxmlb,
        pkgs.curl,
        pkgs.gperf,
        pkgs.gobject_introspection,
        pkgs.python,
        pkgs.gettext,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.libxml2,
        pkgs.libyaml,
        pkgs.libxmlb,
        pkgs.curl,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dstemming=false",
        "-Dsystemd=false",
        "-Dvapi=false",
        "-Dqt=false",
        "-Dcompose=false",
        "-Dapt-support=false",
        "-Dgir=false",
        "-Dsvg-support=false",
        "-Ddocs=false",
        "-Dapidocs=false",
        "-Dinstall-docs=false",
      ],
    },
    inputs = {
      source = appstream_src version source_object_hash,
      # Replaces the appstreamcli metainfo's itstool_join with a plain install of
      # the untranslated file, so the build needs no itstool (which would need
      # python libxml2 bindings). Applied by the synthetic builder (name ^patch).
      patch_no_itstool = {
        name = "appstream-no-itstool-patch",
        tag = "Source",
        object_hash = import "appstream-no-itstool.patch.fsobj-hash" as 'Text,
        origin = {
          tag = "RecipePath",
          path = "appstream/appstream-no-itstool.patch",
        },
      },
    },
  }
  in

  {
    include [
      appstream,
    ],
  }
