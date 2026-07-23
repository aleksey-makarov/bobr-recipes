let recipe = import "../recipe-lib.ncl" in
let graphics = import "qemu-graphics-base.ncl" in
let system_runtime_files_gnome = import "system-runtime-files-gnome.ncl" in

# The GNOME graphical QEMU guest: the shared graphics foundation (see
# qemu-graphics-base.ncl) plus the GNOME session -- gnome-shell/mutter as the
# Wayland compositor, launched by gdm, with settings-daemon and control-center.
# Boot it with tools/bobr-run-qemu-gnome.sh. The plain (qemu_image) and weston
# (qemu_weston_image) systems stay untouched. See 0629_gnome.md for direction.
fun pkgs =>
  # The image contents as a runtime closure: the graphics foundation roots plus
  # the GNOME-specific roots. The whole GTK/GNOME library stack below the
  # top-level apps is pulled automatically from the recipes' deps.runtime, so the
  # former hand-curated flat list is gone. Roots are only the things wanted for
  # their own sake (not reachable as a runtime dep of another root): the GNOME
  # runtime-files overlay (gdm wiring), and the top-level GNOME toolkit/session/
  # apps. "Invisible" deps that ldd cannot see (icon themes, base typelibs, the
  # GSettings dconf backend, the SVG loader) live in the owning recipes'
  # deps.runtime: gtk4, gjs, gdm, gnome-shell.
  let gnome_rootfs_contents = {
    name = "gnome-rootfs-contents",
    tag = "RootfsClosure",
    config = {},
    inputs =
      recipe.numbered_inputs (
        graphics.graphics_base_roots pkgs
        @ [
          # GDM session wiring (autologin `user`, wayland-sessions), the GNOME
          # networkd mask + NetworkManager, the cursor gsettings override.
          system_runtime_files_gnome,
          # Top-level GNOME toolkit/session/apps; the whole GNOME library stack is
          # their runtime closure. gtk4 also provides the gtk4-demo app.
          pkgs.gtk4,
          pkgs.gnome_shell,
          pkgs.gnome_session,
          pkgs.gdm,
          pkgs.gnome_settings_daemon,
          pkgs.gnome_control_center,
        ]
      ),
  }
  in

  let gnome_finalize = graphics.finalize "gnome" gnome_rootfs_contents in

  # The final GNOME rootfs = the merged contents plus the finalize cache layer.
  let qemu_gnome_rootfs = {
    name = "qemu-gnome-rootfs",
    tag = "TreeMerge",
    config = {},
    inputs =
      recipe.numbered_inputs [
        gnome_rootfs_contents,
        gnome_finalize,
      ],
  }
  in

  let qemu_gnome_image =
    recipe.erofs_image
      pkgs
      {
        name = "qemu-gnome-image",
        tree = qemu_gnome_rootfs,
      }
  in

  {
    include [
      qemu_gnome_rootfs,
      qemu_gnome_image,
    ],
  }
