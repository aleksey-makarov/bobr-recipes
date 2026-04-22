let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let kbd_src = {
    name = "kbd-src-2.8.0",
    tag = "Fetch",
    config = {
      url = "https://www.kernel.org/pub/linux/utils/kbd/kbd-2.8.0.tar.xz",
      hash = "md5:24b5d24f7483726b88f214dc6c77aa41",
    },
    inputs = {},
  }
  in

  let kbd_backspace_patch = {
    name = "kbd-backspace-patch",
    tag = "Fetch",
    config = {
      url = "https://www.linuxfromscratch.org/patches/lfs/12.4/kbd-2.8.0-backspace-1.patch",
      hash = "md5:f75cca16a38da6caa7d52151f7136895",
      unpack = false,
    },
    inputs = {},
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
