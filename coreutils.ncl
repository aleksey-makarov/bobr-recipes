let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let coreutils_src = fun version => fun hash => {
    name = "coreutils-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/coreutils/coreutils-%{version}.tar.xz",
        "https://mirrors.kernel.org/gnu/coreutils/coreutils-%{version}.tar.xz",
      ],
    },
  }
  in

  let coreutils_gen1 = {
    version | default = "9.7",
    source_object_hash | default = "e8bb26ad0293f9b5a1fc43fb42ba970e312c66ce92c1b0b16713d7500db251bf",
    name = "coreutils-gen1-%{version}",
    tag = "AutotoolsStageRootfs",
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
            mkdir -pv "/stage/usr/share/man/man8"
            mv -v "/stage/usr/share/man/man1/chroot.1" \
                  "/stage/usr/share/man/man8/chroot.8"
            sed -i 's/"1"/"8"/' \
                   "/stage/usr/share/man/man8/chroot.8"
          "%,
        ],
      },
    },
    inputs = {
      _rootfs = pkgs.oci_buildpack_deps_rootfs,
      source = coreutils_src version source_object_hash,
    },
  }
  in

  let coreutils = {
    version | default = "9.7",
    source_object_hash | default = "e8bb26ad0293f9b5a1fc43fb42ba970e312c66ce92c1b0b16713d7500db251bf",
    name = "coreutils-%{version}",
    tag = "AutotoolsStageRootfs",
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
            mkdir -pv "/stage/usr/share/man/man8"
            mv -v "/stage/usr/share/man/man1/chroot.1" \
                  "/stage/usr/share/man/man8/chroot.8"
            sed -i 's/"1"/"8"/' \
                   "/stage/usr/share/man/man8/chroot.8"
          "%,
        ],
      },
    },
    inputs = {
      _rootfs = recipe.bootstrap_toolchain_rootfs pkgs "coreutils-build-rootfs" [],
      source = coreutils_src version source_object_hash,
    },
  }
  in

  {
    include [
      coreutils_gen1,
      coreutils,
    ],
  }
