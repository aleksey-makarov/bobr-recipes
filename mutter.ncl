# mutter -- GNOME's Wayland compositor / display server (and libmutter, which
# gnome-shell links later). Built Wayland-only: Xwayland, remote desktop /
# screencast (pipewire), gnome-desktop, libwacom, sound (libcanberra), startup
# notification and the profiler are all off, which drops those dependencies.
# The native KMS backend (via logind + udev, EGL/GLES2 from mesa) is on. gvdb is
# a bundled meson subproject, so it needs no recipe.
# `version`/`hashes`/`series` are node fields (overridable), as in linux.ncl.
let default_version = "50.3" in
let default_hashes = {
  "50.3" = "25663fa7afc96a4c092448990c0da664b7f04dd8d9f5e3b9be2b498b1b303cb4",
}
in
let default_series = "50" in

fun pkgs =>
  let mk_src = fun version =>
    fun series =>
      fun hash =>
        {
          name = "mutter-src-%{version}",
          tag = "Source",
          object_hash = hash,
          origin = {
            tag = "Http",
            url = "https://download.gnome.org/sources/mutter/%{series}/mutter-%{version}.tar.xz",
          },
        }
  in

  let mutter = {
    version | default = default_version,
    hashes | default = default_hashes,
    series | default = default_series,
    name = "mutter-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.gsettings_desktop_schemas,
        pkgs.graphene,
        pkgs.glycin,
        pkgs.pixman,
        pkgs.cairo,
        pkgs.pango,
        pkgs.harfbuzz,
        pkgs.fribidi,
        pkgs.libxkbcommon,
        pkgs.at_spi2_core,
        pkgs.colord,
        pkgs.lcms2,
        pkgs.libei,
        pkgs.libdisplay_info,
        pkgs.libdrm,
        pkgs.libinput,
        pkgs.wayland,
        pkgs.wayland_protocols,
        pkgs.mesa,
        pkgs.systemd_dev,
        pkgs.libgudev,
        pkgs.gobject_introspection,
        pkgs.gettext,
        # Build-only: provides the `cvt` program the native backend runs to
        # generate its default-modes table (the library itself is not linked).
        pkgs.libxcvt,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.gsettings_desktop_schemas,
        pkgs.graphene,
        pkgs.glycin,
        pkgs.pixman,
        pkgs.cairo,
        pkgs.pango,
        pkgs.harfbuzz,
        pkgs.fribidi,
        pkgs.libxkbcommon,
        pkgs.at_spi2_core,
        pkgs.colord,
        pkgs.lcms2,
        pkgs.libei,
        pkgs.libdisplay_info,
        pkgs.libdrm,
        pkgs.libinput,
        pkgs.wayland,
        pkgs.mesa,
        pkgs.systemd_libs,
        pkgs.libgudev,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        # Wayland-only: drop X11 and the optional subsystems and their deps.
        "-Dxwayland=false",
        "-Dremote_desktop=false",
        "-Dlibgnome_desktop=false",
        "-Dsound_player=false",
        "-Dlibwacom=false",
        "-Dstartup_notification=false",
        "-Dprofiler=false",
        "-Ddevkit=disabled",
        "-Dbash_completion=false",
        # Native KMS backend and its enablers. Desktop GL (libGL/GLX, an X11
        # path) is off -- our mesa targets GLES2 + EGL for the virgl guest,
        # which is exactly what the native Wayland backend uses.
        "-Dnative_backend=true",
        "-Dlogind=true",
        "-Dudev=true",
        "-Dopengl=false",
        "-Dgles2=true",
        "-Degl=true",
        # Needed downstream (gnome-shell) / keep.
        "-Dintrospection=true",
        "-Dfonts=true",
        "-Ddocs=false",
        # No tests.
        "-Dtests=disabled",
        "-Dcogl_tests=false",
        "-Dclutter_tests=false",
        "-Dmutter_tests=false",
        "-Dinstalled_tests=false",
      ],
    },
    inputs = {
      source = mk_src version series (hashes."%{version}"),
    },
  }
  in

  {
    include [
      mutter,
    ],
  }
