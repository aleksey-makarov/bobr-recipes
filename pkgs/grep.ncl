let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let grep_src = {
    version | default = "3.12",
    name = "grep-src-%{version}",
    tag = "Source",
    object_hash | default = "2649b27c0e90e632eadcd757be06c6e9a4f48d941de51e7c0f83ff76408a07b9",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/grep/grep-%{version}.tar.xz",
        "https://mirrors.kernel.org/gnu/grep/grep-%{version}.tar.xz",
      ],
    },
  }
  in

  let grep_gen1 = {
    name = "grep-gen1-%{inputs.source.version}",
    tag = "AutotoolsStageRootfs",
    config = {
      configure_args = ["--disable-nls", "--disable-perl-regexp"],
    },
    inputs = {
      _rootfs = pkgs.oci_buildpack_deps_rootfs,
      source = pkgs.grep_src,
    },
  }
  in

  let grep = {
    name = "grep-%{inputs.source.version}",
    tag = "AutotoolsStageRootfs",
    config = {
      configure_args = ["--disable-nls", "--disable-perl-regexp"],
    },
    inputs = {
      _rootfs = recipe.bootstrap_toolchain_rootfs pkgs "grep-build-rootfs" [],
      source = pkgs.grep_src,
    },
  }
  in

  {
    include [
      grep_src,
      grep_gen1,
      grep,
    ],
  }
