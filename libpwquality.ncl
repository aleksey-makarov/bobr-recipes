# libpwquality -- password quality checking library. A hard dependency of
# gnome-control-center (the users panel). Autotools build; the cracklib
# dictionary check and the Python bindings are off, so it needs no cracklib or
# python-cffi -- just the entropy/rule checks control-center uses. The PAM module
# is built against linux-pam.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let libpwquality_src = fun version =>
    fun hash =>
      {
        name = "libpwquality-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://github.com/libpwquality/libpwquality/releases/download/libpwquality-%{version}/libpwquality-%{version}.tar.bz2",
        },
      }
  in

  let libpwquality = {
    version | default = "1.4.5",
    source_object_hash
      | default
      = "6fcf18b75d305d99d04d2e42982ed5b787a081af2842220ed63287a2d6a10988",
    name = "libpwquality-%{version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.linux_pam,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
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
      source = libpwquality_src version source_object_hash,
    },
  }
  in

  {
    include [
      libpwquality,
    ],
  }
