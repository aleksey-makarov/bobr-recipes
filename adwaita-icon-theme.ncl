# adwaita-icon-theme -- the default GNOME icon theme. Data (icons), but its
# meson build requires gtk4-update-icon-cache at configure time (required:true);
# the actual cache run is skip_if_destdir, so under our DESTDIR install it is
# skipped and the icon cache is produced later by the gnome_rootfs finalize
# step. Hence gtk4 is a build-only dep. `version`/`source_object_hash` are node fields
# (overridable), as in linux.ncl.

let branch = fun version =>
  let m = std.string.find "^([0-9]+)" version in
  if m.index == 0 && std.array.length m.groups == 1 then std.array.at 0 m.groups
  else std.fail_with "adwaita-icon-theme.ncl: version must start with a number"
in

fun pkgs =>
  let mk_src = fun version =>
    fun hash =>
      {
        name = "adwaita-icon-theme-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/adwaita-icon-theme/%{branch version}/adwaita-icon-theme-%{version}.tar.xz",
        },
      }
  in

  let adwaita_icon_theme = {
    version | default = "50.0",
    source_object_hash | default = "fac6e0401fca714780561a081b8f7e27c3bc1db34ebda4da175081f26b24d460",
    name = "adwaita-icon-theme-%{version}",
    tag = "MesonInstall",
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
      source = mk_src version source_object_hash,
    },
  }
  in

  {
    include [
      adwaita_icon_theme,
    ],
  }
