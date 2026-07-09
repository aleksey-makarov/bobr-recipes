# libxml2 -- XML parser, needed by shared-mime-info (and later gnome-desktop
# and other GNOME bits). `version`/`hashes` are node fields (overridable), as
# in linux.ncl.
let default_version = "2.15.3" in
let default_hashes = {
  "2.15.3" = "2875a51b7d2e4c228eaa847945526d87bb7fa2aebaaf70d253bd1e30e287f94b",
}
in

let branch = fun version =>
  let matched = std.string.find "^([0-9]+[.][0-9]+)[.]" version in
  if matched.index == 0 && std.array.length matched.groups == 1 then
    std.array.at 0 matched.groups
  else
    std.fail_with "libxml2.ncl: version must be MAJOR.MINOR.PATCH"
in

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
    version | default = default_version,
    hashes | default = default_hashes,
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
      source = mk_src version (hashes."%{version}"),
    },
  }
  in

  {
    include [
      libxml2,
    ],
  }
