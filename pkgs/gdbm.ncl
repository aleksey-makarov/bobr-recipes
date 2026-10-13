fun pkgs =>
  let gdbm_src = {
    version | default = "1.26",
    name = "gdbm-src-%{version}",
    tag = "Source",
    object_hash | default = "6a24504a14de4a744103dcb936be976df6fbe88ccff26065e54c1c47946f4a5e",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/gdbm/gdbm-%{version}.tar.gz",
        "https://mirrors.kernel.org/gnu/gdbm/gdbm-%{version}.tar.gz",
      ],
    },
  }
  in

  let gdbm = {
    name = "gdbm-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.c_runtime,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--enable-libgdbm-compat",
      ],
    },
    inputs = {
      source = pkgs.gdbm_src,
    },
  }
  in

  {
    include [
      gdbm_src,
      gdbm,
    ],
  }
