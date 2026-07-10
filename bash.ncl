let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let bash_src = {
    name = "bash-src-5.3",
    tag = "Source",
    object_hash = "0d5cd86965f869a26cf64f4b71be7b96f90a3ba8b3d74e27e8e9d9d5550f31ba",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/bash/bash-5.3.tar.gz",
        "https://mirrors.kernel.org/gnu/bash/bash-5.3.tar.gz",
      ],
    },
  }
  in

  let bash_gen1 = {
    name = "bash-gen1-5.3",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = [
        "--without-bash-malloc",
        "--disable-readline",
      ],
      post_install = {
        name = "link_sh",
        run_as = "root",
        argv = [
          "ln",
          "-svf",
          "bash",
          "@{out}/usr/bin/sh",
        ],
      },
    },
    inputs = {
      _rootfs = pkgs.buildpack_deps_rootfs,
      source = bash_src,
    },
  }
  in

  let bash = {
    name = "bash-5.3",
    tag = "AutotoolsRootfs",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      configure_args = [
        "--without-bash-malloc",
      ],
      post_install = {
        name = "link_sh",
        run_as = "root",
        argv = [
          "ln",
          "-svf",
          "bash",
          "@{out}/usr/bin/sh",
        ],
      },
    },
    inputs = {
      _rootfs = pkgs.system_rootfs_1,
      source = bash_src,
    },
  }
  in

  {
    include [
      bash_gen1,
      bash,
    ],
  }
