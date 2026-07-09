let recipe = import "../recipe-lib.ncl" in

# Gnome-only runtime files, merged into gnome_rootfs but NOT the plain rootfs, so
# the plain (bobr-run-qemu.sh) system stays a headless serial console with no
# graphics. Everything graphical/session-launch lives here: the tty1 autologin,
# the Weston user service + its graphical-session enablement, and the tty1 guard
# that starts the graphical session. System-level identity/config shared by both
# systems stays in system-runtime-files.
fun _pkgs =>
  let system_runtime_files_gnome_source = {
    name = "system-runtime-files-gnome-source",
    tag = "Source",
    object_hash = import "system-runtime-files-gnome.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "filesystem/system-runtime-files-gnome",
    },
  }
  in

  let system_runtime_files_gnome = {
    name = "system-runtime-files-gnome",
    tag = "FsTreeImport",
    config = {
      install = {
        rules = [
          recipe.install.fs_tree_root_default_rule,
        ],
      },
    },
    inputs = {
      input = system_runtime_files_gnome_source,
    },
  }
  in

  {
    include [
      system_runtime_files_gnome,
    ],
  }
