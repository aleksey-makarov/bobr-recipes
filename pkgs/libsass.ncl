# libsass -- C/C++ implementation of a Sass compiler. Pulled in via sassc, which
# libadwaita (and GTK themes generally) use to compile their SCSS stylesheets to
# CSS at build time. The git tag archive ships only configure.ac, so we
# regenerate configure with autoreconf. C++ library, no external dependencies.
# Configure version and hash through `pkgs.libsass_src`.
fun pkgs =>
  let libsass_src = {
    version | default = "3.6.6",
    name = "libsass-src-%{version}",
    tag = "Source",
    object_hash | default = "11f0bb3709a4f20285507419d7618f3877a425c0131ea8df40fe6196129df15d",
    origin = {
      tag = "Http",
      url = "https://github.com/sass/libsass/archive/refs/tags/%{version}.tar.gz",
    },
  }
  in

  let libsass = {
    name = "libsass-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.automake,
        pkgs.libtool,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.gcc_libstdcxx,
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
      source = pkgs.libsass_src,
    },
  }
  in

  {
    include [
      libsass_src,
      libsass,
    ],
  }
