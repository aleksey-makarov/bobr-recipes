let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let qemu_kernel_config = {
    name = "qemu-kernel-config",
    tag = "Source",
    object_hash = import ".config.fsobj-hash" as 'Text,
    origin = {
      type = "path",
      path = "linux/.config",
      mode = "direct",
    },
  }
  in

  let qemu_kernel_buildscript = {
    name = "buildscript-qemu-kernel",
    tag = "Source",
    object_hash = import "kernel.sh.fsobj-hash" as 'Text,
    origin = {
      type = "path",
      path = "linux/kernel.sh",
      mode = "direct",
    },
  }
  in

  let qemu_kernel = {
    name = "qemu-kernel",
    tag = "Sandbox",
    config = {
      script_config = {},
      steps = [
        recipe.prepare_source_step,
        {
          name = "configure",
          run_as = "build-user",
          cwd = "@{build}",
          argv = ["@{script}", "@{build}/source", "@{out}"],
        },
        {
          name = "build",
          run_as = "build-user",
          cwd = "@{build}",
          argv = ["@{script}", "@{build}/source", "@{out}"],
        },
        {
          name = "install",
          run_as = "root",
          cwd = "@{build}",
          argv = ["@{script}", "@{build}/source", "@{out}"],
        },
      ],
    },
    inputs = {
      rootfs = pkgs.system_rootfs_2,
      script = qemu_kernel_buildscript,
      source = pkgs.linux_src,
      kernel_config = qemu_kernel_config,
    },
  }
  in

  {
    include [
      qemu_kernel,
    ],
  }
