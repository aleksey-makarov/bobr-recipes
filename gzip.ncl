let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let gzip_src = fun version => fun hash => {
    name = "gzip-src-%{version}",
    tag = "Source",
    object_hash = hash,
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
    version | default = "1.14",
    source_object_hash | default = "01a7b881bd220bfdf615f97b8718f80bdfd3f6add385b993dcf6efd14e8c0ac6",
    name = "gzip-gen1-%{version}",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = ["--disable-nls"],
    },
    inputs = {
      _rootfs = pkgs.buildpack_deps_rootfs,
      source = gzip_src version source_object_hash,
    },
  }
  in

  let gzip = {
    version | default = "1.14",
    source_object_hash | default = "01a7b881bd220bfdf615f97b8718f80bdfd3f6add385b993dcf6efd14e8c0ac6",
    name = "gzip-%{version}",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = ["--disable-nls"],
    },
    inputs = {
      _rootfs = pkgs.system_rootfs_1,
      source = gzip_src version source_object_hash,
    },
  }
  in

  {
    include [
      gzip_gen1,
      gzip,
    ],
  }
