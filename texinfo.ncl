let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let texinfo_src = {
    name = "texinfo-src-7.2",
    tag = "Source",
    object_hash = "1b62d2456d5314709f83c6e6cca7832eb723956369e51b6e1dd31bfa330d20ac",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/texinfo/texinfo-7.2.tar.xz",
        "https://mirrors.kernel.org/gnu/texinfo/texinfo-7.2.tar.xz",
      ],
    },
    meta = {},
  }
  in

  let texinfo = {
    name = "texinfo-7.2",
    tag = "AutotoolsSandbox",
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
      rootfs = pkgs.system_rootfs,
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
