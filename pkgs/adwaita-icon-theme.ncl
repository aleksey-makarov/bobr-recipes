let recipe = import "../recipe-lib.ncl" in
# adwaita-icon-theme -- the default GNOME icon theme. Data (icons), but its
# meson build requires gtk4-update-icon-cache at configure time (required:true);
# the actual cache run is skip_if_destdir, so under our DESTDIR install it is
# skipped and the icon cache is produced later by the qemu_gnome_rootfs finalize
# step. Hence gtk4 is a build-only dep.
# Configure version and hash through `pkgs.adwaita_icon_theme_src`.
let branch = recipe.version_prefix 1 in

fun pkgs =>
  let adwaita_icon_theme_src = {
    version | default = "50.0",
    name = "adwaita-icon-theme-src-%{version}",
    tag = "Source",
    object_hash | default = "fac6e0401fca714780561a081b8f7e27c3bc1db34ebda4da175081f26b24d460",
    origin = {
      tag = "Http",
      url = "https://download.gnome.org/sources/adwaita-icon-theme/%{branch version}/adwaita-icon-theme-%{version}.tar.xz",
    },
  }
  in

  let adwaita_icon_theme = {
    name = "adwaita-icon-theme-%{inputs.source.version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.gtk4,
      ],
      runtime = [],
    },
    config = {
      setup_args = [
        "--buildtype=release",
      ],
    },
    inputs = {
      source = pkgs.adwaita_icon_theme_src,
    },
  }
  in

  {
    include [
      adwaita_icon_theme_src,
      adwaita_icon_theme,
    ],
  }
