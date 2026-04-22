let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let qemu_kernel_config = {
    name = "qemu-kernel-config",
    tag = "Text",
    config = {
      executable = false,
      source = import ".config" as 'Text,
    },
    inputs = {},
  }
  in

  let qemu_kernel_buildscript = {
    name = "buildscript-qemu-kernel",
    tag = "Text",
    config = {
      executable = true,
      source = import "kernel.sh" as 'Text,
    },
    inputs = {},
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
          cwd = "${build}",
          argv = ["${script}", "${source}", "${out}"],
        },
        {
          name = "build",
          run_as = "build-user",
          cwd = "${build}",
          argv = ["${script}", "${source}", "${out}"],
        },
        {
          name = "install",
          run_as = "root",
          cwd = "${build}",
          argv = ["${script}", "${source}", "${out}"],
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
