# GNU Midnight Commander -- text-mode file manager. Autotools; ncurses screen
# backend, gpm and X11 off (no console-mouse / X deps). Needs glib and ncurses.
# `version`/`source_object_hash` are node fields (overridable), as in linux.ncl.

fun pkgs =>
  let mk_src = fun version =>
    fun hash =>
      {
        name = "mc-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "http://ftp.midnight-commander.org/mc-%{version}.tar.xz",
        },
      }
  in

  let mc = {
    version | default = "4.8.33",
    source_object_hash | default = "cae149d42f844e5185d8c81d7db3913a8fa214c65f852200a9d896b468af164c",
    name = "mc-%{version}",
    tag = "AutotoolsInstall",
    deps = {
      build = [
        pkgs.glib,
        pkgs.ncurses,
        pkgs.pkgconf,
        pkgs.gettext,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.glib,
        pkgs.ncurses,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--with-screen=ncurses",
        "--without-x",
        "--without-gpm-mouse",
      ],
    },
    inputs = {
      source = mk_src version source_object_hash,
    },
  }
  in

  {
    include [
      mc,
    ],
  }
