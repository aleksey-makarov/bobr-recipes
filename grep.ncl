let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let grep_src = {
    name = "grep-src-3.12",
    tag = "Source",
    object_hash = "2649b27c0e90e632eadcd757be06c6e9a4f48d941de51e7c0f83ff76408a07b9",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/grep/grep-3.12.tar.xz",
        "https://mirrors.kernel.org/gnu/grep/grep-3.12.tar.xz",
      ],
    },
  }
  in

  let grep_gen1 = {
    name = "grep-gen1-3.12",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = ["--disable-nls", "--disable-perl-regexp"],
    },
    inputs = {
      _rootfs = pkgs.buildpack_deps_rootfs,
      source = grep_src,
    },
  }
  in

  let grep = {
    name = "grep-3.12",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = ["--disable-nls", "--disable-perl-regexp"],
    },
    inputs = {
      _rootfs = pkgs.system_rootfs_1,
      source = grep_src,
    },
  }
  in

  {
    include [
      grep_gen1,
      grep,
    ],
  }
