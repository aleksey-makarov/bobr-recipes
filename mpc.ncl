let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let mpc_src = {
    name = "mpc-src-1.3.1",
    tag = "Fetch",
    config = {
      url = [
        "https://ftp.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz",
        "https://mirrors.kernel.org/gnu/mpc/mpc-1.3.1.tar.gz",
      ],
      hash = "md5:5c9bc658c9fd0f940e8e3e0f09530c62",
    },
    inputs = {},
  }
  in

  let mpc_build_image = {
    name = "mpc-build-image",
    tag = "Image",
    config = { ref_name | default = "mpc-build-image" } & {},
    inputs = {
      base = pkgs.system_image,
      inputs = [
        pkgs.gmp,
        pkgs.mpfr,
      ],
    },
  }
  in

  let mpc =
    recipe.binary
      "mpc-1.3.1"
      {
        script_config = {
          configure_args = [
            "--disable-static",
            "--docdir=/usr/share/doc/mpc-1.3.1",
          ],
        },
      }
      mpc_build_image
      pkgs.buildscript_autotools
      [mpc_src]
  in

  {
    include [
      mpc_src,
      mpc,
    ],
  }
