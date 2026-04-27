let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let kbd_src = {
    name = "kbd-src-2.8.0",
    tag = "Source",
    object_hash = "264b06aef2d195e374e8045d482722a43f609e24fb261096430d22381f96c08e",
    origin = {
      type = "http",
      url = "https://www.kernel.org/pub/linux/utils/kbd/kbd-2.8.0.tar.xz",
      unpack = true,
    },
    meta = {},
  }
  in

  let kbd_backspace_patch = {
    name = "kbd-backspace-patch",
    tag = "Source",
    object_hash = "e9f468ea0ed2089b0743133e41e13d3cd9891afe258534d82bc596cda98c8f0d",
    origin = {
      type = "http",
      url = "https://www.linuxfromscratch.org/patches/lfs/12.4/kbd-2.8.0-backspace-1.patch",
      unpack = false,
    },
    meta = {},
  }
  in

  let kbd = {
    name = "kbd-2.8.0",
    tag = "Autotools",
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
            cp -R -v "@{source}/docs/doc" -T "@{out}/usr/share/doc/kbd-2.8.0"
          "%,
        ],
      },
    },
    inputs = {
      image = pkgs.system_image,
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
