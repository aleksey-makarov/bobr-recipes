let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let util_linux_src = {
    name = "util-linux-src-2.41.1",
    tag = "Source",
    object_hash = "783f3d20a602e8115a9a9977b4d4d6f7f8e099451e287358a7d3991b1c5c1136",
    origin = {
      type = "http",
      url = "https://www.kernel.org/pub/linux/utils/util-linux/v2.41/util-linux-2.41.1.tar.xz",
    },
  }
  in

  let util_linux = {
    name = "util-linux-2.41.1",
    tag = "AutotoolsPackage",
    deps = {
      build = [
        pkgs.ncurses,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.ncurses_libs,
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
        "--sbindir=/usr/sbin",
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
        "--docdir=/usr/share/doc/util-linux-2.41.1",
      ],
    },
    inputs = {
      source = util_linux_src,
    },
  }
  in

  {
    include [
      util_linux_src,
      util_linux,
    ],
  }
