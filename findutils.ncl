let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let findutils_src =
    {
      name = "findutils-src-4.10.0",
      tag = "Fetch",
      config = {
      url = [
        "https://ftp.gnu.org/gnu/findutils/findutils-4.10.0.tar.xz",
        "https://mirrors.kernel.org/gnu/findutils/findutils-4.10.0.tar.xz",
      ],
      hash = "md5:870cfd71c07d37ebe56f9f4aaf4ad872",
      },
      inputs = {},
    }
  in

  let findutils_gen1 =
    recipe.binary "findutils-gen1-4.10.0" {
      script_config = {
        configure_args = [
          "--disable-nls",
          "--without-selinux",
          "--localstatedir=/var/lib/locate",
        ],
      },
    } pkgs.host_image pkgs.buildscript_autotools [findutils_src]
  in

  let findutils =
    recipe.binary "findutils-4.10.0" {
      script_config = {
        configure_args = [
          "--disable-nls",
          "--without-selinux",
          "--localstatedir=/var/lib/locate",
        ],
      },
    } pkgs.system_image_1 pkgs.buildscript_autotools [findutils_src]
  in

  {
    include [
      findutils_src,
      findutils_gen1,
      findutils,
    ],
  }
