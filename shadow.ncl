let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let shadow_src = {
    name = "shadow-src-4.18.0",
    tag = "Fetch",
    config = {
      url = "https://github.com/shadow-maint/shadow/releases/download/4.18.0/shadow-4.18.0.tar.xz",
      hash = "md5:30ef46f54363db1d624587be68794ef2",
    },
    inputs = {},
  }
  in

  let shadow_build_image = {
    name = "shadow-build-image",
    tag = "Image",
    config = { ref_name | default = "shadow-build-image" } & {},
    inputs =
      { base = pkgs.system_image_2 }
      & recipe.numbered_inputs [
        pkgs.libxcrypt,
      ],
  }
  in

  let shadow = {
    name = "shadow-4.18.0",
    tag = "Autotools",
    config = {
      pre_configure = [
        {
          name = "prepare_live_usr",
          run_as = "root",
          cwd = "${build}",
          argv = [
            "/bin/sh",
            "-ec",
            "mkdir -p /usr/bin && touch /usr/bin/passwd",
          ],
        },
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
        "--disable-static",
        "--with-bcrypt",
        "--with-yescrypt",
        "--without-libbsd",
        "--with-group-name-max-length=32",
      ],
      make_args = ["exec_prefix=/usr"],
      post_install = {
        name = "install_man_pages",
        run_as = "root",
        cwd = "${source}",
        argv = [
          "/bin/sh",
          "-ec",
          "make DESTDIR=\"${out}\" -C man install-man",
        ],
      },
    },
    inputs = {
      image = shadow_build_image,
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
