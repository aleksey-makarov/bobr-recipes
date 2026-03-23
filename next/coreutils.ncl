let buildscripts = import "buildscripts.ncl" in

fun pkgs =>
  let coreutils_src_9_7 =
    store.fetch "coreutils-src-9.7" {
      url = [
        "https://ftp.gnu.org/gnu/coreutils/coreutils-9.7.tar.xz",
        "https://mirrors.kernel.org/gnu/coreutils/coreutils-9.7.tar.xz",
      ],
      hash = "md5:6b7285faf7d5eb91592bdd689270d3f1",
    }
  in

  let buildscript_coreutils_gen1_9_7 =
    store.text "buildscript-coreutils-gen1-9.7" {
      kind = "build-script",
      source =
        (buildscripts.autotools {
          output = "buildscript-coreutils-gen1-9.7",
          configure_args = [
            "--disable-nls",
            "--without-selinux",
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
        }).source,
    }
  in

  let coreutils_gen1_9_7 =
    store.bind coreutils_src_9_7 (fun coreutils_src =>
    store.bind buildscript_coreutils_gen1_9_7 (fun script =>
    store.bind pkgs.host_image (fun image =>
    store.binary "coreutils-gen1-9.7" {
      kind = "binary-output",
      optimize = "size",
    } image script [coreutils_src])))
  in

  {
    include [
      coreutils_src_9_7,
      buildscript_coreutils_gen1_9_7,
      coreutils_gen1_9_7,
    ],
  }
