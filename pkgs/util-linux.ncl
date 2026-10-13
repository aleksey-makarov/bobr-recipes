let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let util_linux_src = {
    version | default = "2.41.5",
    name = "util-linux-src-%{version}",
    tag = "Source",
    object_hash | default = "f586e35d320ff537aab3ffeca37e9ecd482ccbe013590db4429a414d8aa6a728",
    origin = {
      tag = "Http",
      url = "https://www.kernel.org/pub/linux/utils/util-linux/v%{recipe.version_prefix 2 version}/util-linux-%{version}.tar.xz",
    },
  }
  in

  let util_linux = {
    name = "util-linux-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.ncurses,
        pkgs.pkgconf,
        pkgs.zlib,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.ncurses_libs,
        pkgs.zlib,
      ],
    },
    config = {
      pre_configure = {
        name = "patch_permissions",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            sed -i 's#chgrp tty $(DESTDIR)$(usrbin_execdir)/wall#chgrp root $(DESTDIR)$(usrbin_execdir)/wall#' Makefile.in
            sed -i 's#chgrp tty $(DESTDIR)$(usrbin_execdir)/write#chgrp root $(DESTDIR)$(usrbin_execdir)/write#' Makefile.in
          "%,
        ],
      },
      configure_args = [
        "--bindir=/usr/bin",
        "--libdir=/usr/lib",
        "--runstatedir=/run",
        "--sbindir=/usr/bin",
        "--disable-chfn-chsh",
        "--disable-login",
        "--disable-nologin",
        "--disable-su",
        "--disable-setpriv",
        "--disable-runuser",
        "--disable-pylibmount",
        "--disable-liblastlog2",
        "--disable-static",
        "--without-python",
        "ADJTIME_PATH=/var/lib/hwclock/adjtime",
        "--docdir=/usr/share/doc/util-linux-%{inputs.source.version}",
      ],
      make_args = [
        "usrsbin_execdir=/usr/bin",
      ],
    },
    inputs = {
      source = pkgs.util_linux_src,
    },
  }
  in

  let util_linux_libs =
    recipe.split.libs pkgs.util_linux "usr/lib/*.so*"
    & {
      deps = {
        build = [],
        runtime = [
          pkgs.c_runtime,
        ],
      },
    }
  in

  {
    include [
      util_linux,
      util_linux_libs,
      util_linux_src,
    ],
  }
