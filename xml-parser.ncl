let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let xml_parser_src = {
    name = "xml-parser-src-2.47",
    tag = "Source",
    object_hash = "9c0675229f11d6c28c8e57c26de8b57a42f24d5b886a33f1ebb8bbda4fda2e53",
    origin = {
      type = "http",
      url = "https://cpan.metacpan.org/authors/id/T/TO/TODDR/XML-Parser-2.47.tar.gz",
    },
  }
  in

  let xml_parser = {
    name = "xml-parser-2.47",
    tag = "PerlModule",
    deps = {
      build = [
        pkgs.expat,
      ],
      runtime = [
        pkgs.perl,
        pkgs.expat,
      ],
    },
    config = {},
    inputs = {
      rootfs = pkgs.system_rootfs,
      source = xml_parser_src,
    },
  }
  in

  {
    include [
      xml_parser_src,
      xml_parser,
    ],
  }
