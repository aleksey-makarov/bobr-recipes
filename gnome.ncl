let recipe = import "recipe-lib.ncl" in

# A separate rootfs branch for the graphical (eventually GNOME) QEMU guest, so
# the plain rootfs/erofs_rootfs path stays small and untouched. For now it is
# the base rootfs plus the accel-only graphics stack (libdrm + Mesa/virgl) and
# the kmscube DRM/EGL smoke test. It will grow toward a full GNOME session; see
# 0629_gnome.md for the direction. Boot it with tools/bobr-run-qemu-gnome.sh.
fun pkgs =>
  let gnome_rootfs = {
    name = "gnome-rootfs",
    tag = "TreeMerge",
    config = {},
    inputs =
      recipe.numbered_inputs [
        pkgs.rootfs,
        pkgs.libdrm,
        pkgs.mesa,
        pkgs.kmscube,
      ],
  }
  in

  let gnome_erofs_rootfs =
    recipe.erofs_image
      pkgs
      {
        name = "gnome-erofs-rootfs",
        tree = gnome_rootfs,
      }
  in

  {
    include [
      gnome_rootfs,
      gnome_erofs_rootfs,
    ],
  }
