let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let texinfo_src = {
    name = "texinfo-src-7.2",
    tag = "Fetch",
    config = {
      url = [
        "https://ftp.gnu.org/gnu/texinfo/texinfo-7.2.tar.xz",
        "https://mirrors.kernel.org/gnu/texinfo/texinfo-7.2.tar.xz",
      ],
      hash = "md5:11939a7624572814912a18e76c8d8972",
    },
    inputs = {},
  }
  in

  let texinfo =
    let script_config = {
      pre_configure = "sed 's/! $output_file eq/$output_file ne/' -i tp/Texinfo/Convert/*.pm",
      configure_args = [],
      post_install = "make DESTDIR=\"${MBUILD_INSTALL_DIR}\" TEXMF=/usr/share/texmf install-tex",
    }
    in
    recipe.binary
      "texinfo-7.2"
      {
        include script_config,
      }
      pkgs.system_image
      pkgs.buildscript_autotools
      [texinfo_src]
  in

  {
    include [
      texinfo_src,
      texinfo,
    ],
  }
