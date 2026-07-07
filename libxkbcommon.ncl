let version = "1.13.2" in

fun pkgs =>
  let libxkbcommon_src = {
    name = "libxkbcommon-src-%{version}",
    tag = "Source",
    object_hash = "20efaf3351c10bad6ded3cc90639dc3d5c3b0d422813b6b7205b4f2e4a2c6d8a",
    origin = {
      tag = "Http",
      url = "https://github.com/xkbcommon/libxkbcommon/archive/refs/tags/xkbcommon-%{version}.tar.gz",
    },
  }
  in

  # Keymap compiler used by the compositor. x11/wayland integrations and the
  # xkbregistry (libxml2) are off; keymap data comes from xkeyboard-config at
  # the default config root.
  let libxkbcommon = {
    name = "libxkbcommon-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.bison,
        pkgs.flex,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.xkeyboard_config,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Denable-docs=false",
        # We only need the library for the compositor, not the xkbcli tools --
        # and tools/info.c fails to build from this source archive.
        "-Denable-tools=false",
        "-Denable-x11=false",
        "-Denable-wayland=false",
        "-Denable-xkbregistry=false",
        "-Denable-bash-completion=false",
        "-Dxkb-config-root=/usr/share/X11/xkb",
      ],
    },
    inputs = {
      source = libxkbcommon_src,
    },
  }
  in

  {
    include [
      libxkbcommon,
    ],
  }
