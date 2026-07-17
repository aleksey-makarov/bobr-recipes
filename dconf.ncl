# dconf -- low-level configuration system and the default GSettings backend.
# Needed as a build tool for gdm (its data/dconf step runs `dconf compile` to
# build the greeter's locked-down defaults) and at runtime so GNOME settings
# persist instead of falling back to the in-memory GSettings backend. Meson
# build; bash completion, man pages and the Vala bindings are off to avoid
# pulling in xsltproc/docbook and vapigen.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let dconf_src = fun version =>
    fun hash =>
      {
        name = "dconf-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/dconf/0.40/dconf-%{version}.tar.xz",
        },
      }
  in

  let dconf = {
    version | default = "0.40.0",
    source_object_hash
      | default
      = "cf7f22a4c9200421d8d3325c5c1b8b93a36843650c9f95d6451e20f0bcb24533",
    name = "dconf-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.dbus,
        pkgs.systemd_dev,
        pkgs.gettext,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.dbus,
        pkgs.systemd_libs,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dbash_completion=false",
        "-Dman=false",
        "-Dvapi=false",
      ],
    },
    inputs = {
      source = dconf_src version source_object_hash,
    },
  }
  in

  {
    include [
      dconf,
    ],
  }
