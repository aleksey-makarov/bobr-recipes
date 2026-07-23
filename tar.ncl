let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let tar_src = fun version => fun hash => {
    name = "tar-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/tar/tar-%{version}.tar.xz",
        "https://mirrors.kernel.org/gnu/tar/tar-%{version}.tar.xz",
      ],
    },
  }
  in

  let tar_gen1 = {
    version | default = "1.35",
    source_object_hash | default = "4d62ff37342ec7aed748535323930c7cf94acf71c3591882b26a7ea50f3edc16",
    name = "tar-gen1-%{version}",
    tag = "AutotoolsStageRootfs",
    config = {
      configure_args = [
        "--disable-nls",
        "--without-selinux",
      ],
    },
    inputs = {
      _rootfs = pkgs.oci_buildpack_deps_rootfs,
      source = tar_src version source_object_hash,
    },
  }
  in

  let tar = {
    version | default = "1.35",
    source_object_hash | default = "4d62ff37342ec7aed748535323930c7cf94acf71c3591882b26a7ea50f3edc16",
    name = "tar-%{version}",
    tag = "AutotoolsStageRootfs",
    config = {
      configure_args = [
        "--disable-nls",
        "--without-selinux",
      ],
    },
    inputs = {
      _rootfs = recipe.bootstrap_toolchain_rootfs pkgs "tar-build-rootfs" [],
      source = tar_src version source_object_hash,
    },
  }
  in

  {
    include [
      tar_gen1,
      tar,
    ],
  }
