let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let ncurses_src = {
    name = "ncurses-src-6.6",
    tag = "Source",
    object_hash = "1042d01430d5c0f4777a6c51a52e4af1dc58ccbf001070fea5915a859b05190f",
    origin = {
      type = "http",
      url = [
        "https://invisible-mirror.net/archives/ncurses/ncurses-6.6.tar.gz",
      ],
      unpack = true,
    },
    meta = {},
  }
  in

  let ncurses = {
    name = "ncurses-6.6",
    tag = "Autotools",
    config = {
      configure_args = [
        "--mandir=/usr/share/man",
        "--with-shared",
        "--without-debug",
        "--without-normal",
        "--with-cxx-shared",
        "--enable-pc-files",
        "--with-pkg-config-libdir=/usr/lib/pkgconfig",
      ],
      post_install = [
        {
          name = "patch_curses_header",
          run_as = "root",
          argv = [
            "sed",
            "-e",
            "s/^#if.*XOPEN.*$/#if 1/",
            "-i",
            "@{out}/usr/include/curses.h",
          ],
        },
        {
          name = "install_unversioned_symlinks",
          run_as = "root",
          argv = [
            "/bin/sh",
            "-ec",
            m%"
              mkdir -p "@{out}/usr/lib/pkgconfig"
              for lib in ncurses form panel menu; do
                ln -sfv "lib"$lib"w.so" "@{out}/usr/lib/lib"$lib".so"
                ln -sfv "$lib"w.pc "@{out}/usr/lib/pkgconfig/"$lib".pc"
              done
              ln -sfv libncursesw.so "@{out}/usr/lib/libcurses.so"
            "%,
          ],
        },
        {
          name = "install_docs",
          run_as = "root",
          argv = [
            "/bin/sh",
            "-ec",
            m%"
              mkdir -p "@{out}/usr/share/doc"
              cp -v -R "@{source}/doc" -T "@{out}/usr/share/doc/ncurses-6.6"
            "%,
          ],
        },
      ],
    },
    inputs = {
      image = pkgs.system_image_2,
      source = ncurses_src,
    },
  }
  in

  {
    include [
      ncurses_src,
      ncurses,
    ],
  }
