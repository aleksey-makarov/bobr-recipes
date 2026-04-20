let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let procps_ng_src =
    {
      name = "procps-ng-src-4.0.5",
      tag = "Fetch",
      config = {
      url = [
        "https://downloads.sourceforge.net/project/procps-ng/Production/procps-ng-4.0.5.tar.xz",
        "https://sourceforge.net/projects/procps-ng/files/Production/procps-ng-4.0.5.tar.xz/download",
      ],
      hash = "md5:90803e64f51f192f3325d25c3335d057",
      },
      inputs = {},
    }
  in

  let procps_ng_build_image =
    {
      name = "procps-ng-build-image",
      tag = "Image",
      config = { ref_name | default = "procps-ng-build-image" } & {},
      inputs = {
        base = pkgs.system_image,
        inputs = [
      pkgs.libcap,
      pkgs.systemd,
    ],
      },
    }
  in

  let procps_ng =
    recipe.binary "procps-ng-4.0.5" {
      script_config = {
        configure_args = [
          "--docdir=/usr/share/doc/procps-ng-4.0.5",
          "--disable-static",
          "--disable-kill",
          "--enable-watch8bit",
          "--with-systemd",
        ],
      },
    } procps_ng_build_image pkgs.buildscript_autotools [procps_ng_src]
  in

  {
    include [
      procps_ng_src,
      procps_ng,
    ],
  }
