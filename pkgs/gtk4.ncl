let recipe = import "../recipe-lib.ncl" in
# GTK4 -- the toolkit. Wayland backend only (no X11/broadway). GL renderer via
# libepoxy/Mesa (virgl); Vulkan renderer off for now. Accessibility (accesskit,
# a Rust lib) off. Demos built for the 6a validation (gtk4-demo). Print/media/
# cloud/colord/sysprof/tracker off.
# Configure version and hash through `pkgs.gtk4_src`.
let branch = recipe.version_prefix 2 in

fun pkgs =>
  let gtk4_src = {
    version | default = "4.22.4",
    name = "gtk4-src-%{version}",
    tag = "Source",
    object_hash | default = "51bd9f60c7d23a665a556c7364c21fb2e4e282566b3e7e092455e8f910330893",
    origin = {
      tag = "Http",
      url = "https://download.gnome.org/sources/gtk/%{branch version}/gtk-%{version}.tar.xz",
    },
  }
  in

  let gtk4 = {
    name = "gtk4-%{inputs.source.version}",
    tag = "Meson",
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
        pkgs.c_runtime,
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
      source = pkgs.gtk4_src,
    },
  }
  in

  {
    include [
      gtk4_src,
      gtk4,
    ],
  }
