let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

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
      kind = "binary-output",
      script_config = {
        configure_args = [
          "--disable-nls",
          "--without-selinux",
          "--without-openssl",
          "--without-libgmp",
          "--enable-install-program=hostname",
          "--enable-no-install-program=kill,uptime",
        ],
        post_install = m%"
              mkdir -pv "/out/${out}/usr/sbin"
              mv -v "/out/${out}/usr/bin/chroot" \
                    "/out/${out}/usr/sbin/chroot"
              mkdir -pv "/out/${out}/usr/share/man/man8"
              mv -v "/out/${out}/usr/share/man/man1/chroot.1" \
                    "/out/${out}/usr/share/man/man8/chroot.8"
              sed -i 's/"1"/"8"/' \
                     "/out/${out}/usr/share/man/man8/chroot.8"
            "%,
      },
    } pkgs.host_image pkgs.buildscript_autotools [coreutils_src]
  in

  let coreutils =
    build.build_autotools {
      name = "coreutils-9.7",
      sources = [coreutils_src],
      script_config = {
        configure_args = [
          "--disable-nls",
          "--without-selinux",
          "--without-openssl",
          "--without-libgmp",
          "--enable-install-program=hostname",
          "--enable-no-install-program=kill,uptime",
        ],
        post_install = m%"
              mkdir -pv "/out/${out}/usr/sbin"
              mv -v "/out/${out}/usr/bin/chroot" \
                    "/out/${out}/usr/sbin/chroot"
              mkdir -pv "/out/${out}/usr/share/man/man8"
              mv -v "/out/${out}/usr/share/man/man1/chroot.1" \
                    "/out/${out}/usr/share/man/man8/chroot.8"
              sed -i 's/"1"/"8"/' \
                     "/out/${out}/usr/share/man/man8/chroot.8"
            "%,
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
