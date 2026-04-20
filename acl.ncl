let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let acl_src =
    {
      name = "acl-src-2.3.2",
      tag = "Fetch",
      config = {
      url = "https://download.savannah.gnu.org/releases/acl/acl-2.3.2.tar.xz",
      hash = "md5:590765dee95907dbc3c856f7255bd669",
      },
      inputs = {},
    }
  in

  let acl_build_image =
    {
      name = "acl-build-image",
      tag = "Image",
      config = { ref_name | default = "acl-build-image" } & {},
      inputs = {
        base = pkgs.system_image_2,
        inputs = [
      pkgs.attr,
    ],
      },
    }
  in

  let acl =
    recipe.binary "acl-2.3.2" {
      script_config = {
        configure_args = [
          "--disable-static",
          "--docdir=/usr/share/doc/acl-2.3.2",
        ],
      },
    } acl_build_image pkgs.buildscript_autotools [acl_src]
  in

  {
    include [
      acl_src,
      acl,
    ],
  }
