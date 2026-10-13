# libndp -- library for IPv6 Neighbor Discovery Protocol. A hard dependency of
# NetworkManager (router/neighbor discovery). The upstream git snapshot ships
# only configure.ac, so we regenerate configure with autoreconf before the normal
# Autotools configure. No external library dependencies.
# Configure version and hash through `pkgs.libndp_src`.
fun pkgs =>
  let libndp_src = {
    version | default = "1.9",
    name = "libndp-src-%{version}",
    tag = "Source",
    object_hash | default = "e564f5914a6b1b799c3afa64c258824a801c1b79a29e2fe6525b682249c65261",
    origin = {
      tag = "Http",
      url = "https://github.com/jpirko/libndp/archive/refs/tags/v%{version}.tar.gz",
    },
  }
  in

  let libndp = {
    name = "libndp-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.automake,
        pkgs.libtool,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.c_runtime,
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
      source = pkgs.libndp_src,
    },
  }
  in

  {
    include [
      libndp_src,
      libndp,
    ],
  }
