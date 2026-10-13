let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  # Both stages share this Source unless an overlay replaces inputs.source
  # on one consumer. Version is recipe metadata, not a Source wire field.
  let gzip_src = {
    version | default = "1.14",
    name = "gzip-src-%{version}",
    tag = "Source",
    object_hash | default = "01a7b881bd220bfdf615f97b8718f80bdfd3f6add385b993dcf6efd14e8c0ac6",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/gzip/gzip-%{version}.tar.xz",
        "https://mirrors.kernel.org/gnu/gzip/gzip-%{version}.tar.xz",
      ],
    },
  }
  in

  let gzip_gen1 = {
    name = "gzip-gen1-%{inputs.source.version}",
    tag = "AutotoolsStageRootfs",
    config = {
      configure_args = ["--disable-nls"],
    },
    inputs = {
      _rootfs = pkgs.oci_buildpack_deps_rootfs,
      source = pkgs.gzip_src,
    },
  }
  in

  let gzip = {
    name = "gzip-%{inputs.source.version}",
    tag = "AutotoolsStageRootfs",
    config = {
      configure_args = ["--disable-nls"],
    },
    inputs = {
      _rootfs = recipe.bootstrap_toolchain_rootfs pkgs "gzip-build-rootfs" [],
      source = pkgs.gzip_src,
    },
  }
  in

  {
    include [
      gzip_gen1,
      gzip,
      gzip_src,
    ],
  }
