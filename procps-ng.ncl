let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let procps_ng_src = {
    name = "procps-ng-src-4.0.5",
    tag = "Source",
    object_hash = "10da56c9dc78efa7f7abdc4cc35253661d969eb3d18bcb42ad6e4990a2db2139",
    origin = {
      type = "http",
      url = [
        "https://downloads.sourceforge.net/project/procps-ng/Production/procps-ng-4.0.5.tar.xz",
        "https://sourceforge.net/projects/procps-ng/files/Production/procps-ng-4.0.5.tar.xz/download",
      ],
      unpack = true,
    },
    meta = {},
  }
  in

  let procps_ng_build_image = {
    name = "procps-ng-build-image",
    tag = "Image",
    config = { ref_name | default = "procps-ng-build-image" } & {},
    inputs =
      { base = pkgs.system_image }
      & recipe.numbered_inputs [
        pkgs.libcap,
        pkgs.systemd,
      ],
  }
  in

  let procps_ng = {
    name = "procps-ng-4.0.5",
    tag = "Autotools",
    config = {
      configure_args = [
        "--docdir=/usr/share/doc/procps-ng-4.0.5",
        "--disable-static",
        "--disable-kill",
        "--enable-watch8bit",
        "--with-systemd",
      ],
    },
    inputs = {
      image = procps_ng_build_image,
      source = procps_ng_src,
    },
  }
  in

  {
    include [
      procps_ng_src,
      procps_ng,
    ],
  }
