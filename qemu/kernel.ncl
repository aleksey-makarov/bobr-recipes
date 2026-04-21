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

  let qemu_kernel =
    recipe.binary
      "qemu-kernel"
      {
        script_config = {},
      }
      pkgs.system_image_2
      qemu_kernel_buildscript
      [
        pkgs.linux_src,
        qemu_kernel_config,
      ]
  in

  {
    include [
      qemu_kernel,
    ],
  }
