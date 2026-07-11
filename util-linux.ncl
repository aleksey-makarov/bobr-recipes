let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let util_linux_src = fun version =>
    fun hash =>
    let version_series = "2.41" in
    {
      name = "util-linux-src-%{version}",
      tag = "Source",
      object_hash = hash,
      origin = {
        tag = "Http",
        url = "https://www.kernel.org/pub/linux/utils/util-linux/v%{version_series}/util-linux-%{version}.tar.xz",
      },
    }
  in

  let util_linux = {
    version | default = "2.41.5",
    source_object_hash | default = "f586e35d320ff537aab3ffeca37e9ecd482ccbe013590db4429a414d8aa6a728",
    name = "util-linux-%{version}",
    tag = "Autotools",
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
        "--docdir=/usr/share/doc/util-linux-%{version}",
      ],
      make_args = [
        "usrsbin_execdir=/usr/bin",
      ],
    },
    inputs = {
      source = util_linux_src version source_object_hash,
    },
  }
  in

  let util_linux_libs =
    recipe.split.libs util_linux "usr/lib/*.so*"
    & {
      deps = {
        build = [],
        runtime = [
          pkgs.glibc_libs,
        ],
      },
    }
  in

  {
    include [
      util_linux,
      util_linux_libs,
    ],
  }
