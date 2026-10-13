# shared-mime-info -- the freedesktop MIME database + update-mime-database.
# Used by GIO/gdk-pixbuf for content-type detection. Only git-archive tarballs
# are published (gitlab.fd.o archives are deterministic).
# Configure version and hash through `pkgs.shared_mime_info_src`.
fun pkgs =>
  let shared_mime_info_src = {
    version | default = "2.5.1",
    name = "shared-mime-info-src-%{version}",
    tag = "Source",
    object_hash | default = "b75b420da9b0be9a3d99b1bee6ed87957b56ab54583ac1a97fbd0dc98ddddb25",
    origin = {
      tag = "Http",
      url = "https://gitlab.freedesktop.org/xdg/shared-mime-info/-/archive/%{version}/shared-mime-info-%{version}.tar.bz2",
    },
  }
  in

  let shared_mime_info = {
    name = "shared-mime-info-%{inputs.source.version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.libxml2,
        pkgs.gettext,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.gcc_libstdcxx,
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
      source = pkgs.shared_mime_info_src,
    },
  }
  in

  {
    include [
      shared_mime_info_src,
      shared_mime_info,
    ],
  }
