let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let readline_src = fun version => fun hash => {
    name = "readline-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/readline/readline-%{version}.tar.gz",
        "https://mirrors.kernel.org/gnu/readline/readline-%{version}.tar.gz",
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
    version | default = "8.3",
    source_object_hash | default = "fe5383204467828cd495ee8d1d3c037a7eba1389c22bc6a041f627976f9061cc",
    name = "readline-%{version}",
    tag = "AutotoolsRootfs",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
        pkgs.ncurses_libs,
      ],
    },
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
        "--docdir=/usr/share/doc/readline-%{version}",
      ],
      env = { SHLIB_LIBS = "-lncursesw" },
    },
    inputs = {
      _rootfs = readline_build_rootfs,
      source = readline_src version source_object_hash,
    },
  }
  in

  {
    include [
      readline,
    ],
  }
