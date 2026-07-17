# nettle -- low-level cryptographic library (libnettle + libhogweed). The
# crypto backend GnuTLS builds on. Autotools; libhogweed needs GMP. The 3.10
# series is the one GnuTLS 3.8.x targets.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let nettle_src = fun version =>
    fun hash =>
      {
        name = "nettle-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://ftp.gnu.org/gnu/nettle/nettle-%{version}.tar.gz",
        },
      }
  in

  let nettle = {
    version | default = "3.10.2",
    source_object_hash
      | default
      = "fe9ff51cb1f2abb5e65a6b8c10a92da0ab5ab6eaf26e7fc2b675c45f1fb519b5",
    name = "nettle-%{version}",
    tag = "AutotoolsInstall",
    deps = {
      build = [
        pkgs.gmp,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.gmp,
      ],
    },
    config = {
      configure_args = [
        "--libdir=/usr/lib",
        "--disable-static",
        "--disable-documentation",
      ],
    },
    inputs = {
      source = nettle_src version source_object_hash,
    },
  }
  in

  { include [ nettle ] }
