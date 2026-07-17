let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let procps_ng_src = fun version => fun hash => {
    name = "procps-ng-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = [
        "https://downloads.sourceforge.net/project/procps-ng/Production/procps-ng-%{version}.tar.xz",
        "https://sourceforge.net/projects/procps-ng/files/Production/procps-ng-%{version}.tar.xz/download",
      ],
    },
  }
  in

  let procps_ng = {
    version | default = "4.0.5",
    source_object_hash | default = "c2e6d193cc78f84cd6ddb72aaf6d5c6a9162f0470e5992092057f5ff518562fa",
    name = "procps-ng-%{version}",
    tag = "AutotoolsInstall",
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
        "--docdir=/usr/share/doc/procps-ng-%{version}",
        "--sbindir=/usr/bin",
        "--disable-static",
        "--disable-kill",
        "--enable-watch8bit",
        "--with-systemd",
      ],
    },
    inputs = {
      source = procps_ng_src version source_object_hash,
    },
  }
  in

  {
    include [
      procps_ng,
    ],
  }
