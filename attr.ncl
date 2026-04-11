let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let attr_src =
    recipe.fetch "attr-src-2.5.2" {
      url = "https://download.savannah.gnu.org/releases/attr/attr-2.5.2.tar.gz",
      hash = "md5:227043ec2f6ca03c0948df5517f9c927",
    }
  in

  let attr =
    build.build_autotools {
      name = "attr-2.5.2",
      sources = [attr_src],
      script_config = {
        configure_args = [
          "--disable-static",
          "--sysconfdir=/etc",
          "--docdir=/usr/share/doc/attr-2.5.2",
        ],
      },
    }
  in

  {
    include [
      attr_src,
      attr,
    ],
  }
