let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let intltool_src = {
    name = "intltool-src-0.51.0",
    tag = "Source",
    object_hash = "1e2ff2a47dd7c74c37371c1f7beb5fdfe410d6632385f2885abd5ed2054be305",
    origin = {
      type = "http",
      url = "https://launchpad.net/intltool/trunk/0.51.0/+download/intltool-0.51.0.tar.gz",
    },
    meta = {},
  }
  in

  let intltool_build_rootfs = {
    name = "intltool-build-rootfs",
    tag = "TreeMerge",
    config = {},
    inputs =
      { base = pkgs.system_rootfs }
      & recipe.numbered_inputs [
        pkgs.xml_parser,
      ],
  }
  in

  let intltool = {
    name = "intltool-0.51.0",
    tag = "Autotools",
    config = {
      pre_configure = {
        name = "patch_intltool_update",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            sed -i 's:\\$[{]:\\$\\\\{:g' intltool-update.in
          "%,
        ],
      },
      post_install = {
        name = "install_i18n_howto",
        run_as = "root",
        argv = [
          "install",
          "-v",
          "-Dm644",
          "@{build}/source/doc/I18N-HOWTO",
          "@{out}/usr/share/doc/intltool-0.51.0/I18N-HOWTO",
        ],
      },
    },
    inputs = {
      rootfs = intltool_build_rootfs,
      source = intltool_src,
    },
  }
  in

  {
    include [
      intltool_src,
      intltool,
    ],
  }
