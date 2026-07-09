# hicolor-icon-theme -- the base/fallback icon theme structure (index.theme and
# the directory layout every other theme inherits). Data only, no deps.
# `version`/`hashes` are node fields (overridable), as in linux.ncl.
let default_version = "0.18" in
let default_hashes = {
  "0.18" = "f1cded887594e9ea7630f37a1a7611336a8f49d72da0de41d2234fbe90c4d084",
}
in

fun pkgs =>
  let mk_src = fun version =>
    fun hash =>
      {
        name = "hicolor-icon-theme-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://icon-theme.freedesktop.org/releases/hicolor-icon-theme-%{version}.tar.xz",
        },
      }
  in

  let hicolor_icon_theme = {
    version | default = default_version,
    hashes | default = default_hashes,
    name = "hicolor-icon-theme-%{version}",
    tag = "Meson",
    deps = {
      build = [],
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
      hicolor_icon_theme,
    ],
  }
