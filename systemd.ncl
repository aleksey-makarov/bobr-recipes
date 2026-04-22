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
    inputs =
      { base = pkgs.system_image }
      & recipe.numbered_inputs [
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
  }
  in

  let systemd = {
    name = "systemd-257.8",
    tag = "Meson",
    config = {
      pre_configure = {
        name = "patch_udev_rules",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            sed -e 's/GROUP="render"/GROUP="video"/' \
                -e 's/GROUP="sgx", //' \
                -i rules.d/50-udev-default.rules.in
          "%,
        ],
      },
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
      post_install = {
        name = "install_man_pages_and_machine_id",
        run_as = "root",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            install -vdm755 "${out}/usr/share/man"
            tar -xf "${man_pages}" \
                --no-same-owner --strip-components=1 \
                -C "${out}/usr/share/man"
            install -vdm755 "${out}/etc"
            : > "${out}/etc/machine-id"
          "%,
        ],
      },
    },
    inputs = {
      image = systemd_build_image,
      source = systemd_src,
      man_pages = systemd_man_pages_src,
    },
  }
  in

  {
    include [
      systemd_src,
      systemd_man_pages_src,
      systemd,
    ],
  }
