# libtirpc -- transport-independent RPC library (the SunRPC implementation that
# glibc no longer ships). A dependency of Samba. Autotools build; GSSAPI/Kerberos
# support is off.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let libtirpc_src = fun version =>
    fun hash =>
      {
        name = "libtirpc-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://downloads.sourceforge.net/project/libtirpc/libtirpc/%{version}/libtirpc-%{version}.tar.bz2",
        },
      }
  in

  let libtirpc = {
    version | default = "1.3.7",
    source_object_hash
      | default
      = "b47d3ac19d3549e54a05d0019a6c400674da716123858cfdb6d3bdd70a66c702",
    name = "libtirpc-%{version}",
    tag = "AutotoolsInstall",
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
        "--disable-gssapi",
      ],
    },
    inputs = {
      source = libtirpc_src version source_object_hash,
    },
  }
  in

  { include [ libtirpc ] }
