# GNU Midnight Commander -- text-mode file manager. Autotools; S-Lang screen
# backend, gpm and X11 off (no console-mouse / X deps). Needs glib and S-Lang.
# Configure version and hash through `pkgs.mc_src`.
fun pkgs =>
  let mc_src = {
    version | default = "4.8.33",
    name = "mc-src-%{version}",
    tag = "Source",
    object_hash | default = "cae149d42f844e5185d8c81d7db3913a8fa214c65f852200a9d896b468af164c",
    origin = {
      tag = "Http",
      url = "http://ftp.midnight-commander.org/mc-%{version}.tar.xz",
    },
  }
  in

  let runtime_paths_patch = {
    name = "mc-runtime-paths-patch",
    tag = "Source",
    object_hash = import "mc-runtime-paths.patch.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "pkgs/mc/mc-runtime-paths.patch",
    },
  }
  in

  let mc_defaults = {
    name = "mc-defaults",
    tag = "Source",
    object_hash = import "mc.ini.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "pkgs/mc/mc.ini",
    },
  }
  in

  let mc = {
    name = "mc-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.glib,
        pkgs.ncurses,
        pkgs.pkgconf,
        pkgs.gettext,
        pkgs.slang,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.glib,
        pkgs.ncurses_libs,
        pkgs.slang_libs,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--with-screen=slang",
        "--without-x",
        "--without-gpm-mouse",
      ],
      post_install = {
        name = "install_system_defaults",
        run_as = "root",
        argv = [
          "install",
          "-Dm644",
          "@{defaults}",
          "/usr/etc/mc/mc.ini",
        ],
      },
    },
    inputs = {
      source = pkgs.mc_src,
      patch_runtime_paths = runtime_paths_patch,
      defaults = mc_defaults,
    },
  }
  in

  {
    include [
      mc_src,
      mc,
    ],
  }
