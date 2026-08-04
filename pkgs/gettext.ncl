fun pkgs =>
  let gettext_src = fun version => fun hash => {
    name = "gettext-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/gettext/gettext-%{version}.tar.xz",
        "https://mirrors.kernel.org/gnu/gettext/gettext-%{version}.tar.xz",
      ],
    },
  }
  in

  let gettext = {
    version | default = "0.26",
    source_object_hash | default = "d1fb86e260cfe7da6031f94d2e44c0da55903dbae0a2fa0fae78c91ae1b56f00",
    name = "gettext-%{version}",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--docdir=/usr/share/doc/gettext-%{version}",
      ],
      post_install = {
        name = "fix_preloadable_libintl_permissions",
        run_as = "root",
        argv = [
          "chmod",
          "-v",
          "0755",
          "/usr/lib/preloadable_libintl.so",
        ],
      },
    },
    inputs = {
      source = gettext_src version source_object_hash,
    },
  }
  in

  {
    include [
      gettext,
    ],
  }
