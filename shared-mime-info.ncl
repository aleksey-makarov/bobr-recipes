# shared-mime-info -- the freedesktop MIME database + update-mime-database.
# Used by GIO/gdk-pixbuf for content-type detection. Only git-archive tarballs
# are published (gitlab.fd.o archives are deterministic). `version`/`hashes`
# are node fields (overridable), as in linux.ncl.
let default_version = "2.5.1" in
let default_hashes = {
  "2.5.1" = "144ea4e83251ad34db690270ca1b06516a2948358fed7b838eb4a7ec90fa73b2",
}
in

fun pkgs =>
  let mk_src = fun version =>
    fun hash =>
      {
        name = "shared-mime-info-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://gitlab.freedesktop.org/xdg/shared-mime-info/-/archive/%{version}/shared-mime-info-%{version}.tar.bz2",
        },
      }
  in

  let shared_mime_info = {
    version | default = default_version,
    hashes | default = default_hashes,
    name = "shared-mime-info-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.libxml2,
        pkgs.gettext,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.glib,
        pkgs.libxml2,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dupdate-mimedb=true",
        "-Dbuild-tests=false",
        "-Dbuild-spec=false",
      ],
    },
    inputs = {
      source = mk_src version (hashes."%{version}"),
    },
  }
  in

  {
    include [
      shared_mime_info,
    ],
  }
