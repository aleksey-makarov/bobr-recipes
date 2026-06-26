let recipe = import "recipe-lib.ncl" in
let hashes = {
  "2.41.1" = "783f3d20a602e8115a9a9977b4d4d6f7f8e099451e287358a7d3991b1c5c1136",
  "2.41.5" = "356ee5ef126461644fb10855b0d87bb6bc1861354938d6546746a57b605461e4",
} in
let series = {
  "2.41.1" = "2.41",
  "2.41.5" = "2.41",
} in

fun pkgs =>
  let util_linux_src = fun version =>
    let version_series = series."%{version}" in
    {
      name = "util-linux-src-%{version}",
      tag = "Source",
      object_hash = hashes."%{version}",
      origin = {
        tag = "Http",
        url = "https://www.kernel.org/pub/linux/utils/util-linux/v%{version_series}/util-linux-%{version}.tar.xz",
      },
    }
  in

  let util_linux = {
    version | default = "2.41.5",
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
      source = util_linux_src version,
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
