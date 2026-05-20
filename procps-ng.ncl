let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let procps_ng_src = {
    name = "procps-ng-src-4.0.5",
    tag = "Source",
    object_hash = "c41fd9e5e30b6aed75c309f53461634c8a76879e50a18891dbec413836f4e0c8",
    origin = {
      type = "http",
      url = [
        "https://downloads.sourceforge.net/project/procps-ng/Production/procps-ng-4.0.5.tar.xz",
        "https://sourceforge.net/projects/procps-ng/files/Production/procps-ng-4.0.5.tar.xz/download",
      ],
    },
  }
  in

  let procps_ng = {
    name = "procps-ng-4.0.5",
    tag = "AutotoolsPackage",
    deps = {
      build = [
        pkgs.pkgconf,
        pkgs.ncurses,
        pkgs.libcap,
        pkgs.systemd,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.ncurses_libs,
        pkgs.libcap,
        pkgs.systemd,
      ],
    },
    config = {
      configure_args = [
        "--docdir=/usr/share/doc/procps-ng-4.0.5",
        "--disable-static",
        "--disable-kill",
        "--enable-watch8bit",
        "--with-systemd",
      ],
    },
    inputs = {
      source = procps_ng_src,
    },
  }
  in

  {
    include [
      procps_ng_src,
      procps_ng,
    ],
  }
