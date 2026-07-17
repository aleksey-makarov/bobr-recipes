
fun pkgs =>
  let libxkbcommon_src = fun version => fun hash => {
    name = "libxkbcommon-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://github.com/xkbcommon/libxkbcommon/archive/refs/tags/xkbcommon-%{version}.tar.gz",
    },
  }
  in

  # Keymap compiler used by the compositor. x11/wayland integrations are off;
  # keymap data comes from xkeyboard-config at the default config root. The
  # xkbregistry library (libxml2-backed) is on -- mutter links it unconditionally.
  let libxkbcommon = {
    version | default = "1.13.2",
    source_object_hash | default = "acc4d5f7c3cbba5f9f8d08d8bdbeede84ecede46792f47929aa9321873385528",
    name = "libxkbcommon-%{version}",
    tag = "MesonInstall",
    deps = {
      build = [
        pkgs.bison,
        pkgs.flex,
        pkgs.libxml2,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.xkeyboard_config,
        pkgs.libxml2,
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
        "-Denable-xkbregistry=true",
        "-Denable-bash-completion=false",
        "-Dxkb-config-root=/usr/share/X11/xkb",
      ],
    },
    inputs = {
      source = libxkbcommon_src version source_object_hash,
    },
  }
  in

  {
    include [
      libxkbcommon,
    ],
  }
