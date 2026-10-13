# PCRE2 (Perl-compatible regular expressions, v2). GLib 2.x hard-requires it
# (the bundled PCRE was removed).
# Configure version and hash through `pkgs.pcre2_src`.
fun pkgs =>
  let pcre2_src = {
    version | default = "10.45",
    name = "pcre2-src-%{version}",
    tag = "Source",
    object_hash | default = "21547f3516120c75597e5b30a992e27a592a31950b5140e7b8bfde3f192033c4",
    origin = {
      tag = "Http",
      url = "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-%{version}/pcre2-%{version}.tar.bz2",
    },
  }
  in

  let pcre2 = {
    name = "pcre2-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.c_runtime,
      ],
    },
    config = {
      configure_args = [
        "--enable-unicode",
        "--enable-jit",
        "--disable-static",
      ],
    },
    inputs = {
      source = pkgs.pcre2_src,
    },
  }
  in

  {
    include [
      pcre2_src,
      pcre2,
    ],
  }
