# gdk-pixbuf -- image loading for GTK4. PNG/JPEG loaders (libpng/libjpeg-turbo);
# tiff off (no libtiff); glycin off (a Rust loader -- avoid Rust in this tier).
# `version`/`hashes` are node fields (overridable), as in linux.ncl.
let default_version = "2.44.7" in
let default_hashes = {
  "2.44.7" = "a803b2110a6a72639c9f34fa30d608f8664be78a204b538ed6338c04e6734e93",
}
in

let branch = fun version =>
  let m = std.string.find "^([0-9]+[.][0-9]+)[.]" version in
  if m.index == 0 && std.array.length m.groups == 1 then std.array.at 0 m.groups
  else std.fail_with "gdk-pixbuf.ncl: version must be MAJOR.MINOR.PATCH"
in

fun pkgs =>
  let mk_src = fun version =>
    fun hash =>
      {
        name = "gdk-pixbuf-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/gdk-pixbuf/%{branch version}/gdk-pixbuf-%{version}.tar.xz",
        },
      }
  in

  let gdk_pixbuf = {
    version | default = default_version,
    hashes | default = default_hashes,
    name = "gdk-pixbuf-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.libpng,
        pkgs.libjpeg_turbo,
        pkgs.shared_mime_info,
        pkgs.gobject_introspection,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.glib,
        pkgs.libpng,
        pkgs.libjpeg_turbo,
        pkgs.shared_mime_info,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dintrospection=enabled",
        "-Dpng=enabled",
        "-Djpeg=enabled",
        "-Dtiff=disabled",
        "-Dglycin=disabled",
        "-Dthumbnailer=disabled",
        "-Dman=false",
        "-Dtests=false",
        "-Ddocumentation=false",
        "-Dgtk_doc=false",
      ],
    },
    inputs = {
      source = mk_src version (hashes."%{version}"),
    },
  }
  in

  {
    include [
      gdk_pixbuf,
    ],
  }
