let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let systemd_src = {
    name = "systemd-src-257.8",
    tag = "Fetch",
    config = {
      url = "https://github.com/systemd/systemd/archive/v257.8/systemd-257.8.tar.gz",
      hash = "md5:25fe5d328e22641254761f1baa74cee0",
    },
    inputs = {},
  }
  in

  let systemd_man_pages_src = {
    name = "systemd-man-pages-src-257.8",
    tag = "Fetch",
    config = {
      url = "https://anduin.linuxfromscratch.org/LFS/systemd-man-pages-257.8.tar.xz",
      hash = "md5:a44063e2ec0cf4adfd2ed5c9e9e095c5",
      unpack = false,
    },
    inputs = {},
  }
  in

  let systemd_build_image = {
    name = "systemd-build-image",
    tag = "Image",
    config = { ref_name | default = "systemd-build-image" } & {},
    inputs = {
      base = pkgs.system_image,
      inputs = [
        pkgs.attr,
        pkgs.acl,
        pkgs.gperf,
        pkgs.kmod,
        pkgs.libcap,
        pkgs.libxcrypt,
        pkgs.openssl,
        pkgs.util_linux,
        pkgs.xz,
      ],
    },
  }
  in

  let systemd =
    recipe.binary
      "systemd-257.8"
      {
        script_config = {
          pre_configure = m%"
          sed -e 's/GROUP="render"/GROUP="video"/' \
              -e 's/GROUP="sgx", //' \
              -i rules.d/50-udev-default.rules.in
        "%,
          build_dir = "build",
          setup_args = [
            "--buildtype=release",
            "--libdir=/usr/lib",
            "-Ddefault-dnssec=no",
            "-Dfirstboot=false",
            "-Dinstall-tests=false",
            "-Dldconfig=false",
            "-Drpmmacrosdir=no",
            "-Dhomed=disabled",
            "-Duserdb=false",
            "-Dman=disabled",
            "-Dmode=release",
            "-Dpamconfdir=no",
            "-Ddev-kvm-mode=0660",
            "-Dnobody-group=nogroup",
            "-Dsysupdate=disabled",
            "-Dukify=disabled",
            "-Ddocdir=/usr/share/doc/systemd-257.8",
          ],
          post_install = m%"
          install -vdm755 ${MBUILD_INSTALL_DIR}/usr/share/man
          tar -xf /in/sources1 \
              --no-same-owner --strip-components=1 \
              -C ${MBUILD_INSTALL_DIR}/usr/share/man
          install -vdm755 ${MBUILD_INSTALL_DIR}/etc
          : > ${MBUILD_INSTALL_DIR}/etc/machine-id
        "%,
        },
      }
      systemd_build_image
      pkgs.buildscript_meson
      [systemd_src, systemd_man_pages_src]
  in

  {
    include [
      systemd_src,
      systemd_man_pages_src,
      systemd,
    ],
  }
