# PCRE2 (Perl-compatible regular expressions, v2). GLib 2.x hard-requires it
# (the bundled PCRE was removed). `version`/`source_object_hash` are node fields so an
# overlay can override the version (and add its hash), as in linux.ncl.

fun pkgs =>
  let mk_src = fun version =>
    fun hash =>
      {
        name = "pcre2-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-%{version}/pcre2-%{version}.tar.bz2",
        },
      }
  in

  let pcre2 = {
    version | default = "10.45",
    source_object_hash | default = "21547f3516120c75597e5b30a992e27a592a31950b5140e7b8bfde3f192033c4",
    name = "pcre2-%{version}",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
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
      source = mk_src version source_object_hash,
    },
  }
  in

  {
    include [
      pcre2,
    ],
  }
