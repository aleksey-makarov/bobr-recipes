# libtirpc -- transport-independent RPC library (the SunRPC implementation that
# glibc no longer ships). A dependency of Samba. Autotools build; GSSAPI/Kerberos
# support is off.
# Configure version and hash through `pkgs.libtirpc_src`.
fun pkgs =>
  let libtirpc_src = {
    version | default = "1.3.7",
    name = "libtirpc-src-%{version}",
    tag = "Source",
    object_hash | default = "b47d3ac19d3549e54a05d0019a6c400674da716123858cfdb6d3bdd70a66c702",
    origin = {
      tag = "Http",
      url = "https://downloads.sourceforge.net/project/libtirpc/libtirpc/%{version}/libtirpc-%{version}.tar.bz2",
    },
  }
  in

  let libtirpc = {
    name = "libtirpc-%{inputs.source.version}",
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
        "--disable-gssapi",
      ],
    },
    inputs = {
      source = pkgs.libtirpc_src,
    },
  }
  in

  {
    include [
      libtirpc_src,
      libtirpc
    ]
  }
