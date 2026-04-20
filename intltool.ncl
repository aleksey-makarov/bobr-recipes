let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let intltool_src =
    {
      name = "intltool-src-0.51.0",
      tag = "Fetch",
      config = {
      url = "https://launchpad.net/intltool/trunk/0.51.0/+download/intltool-0.51.0.tar.gz",
      hash = "md5:12e517cac2b57a0121cda351570f1e63",
      },
      inputs = {},
    }
  in

  let intltool_build_image =
    recipe.image "intltool-build-image" {} pkgs.system_image [
      pkgs.xml_parser,
    ]
  in

  let intltool =
    recipe.binary "intltool-0.51.0" {
      script_config = {
        pre_configure = m%"
          sed -i 's:\\${:\\$\\{:' intltool-update.in
        "%,
        post_install = "install -v -Dm644 ${MBUILD_SOURCE_DIR}/doc/I18N-HOWTO ${MBUILD_INSTALL_DIR}/usr/share/doc/intltool-0.51.0/I18N-HOWTO",
      },
    } intltool_build_image pkgs.buildscript_autotools [intltool_src]
  in

  {
    include [
      intltool_src,
      intltool,
    ],
  }
