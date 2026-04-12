let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let attr_src =
    recipe.fetch "attr-src-2.5.2" {
      url = "https://download.savannah.gnu.org/releases/attr/attr-2.5.2.tar.gz",
      hash = "md5:227043ec2f6ca03c0948df5517f9c927",
    }
  in

  let attr =
    recipe.binary "attr-2.5.2" {
      script_config = {
        configure_args = [
          "--disable-static",
          "--sysconfdir=/etc",
          "--docdir=/usr/share/doc/attr-2.5.2",
        ],
      },
    } pkgs.system_image_2 pkgs.buildscript_autotools [attr_src]
  in

  {
    include [
      attr_src,
      attr,
    ],
  }
