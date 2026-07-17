# libndp -- library for IPv6 Neighbor Discovery Protocol. A hard dependency of
# NetworkManager (router/neighbor discovery). The upstream git snapshot ships
# only configure.ac, so we regenerate configure with autoreconf before the normal
# Autotools configure. No external library dependencies.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let libndp_src = fun version =>
    fun hash =>
      {
        name = "libndp-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://github.com/jpirko/libndp/archive/refs/tags/v%{version}.tar.gz",
        },
      }
  in

  let libndp = {
    version | default = "1.9",
    source_object_hash
      | default
      = "e564f5914a6b1b799c3afa64c258824a801c1b79a29e2fe6525b682249c65261",
    name = "libndp-%{version}",
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
      # The tag archive has only configure.ac; generate configure first.
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
      source = libndp_src version source_object_hash,
    },
  }
  in

  {
    include [
      libndp,
    ],
  }
