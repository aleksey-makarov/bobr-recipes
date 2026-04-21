let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let readline_src = {
    name = "readline-src-8.3",
    tag = "Fetch",
    config = {
      url = [
        "https://ftp.gnu.org/gnu/readline/readline-8.3.tar.gz",
        "https://mirrors.kernel.org/gnu/readline/readline-8.3.tar.gz",
      ],
      hash = "md5:25a73bfb2a3ad7146c5e9d4408d9f6cd",
    },
    inputs = {},
  }
  in

  let readline_build_image = {
    name = "readline-build-image",
    tag = "Image",
    config = { ref_name | default = "readline-build-image" } & {},
    inputs = {
      base = pkgs.system_image_2,
      inputs = [
        pkgs.ncurses,
      ],
    },
  }
  in

  let readline =
    recipe.binary
      "readline-8.3"
      {
        script_config = {
          pre_configure = m%"
          sed -i '/MV.*old/d' Makefile.in
          sed -i '/{OLDSUFF}/c:' support/shlib-install
          sed -i 's/-Wl,-rpath,[^ ]*//' support/shobj-conf
        "%,
          configure_args = [
            "--disable-static",
            "--with-curses",
            "--docdir=/usr/share/doc/readline-8.3",
          ],
          env = { SHLIB_LIBS = "-lncursesw" },
        },
      }
      readline_build_image
      pkgs.buildscript_autotools
      [readline_src]
  in

  {
    include [
      readline_src,
      readline,
    ],
  }
