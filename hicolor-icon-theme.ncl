# hicolor-icon-theme -- the base/fallback icon theme structure (index.theme and
# the directory layout every other theme inherits). Data only, no deps.
# `version`/`source_object_hash` are node fields (overridable), as in linux.ncl.

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
    version | default = "0.18",
    source_object_hash | default = "db0e50a80aa3bf64bb45cbca5cf9f75efd9348cf2ac690b907435238c3cf81d7",
    name = "hicolor-icon-theme-%{version}",
    tag = "MesonInstall",
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
      source = mk_src version source_object_hash,
    },
  }
  in

  {
    include [
      hicolor_icon_theme,
    ],
  }
