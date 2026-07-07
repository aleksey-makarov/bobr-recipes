let version = "2.44" in

fun pkgs =>
  let xkeyboard_config_src = {
    name = "xkeyboard-config-src-%{version}",
    tag = "Source",
    object_hash = "84af65cf50a3025799583b4b8503f2afd197f359669994bd8591094e155a4606",
    origin = {
      tag = "Http",
      url = "https://www.x.org/releases/individual/data/xkeyboard-config/xkeyboard-config-%{version}.tar.xz",
    },
  }
  in

  # Keymap data consumed by libxkbcommon at runtime (installed under
  # /usr/share/X11/xkb). Data only -- no runtime libraries.
  let xkeyboard_config = {
    name = "xkeyboard-config-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.gettext,
        # xkeyboard-config's generators run Python xml.etree; pyexpat needs
        # libexpat.so at runtime, so expat must be in the build rootfs.
        pkgs.expat,
        # The rules/*.part files are generated with m4 (perl for a few helpers).
        pkgs.m4,
        pkgs.perl,
      ],
      runtime = [],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "-Dxorg-rules-symlinks=true",
      ],
    },
    inputs = {
      source = xkeyboard_config_src,
    },
  }
  in

  {
    include [
      xkeyboard_config,
    ],
  }
