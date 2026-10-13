let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  # Configure version and hash through pkgs.pkgconf_src.
  let pkgconf_src = {
    version | default = "2.5.1",
    name = "pkgconf-src-%{version}",
    tag = "Source",
    object_hash | default = "cd05c9589b9f86ecf044c10a2269822bc9eb001eced2582cfffd658b0a50c243",
    origin = {
      tag = "Http",
      url = "https://distfiles.ariadne.space/pkgconf/pkgconf-%{version}.tar.xz",
    },
  }
  in

  let pkgconf_config = fun version =>
    fun install_dir =>
      {
        configure_args = [
          "--disable-static",
          "--docdir=/usr/share/doc/pkgconf-%{version}",
          # The native system has one physical library directory. Keep pkgconf's
          # built-in defaults aligned with it, so a package cannot accidentally
          # discover metadata or a library through the compatibility lib64 alias.
          "--with-pkg-config-dir=/usr/lib/pkgconfig:/usr/share/pkgconfig",
          "--with-system-libdir=/usr/lib",
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
              "%{install_dir}/usr/bin/pkg-config",
            ],
          },
          {
            name = "link_pkg_config_manpage",
            run_as = "root",
            argv = [
              "ln",
              "-sv",
              "pkgconf.1",
              "%{install_dir}/usr/share/man/man1/pkg-config.1",
            ],
          },
        ],
      }
  in

  let pkgconf_gen1 = {
    name = "pkgconf-gen1-%{inputs.source.version}",
    tag = "AutotoolsStageRootfs",
    config = pkgconf_config inputs.source.version "/stage",
    inputs = {
      _rootfs = recipe.bootstrap_toolchain_rootfs pkgs "pkgconf-gen1-build-rootfs" [],
      source = pkgs.pkgconf_src,
    },
  }
  in

  let pkgconf = {
    name = "pkgconf-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.c_runtime,
      ],
    },
    config = pkgconf_config inputs.source.version "/",
    inputs = {
      source = pkgs.pkgconf_src,
    },
  }
  in

  {
    include [
      pkgconf_gen1,
      pkgconf,
      pkgconf_src,
    ],
  }
