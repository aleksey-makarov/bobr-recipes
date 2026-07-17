let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let gdbm_src = fun version => fun hash => {
    name = "gdbm-src-%{version}",
    tag = "Source",
    object_hash = hash,
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
    version | default = "1.26",
    source_object_hash | default = "6a24504a14de4a744103dcb936be976df6fbe88ccff26065e54c1c47946f4a5e",
    name = "gdbm-%{version}",
    tag = "AutotoolsInstall",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--enable-libgdbm-compat",
      ],
    },
    inputs = {
      source = gdbm_src version source_object_hash,
    },
  }
  in

  {
    include [
      gdbm,
    ],
  }
