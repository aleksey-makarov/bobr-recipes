# libgpg-error -- the common error-code library the GnuPG stack builds on.
# libgcrypt (and thus gcr, which gnome-shell links) needs it. Plain Autotools.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let libgpg_error_src = fun version =>
    fun hash =>
      {
        name = "libgpg-error-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-%{version}.tar.bz2",
        },
      }
  in

  let libgpg_error = {
    version | default = "1.61",
    source_object_hash
      | default
      = "7a85413f2bc354f4f8aa832b718af122e48965e9e0eb9012ee659c13c6385c93",
    name = "libgpg-error-%{version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.gettext,
      ],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--disable-doc",
        "--disable-tests",
      ],
    },
    inputs = {
      source = libgpg_error_src version source_object_hash,
    },
  }
  in

  {
    include [
      libgpg_error,
    ],
  }
