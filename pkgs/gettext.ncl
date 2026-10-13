fun pkgs =>
  # Configure version and hash through pkgs.gettext_src.
  let gettext_src = {
    version | default = "0.26",
    name = "gettext-src-%{version}",
    tag = "Source",
    object_hash | default = "d1fb86e260cfe7da6031f94d2e44c0da55903dbae0a2fa0fae78c91ae1b56f00",
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
    name = "gettext-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.c_runtime,
        pkgs.gcc_libstdcxx,
        pkgs.gcc_libgomp,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--docdir=/usr/share/doc/gettext-%{inputs.source.version}",
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
      source = pkgs.gettext_src,
    },
  }
  in

  {
    include [
      gettext,
      gettext_src,
    ],
  }
