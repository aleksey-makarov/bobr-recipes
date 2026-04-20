let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let shadow_src =
    {
      name = "shadow-src-4.18.0",
      tag = "Fetch",
      config = {
      url = "https://github.com/shadow-maint/shadow/releases/download/4.18.0/shadow-4.18.0.tar.xz",
      hash = "md5:30ef46f54363db1d624587be68794ef2",
      },
      inputs = {},
    }
  in

  let shadow_build_image =
    {
      name = "shadow-build-image",
      tag = "Image",
      config = { ref_name | default = "shadow-build-image" } & {},
      inputs = {
        base = pkgs.system_image_2,
        inputs = [
      pkgs.libxcrypt,
    ],
      },
    }
  in

  let shadow =
    recipe.binary "shadow-4.18.0" {
      steps = [
        recipe.steps.step "prepare_live_usr" "root" "${build_dir}" [
          "/bin/sh",
          "-ec",
          "mkdir -p /usr/bin && touch /usr/bin/passwd",
        ],
        recipe.steps.step "configure" "build-user" "${build_dir}" ["${script}", "configure"],
        recipe.steps.step "build" "build-user" "${build_dir}" ["${script}", "build"],
        recipe.steps.step "install" "root" "${build_dir}" ["${script}", "install"],
        recipe.steps.step "post_install" "root" "${build_dir}" ["${script}", "post_install"],
      ],
      script_config = {
        pre_configure = m%"
          sed -i 's/groups$(EXEEXT) //' src/Makefile.in
          find man -name Makefile.in -exec sed -i 's/groups\\.1 / /' {} ';'
          find man -name Makefile.in -exec sed -i 's/getspnam\\.3 / /' {} ';'
          find man -name Makefile.in -exec sed -i 's/passwd\\.5 / /' {} ';'
          sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD YESCRYPT:' \
              -e 's:/var/spool/mail:/var/mail:' \
              -e '/PATH=/{s@/sbin:@@;s@/bin:@@}' \
              -i etc/login.defs
        "%,
        configure_args = [
          "--sysconfdir=/etc",
          "--disable-static",
          "--with-bcrypt",
          "--with-yescrypt",
          "--without-libbsd",
          "--with-group-name-max-length=32",
        ],
        make_args = ["exec_prefix=/usr"],
        post_install = "make DESTDIR=\"${MBUILD_INSTALL_DIR}\" -C man install-man",
      },
    } shadow_build_image pkgs.buildscript_autotools [shadow_src]
  in

  {
    include [
      shadow_src,
      shadow,
    ],
  }
