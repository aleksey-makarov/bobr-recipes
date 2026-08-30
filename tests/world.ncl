# Aggregate artifact targets.
#
# `os_world` -- the shipped guest-side OS artifacts: kernel, initrd, and the
# three system images. Its dependency closure is the normal package graph.
#
# `host_bundle_world` -- all shipped host-side bundles and both release launcher
# packages. It carries no bundle smoke checks.
#
# `world` -- all shipped artifacts, and the default build target. It contains
# `os_world` and `host_bundle_world`, but no explicit test targets.
let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let os_world = {
    name = "os-world",
    tag = "Group",
    config = {},
    inputs =
      recipe.numbered_inputs [
        pkgs.linux,
        pkgs.initrd,
        pkgs.qemu_image,
        pkgs.qemu_weston_image,
        pkgs.qemu_gnome_image,
      ],
  }
  in

  let host_bundle_world = {
    name = "host-bundle-world",
    tag = "Group",
    config = {},
    inputs =
      recipe.numbered_inputs [
        pkgs.bobr_bundle_launcher_host_x86_64,
        pkgs.bobr_bundle_launcher_host_aarch64,
        pkgs.host_bundle_mc,
        pkgs.host_bundle_test_mesa,
        pkgs.host_bundle_qemu,
        pkgs.host_bundle_qemu_weston,
        pkgs.host_bundle_qemu_gnome,
      ],
  }
  in

  let world = {
    name = "world",
    tag = "Group",
    config = {},
    inputs = recipe.numbered_inputs [os_world, host_bundle_world],
  }
  in

  {
    include [os_world, host_bundle_world, world],
  }
