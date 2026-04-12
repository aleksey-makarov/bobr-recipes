let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let qemu_kernel_config =
    recipe.text "qemu-kernel-config" {
      executable = false,
      source = import ".config" as 'Text,
    }
  in

  let qemu_kernel_buildscript =
    recipe.text "buildscript-qemu-kernel" {
      executable = true,
      source = import "kernel.sh" as 'Text,
    }
  in

  let qemu_kernel =
    recipe.binary "qemu-kernel" {
      script_config = {},
    } pkgs.system_image qemu_kernel_buildscript [
      pkgs.linux_src,
      qemu_kernel_config,
    ]
  in

  {
    include [
      qemu_kernel,
    ],
  }
