let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let coreutils_src = {
    name = "coreutils-src-9.7",
    tag = "Source",
    object_hash = "9b9ce647d9013a0f978cc564ebfc2e7fa86c838e011d4979af05d519255c9899",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/coreutils/coreutils-9.7.tar.xz",
        "https://mirrors.kernel.org/gnu/coreutils/coreutils-9.7.tar.xz",
      ],
      unpack = true,
    },
    meta = {},
  }
  in

  let coreutils_gen1 = {
    name = "coreutils-gen1-9.7",
    tag = "Autotools",
    config = {
      configure_args = [
        "--disable-nls",
        "--without-selinux",
        "--without-openssl",
        "--without-libgmp",
        "--enable-no-install-program=hostname,kill,uptime",
      ],
      post_install = {
        name = "fixup_chroot_install",
        run_as = "root",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            mkdir -pv "@{out}/usr/sbin"
            mv -v "@{out}/usr/bin/chroot" \
                  "@{out}/usr/sbin/chroot"
            mkdir -pv "@{out}/usr/share/man/man8"
            mv -v "@{out}/usr/share/man/man1/chroot.1" \
                  "@{out}/usr/share/man/man8/chroot.8"
            sed -i 's/"1"/"8"/' \
                   "@{out}/usr/share/man/man8/chroot.8"
          "%,
        ],
      },
    },
    inputs = {
      image = pkgs.buildpack_deps_image,
      source = coreutils_src,
    },
  }
  in

  let coreutils = {
    name = "coreutils-9.7",
    tag = "Autotools",
    config = {
      configure_args = [
        "--disable-nls",
        "--without-selinux",
        "--without-openssl",
        "--without-libgmp",
        "--enable-no-install-program=hostname,kill,uptime",
      ],
      post_install = {
        name = "fixup_chroot_install",
        run_as = "root",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            mkdir -pv "@{out}/usr/sbin"
            mv -v "@{out}/usr/bin/chroot" \
                  "@{out}/usr/sbin/chroot"
            mkdir -pv "@{out}/usr/share/man/man8"
            mv -v "@{out}/usr/share/man/man1/chroot.1" \
                  "@{out}/usr/share/man/man8/chroot.8"
            sed -i 's/"1"/"8"/' \
                   "@{out}/usr/share/man/man8/chroot.8"
          "%,
        ],
      },
    },
    inputs = {
      image = pkgs.system_image_1,
      source = coreutils_src,
    },
  }
  in

  {
    include [
      coreutils_src,
      coreutils_gen1,
      coreutils,
    ],
  }
