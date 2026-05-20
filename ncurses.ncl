let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let ncurses_src = {
    name = "ncurses-src-6.6",
    tag = "Source",
    object_hash = "33c7002ae4e50d400f893ce1cfe3d0867503f0b057a00c8c76181519d596351a",
    origin = {
      type = "http",
      url = [
        "https://invisible-mirror.net/archives/ncurses/ncurses-6.6.tar.gz",
      ],
    },
  }
  in

  let ncurses = {
    name = "ncurses-6.6",
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
              cp -v -R "@{build}/source/doc" -T "@{out}/usr/share/doc/ncurses-6.6"
            "%,
          ],
        },
      ],
    },
    inputs = {
      rootfs = pkgs.system_rootfs_2,
      source = ncurses_src,
    },
  }
  in

  let ncurses_libs = {
    name = "ncurses-libs-6.6",
    tag = "TreeSubset",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
      ],
    },
    config = {
      include = [
        "usr/lib/*.so*",
        "usr/share/terminfo/**",
        "usr/share/tabset/**",
      ],
    },
    inputs = {
      tree = ncurses,
    },
  }
  in

  {
    include [
      ncurses_src,
      ncurses,
      ncurses_libs,
    ],
  }
