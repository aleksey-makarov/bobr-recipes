let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let all_image_rootfs = {
    name = "all-image-rootfs",
    tag = "Group",
    config = {},
    inputs =
      recipe.numbered_inputs [
        pkgs.buildpack_deps_rootfs,
        pkgs.alpine_rootfs,
        pkgs.ubuntu_rootfs,
        pkgs.busybox_rootfs,
        pkgs.golang_rootfs,
        pkgs.python_slim_rootfs,
      ],
  }
  in

  let all_test_artifacts = {
    name = "all-test-artifacts",
    tag = "Group",
    config = {},
    inputs =
      recipe.numbered_inputs [
        pkgs.test_reports,
        pkgs.qemu_kernel,
        pkgs.qemu_erofs_rootfs,
      ],
  }
  in

  let all_artifacts = {
    name = "all-artifacts",
    tag = "Group",
    config = {},
    inputs =
      recipe.numbered_inputs [
        all_image_rootfs,
        all_test_artifacts,
      ],
  }
  in

  {
    include [
      all_image_rootfs,
      all_test_artifacts,
      all_artifacts,
    ],
  }
