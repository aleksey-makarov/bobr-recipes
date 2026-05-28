let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let coreutils_src = {
    name = "coreutils-src-9.7",
    tag = "Source",
    object_hash = "8c2767ed9bc9711613a3b0026564e87cbeed79480ccb4f158fc2d239a7da92d2",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/coreutils/coreutils-9.7.tar.xz",
        "https://mirrors.kernel.org/gnu/coreutils/coreutils-9.7.tar.xz",
      ],
    },
  }
  in

  let coreutils_gen1 = {
    name = "coreutils-gen1-9.7",
    tag = "AutotoolsRootfs",
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
      rootfs = pkgs.buildpack_deps_rootfs,
      source = coreutils_src,
    },
  }
  in

  let coreutils = {
    name = "coreutils-9.7",
    tag = "AutotoolsRootfs",
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
      rootfs = pkgs.system_rootfs_1,
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
