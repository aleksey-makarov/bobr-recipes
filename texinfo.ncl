let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let texinfo_src = {
    name = "texinfo-src-7.2",
    tag = "Source",
    object_hash = "0329d7788fbef113fa82cb80889ca197a344ce0df7646fe000974c5d714363a6",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/texinfo/texinfo-7.2.tar.xz",
        "https://mirrors.kernel.org/gnu/texinfo/texinfo-7.2.tar.xz",
      ],
    },
  }
  in

  let texinfo = {
    name = "texinfo-7.2",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.ncurses,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.ncurses_libs,
        pkgs.perl,
      ],
    },
    config = {
      pre_configure = {
        name = "patch_texinfo_sources",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          "sed 's/! $output_file eq/$output_file ne/' -i tp/Texinfo/Convert/*.pm",
        ],
      },
      post_install = {
        name = "install_tex_support",
        run_as = "root",
        cwd = "@{build}/build",
        argv = [
          "/bin/sh",
          "-ec",
          "make DESTDIR=\"@{out}\" TEXMF=/usr/share/texmf install-tex",
        ],
      },
    },
    inputs = {
      source = texinfo_src,
    },
  }
  in

  {
    include [
      texinfo,
    ],
  }
