let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let texinfo_src =
    recipe.fetch "texinfo-src-7.2" {
      url = [
        "https://ftp.gnu.org/gnu/texinfo/texinfo-7.2.tar.xz",
        "https://mirrors.kernel.org/gnu/texinfo/texinfo-7.2.tar.xz",
      ],
      hash = "md5:11939a7624572814912a18e76c8d8972",
    }
  in

  let texinfo =
    build.build_autotools {
      name = "texinfo-7.2",
      sources = [texinfo_src],
      script_config = {
        pre_configure = "sed 's/! $output_file eq/$output_file ne/' -i tp/Texinfo/Convert/*.pm",
        configure_args = [],
        post_install = "make DESTDIR=\"/out/${out}\" TEXMF=/usr/share/texmf install-tex",
      },
    }
  in

  {
    include [
      texinfo_src,
      texinfo,
    ],
  }
