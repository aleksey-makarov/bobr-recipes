# libgpg-error -- the common error-code library the GnuPG stack builds on.
# libgcrypt (and thus gcr, which gnome-shell links) needs it. Plain Autotools.
# Configure version and hash through `pkgs.libgpg_error_src`.
fun pkgs =>
  let libgpg_error_src = {
    version | default = "1.61",
    name = "libgpg-error-src-%{version}",
    tag = "Source",
    object_hash | default = "7a85413f2bc354f4f8aa832b718af122e48965e9e0eb9012ee659c13c6385c93",
    origin = {
      tag = "Http",
      url = "https://gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-%{version}.tar.bz2",
    },
  }
  in

  let libgpg_error = {
    name = "libgpg-error-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.gettext,
      ],
      runtime = [
        pkgs.c_runtime,
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
      source = pkgs.libgpg_error_src,
    },
  }
  in

  {
    include [
      libgpg_error_src,
      libgpg_error,
    ],
  }
