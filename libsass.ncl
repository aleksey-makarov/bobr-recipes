# libsass -- C/C++ implementation of a Sass compiler. Pulled in via sassc, which
# libadwaita (and GTK themes generally) use to compile their SCSS stylesheets to
# CSS at build time. The git tag archive ships only configure.ac, so we
# regenerate configure with autoreconf. C++ library, no external dependencies.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let libsass_src = fun version =>
    fun hash =>
      {
        name = "libsass-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://github.com/sass/libsass/archive/refs/tags/%{version}.tar.gz",
        },
      }
  in

  let libsass = {
    version | default = "3.6.6",
    source_object_hash
      | default
      = "11f0bb3709a4f20285507419d7618f3877a425c0131ea8df40fe6196129df15d",
    name = "libsass-%{version}",
    tag = "AutotoolsInstall",
    deps = {
      build = [
        pkgs.automake,
        pkgs.libtool,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
      ],
    },
    config = {
      pre_configure = {
        name = "autoreconf",
        run_as = "build-user",
        argv = ["/bin/sh", "-ec", "autoreconf -fi"],
      },
      configure_args = [
        "--disable-static",
      ],
    },
    inputs = {
      source = libsass_src version source_object_hash,
    },
  }
  in

  {
    include [
      libsass,
    ],
  }
