let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let ncurses_src = fun version => fun hash => {
    name = "ncurses-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = [
        "https://invisible-mirror.net/archives/ncurses/ncurses-%{version}.tar.gz",
      ],
    },
  }
  in

  let ncurses = {
    version | default = "6.6",
    source_object_hash | default = "355b4cbbed880b0381a04c46617b7656e362585d52e9cf84a67e2009b749ff11",
    name = "ncurses-%{version}",
    tag = "AutotoolsRootfs",
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
        # Split the low-level terminfo/termcap routines (tgetent, tputs,
        # setupterm, ...) into a separate libtinfo, as the big distros do. The
        # "=tinfo" argument forces the name libtinfo (not libtinfow) even though
        # this is a wide-character build, so consumers get a real libtinfo.so.6:
        # readline links it directly (self-contained libreadline.so) and the
        # prebuilt clang's libtinfo.so.N resolves to it instead of a symlink hack.
        "--with-termlib=tinfo",
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
              cp -v -R "@{build}/source/doc" -T "@{out}/usr/share/doc/ncurses-%{version}"
            "%,
          ],
        },
      ],
    },
    inputs = {
      _rootfs = pkgs.system_rootfs_2,
      source = ncurses_src version source_object_hash,
    },
  }
  in

  let ncurses_libs =
    recipe.split.libs
      ncurses
      [
        "usr/lib/*.so*",
        "usr/share/terminfo/**",
        "usr/share/tabset/**",
      ]
    & {
      deps = {
        build = [],
        runtime = [
          pkgs.glibc_libs,
          pkgs.gcc_libs,
        ],
      },
    }
  in

  {
    include [
      ncurses,
      ncurses_libs,
    ],
  }
