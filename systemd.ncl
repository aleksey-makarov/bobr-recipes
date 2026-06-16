let recipe = import "recipe-lib.ncl" in
let version = "260.1" in
let hashes = {
  "257.8" = {
    source = "205fac8b8602a9b692c9bac232f9cac70a52050d9af9a44fc7e24144d7b67e50",
    man_pages = "b0c85b585ffc3cfa57c3ee9da936d2f1e0de9ef2fa1db4bff94005eee5bddc04",
  },
  "260.1" = {
    source = "9828f807cb88b337f4794f19858c5d0a6314ecfd31a83f0f795f8fa377201cc0",
    man_pages = "8e0e15ec0bb84e9a23a3813494fad7a5d2358e564a5efc98abba8997e168dc01",
  },
} in

fun pkgs =>
  let systemd_src = {
    name = "systemd-src-%{version}",
    tag = "Source",
    object_hash = hashes."%{version}".source,
    origin = {
      tag = "Http",
      url = "https://github.com/systemd/systemd/archive/v%{version}/systemd-%{version}.tar.gz",
    },
  }
  in

  let systemd_man_pages_src = {
    name = "systemd-man-pages-src-%{version}",
    tag = "Source",
    object_hash = hashes."%{version}".man_pages,
    origin = {
      tag = "Http",
      url = [
        "https://anduin.linuxfromscratch.org/LFS/systemd-man-pages-%{version}.tar.xz",
        "https://ftp2.osuosl.org/pub/blfs/conglomeration/systemd/systemd-man-pages-%{version}.tar.xz",
      ],
    },
  }
  in

  let systemd = {
    name = "systemd-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.attr,
        pkgs.acl,
        pkgs.gperf,
        pkgs.kmod,
        pkgs.libcap,
        pkgs.libxcrypt,
        pkgs.openssl,
        pkgs.util_linux,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.acl_libs,
        pkgs.libcap_libs,
        pkgs.libxcrypt_libs,
        pkgs.openssl_libs,
        pkgs.util_linux_libs,
      ],
    },
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
        "-Ddocdir=/usr/share/doc/systemd-%{version}",
      ],
      post_install = {
        name = "install_man_pages_and_machine_id",
        run_as = "root",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            install -vdm755 "@{out}/usr/share/man"
            tar -xf "@{man_pages}" \
                --no-same-owner --strip-components=1 \
                -C "@{out}/usr/share/man"
            install -vdm755 "@{out}/etc"
            : > "@{out}/etc/machine-id"

            for shared_lib in "@{out}"/usr/lib/systemd/libsystemd-shared-*.so; do
                [ -e "$shared_lib" ]
                shared_lib_name="$(basename "$shared_lib")"
                ln -sfv "systemd/$shared_lib_name" \
                    "@{out}/usr/lib/$shared_lib_name"
            done
          "%,
        ],
      },
    },
    inputs = {
      source = systemd_src,
      man_pages = systemd_man_pages_src,
    },
  }
  in

  let systemd_libs =
    recipe.split.libs systemd [
      "usr/lib/libsystemd.so*",
      "usr/lib/libudev.so*",
    ]
    & {
      deps = {
        build = [],
        runtime = [
          pkgs.glibc_libs,
          pkgs.libcap_libs,
        ],
      },
    }
  in

  {
    include [
      systemd_src,
      systemd_man_pages_src,
      systemd,
      systemd_libs,
    ],
  }
