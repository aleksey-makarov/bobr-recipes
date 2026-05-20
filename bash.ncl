let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let bash_src = {
    name = "bash-src-5.3",
    tag = "Source",
    object_hash = "c5e99dc9b938b5934034609d191ee1faa4530a37a1732b60333d716086cf2e8a",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/bash/bash-5.3.tar.gz",
        "https://mirrors.kernel.org/gnu/bash/bash-5.3.tar.gz",
      ],
    },
  }
  in

  let bash_gen1 = {
    name = "bash-gen1-5.3",
    tag = "Autotools",
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
      rootfs = pkgs.buildpack_deps_rootfs,
      source = bash_src,
    },
  }
  in

  let bash = {
    name = "bash-5.3",
    tag = "Autotools",
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
      rootfs = pkgs.system_rootfs_1,
      source = bash_src,
    },
  }
  in

  {
    include [
      bash_src,
      bash_gen1,
      bash,
    ],
  }
