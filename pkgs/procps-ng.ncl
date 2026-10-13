fun pkgs =>
  # Configure version and hash through pkgs.procps_ng_src.
  let procps_ng_src = {
    version | default = "4.0.5",
    name = "procps-ng-src-%{version}",
    tag = "Source",
    object_hash | default = "c2e6d193cc78f84cd6ddb72aaf6d5c6a9162f0470e5992092057f5ff518562fa",
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
    name = "procps-ng-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.pkgconf,
        pkgs.ncurses,
        pkgs.systemd,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.ncurses_libs,
        pkgs.systemd_libs,
      ],
    },
    config = {
      configure_args = [
        "--docdir=/usr/share/doc/procps-ng-%{inputs.source.version}",
        "--sbindir=/usr/bin",
        "--disable-static",
        "--disable-kill",
        "--enable-watch8bit",
        "--with-systemd",
      ],
    },
    inputs = {
      source = pkgs.procps_ng_src,
    },
  }
  in

  {
    include [
      procps_ng,
      procps_ng_src,
    ],
  }
