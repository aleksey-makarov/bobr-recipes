fun pkgs =>
  let mpc_src = fun version => fun hash => {
    name = "mpc-src-%{version}",
    tag = "Source",
    object_hash = hash,
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
    version | default = "1.3.1",
    source_object_hash | default = "ab642492f5cf882b74aa0cb730cd410a81edcdbec895183ce930e706c1c759b8",
    name = "mpc-%{version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.gmp,
        pkgs.mpfr,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gmp,
        pkgs.mpfr,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--docdir=/usr/share/doc/mpc-%{version}",
      ],
    },
    inputs = {
      source = mpc_src version source_object_hash,
    },
  }
  in

  {
    include [
      mpc,
    ],
  }
