let recipe = import "recipe-lib.ncl" in
# libxml2 -- XML parser, needed by shared-mime-info (and later gnome-desktop
# and other GNOME bits). `version`/`source_object_hash` are node fields (overridable), as
# in linux.ncl.

let branch = recipe.version_prefix 2 in

fun pkgs =>
  let mk_src = fun version =>
    fun hash =>
      {
        name = "libxml2-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/libxml2/%{branch version}/libxml2-%{version}.tar.xz",
        },
      }
  in

  let libxml2 = {
    version | default = "2.15.3",
    source_object_hash | default = "78262a6e7ac170d6528ebfe2efccdf220191a5af6a6cd61ea4a9a9a5042c7a07",
    name = "libxml2-%{version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.zlib,
        pkgs.xz,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.zlib,
        pkgs.xz,
      ],
    },
    config = {
      configure_args = [
        "--without-python",
        "--with-zlib",
        "--with-lzma",
        "--disable-static",
      ],
    },
    inputs = {
      source = mk_src version source_object_hash,
    },
  }
  in

  {
    include [
      libxml2,
    ],
  }
