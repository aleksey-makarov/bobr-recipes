let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let readline_src = {
    name = "readline-src-8.3",
    tag = "Source",
    object_hash = "a112092958ba47aea0270c071517c9665aa64fa64bf05e8321fdc9f7a8c3f308",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/readline/readline-8.3.tar.gz",
        "https://mirrors.kernel.org/gnu/readline/readline-8.3.tar.gz",
      ],
    },
  }
  in

  let readline_build_rootfs = {
    name = "readline-build-rootfs",
    tag = "TreeMerge",
    config = {},
    inputs =
      { base = pkgs.system_rootfs_2 }
      & recipe.numbered_inputs [
        pkgs.ncurses,
      ],
  }
  in

  let readline = {
    name = "readline-8.3",
    tag = "Autotools",
    config = {
      pre_configure = {
        name = "patch_readline_build",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            sed -i '/MV.*old/d' Makefile.in
            sed -i '/{OLDSUFF}/c:' support/shlib-install
            sed -i 's/-Wl,-rpath,[^ ]*//' support/shobj-conf
          "%,
        ],
      },
      configure_args = [
        "--disable-static",
        "--with-curses",
        "--docdir=/usr/share/doc/readline-8.3",
      ],
      env = { SHLIB_LIBS = "-lncursesw" },
    },
    inputs = {
      rootfs = readline_build_rootfs,
      source = readline_src,
    },
  }
  in

  {
    include [
      readline_src,
      readline,
    ],
  }
