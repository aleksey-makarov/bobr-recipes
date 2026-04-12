let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let ncurses_src =
    recipe.fetch "ncurses-src-6.6" {
      url = [
        "https://invisible-mirror.net/archives/ncurses/ncurses-6.6.tar.gz",
      ],
      hash = "md5:dd45bf6854430af403452a7a6a40652c",
    }
  in

  let ncurses =
    recipe.binary "ncurses-6.6" {
      script_config = {
        configure_args = [
          "--mandir=/usr/share/man",
          "--with-shared",
          "--without-debug",
          "--without-normal",
          "--with-cxx-shared",
          "--enable-pc-files",
          "--with-pkg-config-libdir=/usr/lib/pkgconfig",
        ],
        post_install = m%"
          sed -e 's/^#if.*XOPEN.*$/#if 1/' -i "/out/${out}/usr/include/curses.h"
          mkdir -p "/out/${out}/usr/lib/pkgconfig"
          mkdir -p "/out/${out}/usr/share/doc"
          for lib in ncurses form panel menu; do
            ln -sfv "lib${lib}w.so" "/out/${out}/usr/lib/lib${lib}.so"
            ln -sfv "${lib}w.pc" "/out/${out}/usr/lib/pkgconfig/${lib}.pc"
          done
          ln -sfv libncursesw.so "/out/${out}/usr/lib/libcurses.so"
          cp -v -R doc -T "/out/${out}/usr/share/doc/ncurses-6.6"
        "%,
      },
    } pkgs.system_image_2 pkgs.buildscript_autotools [ncurses_src]
  in

  {
    include [
      ncurses_src,
      ncurses,
    ],
  }
