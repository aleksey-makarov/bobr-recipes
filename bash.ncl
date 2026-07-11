let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let bash_src = fun version => fun hash => {
    name = "bash-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/bash/bash-%{version}.tar.gz",
        "https://mirrors.kernel.org/gnu/bash/bash-%{version}.tar.gz",
      ],
    },
  }
  in

  let bash_gen1 = {
    version | default = "5.3",
    source_object_hash | default = "0d5cd86965f869a26cf64f4b71be7b96f90a3ba8b3d74e27e8e9d9d5550f31ba",
    name = "bash-gen1-%{version}",
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
      source = bash_src version source_object_hash,
    },
  }
  in

  let bash = {
    version | default = "5.3",
    source_object_hash | default = "0d5cd86965f869a26cf64f4b71be7b96f90a3ba8b3d74e27e8e9d9d5550f31ba",
    name = "bash-%{version}",
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
      source = bash_src version source_object_hash,
    },
  }
  in

  {
    include [
      bash_gen1,
      bash,
    ],
  }
