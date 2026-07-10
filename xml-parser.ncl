let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let xml_parser_src = {
    name = "xml-parser-src-2.47",
    tag = "Source",
    object_hash = "ad4aae643ec784f489b956abe952432871a622d4e2b5c619e8855accbfc4d1d8",
    origin = {
      tag = "Http",
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
      source = xml_parser_src,
    },
  }
  in

  {
    include [
      xml_parser,
    ],
  }
