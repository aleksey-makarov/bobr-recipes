# libtasn1 -- GNU ASN.1 parsing library. p11-kit needs it (and gcr pulls in
# p11-kit), so it is on the path to gnome-shell. Plain Autotools; ships its own
# generated parser and man pages, so no bison/help2man at build time.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let libtasn1_src = fun version =>
    fun hash =>
      {
        name = "libtasn1-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = [
            "https://ftp.gnu.org/gnu/libtasn1/libtasn1-%{version}.tar.gz",
            "https://mirrors.kernel.org/gnu/libtasn1/libtasn1-%{version}.tar.gz",
          ],
        },
      }
  in

  let libtasn1 = {
    version | default = "4.21.0",
    source_object_hash
      | default
      = "1d8a444a223cc5464240777346e125de51d8e6abf0b8bac742ac84609167dc87",
    name = "libtasn1-%{version}",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--disable-doc",
      ],
    },
    inputs = {
      source = libtasn1_src version source_object_hash,
    },
  }
  in

  {
    include [
      libtasn1,
    ],
  }
