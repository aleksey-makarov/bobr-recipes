let recipe = import "recipe-lib.ncl" in
# gdk-pixbuf -- image loading for GTK4. PNG/JPEG loaders (libpng/libjpeg-turbo);
# tiff off (no libtiff); glycin off (a Rust loader -- avoid Rust in this tier).
# `version`/`source_object_hash` are node fields (overridable), as in linux.ncl.

let branch = recipe.version_prefix 2 in

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
    version | default = "2.44.7",
    source_object_hash | default = "172f80e3626ec31520a970400f1a3694e04718f6c2cd2885f75250fb5a6995a4",
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
      source = mk_src version source_object_hash,
    },
  }
  in

  {
    include [
      gdk_pixbuf,
    ],
  }
