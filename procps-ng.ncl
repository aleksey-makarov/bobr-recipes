let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let procps_ng_src = {
    name = "procps-ng-src-4.0.5",
    tag = "Source",
    object_hash = "c2e6d193cc78f84cd6ddb72aaf6d5c6a9162f0470e5992092057f5ff518562fa",
    origin = {
      tag = "Http",
      url = [
        "https://downloads.sourceforge.net/project/procps-ng/Production/procps-ng-4.0.5.tar.xz",
        "https://sourceforge.net/projects/procps-ng/files/Production/procps-ng-4.0.5.tar.xz/download",
      ],
    },
  }
  in

  let procps_ng = {
    name = "procps-ng-4.0.5",
    tag = "Autotools",
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
        pkgs.libcap_libs,
        pkgs.systemd_libs,
      ],
    },
    config = {
      configure_args = [
        "--docdir=/usr/share/doc/procps-ng-4.0.5",
        "--sbindir=/usr/bin",
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
      procps_ng,
    ],
  }
