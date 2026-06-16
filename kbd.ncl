let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let kbd_src = {
    name = "kbd-src-2.8.0",
    tag = "Source",
    object_hash = "f2c22be2fabadc5fd2465e1e2ae20dd9af7027c410cdbd12e0d9b491c302f4c3",
    origin = {
      tag = "Http",
      url = "https://www.kernel.org/pub/linux/utils/kbd/kbd-2.8.0.tar.xz",
    },
  }
  in

  let kbd_backspace_patch = {
    name = "kbd-backspace-patch",
    tag = "Source",
    object_hash = "e9f468ea0ed2089b0743133e41e13d3cd9891afe258534d82bc596cda98c8f0d",
    origin = {
      tag = "RecipePath",
      path = "kbd-2.8.0-backspace-1.patch",
    },
  }
  in

  let kbd = {
    name = "kbd-2.8.0",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.flex,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      pre_configure = {
        name = "prepare_kbd_sources",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            patch -Np1 -i "@{backspace_patch}"
            sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure
            sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
          "%,
        ],
      },
      configure_args = [
        "--disable-vlock",
      ],
      post_install = {
        name = "install_docs",
        run_as = "root",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            install -vdm755 "@{out}/usr/share/doc"
            cp -R -v "@{build}/source/docs/doc" -T "@{out}/usr/share/doc/kbd-2.8.0"
          "%,
        ],
      },
    },
    inputs = {
      source = kbd_src,
      backspace_patch = kbd_backspace_patch,
    },
  }
  in

  {
    include [
      kbd_src,
      kbd_backspace_patch,
      kbd,
    ],
  }
