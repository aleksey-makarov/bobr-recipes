# popt -- command-line option parsing library. A system dependency of Samba
# (its bundled copy was removed upstream). Autotools build.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let popt_src = fun version =>
    fun hash =>
      {
        name = "popt-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "http://ftp.rpm.org/popt/releases/popt-1.x/popt-%{version}.tar.gz",
        },
      }
  in

  let popt = {
    version | default = "1.19",
    source_object_hash
      | default
      = "c25a4838fc8e4c1c8aacb8bd620edb3084a3d63bf8987fdad3ca2758c63240f9",
    name = "popt-%{version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
      ],
    },
    config = {
      configure_args = [
        "--libdir=/usr/lib",
        "--disable-static",
      ],
    },
    inputs = {
      source = popt_src version source_object_hash,
    },
  }
  in

  { include [ popt ] }
