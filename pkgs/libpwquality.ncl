# libpwquality -- password quality checking library. A hard dependency of
# gnome-control-center (the users panel). Autotools build; the cracklib
# dictionary check and the Python bindings are off, so it needs no cracklib or
# python-cffi -- just the entropy/rule checks control-center uses. The PAM module
# is built against linux-pam.
# Configure version and hash through `pkgs.libpwquality_src`.
fun pkgs =>
  let libpwquality_src = {
    version | default = "1.4.5",
    name = "libpwquality-src-%{version}",
    tag = "Source",
    object_hash | default = "6fcf18b75d305d99d04d2e42982ed5b787a081af2842220ed63287a2d6a10988",
    origin = {
      tag = "Http",
      url = "https://github.com/libpwquality/libpwquality/releases/download/libpwquality-%{version}/libpwquality-%{version}.tar.bz2",
    },
  }
  in

  let libpwquality = {
    name = "libpwquality-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.linux_pam,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.linux_pam,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--disable-cracklib-check",
        "--disable-python-bindings",
      ],
    },
    inputs = {
      source = pkgs.libpwquality_src,
    },
  }
  in

  {
    include [
      libpwquality_src,
      libpwquality,
    ],
  }
