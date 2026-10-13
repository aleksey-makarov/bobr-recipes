# libtasn1 -- GNU ASN.1 parsing library. p11-kit needs it (and gcr pulls in
# p11-kit), so it is on the path to gnome-shell. Plain Autotools; ships its own
# generated parser and man pages, so no bison/help2man at build time.
# Configure version and hash through `pkgs.libtasn1_src`.
fun pkgs =>
  let libtasn1_src = {
    version | default = "4.21.0",
    name = "libtasn1-src-%{version}",
    tag = "Source",
    object_hash | default = "1d8a444a223cc5464240777346e125de51d8e6abf0b8bac742ac84609167dc87",
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
    name = "libtasn1-%{inputs.source.version}",
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
        "--disable-doc",
      ],
    },
    inputs = {
      source = pkgs.libtasn1_src,
    },
  }
  in

  {
    include [
      libtasn1_src,
      libtasn1,
    ],
  }
