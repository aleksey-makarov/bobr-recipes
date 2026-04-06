let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let qemu_rootfs =
    recipe.ext4_rootfs "qemu-rootfs" {
      size_mib = 512,
      label = "qemu-rootfs",
    } [
      pkgs.qemu_base_filesystem,
      pkgs.qemu_runtime_files,
      pkgs.glibc,
      pkgs.bash,
      pkgs.coreutils,
      pkgs.grep,
      pkgs.sed,
      pkgs.findutils,
      pkgs.gzip,
      pkgs.tar,
    ]
  in

  {
    include [qemu_rootfs],
  }
