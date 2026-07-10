let version = "2.44" in

fun pkgs =>
  let xkeyboard_config_src = {
    name = "xkeyboard-config-src-%{version}",
    tag = "Source",
    object_hash = "54d2c33eeebb031d48fa590c543e54c9bcbd0f00386ebc6489b2f47a0da4342a",
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
