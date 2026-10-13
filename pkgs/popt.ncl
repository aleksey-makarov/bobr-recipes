# popt -- command-line option parsing library. A system dependency of Samba
# (its bundled copy was removed upstream). Autotools build.
# Configure version and hash through `pkgs.popt_src`.
fun pkgs =>
  let popt_src = {
    version | default = "1.19",
    name = "popt-src-%{version}",
    tag = "Source",
    object_hash | default = "c25a4838fc8e4c1c8aacb8bd620edb3084a3d63bf8987fdad3ca2758c63240f9",
    origin = {
      tag = "Http",
      url = "http://ftp.rpm.org/popt/releases/popt-1.x/popt-%{version}.tar.gz",
    },
  }
  in

  let popt = {
    name = "popt-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.c_runtime,
      ],
    },
    config = {
      configure_args = [
        "--libdir=/usr/lib",
        "--disable-static",
      ],
    },
    inputs = {
      source = pkgs.popt_src,
    },
  }
  in

  {
    include [
      popt_src,
      popt
    ]
  }
