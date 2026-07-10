let version = "0.3.0" in

fun pkgs =>
  let libdisplay_info_src = {
    name = "libdisplay-info-src-%{version}",
    tag = "Source",
    object_hash = "6ae77cd937f9cf7d1321d35c116062c4911e8447010a6a713ac4286f7a9d5987",
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
