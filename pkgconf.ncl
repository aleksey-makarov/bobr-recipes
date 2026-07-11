let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let pkgconf_src = fun version => fun hash => {
    name = "pkgconf-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://distfiles.ariadne.space/pkgconf/pkgconf-%{version}.tar.xz",
    },
  }
  in

  let pkgconf_config = fun version => {
    configure_args = [
      "--disable-static",
      "--docdir=/usr/share/doc/pkgconf-%{version}",
      # Search both /usr/lib and /usr/lib64 pkgconfig dirs: some packages (zlib,
      # glibc) install to /usr/lib64, and their .pc files (e.g. zlib.pc) must be
      # discoverable, or `Requires: zlib` resolution fails for dependents like
      # libpng -> and pkg-config reports them missing.
      "--with-pkg-config-dir=/usr/lib/pkgconfig:/usr/lib64/pkgconfig:/usr/share/pkgconfig",
      "--with-system-libdir=/usr/lib:/usr/lib64",
      "--with-system-includedir=/usr/include",
    ],
    post_install = [
      {
        name = "link_pkg_config",
        run_as = "root",
        argv = [
          "ln",
          "-sv",
          "pkgconf",
          "@{out}/usr/bin/pkg-config",
        ],
      },
      {
        name = "link_pkg_config_manpage",
        run_as = "root",
        argv = [
          "ln",
          "-sv",
          "pkgconf.1",
          "@{out}/usr/share/man/man1/pkg-config.1",
        ],
      },
    ],
  }
  in

  let pkgconf_gen1 = {
    version | default = "2.5.1",
    source_object_hash | default = "cd05c9589b9f86ecf044c10a2269822bc9eb001eced2582cfffd658b0a50c243",
    name = "pkgconf-gen1-%{version}",
    tag = "AutotoolsRootfs",
    config = pkgconf_config version,
    inputs = {
      _rootfs = pkgs.system_rootfs_1,
      source = pkgconf_src version source_object_hash,
    },
  }
  in

  let pkgconf = {
    version | default = "2.5.1",
    source_object_hash | default = "cd05c9589b9f86ecf044c10a2269822bc9eb001eced2582cfffd658b0a50c243",
    name = "pkgconf-%{version}",
    tag = "AutotoolsRootfs",
    config = pkgconf_config version,
    inputs = {
      _rootfs = pkgs.system_rootfs_2,
      source = pkgconf_src version source_object_hash,
    },
  }
  in

  {
    include [
      pkgconf_gen1,
      pkgconf,
    ],
  }
