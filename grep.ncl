let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let grep_src = fun version => fun hash => {
    name = "grep-src-%{version}",
    tag = "Source",
    object_hash = hash,
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
    version | default = "3.12",
    source_object_hash | default = "2649b27c0e90e632eadcd757be06c6e9a4f48d941de51e7c0f83ff76408a07b9",
    name = "grep-gen1-%{version}",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = ["--disable-nls", "--disable-perl-regexp"],
    },
    inputs = {
      _rootfs = pkgs.buildpack_deps_rootfs,
      source = grep_src version source_object_hash,
    },
  }
  in

  let grep = {
    version | default = "3.12",
    source_object_hash | default = "2649b27c0e90e632eadcd757be06c6e9a4f48d941de51e7c0f83ff76408a07b9",
    name = "grep-%{version}",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = ["--disable-nls", "--disable-perl-regexp"],
    },
    inputs = {
      _rootfs = pkgs.system_rootfs_1,
      source = grep_src version source_object_hash,
    },
  }
  in

  {
    include [
      grep_gen1,
      grep,
    ],
  }
