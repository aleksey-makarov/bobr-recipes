fun pkgs =>
  let kbd_src = fun version =>
    fun hash =>
    {
      name = "kbd-src-%{version}",
      tag = "Source",
      object_hash = hash,
      origin = {
        tag = "Http",
        url = "https://www.kernel.org/pub/linux/utils/kbd/kbd-%{version}.tar.xz",
      },
    }
  in

  let kbd_backspace_patch = {
    name = "kbd-backspace-patch",
    tag = "Source",
    object_hash = import "kbd-2.8.0-backspace-1.patch.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "kbd/kbd-2.8.0-backspace-1.patch",
    },
  }
  in

  let kbd = {
    version | default = "2.10.0",
    source_object_hash | default = "6e5ca4f8d76ee9e3a8db700b667f13e12aac9933828a64e1aaad93d26be9b479",
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
      # The backspace patch is applied declaratively via the patch_backspace
      # input (see inputs); these seds run afterwards in pre_configure.
      pre_configure = {
        name = "prepare_kbd_sources",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
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
            install -vdm755 "/usr/share/doc"
            cp -R -v "@{build}/source/docs/doc" -T "/usr/share/doc/kbd-%{version}"
          "%,
        ],
      },
    },
    inputs = {
      source = kbd_src version source_object_hash,
      # input name matches ^patch, so the synthetic builder applies it
      # (patch -Np1 in the source root) during source preparation.
      patch_backspace = kbd_backspace_patch,
    },
  }
  in

  {
    include [
      kbd_backspace_patch,
      kbd,
    ],
  }
