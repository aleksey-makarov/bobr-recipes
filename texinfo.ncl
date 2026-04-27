let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let texinfo_src = {
    name = "texinfo-src-7.2",
    tag = "Source",
    object_hash = "bf7334808d0c4c23a617aa9d92fc6958bad23d092a354c00a5b2537920ccecf7",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/texinfo/texinfo-7.2.tar.xz",
        "https://mirrors.kernel.org/gnu/texinfo/texinfo-7.2.tar.xz",
      ],
      unpack = true,
    },
    meta = {},
  }
  in

  let texinfo = {
    name = "texinfo-7.2",
    tag = "Autotools",
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
        cwd = "@{build}",
        argv = [
          "/bin/sh",
          "-ec",
          "make DESTDIR=\"@{out}\" TEXMF=/usr/share/texmf install-tex",
        ],
      },
    },
    inputs = {
      image = pkgs.system_image,
      source = texinfo_src,
    },
  }
  in

  {
    include [
      texinfo_src,
      texinfo,
    ],
  }
