let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let shadow_src = {
    name = "shadow-src-4.18.0",
    tag = "Source",
    object_hash = "06a05b0ff7c6a9a249f9c5cf1783a122d6f5a4b1b0a7f7c00eea73240fb5cce1",
    origin = {
      type = "http",
      url = "https://github.com/shadow-maint/shadow/releases/download/4.18.0/shadow-4.18.0.tar.xz",
    },
  }
  in

  let shadow_build_rootfs = {
    name = "shadow-build-rootfs",
    tag = "TreeMerge",
    config = {},
    inputs =
      { base = pkgs.system_rootfs_2 }
      & recipe.numbered_inputs [
        pkgs.libxcrypt,
      ],
  }
  in

  let shadow = {
    name = "shadow-4.18.0",
    tag = "AutotoolsRootfs",
    config = {
      pre_configure = [
        {
          name = "prepare_shadow_sources",
          run_as = "build-user",
          argv = [
            "/bin/sh",
            "-ec",
            m%"
              sed -i 's/groups$(EXEEXT) //' src/Makefile.in
              find man -name Makefile.in -exec sed -i 's/groups\\.1 / /' {} ';'
              find man -name Makefile.in -exec sed -i 's/getspnam\\.3 / /' {} ';'
              find man -name Makefile.in -exec sed -i 's/passwd\\.5 / /' {} ';'
              sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD YESCRYPT:' \
                  -e 's:/var/spool/mail:/var/mail:' \
                  -e '/PATH=/{s@/sbin:@@;s@/bin:@@}' \
                  -i etc/login.defs
            "%,
          ],
        },
      ],
      configure_args = [
        "--sysconfdir=/etc",
        "--sbindir=/usr/bin",
        "--disable-static",
        "--with-bcrypt",
        "--with-yescrypt",
        "--without-libbsd",
        "--with-group-name-max-length=32",
      ],
      make_args = [
        "exec_prefix=/usr",
        "usbindir=/usr/bin",
      ],
      post_install = {
        name = "install_man_pages",
        run_as = "root",
        cwd = "@{build}/build",
        argv = [
          "/bin/sh",
          "-ec",
          "make DESTDIR=\"@{out}\" -C man install-man",
        ],
      },
    },
    inputs = {
      rootfs = shadow_build_rootfs,
      source = shadow_src,
    },
  }
  in

  {
    include [
      shadow_src,
      shadow,
    ],
  }
