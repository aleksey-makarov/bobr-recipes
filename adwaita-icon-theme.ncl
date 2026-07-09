# adwaita-icon-theme -- the default GNOME icon theme. Data (icons), but its
# meson build requires gtk4-update-icon-cache at configure time (required:true);
# the actual cache run is skip_if_destdir, so under our DESTDIR install it is
# skipped and the icon cache is produced later by the gnome_rootfs finalize
# step. Hence gtk4 is a build-only dep. `version`/`hashes` are node fields
# (overridable), as in linux.ncl.
let default_version = "50.0" in
let default_hashes = {
  "50.0" = "5806ab317350db8111f87b81b517f63e9f885b9661e43d8fd1a64ebb75dc921d",
}
in

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
    version | default = default_version,
    hashes | default = default_hashes,
    name = "adwaita-icon-theme-%{version}",
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
      source = mk_src version (hashes."%{version}"),
    },
  }
  in

  {
    include [
      adwaita_icon_theme,
    ],
  }
