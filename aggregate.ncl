let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let source_attrs =
    std.array.sort
      std.string.compare
      (
        std.array.filter
          (fun attr => std.string.is_match "_src$" attr)
          (std.record.fields pkgs)
      )
  in

  let source_inputs =
    std.record.from_array (
      std.array.map
        (fun attr =>
          {
            field = attr,
            value = std.record.get attr pkgs,
          }
        )
        source_attrs
    )
  in

  let all_sources = {
    name = "all-sources",
    tag = "Group",
    config = {},
    inputs = source_inputs,
  }
  in

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
        pkgs.linux,
        pkgs.erofs_rootfs,
        pkgs.initrd,
      ],
  }
  in

  let all_new = {
    name = "all-new",
    tag = "Group",
    config = {},
    inputs =
      recipe.numbered_inputs [
        pkgs.base_filesystem_new,
        pkgs.system_runtime_files_new,
        pkgs.initrd_files_new,
        pkgs.buildpack_deps_rootfs_new,
        pkgs.alpine_rootfs_new,
        pkgs.ubuntu_rootfs_new,
        pkgs.busybox_rootfs_new,
        pkgs.golang_rootfs_new,
        pkgs.python_slim_rootfs_new,
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
      all_sources,
      all_image_rootfs,
      all_test_artifacts,
      all_new,
      all_artifacts,
    ],
  }
