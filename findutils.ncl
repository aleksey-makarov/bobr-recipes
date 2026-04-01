let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let findutils_src_4_10_0 =
    recipe.fetch "findutils-src-4.10.0" {
      url = [
        "https://ftp.gnu.org/gnu/findutils/findutils-4.10.0.tar.xz",
        "https://mirrors.kernel.org/gnu/findutils/findutils-4.10.0.tar.xz",
      ],
      hash = "md5:870cfd71c07d37ebe56f9f4aaf4ad872",
    }
  in

  let findutils_gen1_4_10_0 =
    recipe.binary "findutils-gen1-4.10.0" {
      kind = "binary-output",
      optimize = "size",
      script_config = {
        configure_args = [
          "--disable-nls",
          "--without-selinux",
          "--localstatedir=/var/lib/locate",
        ],
      },
    } pkgs.host_image pkgs.buildscript_autotools [findutils_src_4_10_0]
  in

  let findutils_4_10_0 =
    build.build_autotools {
      name = "findutils-4.10.0",
      sources = [findutils_src_4_10_0],
      script_config = {
        configure_args = [
          "--disable-nls",
          "--without-selinux",
          "--localstatedir=/var/lib/locate",
        ],
      },
    }
  in

  {
    include [
      findutils_src_4_10_0,
      findutils_gen1_4_10_0,
      findutils_4_10_0,
    ],
  }
