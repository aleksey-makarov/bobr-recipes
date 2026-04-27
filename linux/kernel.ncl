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
    meta = {},
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
    meta = {},
  }
  in

  let qemu_kernel = {
    name = "qemu-kernel",
    tag = "Binary",
    config = {
      script_config = {},
      steps = [
        {
          name = "configure",
          run_as = "build-user",
          cwd = "@{build}",
          argv = ["@{script}", "@{source}", "@{out}"],
        },
        {
          name = "build",
          run_as = "build-user",
          cwd = "@{build}",
          argv = ["@{script}", "@{source}", "@{out}"],
        },
        {
          name = "install",
          run_as = "root",
          cwd = "@{build}",
          argv = ["@{script}", "@{source}", "@{out}"],
        },
      ],
    },
    inputs = {
      image = pkgs.system_image_2,
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
