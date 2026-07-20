let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let intltool_src = fun version => fun hash => {
    name = "intltool-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = [
        "https://gstreamer.freedesktop.org/src/mirror/intltool-%{version}.tar.gz",
        "https://ftp.osuosl.org/pub/blfs/conglomeration/intltool/intltool-%{version}.tar.gz",
        "https://launchpad.net/intltool/trunk/%{version}/+download/intltool-%{version}.tar.gz",
      ],
    },
  }
  in

  let intltool = {
    version | default = "0.51.0",
    source_object_hash | default = "67c74d94196b153b774ab9f89b2fa6c6ba79352407037c8c14d5aeb334e959cd",
    name = "intltool-%{version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.perl_xml_parser,
      ],
      runtime = [
        pkgs.perl,
        pkgs.perl_xml_parser,
      ],
    },
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
          "/usr/share/doc/intltool-%{version}/I18N-HOWTO",
        ],
      },
    },
    inputs = {
      source = intltool_src version source_object_hash,
    },
  }
  in

  {
    include [
      intltool,
    ],
  }
