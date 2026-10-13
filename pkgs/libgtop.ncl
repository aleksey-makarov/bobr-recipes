let recipe = import "../recipe-lib.ncl" in
# libgtop -- library to obtain system/process information. gnome-control-center's
# Privacy/Usage panel links against libgtop-2.0. Autotools build against glib.
# Configure version and hash through `pkgs.libgtop_src`.
fun pkgs =>
  let series = recipe.version_prefix 2 in

  let libgtop_src = {
    version | default = "2.41.3",
    name = "libgtop-src-%{version}",
    tag = "Source",
    object_hash | default = "775676df958e2ea2452f7568f28b2ea581063d312773dd5c0b7624c1b9b2da8c",
    origin = {
      tag = "Http",
      url = "https://download.gnome.org/sources/libgtop/%{series version}/libgtop-%{version}.tar.xz",
    },
  }
  in

  let libgtop = {
    name = "libgtop-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.glib,
        pkgs.gettext,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.c_runtime,
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
      source = pkgs.libgtop_src,
    },
  }
  in

  {
    include [
      libgtop_src,
      libgtop
    ]
  }
