# GNOME-only runtime files, merged into qemu_gnome_rootfs -- imported directly by
# os/qemu_gnome_image.ncl, NOT a pkgs entry. Everything GDM/session-specific
# lives here: the gdm user/group/PAM, custom.conf (autologin `user`,
# WaylandEnable), the networkd mask + NetworkManager, and the cursor gsettings
# override. System identity shared by all images stays in system-runtime-files;
# the Weston session path is in system-runtime-files-weston.
let recipe = import "../recipe-lib.ncl" in

let system_runtime_files_gnome_source = {
  name = "system-runtime-files-gnome-source",
  tag = "Source",
  object_hash = import "system-runtime-files-gnome.fsobj-hash" as 'Text,
  origin = {
    tag = "RecipePath",
    path = "os/system-runtime-files-gnome",
  },
}
in

{
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
