# libgtop -- library to obtain system/process information. gnome-control-center's
# Privacy/Usage panel links against libgtop-2.0. Autotools build against glib.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let series = fun v => std.string.join "." (std.array.slice 0 2 (std.string.split "." v)) in

  let libgtop_src = fun version =>
    fun hash =>
      {
        name = "libgtop-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/libgtop/%{series version}/libgtop-%{version}.tar.xz",
        },
      }
  in

  let libgtop = {
    version | default = "2.41.3",
    source_object_hash
      | default
      = "775676df958e2ea2452f7568f28b2ea581063d312773dd5c0b7624c1b9b2da8c",
    name = "libgtop-%{version}",
    tag = "AutotoolsInstall",
    deps = {
      build = [
        pkgs.glib,
        pkgs.gettext,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
      ],
    },
    config = {
      configure_args = [
        "--libdir=/usr/lib",
        "--disable-static",
        # control-center links libgtop via C and does not use the GTop typelib.
        "--disable-introspection",
      ],
    },
    inputs = {
      source = libgtop_src version source_object_hash,
    },
  }
  in

  { include [ libgtop ] }
