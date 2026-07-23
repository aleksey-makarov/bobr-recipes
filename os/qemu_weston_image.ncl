let recipe = import "../recipe-lib.ncl" in
let graphics = import "qemu-graphics-base.ncl" in
let system_runtime_files_weston = import "system-runtime-files-weston.ncl" in

# A minimal graphical QEMU guest: the shared graphics foundation (see
# qemu-graphics-base.ncl) plus Weston as the Wayland compositor. Weston runs as a
# `systemd --user` service under the tty1/seat0 autologin (logind seat backend),
# wired up by system-runtime-files-weston. No GNOME/GTK stack -- this is the
# small "does the graphics path work" system, a sibling of the GNOME image, not a
# stage below it (GNOME uses its own compositor, mutter).
fun pkgs =>
  let weston_rootfs_contents = {
    name = "weston-rootfs-contents",
    tag = "RootfsClosure",
    config = {},
    inputs =
      recipe.numbered_inputs (
        graphics.graphics_base_roots pkgs
        @ [
          # tty1 autologin, the profile.d guard that starts weston.service on the
          # seat0 login, the weston.service unit and weston.ini.
          system_runtime_files_weston,
          pkgs.weston,
        ]
      ),
  }
  in

  let weston_finalize = graphics.finalize "weston" weston_rootfs_contents in

  # The final Weston rootfs = the merged contents plus the finalize cache layer.
  let qemu_weston_rootfs = {
    name = "qemu-weston-rootfs",
    tag = "TreeMerge",
    config = {},
    inputs =
      recipe.numbered_inputs [
        weston_rootfs_contents,
        weston_finalize,
      ],
  }
  in

  let qemu_weston_image =
    recipe.erofs_image
      pkgs
      {
        name = "qemu-weston-image",
        tree = qemu_weston_rootfs,
      }
  in

  {
    include [
      qemu_weston_rootfs,
      qemu_weston_image,
    ],
  }
