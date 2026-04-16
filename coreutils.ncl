let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let coreutils_src =
    recipe.fetch "coreutils-src-9.7" {
      url = [
        "https://ftp.gnu.org/gnu/coreutils/coreutils-9.7.tar.xz",
        "https://mirrors.kernel.org/gnu/coreutils/coreutils-9.7.tar.xz",
      ],
      hash = "md5:6b7285faf7d5eb91592bdd689270d3f1",
    }
  in

  let coreutils_gen1 =
    recipe.binary "coreutils-gen1-9.7" {
      script_config = {
        configure_args = [
          "--disable-nls",
          "--without-selinux",
          "--without-openssl",
          "--without-libgmp",
          "--enable-no-install-program=hostname,kill,uptime",
        ],
        post_install = m%"
              mkdir -pv "${MBUILD_INSTALL_DIR}/usr/sbin"
              mv -v "${MBUILD_INSTALL_DIR}/usr/bin/chroot" \
                    "${MBUILD_INSTALL_DIR}/usr/sbin/chroot"
              mkdir -pv "${MBUILD_INSTALL_DIR}/usr/share/man/man8"
              mv -v "${MBUILD_INSTALL_DIR}/usr/share/man/man1/chroot.1" \
                    "${MBUILD_INSTALL_DIR}/usr/share/man/man8/chroot.8"
              sed -i 's/"1"/"8"/' \
                     "${MBUILD_INSTALL_DIR}/usr/share/man/man8/chroot.8"
            "%,
      },
    } pkgs.host_image pkgs.buildscript_autotools [coreutils_src]
  in

  let coreutils =
    recipe.binary "coreutils-9.7" {
      script_config = {
        configure_args = [
          "--disable-nls",
          "--without-selinux",
          "--without-openssl",
          "--without-libgmp",
          "--enable-no-install-program=hostname,kill,uptime",
        ],
        post_install = m%"
              mkdir -pv "${MBUILD_INSTALL_DIR}/usr/sbin"
              mv -v "${MBUILD_INSTALL_DIR}/usr/bin/chroot" \
                    "${MBUILD_INSTALL_DIR}/usr/sbin/chroot"
              mkdir -pv "${MBUILD_INSTALL_DIR}/usr/share/man/man8"
              mv -v "${MBUILD_INSTALL_DIR}/usr/share/man/man1/chroot.1" \
                    "${MBUILD_INSTALL_DIR}/usr/share/man/man8/chroot.8"
              sed -i 's/"1"/"8"/' \
                     "${MBUILD_INSTALL_DIR}/usr/share/man/man8/chroot.8"
            "%,
      },
    } pkgs.system_image_1 pkgs.buildscript_autotools [coreutils_src]
  in

  {
    include [
      coreutils_src,
      coreutils_gen1,
      coreutils,
    ],
  }
