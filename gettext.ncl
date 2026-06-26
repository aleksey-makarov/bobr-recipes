let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let gettext_src = {
    name = "gettext-src-0.26",
    tag = "Source",
    object_hash = "fd515db9aa1ffe75113a0345fdcd3baf95f885988b94de37aec41b9b8a22d263",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/gettext/gettext-0.26.tar.xz",
        "https://mirrors.kernel.org/gnu/gettext/gettext-0.26.tar.xz",
      ],
    },
  }
  in

  let gettext = {
    name = "gettext-0.26",
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
        "--docdir=/usr/share/doc/gettext-0.26",
      ],
      post_install = {
        name = "fix_preloadable_libintl_permissions",
        run_as = "root",
        argv = [
          "chmod",
          "-v",
          "0755",
          "@{out}/usr/lib/preloadable_libintl.so",
        ],
      },
    },
    inputs = {
      source = gettext_src,
    },
  }
  in

  {
    include [
      gettext,
    ],
  }
