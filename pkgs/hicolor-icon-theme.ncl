# hicolor-icon-theme -- the base/fallback icon theme structure (index.theme and
# the directory layout every other theme inherits). Data only, no deps.
# Configure version and hash through `pkgs.hicolor_icon_theme_src`.
fun pkgs =>
  let hicolor_icon_theme_src = {
    version | default = "0.18",
    name = "hicolor-icon-theme-src-%{version}",
    tag = "Source",
    object_hash | default = "db0e50a80aa3bf64bb45cbca5cf9f75efd9348cf2ac690b907435238c3cf81d7",
    origin = {
      tag = "Http",
      url = [
        "https://icon-theme.freedesktop.org/releases/hicolor-icon-theme-%{version}.tar.xz",
        "https://sources.buildroot.net/hicolor-icon-theme/hicolor-icon-theme-%{version}.tar.xz",
      ],
    },
  }
  in

  let hicolor_icon_theme = {
    name = "hicolor-icon-theme-%{inputs.source.version}",
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
      source = pkgs.hicolor_icon_theme_src,
    },
  }
  in

  {
    include [
      hicolor_icon_theme_src,
      hicolor_icon_theme,
    ],
  }
