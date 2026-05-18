let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let mpc_src = {
    name = "mpc-src-1.3.1",
    tag = "Source",
    object_hash = "0dbb9db1b4bf66eda95139d5a0358f6db38718481507ab3a32a34efcd870f2e8",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz",
        "https://mirrors.kernel.org/gnu/mpc/mpc-1.3.1.tar.gz",
      ],
    },
  }
  in

  let mpc = {
    name = "mpc-1.3.1",
    tag = "AutotoolsPackage",
    deps = {
      build = [
        pkgs.gmp,
        pkgs.mpfr,
      ],
      runtime = [
        pkgs.glibc,
        pkgs.gmp,
        pkgs.mpfr,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--docdir=/usr/share/doc/mpc-1.3.1",
      ],
    },
    inputs = {
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
