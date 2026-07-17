# GTK4 -- the toolkit. Wayland backend only (no X11/broadway). GL renderer via
# libepoxy/Mesa (virgl); Vulkan renderer off for now. Accessibility (accesskit,
# a Rust lib) off. Demos built for the 6a validation (gtk4-demo). Print/media/
# cloud/colord/sysprof/tracker off. `version`/`source_object_hash` are node fields
# (overridable), as in linux.ncl.

let branch = fun version =>
  let m = std.string.find "^([0-9]+[.][0-9]+)[.]" version in
  if m.index == 0 && std.array.length m.groups == 1 then std.array.at 0 m.groups
  else std.fail_with "gtk4.ncl: version must be MAJOR.MINOR.PATCH"
in

fun pkgs =>
  let mk_src = fun version =>
    fun hash =>
      {
        name = "gtk4-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/gtk/%{branch version}/gtk-%{version}.tar.xz",
        },
      }
  in

  let gtk4 = {
    version | default = "4.22.4",
    source_object_hash | default = "51bd9f60c7d23a665a556c7364c21fb2e4e282566b3e7e092455e8f910330893",
    name = "gtk4-%{version}",
    tag = "MesonInstall",
    deps = {
      build = [
        pkgs.glib,
        pkgs.graphene,
        pkgs.pango,
        pkgs.harfbuzz,
        pkgs.fribidi,
        pkgs.gdk_pixbuf,
        pkgs.cairo,
        pkgs.libepoxy,
        pkgs.libpng,
        pkgs.libjpeg_turbo,
        pkgs.libtiff,
        pkgs.wayland,
        pkgs.wayland_protocols,
        pkgs.libdrm,
        pkgs.fontconfig,
        pkgs.libxkbcommon,
        pkgs.gobject_introspection,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.graphene,
        pkgs.pango,
        pkgs.harfbuzz,
        pkgs.fribidi,
        pkgs.gdk_pixbuf,
        pkgs.cairo,
        pkgs.libepoxy,
        pkgs.libpng,
        pkgs.libjpeg_turbo,
        pkgs.libtiff,
        pkgs.wayland,
        pkgs.libdrm,
        pkgs.fontconfig,
        pkgs.libxkbcommon,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dwayland-backend=true",
        "-Dx11-backend=false",
        "-Dbroadway-backend=false",
        "-Dmedia-gstreamer=disabled",
        "-Dprint-cpdb=disabled",
        "-Dprint-cups=disabled",
        "-Dvulkan=disabled",
        "-Dcloudproviders=disabled",
        "-Dsysprof=disabled",
        "-Dtracker=disabled",
        "-Dcolord=disabled",
        "-Daccesskit=disabled",
        "-Dintrospection=enabled",
        "-Ddocumentation=false",
        "-Dscreenshots=false",
        "-Dman-pages=false",
        "-Dbuild-demos=true",
        "-Dbuild-testsuite=false",
        "-Dbuild-examples=false",
        "-Dbuild-tests=false",
      ],
    },
    inputs = {
      source = mk_src version source_object_hash,
    },
  }
  in

  {
    include [
      gtk4,
    ],
  }
