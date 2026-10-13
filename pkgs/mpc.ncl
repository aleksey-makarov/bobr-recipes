fun pkgs =>
  # Configure version and hash through pkgs.mpc_src.
  let mpc_src = {
    version | default = "1.3.1",
    name = "mpc-src-%{version}",
    tag = "Source",
    object_hash | default = "ab642492f5cf882b74aa0cb730cd410a81edcdbec895183ce930e706c1c759b8",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/mpc/mpc-%{version}.tar.gz",
        "https://mirrors.kernel.org/gnu/mpc/mpc-%{version}.tar.gz",
      ],
    },
  }
  in

  let mpc = {
    name = "mpc-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.gmp,
        pkgs.mpfr,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.gmp,
        pkgs.mpfr,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--docdir=/usr/share/doc/mpc-%{inputs.source.version}",
      ],
    },
    inputs = {
      source = pkgs.mpc_src,
    },
  }
  in

  {
    include [
      mpc,
      mpc_src,
    ],
  }
