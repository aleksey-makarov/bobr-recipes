# Weston-only runtime files, merged into qemu_weston_rootfs -- imported directly
# by os/qemu_weston_image.ncl, NOT a pkgs entry. Everything to bring up Weston as
# the graphical session lives here: the tty1 autologin of `user`, the
# /etc/profile.d guard that hands the login session's seat identity to the user
# manager and starts weston.service, the weston.service unit itself, and the
# system weston.ini. System identity shared by all images stays in
# system-runtime-files; the GDM path is in system-runtime-files-gnome.
let recipe = import "../recipe-lib.ncl" in

let system_runtime_files_weston_source = {
  name = "system-runtime-files-weston-source",
  tag = "Source",
  object_hash = import "system-runtime-files-weston.fsobj-hash" as 'Text,
  origin = {
    tag = "RecipePath",
    path = "os/system-runtime-files-weston",
  },
}
in

{
  name = "system-runtime-files-weston",
  tag = "FsTreeImport",
  config = {
    install = {
      rules = [
        recipe.install.fs_tree_root_default_rule,
      ],
    },
  },
  inputs = {
    input = system_runtime_files_weston_source,
  },
}
