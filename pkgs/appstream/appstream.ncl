# AppStream -- library for reading software metainfo (the libappstream C API).
# libadwaita links it (AdwAboutDialog can populate itself from a component's
# metainfo), and gnome-control-center uses it too. Meson build against glib,
# libxml2, libfyaml, libxmlb and libcurl. Qt bindings, systemd/journal, Vala,
# gir, apt support, display detection, optional compression/hashing, SVG
# rendering, the Snowball stemmer, the compose tool and all docs are off.
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
          url = [
            "https://www.freedesktop.org/software/appstream/releases/AppStream-%{version}.tar.xz",
            "https://deb.debian.org/debian/pool/main/a/appstream/appstream_%{version}.orig.tar.xz",
          ],
        },
      }
  in

  let appstream = {
    version | default = "1.1.6",
    source_object_hash
      | default
      = "e298929f39729e84a70f6be6941f3e7f3fc2ee3c83cb3ea1b1b5b280a8fe3a24",
    name = "appstream-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.libxml2,
        pkgs.libfyaml,
        pkgs.libxmlb,
        pkgs.curl,
        pkgs.gperf,
        pkgs.gettext,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.libxml2,
        pkgs.libfyaml,
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
        "-Dbash-completion=false",
        "-Dapt-support=false",
        "-Dgir=false",
        "-Dzstd-support=false",
        "-Dblake3-support=false",
        "-Ddisplay-detection=none",
        "-Dsvg-support=false",
        "-Ddocs=false",
        "-Dapidocs=false",
        "-Dinstall-docs=false",
        "-Dman=false",
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
          path = "pkgs/appstream/appstream-no-itstool.patch",
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
