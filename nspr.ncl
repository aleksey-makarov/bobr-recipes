# NSPR -- Netscape Portable Runtime. Mozilla's platform-abstraction library;
# NSS builds on it, and evolution-data-server's camel links both (camel.c uses
# NSPR threading and the NSS certificate database unconditionally). Autotools,
# but configure lives in the nspr/ subdirectory of the tarball.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let nspr_src = fun version =>
    fun hash =>
      {
        name = "nspr-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://ftp.mozilla.org/pub/nspr/releases/v%{version}/src/nspr-%{version}.tar.gz",
        },
      }
  in

  let nspr = {
    version | default = "4.39",
    source_object_hash
      | default
      = "bbd02ee87a55676063a63e5bc819e0227de2666b47307b2a0134414cdf42368e",
    name = "nspr-%{version}",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      source_subdir = "nspr",
      configure_args = [
        "--enable-optimize",
        "--disable-debug",
        "--enable-64bit",
      ],
    },
    inputs = {
      source = nspr_src version source_object_hash,
    },
  }
  in

  {
    include [
      nspr,
    ],
  }
