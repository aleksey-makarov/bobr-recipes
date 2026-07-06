let recipe = import "recipe-lib.ncl" in
let hashes = {
  "2.8.0" = "f2c22be2fabadc5fd2465e1e2ae20dd9af7027c410cdbd12e0d9b491c302f4c3",
  "2.10.0" = "9b7925f9078134fbe9092e741bf00824822e5f2bf26871b6b2f07fccb691b522",
}
in

fun pkgs =>
  let kbd_src = fun version =>
    {
      name = "kbd-src-%{version}",
      tag = "Source",
      object_hash = hashes."%{version}",
      origin = {
        tag = "Http",
        url = "https://www.kernel.org/pub/linux/utils/kbd/kbd-%{version}.tar.xz",
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
    version | default = "2.10.0",
    name = "kbd-%{version}",
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
            cp -R -v "@{build}/source/docs/doc" -T "@{out}/usr/share/doc/kbd-%{version}"
          "%,
        ],
      },
    },
    inputs = {
      source = kbd_src version,
      backspace_patch = kbd_backspace_patch,
    },
  }
  in

  {
    include [
      kbd_backspace_patch,
      kbd,
    ],
  }
