let recipe = import "recipe-lib.ncl" in
let version = "260.1" in
let hashes = {
  "257.8" = {
    source = "f280278161446fe3838bedb970c7b3998043ad107f7627735a81483218c6f6f9",
    man_pages = "89d32984d7f3cc410101806f7a2bb01ba20cad04b30c190c98387b1dd8fef7f5",
  },
  "260.1" = {
    source = "11b9821892b75d19af7b21f0f7f4e53636638147faf3e6a4ded78b40cb38993f",
    man_pages = "b0c143b3388afac9e1154facf0821809b396ab86f3f61ddc8028679a7d65d83c",
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
        pkgs.linux_pam,
        pkgs.openssl,
        pkgs.util_linux,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.acl_libs,
        pkgs.libcap_libs,
        pkgs.libxcrypt_libs,
        # pam_systemd.so links libpam.so.0 (built once -Dpam=enabled).
        pkgs.linux_pam_libs,
        pkgs.openssl_libs,
        pkgs.util_linux_libs,
        # udevd's kmod builtin (module autoloading by modalias) links libkmod.
        pkgs.kmod_libs,
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
        # Enable the kmod integration (udev module autoloading by modalias via
        # the kmod builtin + 80-drivers.rules). Required, not auto: fail loudly
        # if libkmod is ever not found rather than silently shipping a udev
        # that cannot load modules.
        "-Dkmod=enabled",
        "-Ddefault-dnssec=no",
        "-Dfirstboot=false",
        "-Dinstall-tests=false",
        "-Dldconfig=false",
        "-Drpmmacrosdir=no",
        "-Dhomed=disabled",
        "-Duserdb=false",
        "-Dman=disabled",
        "-Dmode=release",
        # Build pam_systemd.so so logind registers a session at login (requires
        # linux-pam). Let systemd install its own /etc/pam.d/systemd-user (used
        # by user@.service); the login/system-auth stacks come from
        # system-runtime-files.
        "-Dpam=enabled",
        "-Dpamconfdir=/etc/pam.d",
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
            # Ship the special "uninitialized" marker rather than an empty file:
            # an empty /etc/machine-id is NOT treated as first boot, but the
            # string "uninitialized" is (machine-id(5)). With a volatile /etc the
            # marker reappears every boot, so systemd re-runs first-boot init --
            # notably presetting units -- on each boot, which is how getty@tty1
            # etc. get enabled per policy (no build-time preset, no hand enable).
            printf 'uninitialized\n' > "@{out}/etc/machine-id"

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
      "usr/lib/libsystemd-shared-*.so",
      "usr/lib/systemd/libsystemd-shared-*.so",
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

  let systemd_dev = {
    name = "systemd-dev-%{version}",
    tag = "TreeSubset",
    config = {
      include = [
        "usr/include/libudev.h",
        "usr/include/systemd/*.h",
        "usr/lib/libsystemd.so*",
        "usr/lib/libudev.so*",
        "usr/lib/libsystemd-shared-*.so",
        "usr/lib/pkgconfig/libsystemd.pc",
        "usr/lib/pkgconfig/libudev.pc",
        "usr/lib/systemd/libsystemd-shared-*.so",
      ],
    },
    inputs = {
      tree = systemd,
    },
    deps = {
      build = [],
      runtime = [
        systemd_libs,
      ],
    },
  }
  in

  {
    include [
      systemd,
      systemd_libs,
      systemd_dev,
    ],
  }
