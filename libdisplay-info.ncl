let version = "0.3.0" in

fun pkgs =>
  let libdisplay_info_src = {
    name = "libdisplay-info-src-%{version}",
    tag = "Source",
    object_hash = "5599ce379fad1f059f064d79ec435cdfa28fc0bd239efc661ff9bb08a63f7b78",
    origin = {
      tag = "Http",
      url = "https://gitlab.freedesktop.org/emersion/libdisplay-info/-/releases/%{version}/downloads/libdisplay-info-%{version}.tar.xz",
    },
  }
  in

  # EDID / DisplayID parsing library, required by weston 15's DRM backend.
  # At build time it reads hwdata's pnp.ids to generate a vendor-name table.
  let libdisplay_info = {
    name = "libdisplay-info-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.hwdata,
      ],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
      ],
    },
    inputs = {
      source = libdisplay_info_src,
    },
  }
  in

  {
    include [
      libdisplay_info,
    ],
  }
