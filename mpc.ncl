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
    inputs =
      { base = pkgs.system_image }
      & recipe.numbered_inputs [
        pkgs.gmp,
        pkgs.mpfr,
      ],
  }
  in

  let mpc = {
    name = "mpc-1.3.1",
    tag = "Autotools",
    config = {
      configure_args = [
        "--disable-static",
        "--docdir=/usr/share/doc/mpc-1.3.1",
      ],
    },
    inputs = {
      image = mpc_build_image,
      source = mpc_src,
    },
  }
  in

  {
    include [
      mpc_src,
      mpc,
    ],
  }
