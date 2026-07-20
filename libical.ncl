# libical -- reference iCalendar library. evolution-data-server needs the
# libical-glib GObject bindings (built here with introspection). CMake project,
# built via the Makefile builder with a cmake_configure pre-step (as vulkan-*).
# Shared library only; docs, tests and the vala bindings are off. ICU provides
# RSCALE (non-Gregorian calendar) support; perl drives libical's code generation.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let libical_src = fun version =>
    fun hash =>
      {
        name = "libical-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://github.com/libical/libical/releases/download/v%{version}/libical-%{version}.tar.gz",
        },
      }
  in

  let libical = {
    # eds 3.56 uses libical-glib 3.0 API (e.g. i_cal_duration_as_int), which the
    # 4.0 series removed, so stay on the 3.0 branch.
    version | default = "3.0.20",
    source_object_hash
      | default
      = "e73de92f5a6ce84c1b00306446b290a2b08cdf0a80988eca0a2c9d5c3510b4c2",
    name = "libical-%{version}",
    tag = "Makefile",
    deps = {
      build = [
        pkgs.cmake,
        pkgs.glib,
        pkgs.libxml2,
        pkgs.gobject_introspection,
        # g-ir-scanner imports distutils (gone in 3.13); setuptools provides it.
        pkgs.python_setuptools,
        pkgs.icu,
        pkgs.perl,
        pkgs.python,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.libxml2,
        pkgs.icu,
      ],
    },
    config = {
      pre_build = {
        name = "cmake_configure",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          "cmake -S . -B . -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release -DSHARED_ONLY=True -DICAL_GLIB=True -DGOBJECT_INTROSPECTION=True -DICAL_GLIB_VAPI=False -DICAL_BUILD_DOCS=False -DWITH_CXX_BINDINGS=False -DLIBICAL_BUILD_TESTING=False",
        ],
      },
    },
    inputs = {
      source = libical_src version source_object_hash,
    },
  }
  in

  {
    include [
      libical,
    ],
  }
