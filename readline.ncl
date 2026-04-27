let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let readline_src = {
    name = "readline-src-8.3",
    tag = "Source",
    object_hash = "14d0e394c31d3aaf7cd8f3af259eed02cafe862949e13af7a7363dea5774b9d9",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/readline/readline-8.3.tar.gz",
        "https://mirrors.kernel.org/gnu/readline/readline-8.3.tar.gz",
      ],
      unpack = true,
    },
    meta = {},
  }
  in

  let readline_build_image = {
    name = "readline-build-image",
    tag = "Image",
    config = { ref_name | default = "readline-build-image" } & {},
    inputs =
      { base = pkgs.system_image_2 }
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
      image = readline_build_image,
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
